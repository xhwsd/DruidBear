--[[
Name: KuBa-Spell-1.0
Revision: $Rev: 10008 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 法术相关操作库。
Dependencies: AceLibrary, SpellCache-1.0
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Spell-1.0"
-- 次要版本
local MINOR_VERSION = "$Revision: 10008 $"

-- 检验AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

-- 检查依赖库
---@param dependencies table 依赖库名称列表
local function CheckDependency(dependencies)
	for _, value in ipairs(dependencies) do
		if not AceLibrary:HasInstance(value) then
			error(format("%s requires %s to function properly", MAJOR_VERSION, value))
		end
	end
end

CheckDependency({
	-- 法术缓存
	"SpellCache-1.0"
})

-- 持续时间匹配文本
local DURATION_PATTERNS = {
	"在(%d+%.?%d*)秒",
	"持续(%d+%.?%d*)秒"
}

-- 引入依赖库
local SpellCache = AceLibrary("SpellCache-1.0")

-- 法术相关操作库。
---@class KuBa-Spell-1.0
local Library = {}

-- 库激活
---@param self table 库自身对象
---@param oldLib table 旧版库对象
---@param oldDeactivate function 旧版库停用函数
local function activate(self, oldLib, oldDeactivate)
	-- 新版本使用
	Library = self

	-- 旧版本释放
	if oldLib then
		-- ...
	end

	-- 旧版本停用
	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

-- 外部库加载
---@param self table 库自身对象
---@param major string 外部库主版本
---@param instance table 外部库实例
local function external(self, major, instance)

end

--------------------------------

-- 提示帧
local KuBaSpellTooltip = CreateFrame("GameTooltip", "KuBaSpellTooltip", UIParent, "GameTooltipTemplate")

-- 法术名称到索引
---@param name string 法术名称
---@param rank? number 法术等级；缺省为最高等级
---@return number index 成功返回法术索引，否则返回空
function Library:ToIndex(name, rank)
	local index = 1
	local last = nil
	while true do
		-- 取法术名称
		local spellName, spellRank = GetSpellName(index, BOOKTYPE_SPELL)
		if not spellName or spellName == "" or spellName == "充能点" then
			-- 可能是最后一个法术
			if not rank and last then
				-- 返回最高等级法术索引
				return last
			end

			-- 已到末尾
			break
		end

		-- 比对名称
		if name == spellName then
			-- 比对等级
			if rank then
				if spellRank == "等级 " .. rank then
					return index
				end
			else
				last = index
			end
		elseif not rank and last then
			-- 返回最高等级法术索引
			return last
		end

		-- 索引递增
		index = index + 1
	end
end

-- 取法术冷却
---@param name string 法术名称
---@return number start 冷却开始时间
---@return number duration 冷却时间
---@return number enabled 是否启用冷却
function Library:GetCooldown(name)
	local index = self:ToIndex(name)
	if index then
		return GetSpellCooldown(index, BOOKTYPE_SPELL)
	end
end

-- 检验法术是否无冷却
---@param name string 法术名称
---@return boolean ready 已就绪返回真，否则返回假
function Library:IsReady(name)
	local start = self:GetCooldown(name)
	return start and start == 0
end

-- 从法术描述中解析法术持续时间
---@param index number 法术索引
---@param patterns? table 模式数组；缺省为默认
---@return number duration 持续时间
function Library:ParseDuration(index, patterns)
	patterns = patterns or DURATION_PATTERNS

	-- 无效法术索引
	if not index then
		return
	end

	-- 取法术描述
	KuBaSpellTooltip:SetOwner(KuBaSpellTooltip, "ANCHOR_NONE")
	KuBaSpellTooltip:ClearLines()
	KuBaSpellTooltip:SetSpell(index, BOOKTYPE_SPELL)
	local numLines = KuBaSpellTooltip:NumLines()
	if numLines and numLines > 0 then
		-- 获取最后一行
		local text = getglobal("KuBaSpellTooltipTextLeft" .. numLines):GetText()
		if text then
			-- 法术描述样本
			-- 腐蚀术：腐蚀目标，在18.69秒内造成累计828到834点伤害。
			-- 精灵之火：使目标的护甲降低175点，持续40秒。在效果持续期间，目标无法潜行或隐形。
			-- 虫群：敌人被飞虫围绕，攻击命中率降低2%，在18秒内受到总计99点自然伤害。
			-- 驱毒术：尝试驱散目标身上的1个中毒效果，并每2秒驱散1个中毒效果，持续8秒。
			for _, pattern in ipairs(patterns) do
				local _, _, duration = string.find(text, pattern)
				if duration then
					---@diagnostic disable-next-line
					return tonumber(duration)
				end
			end
		end
	end
end

-- 取法术持续时间
---@param name string 法术名称
---@param rank? number 法术等级；缺省为最高等级
---@return number duration 持续时间
function Library:GetDuration(name, rank)
	local index = self:ToIndex(name, rank)
	if index then
		return self:ParseDuration(index)
	end
end

-- 解析法术文本信息
---@param text string 法术文本
---@return string name 法术名称
---@return number rank 法术等级
---@return number id 法术索引；从1开始
function Library:parseText(text)
	if text then
		-- 取法术数据
		local name, _, id, _, rank = SpellCache:GetSpellData(text, nil)
		return name or text, rank, id
	end
end

--------------------------------

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line
Library = nil