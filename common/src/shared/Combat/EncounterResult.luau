local Contract = require(script.Parent.Parent.Utils.Contract)
local RewardBundle = require(script.Parent.Parent.Rewards.RewardBundle)
local CombatActionResult = require(script.Parent.CombatActionResult)
local EncounterOutcomes = require(script.Parent.EncounterOutcomes)

export type EncounterResult = {
	encounterId: string,
	outcome: string,
	startedAt: number,
	endedAt: number,
	durationSeconds: number,
	actionResults: { CombatActionResult.CombatActionResult },
	remainingFighterCombatantIds: { string },
	defeatedFighterCombatantIds: { string },
	defeatedEnemyCombatantIds: { string },
	rewardBundle: RewardBundle.RewardBundle?,
}

local EncounterResult = {}

function EncounterResult.assert(value, fieldName)
	fieldName = fieldName or "EncounterResult"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.encounterId, string.format("%s.encounterId", fieldName))
	Contract.assertEnumValue(
		value.outcome,
		EncounterOutcomes,
		string.format("%s.outcome", fieldName)
	)
	Contract.assertNonNegativeNumber(value.startedAt, string.format("%s.startedAt", fieldName))
	Contract.assertNonNegativeNumber(value.endedAt, string.format("%s.endedAt", fieldName))
	Contract.assertNonNegativeNumber(
		value.durationSeconds,
		string.format("%s.durationSeconds", fieldName)
	)
	Contract.assertArray(value.actionResults, string.format("%s.actionResults", fieldName))

	for index, actionResult in ipairs(value.actionResults) do
		CombatActionResult.assert(
			actionResult,
			string.format("%s.actionResults[%d]", fieldName, index)
		)
	end

	Contract.assertStringArray(
		value.remainingFighterCombatantIds,
		string.format("%s.remainingFighterCombatantIds", fieldName)
	)
	Contract.assertStringArray(
		value.defeatedFighterCombatantIds,
		string.format("%s.defeatedFighterCombatantIds", fieldName)
	)
	Contract.assertStringArray(
		value.defeatedEnemyCombatantIds,
		string.format("%s.defeatedEnemyCombatantIds", fieldName)
	)

	if value.rewardBundle ~= nil then
		RewardBundle.assert(value.rewardBundle, string.format("%s.rewardBundle", fieldName))
	end

	return value
end

function EncounterResult.new(data)
	EncounterResult.assert(data)

	return table.freeze(data)
end

return EncounterResult
