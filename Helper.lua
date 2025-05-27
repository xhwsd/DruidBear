if not DruidBear then
	return
end

-- 定义辅助对象
local Helper = {}

-- 自动攻击
function Helper:AutoAttack()
	if not PlayerFrame.inCombat then
		CastSpellByName("攻击")
	end
end

-- 将辅助注入到插件中
DruidBear.helper = Helper
