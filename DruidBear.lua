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
	"AceDebug-2.0", 
	-- 数据库
	"AceDB-2.0",
	-- 事件
	"AceEvent-2.0",
	-- 小地图菜单
	"FuBarPlugin-2.0"
)

-- 提示操作
local Tablet = AceLibrary("Tablet-2.0")
-- 法术状态
local SpellStatus = AceLibrary("SpellStatus-1.0")
-- 光环事件
local AuraEvent = AceLibrary("SpecialEvents-Aura-2.0")
-- 日志解析
local ParserLib = ParserLib:GetInstance("1.1")

---@type KuBa-Health-1.0
local Health = AceLibrary("KuBa-Health-1.0")
---@type KuBa-Buff-1.0
local Buff = AceLibrary("KuBa-Buff-1.0")
---@type KuBa-Spell-1.0
local Spell = AceLibrary("KuBa-Spell-1.0")
---@type KuBa-Chat-1.0
local Chat = AceLibrary("KuBa-Chat-1.0")

-- 插件载入
function DruidBear:OnInitialize()
	-- 精简标题
	self.title = "熊德"
	-- 开启调试
	self:SetDebugging(true)
	-- 调试等级
	self:SetDebugLevel(2)

	-- 注册数据
	self:RegisterDB("DruidBearDB")
	-- 注册默认值
	self:RegisterDefaults('profile', {
		-- 时机
		timing = {
			-- 狂暴回复：怒气转生命；起始损失
			frenziedRegeneration = 30,
			-- 狂怒：涨怒气
			enrage = {
				-- 起始怒气
				start = 10,
				-- 狂暴回复时
				frenziedRegeneration = true
			},
			-- 狂暴：提升生命上限
			frenzied = {
				-- 起始损失
				start = 30,
				frenziedRegeneration = true,
			},
			-- 野蛮撕咬：大量伤害和仇恨；起始怒气
			savageBite = 60,
		    -- 精灵之火（野性）：减护甲
			faerieFireWild = "ready",
		},
		-- 通报
		report = {
			["低吼"] = true,
			["挑战咆哮"] = false,
			["狂暴回复"] = true,
			["狂暴"] = false,
			["树皮术（野性）"] = true,
		},
	})

	-- 具有图标
	self.hasIcon = true
	-- 小地图图标
	self:SetIcon("Interface\\Icons\\Ability_Racial_BearForm")
	-- 默认位置
	self.defaultPosition = "LEFT"
	-- 默认小地图位置
	self.defaultMinimapPosition = 210
	-- 无法分离提示（标签）
	self.cannotDetachTooltip = false
	-- 角色独立配置
	self.independentProfile = true
	-- 挂载时是否隐藏
	self.hideWithoutStandby = false
	-- 注册菜单项
	self.OnMenuRequest = {
		type = "group",
		handler = self,
		args = {
			timing = {
				type = "group",
				name = "时机",
				desc = "设置施放技能的时机",
				order = 1,
				args = {
					frenziedRegeneration = {
						type = "range",
						name = "狂暴回复",
						desc = "当生命小于或等于该百分比时施放狂暴回复",
						order = 1,
						min = 0,
						max = 100,
						step = 1,
						get = function()
							return self.db.profile.timing.frenziedRegeneration
						end,
						set = function(value)
							self.db.profile.timing.frenziedRegeneration = value
						end
					},
					enrage = {
						type = "group",
						name = "狂怒",
						desc = "设置狂怒使用时机",
						order = 2,
						min = 0,
						args = {
							-- 起始怒气
							start = {
								type = "range",
								name = "起手怒气",
								desc = "当怒气小于该值时施放狂怒",
								order = 1,
								min = 0,
								max = 100,
								step = 1,
								get = function()
									return self.db.profile.timing.enrage.start
								end,
								set = function(value)
									self.db.profile.timing.enrage.start = value
								end
							},
							-- 狂暴回复
							frenziedRegeneration = {
								type = "toggle",
								name = "狂暴回复",
								desc = "当有狂暴回复时施放狂怒",
								order = 2,
								get = function()
									return self.db.profile.timing.enrage.frenziedRegeneration
								end,
								set = function(value)
									self.db.profile.timing.enrage.frenziedRegeneration = value
								end
							},
						}
					},
					frenzied = {
						type = "group",
						name = "狂暴",
						desc = "设置狂暴使用时机",
						order = 3,
						min = 0,
						args = {
							-- 起始怒气
							start = {
								type = "range",
								name = "起手损失",
								desc = "当损失小于或等于该值且未在战斗中时施放狂暴",
								order = 1,
								min = 0,
								max = 100,
								step = 1,
								get = function()
									return self.db.profile.timing.frenzied.start
								end,
								set = function(value)
									self.db.profile.timing.frenzied.start = value
								end
							},
							-- 狂暴回复
							frenziedRegeneration = {
								type = "toggle",
								name = "狂暴回复",
								desc = "当有狂暴回复时施放狂暴",
								order = 2,
								get = function()
									return self.db.profile.timing.frenzied.frenziedRegeneration
								end,
								set = function(value)
									self.db.profile.timing.frenzied.frenziedRegeneration = value
								end
							},
						}
					},
					savageBite = {
						type = "range",
						name = "野蛮撕咬",
						desc = "当怒气大于或等于该值且无狂暴回复时施放野蛮撕咬",
						order = 4,
						min = 30,
						max = 100,
						step = 1,
						get = function()
							return self.db.profile.timing.savageBite
						end,
						set = function(value)
							self.db.profile.timing.savageBite = value
						end
					},
					faerieFireWild = {
						type = "text",
						name = "精灵之火（野性）",
						desc = "选择使用精灵之火（野性）的时机",
						order = 5,
						get = function()
							return self.db.profile.timing.faerieFireWild
						end,
						set = function(value)
							self.db.profile.timing.faerieFireWild = value
						end,
						validate = {
							["disable"] = "禁止施放",
							["ready"] = "技能就绪",
							["none"] = "目标无效果",
						}
					},
				},
			},
			report = {
				type = "group",
				name = "通报",
				desc = "设置施放技能后是否通报",
				order = 2,
				args = {
					growl = {
						type = "toggle",
						name = "低吼",
						desc = "使用低吼后通报",
						order = 1,
						get = function()
							return self.db.profile.report["低吼"]
						end,
						set = function(value)
							self.db.profile.report["低吼"] = value
						end
					},
					challengingRoar = {
						type = "toggle",
						name = "挑战咆哮",
						desc = "使用挑战咆哮后通报",
						order = 2,
						get = function()
							return self.db.profile.report["挑战咆哮"]
						end,
						set = function(value)
							self.db.profile.report["挑战咆哮"] = value
						end
					},
					frenziedRegeneration = {
						type = "toggle",
						name = "狂暴回复",
						desc = "使用狂暴回复后通报",
						order = 3,
						get = function()
							return self.db.profile.report["狂暴回复"]
						end,
						set = function(value)
							self.db.profile.report["狂暴回复"] = value
						end
					},
					barkskinWild = {
						type = "toggle",
						name = "树皮术（野性）",
						desc = "使用树皮术（野性）后通报",
						order = 4,
						get = function()
							return self.db.profile.report["树皮术（野性）"]
						end,
						set = function(value)
							self.db.profile.report["树皮术（野性）"] = value
						end
					},
				}
			},
			-- 其它
			other = {
				type = "header",
				name = "其它",
				order = 3,
			},
			debug = {
				type = "toggle",
				name = "调试模式",
				desc = "开启或关闭调试模式",
				order = 4,
				get = "IsDebugging",
				set = "SetDebugging"
			},	
			level = {
				type = "range",
				name = "调试等级",
				desc = "设置或获取调试等级",
				order = 5,
				min = 1,
				max = 3,
				step = 1,
				get = "GetDebugLevel",
				set = "SetDebugLevel"
			}
		}
	}
