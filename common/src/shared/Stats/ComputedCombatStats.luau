local Contract = require(script.Parent.Parent.Utils.Contract)
local BaseCombatStats = require(script.Parent.BaseCombatStats)

export type ComputedCombatStats = BaseCombatStats.BaseCombatStats & {
	attackIntervalSeconds: number,
}

local ComputedCombatStats = {}

function ComputedCombatStats.assert(value, fieldName)
	fieldName = fieldName or "ComputedCombatStats"
	BaseCombatStats.assert(value, fieldName)
	Contract.assertPositiveNumber(
		value.attackIntervalSeconds,
		string.format("%s.attackIntervalSeconds", fieldName)
	)

	return value
end

function ComputedCombatStats.new(data)
	ComputedCombatStats.assert(data)

	return table.freeze(data)
end

return ComputedCombatStats
