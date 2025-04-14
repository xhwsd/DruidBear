--[[
Name: Wsd-Buff-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://github.com/xhwsd
Description: 效果相关操作库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "Wsd-Buff-1.0"
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
---@class Wsd-Buff-1.0
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

	-- 新版本初始化
	-- ...

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
-- GameTooltip方法 https://warcraft.wiki.gg/wiki/Special:PrefixIndex/API_GameTooltip
-- GameTooltip模板 https://warcraft.wiki.gg/wiki/XML/GameTooltip
local WsdBuffTooltip = CreateFrame("GameTooltip", "WsdBuffTooltip", nil, "GameTooltipTemplate")

-- 取单位效果信息
---@param name string 效果名称
---@param unit? string 预取单位；额外还支持`mainhand`、`offhand`；缺省为`player`
---@return string kind 效果类型；可选值：`mainhand`、`offhand`、`buff`、`debuff`
---@return number index 效果索引；从1开始
---@return string text 效果文本
---@return string texture 纹理路径
---@return number applications 应用层数；仅在`buff`、`debuff`时有效
---@return string dispelType 驱散类型；仅在`debuff`时有效
function Library:GetUnit(name, unit)
	unit = unit or "player"
	if not name then
		return
	end

	WsdBuffTooltip:SetOwner(UIParent, "ANCHOR_NONE")

	-- 适配单位
	if string.lower(unit) == "mainhand" then
		-- 主手
		local id, texture = GetInventorySlotInfo("MainHandSlot")
		WsdBuffTooltip:ClearLines()
		WsdBuffTooltip:SetInventoryItem("player", id);
		for index = 1, WsdBuffTooltip:NumLines() do
			local text = getglobal("WsdBuffTooltipTextLeft" .. index):GetText() or ""
			if string.find(text, name) then
				return "mainhand", index, text, texture
			end
		end
	elseif string.lower(unit) == "offhand" then
		-- 副手
		local id, texture = GetInventorySlotInfo("SecondaryHandSlot")
		WsdBuffTooltip:ClearLines()
		WsdBuffTooltip:SetInventoryItem("player", id)
		for index = 1, WsdBuffTooltip:NumLines() do
			local text = getglobal("WsdBuffTooltipTextLeft" .. index):GetText() or ""
			if string.find(text, name) then
				return "offhand", index, text, texture
			end
		end
	else
		-- 增益
		local index = 1
		while UnitBuff(unit, index) do
			WsdBuffTooltip:ClearLines()
			WsdBuffTooltip:SetUnitBuff(unit, index)
			local text = WsdBuffTooltipTextLeft1:GetText() or ""
			if string.find(text, name) then
				local texture, applications = UnitBuff(unit, index)
				return "buff", index, text, texture, applications
			end
			index = index + 1
		end

		-- 减益
		index = 1
		while UnitDebuff(unit, index) do
			WsdBuffTooltip:ClearLines()
			WsdBuffTooltip:SetUnitDebuff(unit, index)
			local text = WsdBuffTooltipTextLeft1:GetText() or ""
			if string.find(text, name) then
				local texture, applications, dispelType = UnitDebuff(unit, index)
				return "debuff", index, text, texture, applications, dispelType
			end
			index = index + 1
		end
	end
end

-- 取自身效果信息
---@param name string 效果名称
---@return number index 效果索引；从1开始
---@return string text 效果文本
---@return number timeleft 效果剩余时间
---@return string texture 效果图标
---@return number cancelled 直到取消（如光环、形态、影身）
function Library:GetPlayer(name)
	WsdBuffTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	for id = 0, 64 do
		-- https://warcraft.wiki.gg/wiki/API_GetPlayerBuff?oldid=3951140
		local index, cancelled = GetPlayerBuff(id)
		-- TODO: 无法确认这里是否从1开始 xhwsd 2025-4-4
		if index >= 0 then
			WsdBuffTooltip:ClearLines()
			-- https://warcraft.wiki.gg/wiki/API_GameTooltip_SetPlayerBuff?oldid=323371
			WsdBuffTooltip:SetPlayerBuff(index)
			local text = WsdBuffTooltipTextLeft1:GetText() or ""
			if string.find(text, name) then
				-- https://warcraft.wiki.gg/wiki/API_GetPlayerBuffTimeLeft?oldid=2250730
				local timeleft = GetPlayerBuffTimeLeft(index)
				-- https://warcraft.wiki.gg/wiki/API_GetPlayerBuffTexture?oldid=4896681
				local texture = GetPlayerBuffTexture(index)
				return index, text, timeleft, texture, cancelled
			end
		end
	end

	-- buffId 从0开始
	-- buffIndex 从1开始
	-- https://warcraft.wiki.gg/wiki/BuffId?oldid=1793622
end

--------------------------------

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line: cast-local-type
Library = nil