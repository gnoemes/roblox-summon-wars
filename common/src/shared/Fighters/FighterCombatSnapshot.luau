local Contract = require(script.Parent.Parent.Utils.Contract)
local BaseCombatStats = require(script.Parent.Parent.Stats.BaseCombatStats)
local ComputedCombatStats = require(script.Parent.Parent.Stats.ComputedCombatStats)
local ClassIds = require(script.Parent.ClassIds)
local GradeIds = require(script.Parent.Parent.Progression.Grades.GradeIds)

export type FighterCombatSnapshot = {
	combatantId: string,
	fighterId: string,
	classId: string,
	grade: string,
	level: number,
	baseStats: BaseCombatStats.BaseCombatStats,
	computedStats: ComputedCombatStats.ComputedCombatStats,
	activeSkillIds: { string },
	traitId: string?,
}

local FighterCombatSnapshot = {}

function FighterCombatSnapshot.assert(value, fieldName)
	fieldName = fieldName or "FighterCombatSnapshot"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.combatantId, string.format("%s.combatantId", fieldName))
	Contract.assertString(value.fighterId, string.format("%s.fighterId", fieldName))
	Contract.assertEnumValue(value.classId, ClassIds, string.format("%s.classId", fieldName))
	Contract.assertEnumValue(value.grade, GradeIds, string.format("%s.grade", fieldName))
	Contract.assertPositiveInteger(value.level, string.format("%s.level", fieldName))
	BaseCombatStats.assert(value.baseStats, string.format("%s.baseStats", fieldName))
	ComputedCombatStats.assert(value.computedStats, string.format("%s.computedStats", fieldName))
	Contract.assertStringArray(value.activeSkillIds, string.format("%s.activeSkillIds", fieldName))
	Contract.assertOptionalString(value.traitId, string.format("%s.traitId", fieldName))

	return value
end

function FighterCombatSnapshot.new(data)
	FighterCombatSnapshot.assert(data)

	return table.freeze(data)
end

return FighterCombatSnapshot