end

-- 插件打开
function DruidBear:OnEnable()
	self:LevelDebug(3, "插件打开")

	-- 瞬间施法
	self:RegisterEvent("SpellStatus_SpellCastInstant")
	-- 自身获得增益
	self:RegisterEvent("SpecialEvents_PlayerBuffGained")

	-- 周期性伤害
	ParserLib:RegisterEvent(
		"DruidBear",
		"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", 
		function (event, info)
			self:SPELL_PERIODIC(event, info) 		
		end
	)

	-- 自身法术造成伤害（如荆棘术）
	ParserLib:RegisterEvent(
		"DruidBear",
		"CHAT_MSG_SPELL_SELF_DAMAGE",
		function(event, info)
			self:SELF_DAMAGE(event, info)
		end
	)

	-- 自身增益（或物品）造成伤害（如荆棘术）
	ParserLib:RegisterEvent(
		"DruidBear",
		"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
		function(event, info)
			self:SELF_DAMAGE(event, info)
		end
	)
end

-- 插件关闭
function DruidBear:OnDisable()
	self:LevelDebug(3, "插件关闭")

	-- 注销日记监听
	ParserLib:UnregisterAllEvents("DruidBear")
end

-- 提示更新
function DruidBear:OnTooltipUpdate()
	-- 置小地图图标点燃提示
	Tablet:SetHint("\n鼠标右键 - 显示插件选项")
