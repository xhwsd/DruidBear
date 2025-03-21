--[[
Name: Wsd-Effect-1.0
Revision: $Rev: 10001 $
Author(s): xhwsd
Website: https://github.com/xhwsd
Description: 效果相关操作库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "Wsd-Effect-1.0"
-- 次要版本
local MINOR_VERSION = "$Revision: 10001 $"

-- 检验AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

-- 效果相关操作库。
---@class Wsd-Effect-1.0
local Library = {}

-- 库激活
---@param self table 库自身对象
---@param oldLib table 旧版库对象
---@param oldDeactivate function 旧版库停用函数
local function activate(self, oldLib, oldDeactivate)

end

-- 外部库加载
---@param self table 库自身对象
---@param major string 外部库主版本
---@param instance table 外部库实例
local function external(self, major, instance)

end

--------------------------------

-- 查找单位效果名称
---@param name string 效果名称
---@param unit? string 目标单位；额外还支持`mainhand`、`offhand`；缺省为`player`
---@return string kind 效果类型；可选值：`mainhand`、`offhand`、`buff`、`debuff`
---@return integer index 效果索引；从1开始
---@return string text 效果文本
function Library:FindName(name, unit)
	unit = unit or "player"

	if not name then
		return
	end

	-- 适配单位
	auratooltip:SetOwner(UIParent, "ANCHOR_NONE")
	if string.lower(unit) == "mainhand" then
		-- 主手
		auratooltip:ClearLines()
		auratooltip:SetInventoryItem("player", GetInventorySlotInfo("MainHandSlot"));
		for index = 1, auratooltip:NumLines() do
			local text = getglobal("auratooltipTextLeft" .. index):GetText() or ""
			if string.find(text, name) then
				return "mainhand", index, text
			end
		end
	elseif string.lower(unit) == "offhand" then
		-- 副手
		auratooltip:ClearLines()
		auratooltip:SetInventoryItem("player", GetInventorySlotInfo("SecondaryHandSlot"))
		for index = 1, auratooltip:NumLines() do
			local text = getglobal("auratooltipTextLeft" .. index):GetText() or ""
			if string.find(text, name) then
				return "offhand", index, text
			end
		end
	else
		-- 增益
		local index = 1
		while UnitBuff(unit, index) do 
			auratooltip:ClearLines()
			auratooltip:SetUnitBuff(unit, index)
			local text = auratooltipTextLeft1:GetText() or ""
			if string.find(text, name) then
				return "buff", index, text
			end
			index = index + 1
		end

		-- 减益
		local index = 1
		while UnitDebuff(unit, index) do
			auratooltip:ClearLines()
			auratooltip:SetUnitDebuff(unit, index)
			local text = auratooltipTextLeft1:GetText() or ""
			if string.find(text, name) then
				return "debuff", index, text
			end
			index = index + 1
		end
	end
end

--------------------------------

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line: cast-local-type
Library = nil