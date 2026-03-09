local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("Combat")
		:WaitForChild("Simulation")
)
local DeterministicRandom = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Utils")
		:WaitForChild("DeterministicRandom")
)

local CombatTargeting = {}

local function isAlive(runtimeState)
	return runtimeState.currentHp > 0
end

function CombatTargeting.selectEnemyTarget(enemyCombatants)
	for _, combatant in ipairs(enemyCombatants) do
		if isAlive(combatant.runtimeState) then
			return combatant
		end
	end

	return nil
end

function CombatTargeting.selectFighterTarget(fighterCombatants, rngState)
	local weighted = {}

	for _, combatant in ipairs(fighterCombatants) do
		if isAlive(combatant.runtimeState) then
			table.insert(weighted, {
				weight = math.max(
					combatant.aggroWeight or CombatConfig.Targeting.FallbackAggroWeight,
					1
				),
				value = combatant,
			})
		end
	end

	if #weighted == 0 then
		return nil, rngState
	end

	return DeterministicRandom.nextWeightedEntry(rngState, weighted)
end

return CombatTargeting
