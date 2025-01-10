--[[
Name: SpellCheck-1.0
Revision: $Rev: 10001 $
Author(s): xhwsd
Website: https://github.com/xhwsd
Description: 法术检测相关操作库。
Dependencies: AceLibrary, SpellCache-1.0
]]

-- 主要版本
local MAJOR_VERSION = "SpellCheck-1.0"
--次要版本
local MINOR_VERSION = "$Revision: 10001 $"

-- 检验 AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

---检查依赖库
---@param dependencies table 依赖库名称列表
local function CheckDependency(dependencies)
	for index, value in ipairs(dependencies) do
		if not AceLibrary:HasInstance(value) then 
			error(format("%s requires %s to function properly", MAJOR_VERSION, value))
		end
	end
end

CheckDependency({
	-- 法术缓存
	"SpellCache-1.0"
})

-- 引入依赖库
local spellCache = AceLibrary("SpellCache-1.0")

-- 创建库对象
local SpellCheck = {}

---库激活
---@param self table 库自身对象
---@param oldLib table 旧版库对象
---@param oldDeactivate function 旧版库停用函数
local function activate(self, oldLib, oldDeactivate)

end

---外部库加载
---@param self table 库自身对象
---@param major string 外部库主版本
---@param instance table 外部库实例
local function external(self, major, instance)

end

------------------------------------------------

---检验法术的冷却时间是否结束
---@param spell string 法术名称
---@return boolean ready 已就绪返回真，否则返回假
function SpellCheck:IsReady(spell)
	if not spell then 
		return false
	end

	-- 名称到索引
	local index = 1
	while true do
		-- 取法术名称
		local name = GetSpellName(index, BOOKTYPE_SPELL)
		if not name or name == "" or name == "充能点" then
			break
		end

		-- 比对名称
		if name == spell then
			-- 取法术冷却
			return GetSpellCooldown(index, "spell") == 0
		end

		-- 索引递增
		index = index + 1
	end
	return false    
end

---解析法术文本信息
---@param text string 法术文本
---@return string name 法术名称
---@return integer rank 法术等级
---@return integer id 法术索引；从1开始
function SpellCheck:parseText(text)
	if text then
		-- 取法术数据
		local sName, _, sId, _, sRank = spellCache:GetSpellData(text, nil)
		return sName or text, sRank, sId 
	end
end

------------------------------------------------

-- 最终注册库
AceLibrary:Register(SpellCheck, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
SpellCheck = nil