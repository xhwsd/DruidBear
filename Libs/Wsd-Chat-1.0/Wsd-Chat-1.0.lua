--[[
Name: Wsd-Chat-1.0
Revision: $Rev: 10002 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://github.com/xhwsd
Description: 聊天相关库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "Wsd-Chat-1.0"
-- 次要版本
local MINOR_VERSION = "$Revision: 10002 $"

-- 检验AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

-- 聊天相关库。
---@class Wsd-Chat-1.0
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

-- 发送
---@param type string 类型；可选值：SAY, YELL, PARTY, RAID
---@param message string 信息
---@param ... any 格式化参数
function Library:Send(type, message, ...)
	if arg.n > 0 then
		message = string.format(message, unpack(arg))
	end
	SendChatMessage(message, type)
end

-- 说话
---@param message string 信息
---@param ... any 格式化参数
function Library:Say(message, ...)
	self:Send("SAY", message, unpack(arg))
end

-- 大喊
---@param message string 信息
---@param ... any 格式化参数
function Library:Yell(message, ...)
	self:Send("YELL", message, unpack(arg))
end

-- 队伍
---@param message string 信息
---@param ... any 格式化参数
function Library:Party(message, ...)
	self:Send("PARTY", message, unpack(arg))
end

-- 团队
---@param message string 信息
---@param ... any 格式化参数
function Library:Raid(message, ...)
	self:Send("RAID", message, unpack(arg))
end

--------------------------------

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line
Library = nil