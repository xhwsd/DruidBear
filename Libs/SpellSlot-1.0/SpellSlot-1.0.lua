--[[
Name: SpellSlot-1.0
Revision: $Rev: 10001 $
Author(s): xhwsd
Website: https://github.com/xhwsd
Description: 法术插槽相关操作库。
Dependencies: AceLibrary, Gratuity-2.0, SpellCache-1.0
]]

-- 主要版本
local MAJOR_VERSION = "SpellSlot-1.0"
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
	-- 提示解析
	"Gratuity-2.0", 
	-- 法术缓存
	"SpellCache-1.0"
})

-- 引入依赖库
local gratuity = AceLibrary("Gratuity-2.0")
local spellCache = AceLibrary("SpellCache-1.0")

-- 创建库对象
local SpellSlot = {}

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

-- 法术缓存
local spellCaches = {}

---检验值是否包含于索引数组中
---@param array table 数组(索引表）
---@param value any 值
---@return integer index 返回索引
local function InArray(array, value)
	if type(array) == "table" then
		for index, data in ipairs(array) do
			if data == value then
				return index
			end
		end
	end
end

---取插槽法术图标
---@param slot integer 插槽索引
---@return string icon 图标纹理
local function GetSpellIcon(slot)
	-- 普通法术没有文本
	if slot and HasAction(slot) and not GetActionText(slot) then
		return GetActionTexture(slot)
	end
end

---检验插槽是否为宏
---@param slot integer 插槽索引；从1开始
---@return boolean is 是否为宏
function SpellSlot:IsMacro(slot)
	return slot and HasAction(slot) and GetActionText(slot) ~= nil
end

---检验插槽是否法术（非宏）
---@param slot integer 插槽索引；从1开始
---@return boolean is 是否为法术
function SpellSlot:IsSpell(slot)
	return slot and HasAction(slot) and not GetActionText(slot)
end

---取插槽法术信息
---@param slot integer 插槽索引；从1开始
---@return string name 法术名称
---@return integer rank 法术等级
---@return integer id 法术索引；从1开始
function SpellSlot:GetSpell(slot)
	-- 仅限法术插槽
	if self:IsSpell(slot) then
		-- 取提示文本
		gratuity:SetAction(slot)
		local spellName, spellRank = gratuity:GetLine(1), gratuity:GetLine(1, true)

		-- 取法术数据
		local sName, _, sId, _, sRank = spellCache:GetSpellData(spellName, spellRank)
		return spellName or sName, sRank or spellRank, sId
	end
end

-- 查找任意一个法术在动作条中的插槽索引
---@param ... string 法术名称
---@return integer slot 插槽索引；1~120
---@return string name 法术名称
---@return string icon 图标纹理
function SpellSlot:FindSpell(...)
	-- 检验法术
	if arg.n == 0 then
		return
	end

	-- 从缓存匹配
	for _, spell in ipairs(arg) do
		if type(spell) == "string" and spell ~= "" then
			if spellCaches[spell] then
				local icon, slot = spellCaches[spell].icon, spellCaches[spell].slot
				if icon and slot and icon == GetSpellIcon(slot) then
					return slot
				else
					-- 缓存失效
					spellCaches[spell].slot = nil
				end
			end
		end
	end

	-- 准备法术图标
	local index = 1
	while true do
		-- 取法术名称
		local spell = GetSpellName(index, BOOKTYPE_SPELL)
		if not spell or spell == "" or spell == "充能点" then
			break
		end

		-- 缓存图标
		if InArray(arg, spell) and not spellCaches[spell] then
			local icon = GetSpellTexture(index, BOOKTYPE_SPELL)
			if icon then
				spellCaches[spell] = {icon = icon}
			end
		end

		-- 递增索引
		index = index + 1
	end

	--- 准备法术插槽
	for index = 1, 120 do
		local icon = GetSpellIcon(index)
		if icon then
			-- 匹配法术
			local spell = nil
			for name, data in pairs(spellCaches) do
				if data.icon == icon then
					spell = name
					break
				end
			end

			-- 缓存插槽
			if spell then
				spellCaches[spell].slot = index
				if InArray(arg, spell) then
					return index, spell, icon
				end
			end
		end
	end
end

------------------------------------------------

-- 最终注册库
AceLibrary:Register(SpellSlot, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
SpellSlot = nil