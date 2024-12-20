-- 非德鲁伊退出运行
local _, playerClass = UnitClass("player")
if playerClass ~= "DRUID" then return end

-- 定义插件
DaruidBear = AceLibrary("AceAddon-2.0"):new(
	-- 控制台
	"AceConsole-2.0",
	-- 调试
	"AceDebug-2.0"
)

-- 标签
local DaruidBearTooltip = CreateFrame("GameTooltip", "DaruidBearTooltip", nil, "GameTooltipTemplate")

-- 使用低吼时间
local useGrowlTime = GetTime()
-- 使用挑战咆哮时间
local useGhallengingRoarTime = GetTime()
-- 低吼纹理
local growlTextures = {}

-- 取一个数字 1-3
-- 第 1 级：每个用户都应收到的关键信息
-- 第 2 级：用于本地调试（函数调用等）
-- 第 3 级：非常冗长的调试，将转储所有内容和信息
-- 如果设置为 "nil"，则不会收到任何调试信息

-- 调试常规
-- @param number level = 3 输出等级；可选值：1~3(从高到低)
-- @param string message 输出信息
-- @param array ... 格式化参数
local function DebugGeneral(level, message, ...)
	level = level or 3
	DaruidBear:CustomLevelDebug(level, 0.75, 0.75, 0.75, nil, 0, message, unpack(arg))
end

-- 调试信息
-- @param number level = 2 输出等级；可选值：1~3(从高到低)
-- @param string message 输出信息
-- @param array ... 格式化参数
local function DebugInfo(level, message, ...)
	level = level or 2
	DaruidBear:CustomLevelDebug(level, 0.0, 1.0, 0.0, nil, 0, message, unpack(arg))
end

-- 调试警告
-- @param number level = 2 输出等级；可选值：1~3(从高到低)
-- @param string message 输出信息
-- @param array ... 格式化参数
local function DebugWarning(level, message, ...)
	level = level or 2
	DaruidBear:CustomLevelDebug(level, 1.0, 1.0, 0.0, nil, 0, message, unpack(arg))
end

-- 调试错误
-- @param number level = 1 输出等级；可选值：1~3(从高到低)
-- @param string message 输出信息
-- @param array ... 格式化参数
local function DebugError(level, message, ...)
	level = level or 1
	DaruidBear:CustomLevelDebug(level, 1.0, 0.0, 0.0, nil, 0, message, unpack(arg))
end

