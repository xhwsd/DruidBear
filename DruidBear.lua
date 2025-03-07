-- 非德鲁伊退出运行
local _, playerClass = UnitClass("player")
if playerClass ~= "DRUID" then
	return
end

-- 定义插件
DruidBear = AceLibrary("AceAddon-2.0"):new(
	-- 控制台
	"AceConsole-2.0",
	-- 调试
	"AceDebug-2.0"
)

-- [ GetCaptures ]
-- Returns the indexes of a given regex pattern
-- 'pat'        [string]         unformatted pattern
-- returns:     [numbers]        capture indexes
local capture_cache = {}
local function GetCaptures(pat)
	local r = capture_cache
	if not r[pat] then
		for a, b, c, d, e in gfind(gsub(pat, "%((.+)%)", "%1"), gsub(pat, "%d%$", "%%(.-)$")) do
			r[pat] = { a, b, c, d, e}
		end
	end

	if not r[pat] then return nil, nil, nil, nil end
	return r[pat][1], r[pat][2], r[pat][3], r[pat][4], r[pat][5]
end

-- [ SanitizePattern ]
-- Sanitizes and convert patterns into gfind compatible ones.
-- 'pattern'    [string]         unformatted pattern
-- returns:     [string]         simplified gfind compatible pattern
local sanitize_cache = {}
local function SanitizePattern(pattern)
	if not sanitize_cache[pattern] then
		local ret = pattern
		-- escape magic characters
		ret = gsub(ret, "([%+%-%*%(%)%?%[%]%^])", "%%%1")
		-- remove capture indexes
		ret = gsub(ret, "%d%$","")
		-- catch all characters
		ret = gsub(ret, "(%%%a)","%(%1+%)")
		-- convert all %s to .+
		ret = gsub(ret, "%%s%+",".+")
		-- set priority to numbers over strings
		ret = gsub(ret, "%(.%+%)%(%%d%+%)","%(.-%)%(%%d%+%)")
		-- cache it
		sanitize_cache[pattern] = ret
	end

	return sanitize_cache[pattern]
end

-- [ cmatch ]
-- Same as string.match but aware of capture indexes (up to 5)
-- 'str'        [string]         input string that should be matched
-- 'pat'        [string]         unformatted pattern
-- returns:     [strings]        matched string in capture order
local a, b, c, d, e
local _, va, vb, vc, vd, ve
local ra, rb, rc, rd, re
local function cmatch(str, pat)
	-- read capture indexes
	a, b, c, d, e = GetCaptures(pat)
	_, _, va, vb, vc, vd, ve = string.find(str, SanitizePattern(pat))

	-- put entries into the proper return values
	ra = e == 1 and ve or d == 1 and vd or c == 1 and vc or b == 1 and vb or va
	rb = e == 2 and ve or d == 2 and vd or c == 2 and vc or a == 2 and va or vb
	rc = e == 3 and ve or d == 3 and vd or a == 3 and va or b == 3 and vb or vc
	rd = e == 4 and ve or a == 4 and va or c == 4 and vc or b == 4 and vb or vd
	re = a == 5 and va or d == 5 and vd or c == 5 and vc or b == 5 and vb or ve

	return ra, rb, rc, rd, re
end

---自动攻击
local function AutoAttack()
	if not PlayerFrame.inCombat then
		CastSpellByName("攻击")
	end
end

---是否具有光环
---@param aura string 光环名称
---@param unit? string 单位；缺省为`player`
---@return boolean has 光环存在返回真，否则返回假
local function HasAura(aura, unit)
	unit = unit or "player"
	return UnitHasAura(unit, aura)
end

---取生命剩余
---@param unit? string 单位；缺省为`player`
---@return integer percentage 生命剩余百分比
---@return integer residual 生命剩余
local function HealthResidual(unit)
	unit = unit or "player"
	local residual = UnitHealth(unit)
	-- 百分比 = 部分 / 整体 * 100
	return math.floor(residual / UnitHealthMax(unit) * 100), residual
end

---插件载入
function DruidBear:OnInitialize()
	-- 精简标题
	self.title = "熊德辅助"
	-- 开启调试
	self:SetDebugging(true)
	-- 调试等级
	self:SetDebugLevel(2)
end

