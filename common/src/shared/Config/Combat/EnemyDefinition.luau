local Contract = require(script.Parent.Parent.Parent.Utils.Contract)
local ComputedCombatStats = require(script.Parent.Parent.Parent.Stats.ComputedCombatStats)
local EnemyTierIds = require(script.Parent.Parent.Parent.Enemies.EnemyTierIds)
local DropTables = require(script.Parent.DropTables)
local SkillDefinitions = require(script.Parent.SkillDefinitions)

export type EnemyFlags = {
	isRare: boolean,
	isChestReplacement: boolean,
	usesPhases: boolean,
}

export type EnemyDefinition = {
	enemyId: string,
	displayName: string,
	tier: string,
	computedStats: ComputedCombatStats.ComputedCombatStats,
	basicAttackSkillId: string,
	specialSkillIds: { string },
	passiveSkillIds: { string },
	dropTableId: string,
	threatTag: string?,
	flags: EnemyFlags,
}

local EnemyDefinition = {}

local function assertFlags(value, fieldName)
	Contract.assertTable(value, fieldName)
	Contract.assertBoolean(value.isRare, string.format("%s.isRare", fieldName))
	Contract.assertBoolean(
		value.isChestReplacement,
		string.format("%s.isChestReplacement", fieldName)
	)
	Contract.assertBoolean(value.usesPhases, string.format("%s.usesPhases", fieldName))
end

local function assertSkillList(skillIds, fieldName, expectedKind)
	Contract.assertStringArray(skillIds, fieldName)

	for index, skillId in ipairs(skillIds) do
		local definition = SkillDefinitions.get(skillId)

		if expectedKind == "Special" then
			assert(
				definition.flags.isSpecialSkill,
				string.format("%s[%d] must reference a special skill", fieldName, index)
			)
		elseif expectedKind == "Passive" then
			assert(
				definition.flags.isPassive,
				string.format("%s[%d] must reference a passive skill", fieldName, index)
			)
		end
	end
end

local function assertTierComplexity(value, fieldName)
	local specialCount = #value.specialSkillIds
	local passiveCount = #value.passiveSkillIds

	if value.tier == "Normal" then
		assert(
			specialCount == 1,
			string.format("%s Normal enemies must define 1 special skill", fieldName)
		)
		assert(
			passiveCount == 0,
			string.format("%s Normal enemies cannot define passive skills", fieldName)
		)
		assert(
			not value.flags.usesPhases,
			string.format("%s Normal enemies cannot use phases", fieldName)
		)
	elseif value.tier == "Elite" then
		assert(
			specialCount == 2,
			string.format("%s Elite enemies must define 2 special skills", fieldName)
		)
		assert(
			passiveCount <= 1,
			string.format("%s Elite enemies may define at most 1 passive skill", fieldName)
		)
		assert(
			not value.flags.usesPhases,
			string.format("%s Elite enemies cannot use phases", fieldName)
		)
	elseif value.tier == "Boss" then
		assert(
			specialCount >= 2 and specialCount <= 3,
			string.format("%s Boss enemies must define 2 to 3 special skills", fieldName)
		)
	end

	if value.flags.usesPhases then
		assert(
			value.tier == "Boss",
			string.format("%s only Boss enemies can use phases", fieldName)
		)
	end
end

function EnemyDefinition.assert(value, fieldName)
	fieldName = fieldName or "EnemyDefinition"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.enemyId, string.format("%s.enemyId", fieldName))
	Contract.assertString(value.displayName, string.format("%s.displayName", fieldName))
	Contract.assertEnumValue(value.tier, EnemyTierIds, string.format("%s.tier", fieldName))
	ComputedCombatStats.assert(value.computedStats, string.format("%s.computedStats", fieldName))
	Contract.assertString(
		value.basicAttackSkillId,
		string.format("%s.basicAttackSkillId", fieldName)
	)
	assertSkillList(
		value.specialSkillIds,
		string.format("%s.specialSkillIds", fieldName),
		"Special"
	)
	assertSkillList(
		value.passiveSkillIds,
		string.format("%s.passiveSkillIds", fieldName),
		"Passive"
	)
	Contract.assertString(value.dropTableId, string.format("%s.dropTableId", fieldName))
	Contract.assertOptionalString(value.threatTag, string.format("%s.threatTag", fieldName))
	assertFlags(value.flags, string.format("%s.flags", fieldName))

	local basicAttackDefinition = SkillDefinitions.get(value.basicAttackSkillId)
	assert(
		basicAttackDefinition.flags.isBasicAttack,
		string.format("%s.basicAttackSkillId must reference a basic attack skill", fieldName)
	)
	assert(
		DropTables.has(value.dropTableId),
		string.format(
			"%s.dropTableId references unknown drop table %s",
			fieldName,
			value.dropTableId
		)
	)
	assertTierComplexity(value, fieldName)

	return value
end

function EnemyDefinition.new(data)
	EnemyDefinition.assert(data)

	return table.freeze(data)
end

return EnemyDefinition
