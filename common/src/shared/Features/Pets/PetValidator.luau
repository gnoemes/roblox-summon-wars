local DefinitionsFolder = script.Parent:WaitForChild("Definitions")

local CosmeticDefinitions = require(DefinitionsFolder:WaitForChild("CosmeticDefinitions"))
local MutationDefinitions = require(DefinitionsFolder:WaitForChild("MutationDefinitions"))
local PetDefinitions = require(DefinitionsFolder:WaitForChild("PetDefinitions"))
local SkillDefinitions = require(DefinitionsFolder:WaitForChild("SkillDefinitions"))
local VisualChannelRules = require(DefinitionsFolder:WaitForChild("VisualChannelRules"))

local PetValidator = {}

local function pushError(errors, message)
	table.insert(errors, message)
end

local function listContains(list, target)
	for _, value in ipairs(list) do
		if value == target then
			return true
		end
	end
	return false
end

local function validateSkills(profile, definition, errors)
	local seen = {}
	local skillIds = profile.skillIds
	if type(skillIds) ~= "table" then
		pushError(errors, "Pet profile skillIds must be a table")
		return
	end

	for _, skillId in ipairs(skillIds) do
		if type(skillId) ~= "string" then
			pushError(errors, "Pet profile contains a non-string skill id")
		elseif seen[skillId] then
			pushError(errors, ("Pet profile has duplicate skill '%s'"):format(skillId))
		elseif SkillDefinitions.ById[skillId] == nil then
			pushError(errors, ("Unknown skill '%s'"):format(skillId))
		end
		seen[skillId] = true
	end

	for _, baseSkillId in ipairs(definition.baseSkillIds) do
		if not listContains(skillIds, baseSkillId) then
			pushError(errors, ("Pet profile is missing base skill '%s'"):format(baseSkillId))
		end
	end
end

local function validateCombatMutations(profile, errors)
	local totalCost = 0
	local seen = {}

	for _, mutationId in ipairs(profile.combatMutationIds or {}) do
		local mutation = MutationDefinitions.ById[mutationId]
		if type(mutationId) ~= "string" then
			pushError(errors, "Pet profile contains a non-string combat mutation id")
		elseif seen[mutationId] then
			pushError(errors, ("Pet profile has duplicate combat mutation '%s'"):format(mutationId))
		elseif mutation == nil then
			pushError(errors, ("Unknown combat mutation '%s'"):format(mutationId))
		elseif mutation.category ~= "combat" then
			pushError(errors, ("Mutation '%s' is not a combat mutation"):format(mutationId))
		else
			totalCost += mutation.mutationCost or 0
		end
		seen[mutationId] = true
	end

	if totalCost > profile.genomeCapacity then
		pushError(
			errors,
			("Combat mutations exceed genome capacity (%d > %d)"):format(totalCost, profile.genomeCapacity)
		)
	end
end

local function validateVisualMutations(profile, errors)
	local loadout = profile.visualMutations or {}
	local result = VisualChannelRules.validateLoadout(loadout)
	for _, errorMessage in ipairs(result.errors) do
		pushError(errors, errorMessage)
	end

	for channelId, mutationId in pairs(loadout) do
		if mutationId ~= nil then
			local mutation = MutationDefinitions.ById[mutationId]
			if mutation == nil then
				pushError(errors, ("Unknown visual mutation '%s'"):format(tostring(mutationId)))
			elseif mutation.category ~= "visual" then
				pushError(errors, ("Mutation '%s' is not a visual mutation"):format(tostring(mutationId)))
			elseif mutation.channel ~= nil and mutation.channel ~= channelId then
				pushError(
					errors,
					("Visual mutation '%s' cannot be equipped in channel '%s'"):format(mutationId, tostring(channelId))
				)
			end
		end
	end
end

local function validateCosmetics(profile, errors)
	local cosmetics = profile.cosmetics or {}
	for slotName, cosmeticId in pairs(cosmetics) do
		if cosmeticId ~= nil then
			local definition = CosmeticDefinitions.ById[cosmeticId]
			if definition == nil then
				pushError(errors, ("Unknown cosmetic '%s' in slot '%s'"):format(tostring(cosmeticId), tostring(slotName)))
			elseif definition.slot ~= nil and definition.slot ~= slotName then
				pushError(
					errors,
					("Cosmetic '%s' cannot be equipped in slot '%s'"):format(tostring(cosmeticId), tostring(slotName))
				)
			end
		end
	end
end

function PetValidator.validate(profile)
	local errors = {}

	if type(profile) ~= "table" then
		pushError(errors, "Pet profile must be a table")
		return {
			ok = false,
			errors = errors,
		}
	end

	if type(profile.id) ~= "string" or profile.id == "" then
		pushError(errors, "Pet profile id must be a non-empty string")
	end

	local definition = PetDefinitions.ById[profile.definitionId]
	if definition == nil then
		pushError(errors, ("Unknown pet definition '%s'"):format(tostring(profile.definitionId)))
	end

	if type(profile.level) ~= "number" or profile.level < 1 then
		pushError(errors, "Pet profile level must be >= 1")
	end

	if type(profile.genomeCapacity) ~= "number" or profile.genomeCapacity < 0 or profile.genomeCapacity > 10 then
		pushError(errors, "Pet profile genomeCapacity must be between 0 and 10")
	end

	if definition ~= nil then
		validateSkills(profile, definition, errors)
	end

	validateCombatMutations(profile, errors)
	validateVisualMutations(profile, errors)
	validateCosmetics(profile, errors)

	return {
		ok = #errors == 0,
		errors = errors,
	}
end

return PetValidator
