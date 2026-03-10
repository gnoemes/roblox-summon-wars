local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))

local ClassPackages = CombatConfig.Fighters.ClassPackages

local FighterLoadoutRules = {}

local function buildSkillLookup(classPackage)
	local lookup = {}
	for _, skillDefinition in ipairs(classPackage.skillPool) do
		lookup[skillDefinition.skillId] = skillDefinition
	end
	return lookup
end

function FighterLoadoutRules.assertActiveOnlySpecialLoadout(
	classId,
	specialSkillId,
	activeSkillIds,
	fieldName
)
	fieldName = fieldName or "FighterLoadout"

	local classPackage = ClassPackages.get(classId)
	assert(
		classPackage ~= nil,
		string.format("%s.classId references unknown class %s", fieldName, tostring(classId))
	)

	local skillLookup = buildSkillLookup(classPackage)
	local specialSkillDefinition = skillLookup[specialSkillId]
	assert(
		specialSkillDefinition ~= nil,
		string.format(
			"%s.specialSkillId %s does not belong to class %s",
			fieldName,
			tostring(specialSkillId),
			tostring(classId)
		)
	)
	assert(
		specialSkillDefinition.kind == "Active",
		string.format(
			"%s.specialSkillId %s must reference an Active special skill in the current fighter runtime",
			fieldName,
			tostring(specialSkillId)
		)
	)
	assert(
		specialSkillDefinition.flags.isSpecialSkill == true,
		string.format(
			"%s.specialSkillId %s must reference a skill marked as special",
			fieldName,
			tostring(specialSkillId)
		)
	)

	local seenSkillIds = {}
	local containsSpecialSkill = false
	for index, skillId in ipairs(activeSkillIds) do
		assert(
			seenSkillIds[skillId] == nil,
			string.format(
				"%s.activeSkillIds[%d] duplicates skill %s",
				fieldName,
				index,
				tostring(skillId)
			)
		)
		seenSkillIds[skillId] = true

		local skillDefinition = skillLookup[skillId]
		assert(
			skillDefinition ~= nil,
			string.format(
				"%s.activeSkillIds[%d] skill %s does not belong to class %s",
				fieldName,
				index,
				tostring(skillId),
				tostring(classId)
			)
		)
		assert(
			skillDefinition.kind == "Active",
			string.format(
				"%s.activeSkillIds[%d] skill %s must be Active in the current fighter runtime",
				fieldName,
				index,
				tostring(skillId)
			)
		)
		assert(
			skillDefinition.flags.isSpecialSkill == true,
			string.format(
				"%s.activeSkillIds[%d] skill %s must be marked as a special skill",
				fieldName,
				index,
				tostring(skillId)
			)
		)

		if skillId == specialSkillId then
			containsSpecialSkill = true
		end
	end

	assert(
		containsSpecialSkill,
		string.format(
			"%s.activeSkillIds must contain the fighter special skill %s",
			fieldName,
			tostring(specialSkillId)
		)
	)
end

return FighterLoadoutRules