-- 位与数组
-- @param table array 数组(索引表）
-- @param string|number data 数据
-- @return number 成功返回索引，失败返回nil
local function InArray(array, data)
	if type(array) == "table" then
		for index, value in ipairs(array) do
			if value == data then
				return index
			end
		end
	end
end

-- 自动攻击
local function AutoAttack()
	if not PlayerFrame.inCombat then
		CastSpellByName("攻击")
	end
end

-- 取生命损失
-- @param string unit = "player" 单位
-- @return number 生命损失百分比
-- @return number 生命损失
local function HealthLose(unit)
	unit = unit or "player"

	local max = UnitHealthMax(unit)
	local lose = max - UnitHealth(unit)
	-- 百分比 = 部分 / 整体 * 100
	return math.floor(lose / max * 100), lose
end

-- 取生命剩余
-- @param string unit = "player" 单位
-- @return number 生命剩余百分比
-- @return number 生命剩余
local function HealthResidual(unit)
	unit = unit or "player"

	local residual = UnitHealth(unit)
	-- 百分比 = 部分 / 整体 * 100
	return math.floor(residual / UnitHealthMax(unit) * 100), residual
end

-- 查询效果；查询单位指定效果是否存在
-- @param string buff 效果名称
-- @param string unit = "player" 目标单位；额外还支持`mainhand`、`offhand`
-- @return string|nil 效果类型；可选值：`mainhand`、`offhand`、`buff`、`debuff`
-- @return number 效果索引；从1开始
local function FindBuff(buff, unit)
	if not buff then return end
	unit = unit or "player"

	-- 适配单位
	DaruidBearTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	if string.lower(unit) == "mainhand" then
		-- 主手
		DaruidBearTooltip:ClearLines()
		DaruidBearTooltip:SetInventoryItem("player", GetInventorySlotInfo("MainHandSlot"));
		for index = 1, DaruidBearTooltip:NumLines() do
			if string.find((getglobal("DaruidBearTooltipTextLeft" .. index):GetText() or ""), buff) then
				return "mainhand", index
			end
		end
	elseif string.lower(unit) == "offhand" then
		-- 副手
		DaruidBearTooltip:ClearLines()
		DaruidBearTooltip:SetInventoryItem("player", GetInventorySlotInfo("SecondaryHandSlot"))
		for index = 1, DaruidBearTooltip:NumLines() do
			if string.find((getglobal("DaruidBearTooltipTextLeft" .. index):GetText() or ""), buff) then
				return "offhand", index
			end
		end
	else
		-- 增益
		local index = 1
		while UnitBuff(unit, index) do 
			DaruidBearTooltip:ClearLines()
			DaruidBearTooltip:SetUnitBuff(unit, index)
			if string.find(DaruidBearTooltipTextLeft1:GetText() or "", buff) then
				return "buff", index
			end
			index = index + 1
		end

		-- 减益
		local index = 1
		while UnitDebuff(unit, index) do
			DaruidBearTooltip:ClearLines()
			DaruidBearTooltip:SetUnitDebuff(unit, index)
			if string.find(DaruidBearTooltipTextLeft1:GetText() or "", buff) then
				return "debuff", index
			end
			index = index + 1
		end
	end
end

-- 法术就绪；检验法术的冷却时间是否结束
-- @param string spell 法术名称
-- @return boolean 已就绪返回true，否则返回false
local function SpellReady(spell)
	if not spell then return false end

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

-- 准备法术纹理
-- @param table textures 法术纹理；非空表直接返回，可将变量定义到程序集作用域
-- @param string 法术名称
-- @return table 成功返回非空表，否则返回空表
local function SpellTextures(textures, ...)
	if next(textures) then return textures end

	-- 遍历法术
	local index = 1
	while true do
		-- 取法术名称
		local name = GetSpellName(index, BOOKTYPE_SPELL)
		if not name or name == "" or name == "充能点" then
			break
		end

		-- 匹配法术
		if InArray(arg, name) then
			-- 取法术纹理
			local texture = GetSpellTexture(index, BOOKTYPE_SPELL)
			if not textures[texture] then
				textures[texture] = {spell = name}
			end
		end

		-- 递增索引
		index = index + 1
	end
	return textures
end

-- 取插槽法术纹理
-- @param number slot 插槽索引
-- @return string|null 成功返回纹理，失败返回nil
local function GetSlotSpellTexture(slot)
	-- 普通法术有纹理，但没有文本
	if HasAction(slot) and not GetActionText(slot) then
		return GetActionTexture(slot)
	end
end

-- 根据法术纹理匹配插槽
-- @param table textures 纹理数据，`SpellTextures()`返回的结果
-- @return number|nil 插槽索引
local function MatchSlot(textures)
	if next(textures) == nil then
		DebugWarning(2, "匹配法术插槽的纹理为空")
		return
	end

	-- 先看纹理数据中插槽
	for texture, data in pairs(textures) do
		-- 插槽还是该纹理
		if data.slot and GetSlotSpellTexture(data.slot) == texture then
			return data.slot
		end
	end

	--- 从动作条插槽中查找
	for index = 1, 120 do
		-- 普通法术没有文本
		local texture = GetSlotSpellTexture(index)
		if texture and textures[texture] then
			textures[texture].slot = index
			return index
		end
	end
	DebugWarning(2, "匹配法术插槽失败；纹理：%s", textures)
end

-- 检验单位是否在范围
-- @param string unit = "target" 单位名称
-- @param table textures = {} 法术纹理，`SpellTextures()`返回结果
-- @return boolean 范围内返回true，范围外返回false
local function IsRange(unit, textures)
	unit = unit or "target"
	textures = textures or {}

	-- 单位不存在
	if not UnitExists(unit) then
		return false
	end

	-- 目标为自己
	if UnitIsUnit(unit, "player") then
		return true
	end

	-- 客户端不可见
	if not UnitIsVisible(unit) then
		return false
	end

	-- 法术范围
	if next(textures) then
		-- 匹配插槽
		local slot = MatchSlot(textures)
		if slot then
			-- 无目标
			local target = 0
			if UnitIsUnit(unit, "target") then
				-- 相同目标
				target = 2
			elseif UnitExists("target") then
				-- 其他目标
				target = 1
				TargetUnit(unit)
			end

			-- 检验目标是否在动作范围内
			local satisfy = IsActionInRange(slot) == 1

			-- 恢复目标
			if target == 0 then
				-- 清除目标
				ClearTarget()
			elseif target == 1 then
				-- 其他目标
				TargetLastTarget()
			end
			return satisfy
		end
	end

	-- 决斗范围内（10码）
	return CheckInteractDistance(unit, 1) == 1
end

-- 插件载入
function DaruidBear:OnInitialize()
	-- 自定义标题，以便调试输出
	self.title = "XD"
	-- 开启调试
	self:SetDebugging(true)
	-- 输出1~2级调试
	self:SetDebugLevel(2)

	-- 注册命令
	self:RegisterChatCommand({'/DaruidBear', "/XD"}, {
		type = "group",
		args = {
			level = {
				name = "level",
				desc = "调试等级",
				type = "toggle",
				get = "GetDebugLevel",
				set = "SetDebugLevel",
			},
			test = {
				name = "test",
				desc = "执行测试",
				type = "execute",
				func = function ()
					print("[XD] 测试开始")
					DaruidBear:Test()
					print("[XD] 测试结束")
				end
			},
		},
	})
end

-- 插件打开
function DaruidBear:OnEnable()

end

-- 插件关闭
function DaruidBear:OnDisable()

end

-- 测试
function DaruidBear:Test()

end

-- 嘲单
function DaruidBear:TauntSingle()
	-- 自动攻击
	AutoAttack()

	-- 使用间隔、技能就绪、可以攻击
	if GetTime() - useGrowlTime >= 2 and SpellReady("低吼") and UnitCanAttack("player", "target") then
		-- IsUsableAction 判断插槽是否可以使用
		-- 法术范围内
		growlTextures = SpellTextures(growlTextures, "低吼")
		if IsRange("target", growlTextures) then
			-- 使用法术
			CastSpellByName("低吼")
			SendChatMessage("已对<%t>使用<低吼>！", "YELL")
			useGrowlTime = GetTime()
		end
	end
end

-- 群嘲
function DaruidBear:TauntGroup()
	-- 自动攻击
	AutoAttack()

	-- 使用间隔、技能就绪、魔力足够
	if GetTime() - useGhallengingRoarTime >= 2 and SpellReady("挑战咆哮") then
		if UnitMana("player") >= 15 then
			CastSpellByName("挑战咆哮")
			SendChatMessage("已对周围使用<挑战咆哮>！", "YELL")
			useGhallengingRoarTime = GetTime()
		else
			UIErrorsFrame:AddMessage("怒气不足", 1.0, 1.0, 0.0, 53, 5)
		end
	end
end

-- 拉单
-- @param number dying = 30 濒死；当剩余生命百分比低于或等于时，将尝试保命
-- @param number dying = 95 健康；当剩余生命百分比高于或等于时，将尝试涨怒气
function DaruidBear:PullSingle(dying, healthy)
	dying = dying or 30
	healthy = healthy or 95

	-- 自动攻击
	AutoAttack()

	-- 抉择
	local residual = HealthResidual("player")
	local mana = UnitMana("player")
	if SpellReady("狂暴回复") and not FindBuff("狂暴回复") and residual <= dying then
		-- 回生命
		CastSpellByName("狂暴回复")
		SendChatMessage("危急濒死，已使用<狂暴回复>！", "YELL")
	elseif SpellReady("狂怒") and (FindBuff("狂暴回复") or (mana < 10 and not UnitAffectingCombat("player") and residual >= healthy)) then
		-- 涨怒气
		CastSpellByName("狂怒")
	elseif SpellReady("狂暴") and (FindBuff("狂暴回复") or residual <= dying) then
		-- 提生命上限
		CastSpellByName("狂暴")
	elseif SpellReady("野蛮撕咬") and (FindBuff("节能施法") or (mana >= 40 and not FindBuff("狂暴回复"))) then
		-- 怒气过多
		CastSpellByName("野蛮撕咬")
	elseif SpellReady("精灵之火（野性）") then
		-- 骗节能
		CastSpellByName("精灵之火（野性）")
	else
		-- 泄怒气
		CastSpellByName("槌击")
	end
end

-- 拉群
-- @param number dying = 30 濒死；当剩余生命百分比低于或等于时，将尝试保命
-- @param number healthy = 95 健康；当剩余生命百分比高于或等于时，将尝试涨怒气
function DaruidBear:PullGroup(dying, healthy)
	dying = dying or 30
	healthy = healthy or 95

	-- 自动攻击
	AutoAttack()

	-- 抉择
	local residual = HealthResidual("player")
	local mana = UnitMana("player")
	if SpellReady("狂暴回复") and not FindBuff("狂暴回复") and residual <= dying then
		-- 回生命
		CastSpellByName("狂暴回复")
		SendChatMessage("危急濒死，已使用<狂暴回复>！", "YELL")
	elseif SpellReady("狂怒") and (FindBuff("狂暴回复") or (mana < 10 and not UnitAffectingCombat("player") and residual >= healthy)) then
		-- 涨怒气
		CastSpellByName("狂怒")
	elseif SpellReady("狂暴") and (FindBuff("狂暴回复") or residual <= dying) then
		-- 提生命上限
		CastSpellByName("狂暴")
	elseif SpellReady("野蛮撕咬") and (FindBuff("节能施法") or (mana >= 80 and not FindBuff("狂暴回复"))) then
		-- 怒气太多
		CastSpellByName("野蛮撕咬")
	elseif mana >= 40 and not FindBuff("狂暴回复") then
		-- 怒气过多
		CastSpellByName("槌击")
	elseif mana >= 10 and not FindBuff("挫志咆哮", "target") and not FindBuff("挫志怒吼", "target") then
		-- 上减益
		CastSpellByName("挫志咆哮")
	elseif SpellReady("精灵之火（野性）") then
		-- 骗节能
		CastSpellByName("精灵之火（野性）") 
	else
		-- 泄怒气
		CastSpellByName("挥击")
	end
end
