local definitions = {
	retaliatory_pulse = {
		id = "retaliatory_pulse",
		displayName = "Ответный импульс",
		executionMode = "reactive",
		tacticalEligible = false,
		trigger = "damage_taken",
		internalCooldown = 0.75,
		targeting = "nearest_enemy",
		params = {
			reflectRatioBase = 0.30,
			reflectRatioPerLevel = 0.05,
		},
	},
	shockwave = {
		id = "shockwave",
		displayName = "Ударная волна",
		executionMode = "auto_cooldown",
		tacticalEligible = true,
		cooldown = 4,
		targeting = "self_aoe",
		params = {
			radius = 8,
			damage = 28,
			microStunDuration = 0.5,
		},
	},
	rage = {
		id = "rage",
		displayName = "Ярость",
		executionMode = "auto_cooldown",
		tacticalEligible = true,
		cooldown = 8,
		targeting = "self_buff",
		params = {
			duration = 3,
			attackSpeedBonus = 0.45,
			damageBonus = 0.12,
		},
	},
}

return {
	OrderedIds = {
		"retaliatory_pulse",
		"shockwave",
		"rage",
	},
	ById = definitions,
}
