local GradeIds = require(script.Parent.Parent.Parent.Parent.Progression.Grades.GradeIds)

local definitions = {
	Common = table.freeze({
		primaryStatMultiplier = 1,
		attackIntervalMultiplier = 1,
		accuracyBonus = 0,
		evasionBonus = 0,
		critChanceBonus = 0,
		critDamageBonus = 0,
		statusResistBonus = 0,
	}),
	Uncommon = table.freeze({
		primaryStatMultiplier = 1.05,
		attackIntervalMultiplier = 0.99,
		accuracyBonus = 0.01,
		evasionBonus = 0.01,
		critChanceBonus = 0.01,
		critDamageBonus = 0.02,
		statusResistBonus = 0.01,
	}),
	Rare = table.freeze({
		primaryStatMultiplier = 1.12,
		attackIntervalMultiplier = 0.97,
		accuracyBonus = 0.02,
		evasionBonus = 0.02,
		critChanceBonus = 0.02,
		critDamageBonus = 0.05,
		statusResistBonus = 0.02,
	}),
	Epic = table.freeze({
		primaryStatMultiplier = 1.22,
		attackIntervalMultiplier = 0.95,
		accuracyBonus = 0.03,
		evasionBonus = 0.03,
		critChanceBonus = 0.04,
		critDamageBonus = 0.1,
		statusResistBonus = 0.03,
	}),
	Legendary = table.freeze({
		primaryStatMultiplier = 1.35,
		attackIntervalMultiplier = 0.92,
		accuracyBonus = 0.05,
		evasionBonus = 0.04,
		critChanceBonus = 0.06,
		critDamageBonus = 0.15,
		statusResistBonus = 0.05,
	}),
}

for _, gradeId in ipairs(GradeIds.Values) do
	assert(definitions[gradeId] ~= nil, string.format("Missing grade modifier for %s", gradeId))
end

return table.freeze(definitions)