---插件打开
function DruidBear:OnEnable()
	self:LevelDebug(3, "插件打开")

	-- 注册命令
	self:RegisterChatCommand({"/DB", '/DruidBear'}, {
		type = "group",
		args = {
			debug = {
				name = "调试模式",
				desc = "开启或关闭调试模式",
				type = "toggle",
				get = "IsDebugging",
				set = "SetDebugging"
			},
			level = {
				name = "调试等级",
				desc = "设置或获取调试等级",
				type = "range",
				min = 1,
				max = 3,
				get = "GetDebugLevel",
				set = "SetDebugLevel"
			}
		},
	})

	-- 法术检查
	self.spellCheck = AceLibrary("SpellCheck-1.0")
	-- 法术插槽
	self.spellSlot = AceLibrary("SpellSlot-1.0")
	-- 目标切换
	self.targetSwitch = AceLibrary("TargetSwitch-1.0")

	-- 使用低吼时间
	self.useGrowlTime = GetTime()
	-- 使用挑战咆哮时间
	self.useGhallengingRoarTime = GetTime()

	-- 施放法术
	self.castSpells = {}

	-- 监听战斗日志
	self.parser = ParserLib:GetInstance("1.1")
	self.parser:RegisterEvent(
		"DruidBear",
		"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", 
		function (event, info)
			self:SPELL_PERIODIC(event, info) 		
		end
	)
	self.parser:RegisterEvent(
		"DruidBear",
		"CHAT_MSG_SPELL_SELF_DAMAGE",
		function(event, info)
			self:SELF_DAMAGE(event, info)
		end
	)
	self.parser:RegisterEvent(
		"DruidBear",
		"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
		function(event, info)
			self:SELF_DAMAGE(event, info)
		end
	)
	self.parser:RegisterEvent(
		"DruidBear",
		"CHAT_MSG_SPELL_FAILED_LOCALPLAYER",
		function(event, info)
			self:SPELL_FAILED(event, info)
		end
	)
end

---插件关闭
function DruidBear:OnDisable()
	self:LevelDebug(3, "插件关闭")
end

---说话
---@param message string 信息
---@param ...? any 格式化参数
function DruidBear:Say(message, ...)
	if arg.n > 0 then
		message = string.format(message, unpack(arg))
	end
	SendChatMessage(message, "SAY")
end

---大喊
---@param message string 信息
---@param ...? any 格式化参数
function DruidBear:Yell(message, ...)
	if arg.n > 0 then
		message = string.format(message, unpack(arg))
	end
	SendChatMessage(message, "YELL")
end

function DruidBear:SPELL_PERIODIC(event, info)
	-- Printd("event：")
	-- PrintTable(event)
	-- Printd("info：")
	-- PrintTable(info)
	if info.type == "unknown" and info.message then
		-- 伤害者 is afflicted by 法术名称 (等级).
		local victim, skill = cmatch(info.message, "%s is afflicted by %s (1).")
		if victim and skill and self.castSpells[skill] == victim  then
			self:Say("<%s>已作用于<%s>！", skill, victim)
		end
	end
end

-- 自身施法成功（包括躲闪、抵抗、击中）
function DruidBear:SELF_DAMAGE(event, info)
	self:LevelDebug(3, "自身施法成功；法术：%s；目标：%s；类型：%s；失效：%s", info.skill or "", info.victim or "", info.type or "", info.missType or "")
	local victim = self.castSpells[info.skill]
	if victim and info.victim == victim then
		if info.type == "hit" or info.type == "cast" then
			self:Say("<%s>已作用于<%s>！", info.skill, info.victim)
		elseif info.type == "miss" then
			local types = {
				resist = "抵抗",
				immune = "免疫",
				block = "阻挡",
				deflect = "偏移",
				dodge = "躲闪",
				evade = "回避",
				absorb = "吸收",
				parry = "招架",
				reflect = "反射",
			}
			if types[info.missType] then
				self:Yell("<%s>%s<%s>！", info.victim, types[info.missType], info.skill)
			else
				self:Yell("<%s>未作用于<%s>！", info.skill, info.victim)
			end
		elseif info.type == "leech" then
			self:Yell("<%s>吸收<%s>！", info.victim, info.skill)
		elseif info.type == "dispel" then
			self:Yell("<%s>驱散<%s>！", info.victim, info.skill)
		else
			self:Yell("<%s>未生效于<%s>！", info.skill, info.victim)
		end
		self.castSpells[info.skill] = nil
	end
end

-- 自身施法失败
function DruidBear:SPELL_FAILED(event, info)
	-- self:LevelDebug(3, "自身施法失败；法术：%s；目标：%s；类型：%s", info.skill or "nil", info.victim or "nil", info.type or "nil")
end

---检验单位是否在范围
---@param unit? string 单位名称；缺省为`target`
---@param spell? string 法术名称；缺省为`低吼`
---@return boolean satisfy 范围内返回真，范围外返回假
function DruidBear:IsRange(unit, spell)
	unit = unit or "target"
	spell = spell or "低吼"

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

	-- 取动作插槽
	local slot = self.spellSlot:FindSpell(spell)
	if slot then
		if self.targetSwitch:ToUnit(unit) then
			local satisfy = IsActionInRange(slot) == 1
			self.targetSwitch:ToLast()
			return satisfy
		else
			self:LevelDebug(2, "切换到单位失败；单位：%s", unit)
		end
	else
		self:LevelDebug(2, "未在动作条找到法术；法术：%s", spell)
	end

	-- 决斗范围内（10码）
	return CheckInteractDistance(unit, 1) == 1
