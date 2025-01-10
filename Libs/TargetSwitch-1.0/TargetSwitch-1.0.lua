--[[
Name: TargetSwitch-1.0
Revision: $Rev: 10220 $
Author(s): xhwsd
Website: https://github.com/xhwsd
Description: 目标切换相关操作库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "TargetSwitch-1.0"
--次要版本
local MINOR_VERSION = "$Revision: 10220 $"

-- 检验 AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

-- 创建库对象
local TargetSwitch = {}

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

-- 切换目标
local switchTargets = {}

---切换到单位目标
---@param unit string 单位
---@return boolean success 成功返回真，否则返回假
function TargetSwitch:ToUnit(unit)
	if not unit or unit == "" then
		return false
	elseif not UnitExists(unit) then
		return false
	end

	local switch = {
		unit = unit,
		request = UnitName(unit),
		before = UnitName("target"),
	}
	if UnitIsUnit(switch.unit, "target") then
		-- 相同目标
		switch.type = 2
		switch.after = switch.before
	elseif switch.before then
		-- 其他目标
		switch.type = 1
		TargetUnit(switch.unit)
		switch.after = UnitName("target")
		if switch.after ~= switch.request then
			return false
		end
	else
		-- 无目标
		switch.type = 0
		TargetUnit(switch.unit)
		switch.after = UnitName("target")
		if switch.after ~= switch.request then
			return false
		end
	end

	-- 压入切换
	table.insert(switchTargets, 1, switch)
	return true
end

---切换到名称目标
---@param name string 名称
---@return boolean success 成功返回真，否则返回假
function TargetSwitch:ToName(name)
	if not name or name == "" then
		return false
	end

	local switch = {
		unit = nil,
		request = name,
		before = UnitName("target"),
	}

	if switch.before == switch.request then
		-- 相同目标
		switch.type = 2
		switch.after = switch.before
	elseif switch.before then
		-- 其他目标
		switch.type = 1
		TargetByName(switch.request)
		switch.after = UnitName("target")
		if switch.after ~= switch.request then
			return false
		end
	else
		-- 无目标
		switch.type = 0
		TargetByName(switch.request)
		switch.after = UnitName("target")
		if switch.after ~= switch.request then
			return false
		end
	end

	-- 压入切换
	table.insert(switchTargets, 1, switch)
	return true
end

---恢复到上次目标
---@return boolean success 成功返回真，否则返回假
function TargetSwitch:ToLast()
	if next(switchTargets) == nil then
		return false
	end

	-- 弹出切换
	local switch = table.remove(switchTargets, 1)
	if switch.type == 2 then
		-- 相同目标
		local after = UnitName("target")
		if after ~= switch.before then
			return false
		end
	elseif switch.type == 1 then
		-- 其他目标
		TargetLastTarget()
		local after = UnitName("target")
		if after ~= switch.before then
			return false
		end
	else
		-- 无目标
		ClearTarget()
	end
	return true
end

------------------------------------------------

-- 最终注册库
AceLibrary:Register(TargetSwitch, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
TargetSwitch = nil