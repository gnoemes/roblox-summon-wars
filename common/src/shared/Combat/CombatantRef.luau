local Contract = require(script.Parent.Parent.Utils.Contract)
local CombatantKinds = require(script.Parent.CombatantKinds)

export type CombatantRef = {
	kind: string,
	combatantId: string,
}

local CombatantRef = {}

function CombatantRef.assert(value, fieldName)
	fieldName = fieldName or "CombatantRef"
	Contract.assertTable(value, fieldName)
	Contract.assertEnumValue(value.kind, CombatantKinds, string.format("%s.kind", fieldName))
	Contract.assertString(value.combatantId, string.format("%s.combatantId", fieldName))

	return value
end

function CombatantRef.new(data)
	CombatantRef.assert(data)

	return table.freeze(data)
end

return CombatantRef