end

---嘲单
function DruidBear:TauntSingle()
	-- 自动攻击
	AutoAttack()

	-- 使用间隔、技能就绪、可以攻击、目标在范围内
	if GetTime() - self.useGrowlTime >= 2 and self.spellCheck:IsReady("低吼") and UnitCanAttack("player", "target") and self:IsRange("target", "低吼") then
		-- 仅通过这里施放的低吼后续才处理
		self.castSpells["低吼"] = UnitName("target")
		CastSpellByName("低吼")
		self.useGrowlTime = GetTime()
	end
end

---嘲群
function DruidBear:TauntGroup()
	-- 自动攻击
	AutoAttack()

	-- 使用间隔、技能就绪、魔力足够
	if GetTime() - self.useGhallengingRoarTime >= 2 and self.spellCheck:IsReady("挑战咆哮") and UnitMana("player") >= 15 then
		CastSpellByName("挑战咆哮")
		self:Say("对周围使用<挑战咆哮>成功！")
		self.useGhallengingRoarTime = GetTime()
	end
end

---拉单
---@param dying? integer 濒死；当剩余生命百分比低于或等于时，将尝试保命；缺省为`30`
---@param healthy? integer 健康；当剩余生命百分比高于或等于时，将尝试涨怒气；缺省为`95`
function DruidBear:PullSingle(dying, healthy)
	dying = dying or 30
	healthy = healthy or 95

	-- 自动攻击
	AutoAttack()

	-- 抉择
	local residual = HealthResidual("player")
	local mana = UnitMana("player")
	if self.spellCheck:IsReady("狂暴回复") and not HasAura("狂暴回复") and residual <= dying then
		-- 回生命
		CastSpellByName("狂暴回复")
		self:Yell("危急濒死，已使用<狂暴回复>！")
	elseif self.spellCheck:IsReady("狂怒") and (HasAura("狂暴回复") or (mana < 10 and not UnitAffectingCombat("player") and residual >= healthy)) then
		-- 涨怒气
		CastSpellByName("狂怒")
	elseif self.spellCheck:IsReady("狂暴") and (HasAura("狂暴回复") or residual <= dying) then
		-- 提生命上限
		CastSpellByName("狂暴")
	elseif self.spellCheck:IsReady("野蛮撕咬") and (HasAura("节能施法") or (mana >= 60 and not HasAura("狂暴回复"))) then
		-- 怒气过多
		CastSpellByName("野蛮撕咬")
	elseif self.spellCheck:IsReady("精灵之火（野性）") then
		-- 骗节能
		CastSpellByName("精灵之火（野性）")
	else
		-- 泄怒气
		CastSpellByName("槌击")
	end
end

---拉群
---@param dying? integer 濒死；当剩余生命百分比低于或等于时，将尝试保命；缺省为`30`
---@param healthy? integer 健康；当剩余生命百分比高于或等于时，将尝试涨怒气；缺省为`95`
function DruidBear:PullGroup(dying, healthy)
	dying = dying or 30
	healthy = healthy or 95

	-- 自动攻击
	AutoAttack()
	
	-- 抉择
	local residual = HealthResidual("player")
	local mana = UnitMana("player")
	if self.spellCheck:IsReady("狂暴回复") and not HasAura("狂暴回复") and residual <= dying then
		-- 回生命
		CastSpellByName("狂暴回复")
		self:Yell("危急濒死，已使用<狂暴回复>！")
	elseif self.spellCheck:IsReady("狂怒") and (HasAura("狂暴回复") or (mana < 10 and not UnitAffectingCombat("player") and residual >= healthy)) then
		-- 涨怒气
		CastSpellByName("狂怒")
	elseif self.spellCheck:IsReady("狂暴") and (HasAura("狂暴回复") or residual <= dying) then
		-- 提生命上限
		CastSpellByName("狂暴")
	elseif self.spellCheck:IsReady("野蛮撕咬") and (HasAura("节能施法") or (mana >= 80 and not HasAura("狂暴回复"))) then
		-- 怒气太多
		CastSpellByName("野蛮撕咬")
	elseif mana >= 40 and not HasAura("狂暴回复") then
		-- 怒气过多
		CastSpellByName("槌击")
	elseif mana >= 10 and not HasAura("挫志咆哮", "target") and not HasAura("挫志怒吼", "target") then
		-- 上减益
		CastSpellByName("挫志咆哮")
	elseif self.spellCheck:IsReady("精灵之火（野性）") then
		-- 骗节能
		CastSpellByName("精灵之火（野性）") 
	else
		-- 泄怒气
		CastSpellByName("挥击")
	end
end
