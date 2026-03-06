local PetFactory = {}

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

function PetFactory.buildComponents(snapshot, components)
	local initialCooldowns = {}
	for _, skillId in ipairs(snapshot.skillIds) do
		initialCooldowns[skillId] = 0
	end

	return {
		components.PetIdentity({
			petId = snapshot.petId,
			definitionId = snapshot.definitionId,
			displayName = snapshot.displayName,
		}),
		components.PetOwner({
			userId = snapshot.ownerUserId,
		}),
		components.ResolvedStats({
			values = cloneDictionary(snapshot.stats),
			attackRange = snapshot.attackRange,
			genomeCapacity = snapshot.genomeCapacity,
		}),
		components.HealthState({
			currentHealth = snapshot.currentHealth,
			maxHealth = snapshot.stats.maxHealth,
		}),
		components.SkillLoadout({
			skillIds = cloneArray(snapshot.skillIds),
		}),
		components.SkillCooldowns({
			bySkillId = initialCooldowns,
		}),
		components.MutationLoadout({
			combatMutationIds = cloneArray(snapshot.combatMutationIds),
		}),
		components.VisualLoadout({
			visualMutations = cloneDictionary(snapshot.visualMutations),
			cosmetics = cloneDictionary(snapshot.cosmetics),
			scalePresetId = snapshot.scalePresetId,
		}),
		components.CommandState(snapshot.commandState),
		components.SkillRuntimeState({
			tacticalSkillId = snapshot.runtimeState.tacticalSkillId,
			tacticalSkillForcedAuto = snapshot.runtimeState.tacticalSkillForcedAuto,
			lastActivatedAtBySkillId = {},
			activationCountsBySkillId = {},
		}),
	}
end

return PetFactory
