local Contract = require(script.Parent.Parent.Parent.Parent.Utils.Contract)
local BaseCombatStats = require(script.Parent.Parent.Parent.Parent.Stats.BaseCombatStats)
local ClassIds = require(script.Parent.Parent.Parent.Parent.Fighters.ClassIds)

export type ClassDefinition = {
	classId: string,
	displayName: string,
	aggroWeight: number,
	baseStats: BaseCombatStats.BaseCombatStats,
	levelGrowth: BaseCombatStats.BaseCombatStats,
	baseAttackIntervalSeconds: number,
	attackIntervalDeltaPerLevel: number,
	minimumAttackIntervalSeconds: number,
}

local ClassDefinition = {}

function ClassDefinition.assert(value, fieldName)
	fieldName = fieldName or "ClassDefinition"
	Contract.assertTable(value, fieldName)
	Contract.assertEnumValue(value.classId, ClassIds, string.format("%s.classId", fieldName))
	Contract.assertString(value.displayName, string.format("%s.displayName", fieldName))
	Contract.assertPositiveInteger(value.aggroWeight, string.format("%s.aggroWeight", fieldName))
	BaseCombatStats.assert(value.baseStats, string.format("%s.baseStats", fieldName))
	BaseCombatStats.assert(value.levelGrowth, string.format("%s.levelGrowth", fieldName))
	Contract.assertPositiveNumber(
		value.baseAttackIntervalSeconds,
		string.format("%s.baseAttackIntervalSeconds", fieldName)
	)
	Contract.assertNumber(
		value.attackIntervalDeltaPerLevel,
		string.format("%s.attackIntervalDeltaPerLevel", fieldName)
	)
	Contract.assertPositiveNumber(
		value.minimumAttackIntervalSeconds,
		string.format("%s.minimumAttackIntervalSeconds", fieldName)
	)
	assert(
		value.minimumAttackIntervalSeconds <= value.baseAttackIntervalSeconds,
		string.format(
			"%s.minimumAttackIntervalSeconds must be <= %s.baseAttackIntervalSeconds",
			fieldName,
			fieldName
		)
	)

	return value
end

function ClassDefinition.new(data)
	ClassDefinition.assert(data)

	return table.freeze(data)
end

return ClassDefinition
