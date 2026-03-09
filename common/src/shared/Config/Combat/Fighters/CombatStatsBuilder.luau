local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassDefinitions = require(script.ClassDefinitions)
local ClassPackages = require(script.ClassPackages)
local GradeModifiers = require(script.GradeModifiers)
local BaseCombatStats = require(script.Parent.Parent.Parent.Parent.Stats.BaseCombatStats)
local ComputedCombatStats = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Stats")
		:WaitForChild("ComputedCombatStats")
)
local FighterCombatSnapshot = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Fighters")
		:WaitForChild("FighterCombatSnapshot")
)

local PRIMARY_STATS = {
	"hp",
	"damage",
	"defense",
}

local CombatStatsBuilder = {}

local function cloneStats(stats)
	return table.clone(stats)
end

local function applyPartial(baseStats, partial)
	local nextStats = cloneStats(baseStats)

	if partial == nil then
		return nextStats
	end

	for key, value in pairs(partial) do
		nextStats[key] = value
	end

	return nextStats
end

local function containsSkill(classPackage, skillId)
	for _, skillDefinition in ipairs(classPackage.skillPool) do
		if skillDefinition.skillId == skillId then
			return true
		end
	end
	return false
end

local function assertStringArray(value, fieldName)
	assert(type(value) == "table", string.format("%s must be an array", fieldName))

	for key in pairs(value) do
		assert(
			type(key) == "number" and key % 1 == 0 and key >= 1,
			string.format("%s must be an array", fieldName)
		)
	end

	for index, entry in ipairs(value) do
		assert(
			type(entry) == "string" and entry ~= "",
			string.format("%s[%d] must be a non-empty string", fieldName, index)
		)
	end

	return value
end

local function validateActiveSkills(classPackage, classId, activeSkillIds)
	local seenSkillIds = {}
	assertStringArray(activeSkillIds, "Fighter spec.activeSkillIds")

	for index, skillId in ipairs(activeSkillIds) do
		assert(
			seenSkillIds[skillId] == nil,
			string.format("Duplicate active skill %s at index %d", tostring(skillId), index)
		)
		seenSkillIds[skillId] = true
		assert(
			containsSkill(classPackage, skillId),
			string.format(
				"Active skill %s does not belong to class %s",
				tostring(skillId),
				tostring(classId)
			)
		)
	end
end

function CombatStatsBuilder.buildBaseStats(classId, baseOverrides)
	local classDefinition = ClassDefinitions.get(classId)
	local baseStats = applyPartial(classDefinition.baseStats, baseOverrides)
	BaseCombatStats.assert(baseStats, "CombatStatsBuilder.baseStats")
	return BaseCombatStats.new(baseStats)
end

function CombatStatsBuilder.buildComputedStats(classId, grade, level, options)
	options = options or {}
	local classDefinition = ClassDefinitions.get(classId)
	local gradeModifier = GradeModifiers[grade]
	assert(gradeModifier ~= nil, string.format("Unknown grade %s", tostring(grade)))
	assert(
		type(level) == "number" and level >= 1 and level % 1 == 0,
		"level must be a positive integer"
	)

	local baseStats = applyPartial(classDefinition.baseStats, options.baseOverrides)
	local computedStats = {}
	local levelIndex = level - 1

	for key, baseValue in pairs(baseStats) do
		local nextValue = baseValue + classDefinition.levelGrowth[key] * levelIndex
		for _, primaryStatName in ipairs(PRIMARY_STATS) do
			if key == primaryStatName then
				nextValue *= gradeModifier.primaryStatMultiplier
				break
			end
		end
		computedStats[key] = nextValue
	end

	computedStats.accuracy += gradeModifier.accuracyBonus
	computedStats.evasion += gradeModifier.evasionBonus
	computedStats.critChance += gradeModifier.critChanceBonus
	computedStats.critDamage += gradeModifier.critDamageBonus
	computedStats.statusResist += gradeModifier.statusResistBonus

	if options.additiveStats ~= nil then
		for key, value in pairs(options.additiveStats) do
			computedStats[key] = (computedStats[key] or 0) + value
		end
	end

	computedStats.attackIntervalSeconds = math.max(
		(
			classDefinition.baseAttackIntervalSeconds
			+ classDefinition.attackIntervalDeltaPerLevel * levelIndex
		) * gradeModifier.attackIntervalMultiplier,
		classDefinition.minimumAttackIntervalSeconds
	)
	if options.attackIntervalOffset ~= nil then
		computedStats.attackIntervalSeconds = math.max(
			computedStats.attackIntervalSeconds + options.attackIntervalOffset,
			classDefinition.minimumAttackIntervalSeconds
		)
	end

	return ComputedCombatStats.new(computedStats)
end

function CombatStatsBuilder.buildFighterSnapshot(spec)
	assert(type(spec) == "table", "Fighter spec must be a table")
	local classPackage = ClassPackages.get(spec.classId)
	assert(classPackage ~= nil, string.format("Unknown class package %s", tostring(spec.classId)))
	validateActiveSkills(classPackage, spec.classId, spec.activeSkillIds)

	local baseStats = CombatStatsBuilder.buildBaseStats(spec.classId, spec.baseOverrides)
	local computedStats =
		CombatStatsBuilder.buildComputedStats(spec.classId, spec.grade, spec.level, {
			baseOverrides = spec.baseOverrides,
			additiveStats = spec.additiveStats,
			attackIntervalOffset = spec.attackIntervalOffset,
		})

	return FighterCombatSnapshot.new({
		combatantId = spec.fighterId,
		fighterId = spec.fighterId,
		classId = spec.classId,
		grade = spec.grade,
		level = spec.level,
		baseStats = baseStats,
		computedStats = computedStats,
		activeSkillIds = table.freeze(table.clone(spec.activeSkillIds)),
		traitId = spec.traitId,
	})
end

return CombatStatsBuilder
