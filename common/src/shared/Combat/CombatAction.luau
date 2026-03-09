local Contract = require(script.Parent.Parent.Utils.Contract)
local CombatActionTypes = require(script.Parent.CombatActionTypes)
local CombatantRef = require(script.Parent.CombatantRef)

export type CombatAction = {
	actionId: string,
	sequence: number,
	actor: CombatantRef.CombatantRef,
	target: CombatantRef.CombatantRef?,
	actionType: string,
	skillId: string?,
	startedAt: number,
}

local CombatAction = {}

function CombatAction.assert(value, fieldName)
	fieldName = fieldName or "CombatAction"
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
	Contract.assertNonNegativeNumber(value.startedAt, string.format("%s.startedAt", fieldName))

	return value
end

function CombatAction.new(data)
	CombatAction.assert(data)

	return table.freeze(data)
end

return CombatAction
