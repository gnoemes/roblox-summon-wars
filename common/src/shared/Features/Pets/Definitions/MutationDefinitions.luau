local definitions = {
	marionette = {
		id = "marionette",
		displayName = "Marionette",
		category = "combat",
		mutationCost = 2,
		trigger = "wave_milestone_25",
		params = {
			tacticalSkillPool = "tactical_eligible_skills",
		},
	},
}

return {
	OrderedIds = {
		"marionette",
	},
	ById = definitions,
}
