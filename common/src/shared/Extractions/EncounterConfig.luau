local Contract = require(script.Parent.Parent.Utils.Contract)
local ExtractionTypeIds = require(script.Parent.ExtractionTypeIds)

export type EncounterFlags = {
	isElite: boolean,
	isRare: boolean,
	isBoss: boolean,
	isChestReplacement: boolean,
}

export type EncounterConfig = {
	encounterId: string,
	extractionType: string,
	enemyId: string,
	stageLabel: string?,
	recommendedSquadPower: number?,
	minimumSquadPower: number?,
	runInstanceId: string?,
	flags: EncounterFlags,
}

local EncounterConfig = {}

local function assertFlags(value, fieldName)
	Contract.assertTable(value, fieldName)
	Contract.assertBoolean(value.isElite, string.format("%s.isElite", fieldName))
	Contract.assertBoolean(value.isRare, string.format("%s.isRare", fieldName))
	Contract.assertBoolean(value.isBoss, string.format("%s.isBoss", fieldName))
	Contract.assertBoolean(
		value.isChestReplacement,
		string.format("%s.isChestReplacement", fieldName)
	)
end

function EncounterConfig.assert(value, fieldName)
	fieldName = fieldName or "EncounterConfig"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.encounterId, string.format("%s.encounterId", fieldName))
	Contract.assertEnumValue(
		value.extractionType,
		ExtractionTypeIds,
		string.format("%s.extractionType", fieldName)
	)
	Contract.assertString(value.enemyId, string.format("%s.enemyId", fieldName))
	Contract.assertOptionalString(value.stageLabel, string.format("%s.stageLabel", fieldName))
	Contract.assertOptionalNonNegativeNumber(
		value.recommendedSquadPower,
		string.format("%s.recommendedSquadPower", fieldName)
	)
	Contract.assertOptionalNonNegativeNumber(
		value.minimumSquadPower,
		string.format("%s.minimumSquadPower", fieldName)
	)
	Contract.assertOptionalString(value.runInstanceId, string.format("%s.runInstanceId", fieldName))
	assertFlags(value.flags, string.format("%s.flags", fieldName))

	return value
end

function EncounterConfig.new(data)
	EncounterConfig.assert(data)

	return table.freeze(data)
end

return EncounterConfig
