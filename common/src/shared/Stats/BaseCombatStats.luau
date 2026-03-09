local Contract = require(script.Parent.Parent.Utils.Contract)

export type BaseCombatStats = {
	hp: number,
	damage: number,
	defense: number,
	accuracy: number,
	evasion: number,
	critChance: number,
	critDamage: number,
	statusResist: number,
}

local REQUIRED_FIELDS = {
	"hp",
	"damage",
	"defense",
	"accuracy",
	"evasion",
	"critChance",
	"critDamage",
	"statusResist",
}

local BaseCombatStats = {}

function BaseCombatStats.assert(value, fieldName)
	fieldName = fieldName or "BaseCombatStats"
	Contract.assertTable(value, fieldName)

	for _, statName in ipairs(REQUIRED_FIELDS) do
		Contract.assertNonNegativeNumber(
			value[statName],
			string.format("%s.%s", fieldName, statName)
		)
	end

	return value
end

function BaseCombatStats.new(data)
	BaseCombatStats.assert(data)

	return table.freeze(data)
end

return BaseCombatStats
