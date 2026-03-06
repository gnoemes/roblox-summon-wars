local DefinitionsFolder = script.Parent:WaitForChild("Definitions")

local CosmeticDefinitions = require(DefinitionsFolder:WaitForChild("CosmeticDefinitions"))
local PetDefinitions = require(DefinitionsFolder:WaitForChild("PetDefinitions"))

local DEFAULT_BONUS_STATS = {
	maxHealth = 0,
	damage = 0,
	defense = 0,
	attackSpeed = 0,
	crit = 0,
	lifesteal = 0,
	statusPower = 0,
	cooldownReduction = 0,
	passiveRegenHpPerSec = 0,
}

local PetProfile = {}

local function cloneArray(list)
	if type(list) ~= "table" then
		return {}
	end
	return table.clone(list)
end

local function cloneDictionary(map)
	if type(map) ~= "table" then
		return {}
	end
	local out = {}
	for key, value in pairs(map) do
		out[key] = value
	end
	return out
end

local function normalizeBonusStats(bonusStats)
	local out = table.clone(DEFAULT_BONUS_STATS)
	if type(bonusStats) ~= "table" then
		return out
	end

	for statName, value in pairs(bonusStats) do
		if out[statName] ~= nil and type(value) == "number" then
			out[statName] = value
		end
	end

	return out
end

local function normalizeCosmetics(cosmetics)
	local out = table.clone(CosmeticDefinitions.DefaultLoadout)
	if type(cosmetics) ~= "table" then
		return out
	end

	for key, value in pairs(cosmetics) do
		if out[key] ~= nil and (value == nil or type(value) == "string") then
			out[key] = value
		end
	end

	return out
end

function PetProfile.create(params)
	local definition = PetDefinitions.ById[params.definitionId]
	assert(definition ~= nil, ("Unknown pet definition '%s'"):format(tostring(params.definitionId)))
	assert(type(params.id) == "string" and params.id ~= "", "Pet profile id must be a non-empty string")

	return {
		id = params.id,
		definitionId = definition.id,
		displayName = params.displayName or definition.displayName,
		level = params.level or 1,
		genomeCapacity = params.genomeCapacity or definition.baseGenomeCapacity,
		skillIds = cloneArray(params.skillIds or definition.baseSkillIds),
		combatMutationIds = cloneArray(params.combatMutationIds),
		visualMutations = cloneDictionary(params.visualMutations),
		cosmetics = normalizeCosmetics(params.cosmetics),
		bonusStats = normalizeBonusStats(params.bonusStats),
	}
end

function PetProfile.clone(profile)
	return PetProfile.create(profile)
end

return PetProfile
