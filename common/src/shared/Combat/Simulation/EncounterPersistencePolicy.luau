local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExtractionTypeIds = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Extractions")
		:WaitForChild("ExtractionTypeIds")
)

local EncounterPersistencePolicy = {}

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
	if extractionType == ExtractionTypeIds.Values[1] then
		return clonePersistentStateMap(baseStatesByCombatantId)
	end

	if
		extractionType == ExtractionTypeIds.Values[2]
		or extractionType == ExtractionTypeIds.Values[3]
	then
		return clonePersistentStateMap(finalStatesByCombatantId)
	end

	error(string.format("Unknown extractionType %s", tostring(extractionType)))
end

return EncounterPersistencePolicy