end

-- 瞬间施法
---@param id number 法术标识
---@param name string 法术名称
---@param rank string 法术等级
---@param fullName string 法术全名
function DruidBear:SpellStatus_SpellCastInstant(id, name, rank, fullName)
	self:LevelDebug(3, "瞬间施法；法术：%s", name)

	-- 是否通报
	if not self.db.profile.report[buff] then
		return
	end

	if name == "挑战咆哮" then
		Chat:Say("对周围施放<%s>！", name)
	else
		Chat:Say("施放<%s>！", name)
	end
end

-- 获得增益效果
---@param buff string 增益名称
---@param index number 增益索引
function DruidBear:SpecialEvents_PlayerBuffGained(buff, index)
	self:LevelDebug(3, "失去增益；增益：%s", buff)

	-- 是否通报
	if not self.db.profile.report[buff] then
		return
	end

	if buff == "狂暴回复" then
		Chat:Yell("开启<%s>怒气转为生命！", buff)
	elseif buff == "狂暴" then
		Chat:Yell("开启<%s>生命上限提升！", buff)
	elseif buff == "树皮术（野性）" then
		Chat:Yell("开启<%s>受到近战伤害减半！", buff)
	else 
		Chat:Send("获得<%s>！", buff)
	end
end

-- 造成周期性伤害
function DruidBear:SPELL_PERIODIC(event, info)
	if info.type == "unknown" then
		-- 训练假人 is afflicted by 低吼 (1).
		local victim, skill, rank = ParserLib:Deformat(info.message, "%s is afflicted by %s (%d).")
		if victim and skill then
			info.type = "debuff"
			info.victim = victim
			info.skill = skill
			info.amountRank = rank
			info.message = nil
		end
	end

	self:LevelDebug(3, "造成周期性伤害；类型：%s；法术：%s；事件：%s；消息：%s", info.type, info.skill, event, info.message)
	if not info.skill then
		return
	end

	-- 通报类型
	local type = self.db.profile.report[info.skill]
	if not type or type == "disable" then
		return
	end

	-- Chat:Say("<%s>已生效于<%s>！", info.skill, info.victim)
end

-- 自身造成伤害（躲闪、抵抗、击中、荆棘等）
function DruidBear:SELF_DAMAGE(event, info)
	self:LevelDebug(3, "自身造成伤害；类型：%s；法术：%s；事件：%s；消息：%s", info.type, info.skill, event, info.message)
	if not info.skill then
		return
	end

	-- 是否通报
	if not self.db.profile.report[info.skill] or info.skill ~= "低吼" then
		return
	end

	if info.type == "hit" or info.type == "cast" then
		Chat:Say("<%s>作用于<%s>！", info.skill, info.victim)
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
			Chat:Yell("<%s>被<%s>%s！", info.skill, info.victim, types[info.missType])
		else
			Chat:Yell("<%s>未命中<%s>！", info.skill, info.victim)
		end
	elseif info.type == "leech" then
		Chat:Yell("<%s>被<%s>吸收！", info.skill, info.victim)
	elseif info.type == "dispel" then
		Chat:Yell("<%s>被<%s>驱散！", info.skill, info.victim)
	else
		Chat:Yell("<%s>未生效！", info.skill)
	end
end

