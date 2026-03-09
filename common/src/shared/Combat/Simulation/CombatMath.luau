local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("Combat")
		:WaitForChild("Simulation")
)

local CombatMath = {}

local function clamp(value, minValue, maxValue)
	return math.max(minValue, math.min(maxValue, value))
end

function CombatMath.clamp(value, minValue, maxValue)
	return clamp(value, minValue, maxValue)
end

function CombatMath.calculateHitChance(attackerStats, targetStats)
	local evasion = math.min(targetStats.evasion, CombatConfig.HitModel.EvasionCap)
	local hitChance = CombatConfig.HitModel.BaseHitChance + attackerStats.accuracy - evasion

	return clamp(hitChance, CombatConfig.HitModel.MinHitChance, CombatConfig.HitModel.MaxHitChance)
end

function CombatMath.rollSuccess(chance, roll)
	return roll <= clamp(chance, 0, 1)
end

function CombatMath.calculateDamage(attackerStats, targetStats, skillDefinition, isCritical)
	local critMultiplier = if isCritical then attackerStats.critDamage else 1
	local rawDamage = attackerStats.damage * skillDefinition.damageMultiplier * critMultiplier
	local finalDamage = math.max(rawDamage - targetStats.defense, 1)

	return math.floor(finalDamage + 0.5)
end

function CombatMath.calculateHealing(attackerStats, skillDefinition)
	local rawHealing = attackerStats.damage * skillDefinition.healMultiplier
	return math.max(math.floor(rawHealing + 0.5), 1)
end

function CombatMath.calculateStatusChance(skillDefinition, targetStats)
	if #skillDefinition.appliedStatusIds == 0 then
		return 0
	end

	return clamp(skillDefinition.statusApplyChance - targetStats.statusResist, 0, 1)
end

function CombatMath.calculateDotDamage(maxHp, stacks, ratio)
	local damage = math.max(maxHp * ratio * stacks, 1)
	return math.floor(damage + 0.5)
end

return CombatMath
