local Contract = require(script.Parent.Parent.Parent.Utils.Contract)

export type StatusAssetBindingDefinition = {
	statusId: string,
	iconAssetId: string | number?,
}

local StatusAssetBindingDefinition = {}

function StatusAssetBindingDefinition.assert(value, fieldName)
	fieldName = fieldName or "StatusAssetBindingDefinition"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.statusId, string.format("%s.statusId", fieldName))
	Contract.assertOptionalAssetId(value.iconAssetId, string.format("%s.iconAssetId", fieldName))

	return value
end

function StatusAssetBindingDefinition.new(data)
	StatusAssetBindingDefinition.assert(data)

	return table.freeze(data)
end

return StatusAssetBindingDefinition
