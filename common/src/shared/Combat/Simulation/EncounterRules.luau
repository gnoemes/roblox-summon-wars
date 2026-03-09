local EncounterRules = {}

local function countAlive(combatants)
	local alive = 0
	for _, combatant in ipairs(combatants) do
		if combatant.runtimeState.currentHp > 0 then
			alive += 1
		end
	end
	return alive
end

function EncounterRules.getOutcome(fighterCombatants, enemyCombatants)
	local aliveFighters = countAlive(fighterCombatants)
	local aliveEnemies = countAlive(enemyCombatants)

	if aliveEnemies == 0 then
		return "Victory"
	end

	if aliveFighters == 0 then
		return "Defeat"
	end

	return nil
end

return EncounterRules
