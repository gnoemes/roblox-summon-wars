local DefinitionsFolder = script.Parent:WaitForChild("Definitions")

local MutationDefinitions = require(DefinitionsFolder:WaitForChild("MutationDefinitions"))
local PetDefinitions = require(DefinitionsFolder:WaitForChild("PetDefinitions"))

local PetStatCalculator = {}

local function cloneDictionary(map)
	local out = {}
	for key, value in pairs(map) do
		out[key] = value
	end
	return out
end

local function applyStatBonuses(target, statBonuses)
	if type(statBonuses) ~= "table" then
		return
	end

	for statName, value in pairs(statBonuses) do
		if type(value) == "number" and type(target[statName]) == "number" then
			target[statName] += value
		end
	end
end

function PetStatCalculator.calculate(profile)
	local definition = PetDefinitions.ById[profile.definitionId]
	assert(definition ~= nil, ("Unknown pet definition '%s'"):format(tostring(profile.definitionId)))

	local stats = cloneDictionary(definition.baseStats)
	applyStatBonuses(stats, profile.bonusStats)

	for _, mutationId in ipairs(profile.combatMutationIds or {}) do
		local mutation = MutationDefinitions.ById[mutationId]
		if mutation and type(mutation.statBonuses) == "table" then
			applyStatBonuses(stats, mutation.statBonuses)
		end
	end

	return {
		petId = profile.id,
		definitionId = definition.id,
		displayName = profile.displayName or definition.displayName,
		archetype = definition.archetype,
		level = profile.level,
		attackRange = definition.attackRange,
		genomeCapacity = profile.genomeCapacity,
		stats = stats,
		skillIds = table.clone(profile.skillIds or definition.baseSkillIds),
		combatMutationIds = table.clone(profile.combatMutationIds or {}),
	}
end

return PetStatCalculator
