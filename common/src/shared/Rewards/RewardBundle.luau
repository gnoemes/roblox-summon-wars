local Contract = require(script.Parent.Parent.Utils.Contract)

export type RewardBundle = {
	currencies: { [string]: number },
	resources: { [string]: number },
	cardIds: { string },
	fighterExperience: number,
	accountExperience: number,
}

local RewardBundle = {}

function RewardBundle.assert(value, fieldName)
	fieldName = fieldName or "RewardBundle"
	Contract.assertTable(value, fieldName)
	Contract.assertStringNumberDictionary(
		value.currencies,
		string.format("%s.currencies", fieldName)
	)
	Contract.assertStringNumberDictionary(value.resources, string.format("%s.resources", fieldName))
	Contract.assertStringArray(value.cardIds, string.format("%s.cardIds", fieldName))
	Contract.assertNonNegativeNumber(
		value.fighterExperience,
		string.format("%s.fighterExperience", fieldName)
	)
	Contract.assertNonNegativeNumber(
		value.accountExperience,
		string.format("%s.accountExperience", fieldName)
	)

	return value
end

function RewardBundle.new(data)
	RewardBundle.assert(data)

	return table.freeze(data)
end

return RewardBundle
