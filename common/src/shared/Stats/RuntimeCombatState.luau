local Contract = require(script.Parent.Parent.Utils.Contract)

export type RuntimeCombatState = {
	currentHp: number,
	isAlive: boolean,
	pendingActionType: string?,
	nextSkillId: string?,
	nextActionAt: number?,
	activeEffectIds: { string },
	effectStacksById: { [string]: number },
	remainingCooldownsBySkillId: { [string]: number },
}

local RuntimeCombatState = {}

function RuntimeCombatState.assert(value, fieldName)
	fieldName = fieldName or "RuntimeCombatState"
	Contract.assertTable(value, fieldName)
	Contract.assertNonNegativeNumber(value.currentHp, string.format("%s.currentHp", fieldName))
	Contract.assertBoolean(value.isAlive, string.format("%s.isAlive", fieldName))
	Contract.assertOptionalString(
		value.pendingActionType,
		string.format("%s.pendingActionType", fieldName)
	)
	Contract.assertOptionalString(value.nextSkillId, string.format("%s.nextSkillId", fieldName))
	Contract.assertOptionalNonNegativeNumber(
		value.nextActionAt,
		string.format("%s.nextActionAt", fieldName)
	)
	Contract.assertStringArray(
		value.activeEffectIds,
		string.format("%s.activeEffectIds", fieldName)
	)
	Contract.assertStringIntegerDictionary(
		value.effectStacksById,
		string.format("%s.effectStacksById", fieldName)
	)
	Contract.assertStringNumberDictionary(
		value.remainingCooldownsBySkillId,
		string.format("%s.remainingCooldownsBySkillId", fieldName)
	)

	return value
end

function RuntimeCombatState.new(data)
	RuntimeCombatState.assert(data)

	return table.freeze(data)
end

return RuntimeCombatState
