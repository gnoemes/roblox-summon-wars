local Contract = require(script.Parent.Parent.Utils.Contract)
local CombatActionResultOutcomes = require(script.Parent.CombatActionResultOutcomes)
local CombatActionTypes = require(script.Parent.CombatActionTypes)
local CombatantRef = require(script.Parent.CombatantRef)

export type CombatActionResult = {
	actionId: string,
	sequence: number,
	actor: CombatantRef.CombatantRef,
	target: CombatantRef.CombatantRef?,
	actionType: string,
	skillId: string?,
	outcome: string,
	hit: boolean,
	damageDealt: number,
	healingDone: number,
	appliedEffectIds: { string },
	defeatedCombatantIds: { string },
	resolvedAt: number,
}

local CombatActionResult = {}

function CombatActionResult.assert(value, fieldName)
	fieldName = fieldName or "CombatActionResult"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.actionId, string.format("%s.actionId", fieldName))
	Contract.assertPositiveInteger(value.sequence, string.format("%s.sequence", fieldName))
	CombatantRef.assert(value.actor, string.format("%s.actor", fieldName))

	if value.target ~= nil then
		CombatantRef.assert(value.target, string.format("%s.target", fieldName))
	end

	Contract.assertEnumValue(
		value.actionType,
		CombatActionTypes,
		string.format("%s.actionType", fieldName)
	)
	Contract.assertOptionalString(value.skillId, string.format("%s.skillId", fieldName))
	Contract.assertEnumValue(
		value.outcome,
		CombatActionResultOutcomes,
		string.format("%s.outcome", fieldName)
	)
	Contract.assertBoolean(value.hit, string.format("%s.hit", fieldName))
	Contract.assertNonNegativeNumber(value.damageDealt, string.format("%s.damageDealt", fieldName))
	Contract.assertNonNegativeNumber(value.healingDone, string.format("%s.healingDone", fieldName))
	Contract.assertStringArray(
		value.appliedEffectIds,
		string.format("%s.appliedEffectIds", fieldName)
	)
	Contract.assertStringArray(
		value.defeatedCombatantIds,
		string.format("%s.defeatedCombatantIds", fieldName)
	)
	Contract.assertNonNegativeNumber(value.resolvedAt, string.format("%s.resolvedAt", fieldName))

	return value
end

function CombatActionResult.new(data)
	CombatActionResult.assert(data)

	return table.freeze(data)
end

return CombatActionResult
