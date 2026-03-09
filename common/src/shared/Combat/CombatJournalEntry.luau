local Contract = require(script.Parent.Parent.Utils.Contract)
local CombatJournalEntryKinds = require(script.Parent.CombatJournalEntryKinds)
local CombatActionResult = require(script.Parent.CombatActionResult)

export type CombatJournalEntry = {
	kind: string,
	at: number,
	actionResult: CombatActionResult.CombatActionResult?,
	encounterOutcome: string?,
}

local CombatJournalEntry = {}

function CombatJournalEntry.assert(value, fieldName)
	fieldName = fieldName or "CombatJournalEntry"
	Contract.assertTable(value, fieldName)
	Contract.assertEnumValue(
		value.kind,
		CombatJournalEntryKinds,
		string.format("%s.kind", fieldName)
	)
	Contract.assertNonNegativeNumber(value.at, string.format("%s.at", fieldName))
	Contract.assertOptionalString(
		value.encounterOutcome,
		string.format("%s.encounterOutcome", fieldName)
	)

	if value.actionResult ~= nil then
		CombatActionResult.assert(value.actionResult, string.format("%s.actionResult", fieldName))
	end

	if value.kind == "Action" then
		assert(value.actionResult ~= nil, string.format("%s.actionResult is required", fieldName))
	end

	if value.kind == "EncounterEnd" then
		assert(
			value.encounterOutcome ~= nil,
			string.format("%s.encounterOutcome is required", fieldName)
		)
	end

	return value
end

function CombatJournalEntry.new(data)
	CombatJournalEntry.assert(data)

	return table.freeze(data)
end

return CombatJournalEntry
