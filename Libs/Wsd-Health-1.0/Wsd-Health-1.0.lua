--[[
Name: Wsd-Health-1.0
Revision: $Rev: 10001 $
Author(s): xhwsd
Website: https://github.com/xhwsd
Description: 单位生命值相关库。
Dependencies:
]]

-- 主要版本
local MAJOR_VERSION = "Wsd-Health-1.0"
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

-- 单位生命值相关库。
---@class Wsd-Health-1.0
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

-- 取生命损失
---@param unit? string 单位；缺省为`player`
---@return integer percentage 生命损失百分比
---@return integer lose 生命损失
---@return integer max 生命上限
function Library:GetLose(unit)
	unit = unit or "player"
	-- 生命上限
	local max = UnitHealthMax(unit)
	-- 生命损失
	local lose = max - UnitHealth(unit)
	-- 百分比 = 部分 / 整体 * 100
	return math.floor(lose / max * 100), lose, max
end

-- 取生命剩余
---@param unit? string 单位；缺省为`player`
---@return integer percentage 生命剩余百分比
---@return integer remaining 生命剩余
---@return integer max 生命上限
function Library:GetRemaining(unit)
	unit = unit or "player"
	-- 生命剩余
	local residual = UnitHealth(unit)
    local max = UnitHealthMax(unit)
	-- 百分比 = 部分 / 整体 * 100
	return math.floor(residual / max * 100), residual, max
end

--------------------------------

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line: cast-local-type
Library = nil