-- 拉单
function DruidBear:PullSingle()
	-- 自动攻击
	self.helper:AutoAttack()

	-- 抉择技能
	local health = Health:GetRemaining("player")
	local mana = UnitMana("player")
	if health <= self.db.profile.timing.frenziedRegeneration and not Buff:FindUnit("狂暴回复") and Spell:IsReady("狂暴回复") then
		-- 当生命小于或等于该百分比时：怒气转生命
		CastSpellByName("狂暴回复")
	elseif mana < self.db.profile.timing.enrage.start and not UnitAffectingCombat("player") and Spell:IsReady("狂怒") then
		-- 当怒气小于该值且未在战斗中时：涨怒气
		CastSpellByName("狂怒")
	elseif self.db.profile.timing.enrage.frenziedRegeneration and Buff:FindUnit("狂暴回复") and Spell:IsReady("狂怒") then
		-- 当有狂暴回复时：涨怒气
		CastSpellByName("狂怒")
	elseif health <= self.db.profile.timing.frenzied.start and Spell:IsReady("狂暴") then
		-- 当损失小于或等于该值时：提升生命上限
		CastSpellByName("狂暴")
	elseif self.db.profile.timing.frenzied.frenziedRegeneration and Buff:FindUnit("狂暴回复") and Spell:IsReady("狂暴") then
		-- 当有狂暴回复时：提升生命上限
		CastSpellByName("狂暴")
	elseif Buff:FindUnit("节能施法") then
		-- 当有节能施法时：白嫖技能
		if Spell:IsReady("野蛮撕咬") then
			CastSpellByName("野蛮撕咬")
		else
			CastSpellByName("槌击")
		end
	elseif mana >= self.db.profile.timing.savageBite and not Buff:FindUnit("狂暴回复") and Spell:IsReady("野蛮撕咬") then
		-- 当怒气大于或等于该值且无狂暴回复时：泄怒气
		CastSpellByName("野蛮撕咬")
	elseif self.db.profile.timing.faerieFireWild == "ready" and Spell:IsReady("精灵之火（野性）") then
		-- 当法术就绪时：骗节能
		CastSpellByName("精灵之火（野性）")
	elseif self.db.profile.timing.faerieFireWild == "none" and not Buff:FindUnit("精灵之火", "target") and Spell:IsReady("精灵之火（野性）") then
		-- 当目标无精灵之火时：减护甲
		CastSpellByName("精灵之火（野性）")
	else
		-- 泄怒气
		CastSpellByName("槌击")
	end
end

-- 拉群
function DruidBear:PullGroup()
	-- 自动攻击
	self.helper:AutoAttack()
	
	-- 抉择技能
	local health = Health:GetRemaining("player")
	local mana = UnitMana("player")
	if health <= self.db.profile.timing.frenziedRegeneration and not Buff:FindUnit("狂暴回复") and Spell:IsReady("狂暴回复") then
		-- 当生命小于或等于该百分比时：怒气转生命
		CastSpellByName("狂暴回复")
	elseif mana < self.db.profile.timing.enrage.start and not UnitAffectingCombat("player") and Spell:IsReady("狂怒") then
		-- 当怒气小于该值且未在战斗中时：涨怒气
		CastSpellByName("狂怒")
	elseif self.db.profile.timing.enrage.frenziedRegeneration and Buff:FindUnit("狂暴回复") and Spell:IsReady("狂怒") then
		-- 当有狂暴回复时：涨怒气
		CastSpellByName("狂怒")
	elseif health <= self.db.profile.timing.frenzied.start and Spell:IsReady("狂暴") then
		-- 当损失小于或等于该值时：提升生命上限
		CastSpellByName("狂暴")
	elseif self.db.profile.timing.frenzied.frenziedRegeneration and Buff:FindUnit("狂暴回复") and Spell:IsReady("狂暴") then
		-- 当有狂暴回复时：提升生命上限
		CastSpellByName("狂暴")
	elseif Buff:FindUnit("节能施法") then
		-- 当有节能施法时：白嫖技能
		if Spell:IsReady("野蛮撕咬") then
			CastSpellByName("野蛮撕咬")
		else
			CastSpellByName("槌击")
		end
	elseif mana >= 10 and not Buff:FindUnit("挫志咆哮", "target") and not Buff:FindUnit("挫志怒吼", "target") and Spell:IsReady("挫志咆哮") then
		-- 当目标挫志咆哮和挫志怒吼时：减攻击强度
		CastSpellByName("挫志咆哮")
	elseif mana >= self.db.profile.timing.savageBite and not Buff:FindUnit("狂暴回复") and Spell:IsReady("野蛮撕咬") then
		-- 当怒气大于或等于该值且无狂暴回复时：泄怒气
		CastSpellByName("野蛮撕咬")
	elseif self.db.profile.timing.faerieFireWild == "ready" and Spell:IsReady("精灵之火（野性）") then
		-- 当法术就绪时：骗节能
		CastSpellByName("精灵之火（野性）")
	elseif self.db.profile.timing.faerieFireWild == "none" and not Buff:FindUnit("精灵之火", "target") and Spell:IsReady("精灵之火（野性）") then
		-- 当目标无精灵之火时：减护甲
		CastSpellByName("精灵之火（野性）")
	else
		-- 泄怒气
		CastSpellByName("挥击")
	end
end
