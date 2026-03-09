local Contract = require(script.Parent.Parent.Utils.Contract)
local ComputedCombatStats = require(script.Parent.Parent.Stats.ComputedCombatStats)
local EnemyTierIds = require(script.Parent.EnemyTierIds)

export type EnemyCombatSnapshot = {
	combatantId: string,
	enemyId: string,
	tier: string,
	computedStats: ComputedCombatStats.ComputedCombatStats,
	skillIds: { string },
	dropTableId: string,
	threatTag: string?,
}

local EnemyCombatSnapshot = {}

function EnemyCombatSnapshot.assert(value, fieldName)
	fieldName = fieldName or "EnemyCombatSnapshot"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.combatantId, string.format("%s.combatantId", fieldName))
	Contract.assertString(value.enemyId, string.format("%s.enemyId", fieldName))
	Contract.assertEnumValue(value.tier, EnemyTierIds, string.format("%s.tier", fieldName))
	ComputedCombatStats.assert(value.computedStats, string.format("%s.computedStats", fieldName))
	Contract.assertStringArray(value.skillIds, string.format("%s.skillIds", fieldName))
	Contract.assertString(value.dropTableId, string.format("%s.dropTableId", fieldName))
	Contract.assertOptionalString(value.threatTag, string.format("%s.threatTag", fieldName))

	return value
end

function EnemyCombatSnapshot.new(data)
	EnemyCombatSnapshot.assert(data)

	return table.freeze(data)
end

return EnemyCombatSnapshot
