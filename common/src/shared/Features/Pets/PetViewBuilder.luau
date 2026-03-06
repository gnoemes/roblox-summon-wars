local PetScalePresets = require(script.Parent:WaitForChild("PetScalePresets"))
local PetStatCalculator = require(script.Parent:WaitForChild("PetStatCalculator"))
local PetValidator = require(script.Parent:WaitForChild("PetValidator"))

local PetViewBuilder = {}

local function cloneDictionary(map)
	local out = {}
	for key, value in pairs(map or {}) do
		out[key] = value
	end
	return out
end

local function cloneArray(list)
	if type(list) ~= "table" then
		return {}
	end
	return table.clone(list)
end

function PetViewBuilder.build(profile, options)
	local validation = PetValidator.validate(profile)
	if not validation.ok then
		return nil, validation.errors
	end

	local scalePresetId = options and options.scalePresetId or PetScalePresets.DefaultId
	local scalePreset = PetScalePresets.ById[scalePresetId]
	if not scalePreset then
		return nil, { ("Unknown pet scale preset '%s'"):format(tostring(scalePresetId)) }
	end

	local summary = PetStatCalculator.calculate(profile)

	return {
		petId = profile.id,
		definitionId = profile.definitionId,
		displayName = profile.displayName,
		archetype = summary.archetype,
		level = profile.level,
		genomeCapacity = profile.genomeCapacity,
		scalePresetId = scalePreset.id,
		scale = scalePreset.scale,
		attackRange = summary.attackRange,
		stats = summary.stats,
		skillIds = cloneArray(profile.skillIds),
		combatMutationIds = cloneArray(profile.combatMutationIds),
		visualMutations = cloneDictionary(profile.visualMutations),
		cosmetics = cloneDictionary(profile.cosmetics),
	}
end

return PetViewBuilder
