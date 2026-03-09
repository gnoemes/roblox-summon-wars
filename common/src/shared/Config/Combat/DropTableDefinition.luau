local Contract = require(script.Parent.Parent.Parent.Utils.Contract)
local DropEntryDefinition = require(script.Parent.DropEntryDefinition)

export type DropTableDefinition = {
	dropTableId: string,
	guaranteedEntries: { DropEntryDefinition.DropEntryDefinition },
	weightedEntries: { DropEntryDefinition.DropEntryDefinition },
	rolls: number,
}

local DropTableDefinition = {}

local function assertEntries(entries, fieldName, expectsWeight)
	Contract.assertArray(entries, fieldName)

	for index, entry in ipairs(entries) do
		DropEntryDefinition.assert(entry, string.format("%s[%d]", fieldName, index))

		if expectsWeight then
			assert(
				entry.weight ~= nil,
				string.format("%s[%d].weight is required for weighted entries", fieldName, index)
			)
		else
			assert(
				entry.weight == nil,
				string.format(
					"%s[%d].weight is not allowed for guaranteed entries",
					fieldName,
					index
				)
			)
		end
	end
end

function DropTableDefinition.assert(value, fieldName)
	fieldName = fieldName or "DropTableDefinition"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.dropTableId, string.format("%s.dropTableId", fieldName))
	assertEntries(value.guaranteedEntries, string.format("%s.guaranteedEntries", fieldName), false)
	assertEntries(value.weightedEntries, string.format("%s.weightedEntries", fieldName), true)
	Contract.assertNonNegativeNumber(value.rolls, string.format("%s.rolls", fieldName))
	assert(value.rolls % 1 == 0, string.format("%s.rolls must be an integer", fieldName))

	if value.rolls > 0 then
		assert(
			#value.weightedEntries > 0,
			string.format("%s.weightedEntries must not be empty when rolls > 0", fieldName)
		)
	end

	return value
end

function DropTableDefinition.new(data)
	DropTableDefinition.assert(data)

	return table.freeze(data)
end

return DropTableDefinition
