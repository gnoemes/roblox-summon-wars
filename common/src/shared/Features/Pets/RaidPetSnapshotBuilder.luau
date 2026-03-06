local PetScalePresets = require(script.Parent:WaitForChild("PetScalePresets"))
local PetStatCalculator = require(script.Parent:WaitForChild("PetStatCalculator"))
local PetValidator = require(script.Parent:WaitForChild("PetValidator"))

local RaidPetSnapshotBuilder = {}

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

function RaidPetSnapshotBuilder.build(profile, params)
	local validation = PetValidator.validate(profile)
	if not validation.ok then
		return nil, validation.errors
	end

	local summary = PetStatCalculator.calculate(profile)
	local maxHealth = summary.stats.maxHealth
	local currentHealth = if params and type(params.currentHealth) == "number" then params.currentHealth else maxHealth

	return {
		petId = profile.id,
		ownerUserId = if params then params.ownerUserId else nil,
		definitionId = profile.definitionId,
		displayName = profile.displayName,
		scalePresetId = PetScalePresets.DefaultId,
		stats = summary.stats,
		currentHealth = math.clamp(currentHealth, 0, maxHealth),
		attackRange = summary.attackRange,
		genomeCapacity = profile.genomeCapacity,
		skillIds = cloneArray(profile.skillIds),
		combatMutationIds = cloneArray(profile.combatMutationIds),
		visualMutations = cloneDictionary(profile.visualMutations),
		cosmetics = cloneDictionary(profile.cosmetics),
		commandState = {
			stance = "balance",
			mode = "idle",
			focusTargetEntityId = nil,
			holdPoint = nil,
		},
		runtimeState = {
			tacticalSkillId = nil,
			tacticalSkillForcedAuto = false,
			activeBuffIds = {},
			activeDebuffIds = {},
		},
	}
end

return RaidPetSnapshotBuilder
