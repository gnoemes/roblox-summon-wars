local Contract = require(script.Parent.Parent.Parent.Utils.Contract)
local DropEntryKinds = require(script.Parent.DropEntryKinds)

export type DropEntryDefinition = {
	kind: string,
	itemId: string,
	minAmount: number,
	maxAmount: number,
	weight: number?,
}

local DropEntryDefinition = {}

function DropEntryDefinition.assert(value, fieldName)
	fieldName = fieldName or "DropEntryDefinition"
	Contract.assertTable(value, fieldName)
	Contract.assertEnumValue(value.kind, DropEntryKinds, string.format("%s.kind", fieldName))
	Contract.assertString(value.itemId, string.format("%s.itemId", fieldName))
	Contract.assertPositiveInteger(value.minAmount, string.format("%s.minAmount", fieldName))
	Contract.assertPositiveInteger(value.maxAmount, string.format("%s.maxAmount", fieldName))
	Contract.assertOptionalPositiveNumber(value.weight, string.format("%s.weight", fieldName))
	assert(
		value.minAmount <= value.maxAmount,
		string.format("%s.minAmount must be <= %s.maxAmount", fieldName, fieldName)
	)

	return value
end

function DropEntryDefinition.new(data)
	DropEntryDefinition.assert(data)

	return table.freeze(data)
end

return DropEntryDefinition
