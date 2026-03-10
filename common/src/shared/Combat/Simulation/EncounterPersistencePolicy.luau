local EncounterPersistencePolicy = {}

local HUNTING_GROUNDS = "HuntingGrounds"
local DUNGEON = "Dungeon"
local RAID = "Raid"

local function clonePersistentStateMap(source)
	local cloned = {}
	for combatantId, state in pairs(source) do
		cloned[combatantId] = {
			combatantId = combatantId,
			currentHp = state.currentHp,
			maxHp = state.maxHp,
		}
	end
	return cloned
end

function EncounterPersistencePolicy.apply(
	extractionType,
	baseStatesByCombatantId,
	finalStatesByCombatantId
)
	if extractionType == HUNTING_GROUNDS then
		return clonePersistentStateMap(baseStatesByCombatantId)
	end

	if extractionType == DUNGEON or extractionType == RAID then
		return clonePersistentStateMap(finalStatesByCombatantId)
	end

	error(string.format("Unknown extractionType %s", tostring(extractionType)))
end

return EncounterPersistencePolicy
