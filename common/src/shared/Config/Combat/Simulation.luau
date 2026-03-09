local Simulation = {
	DefaultBasicSkillId = "Core.BasicAttack",
	Encounter = table.freeze({
		MaxActionCatchUpPerFrame = 3,
		JournalLimit = 120,
		ActionOrderBiasByKind = table.freeze({
			Fighter = 1,
			Enemy = 2,
		}),
	}),
	HitModel = table.freeze({
		BaseHitChance = 0.75,
		MinHitChance = 0.1,
		MaxHitChance = 0.95,
		EvasionCap = 0.5,
	}),
	Targeting = table.freeze({
		FallbackAggroWeight = 1,
	}),
	Statuses = table.freeze({
		["Status.Poison"] = table.freeze({
			tickDamageRatio = 0.08,
			bypassDefense = true,
		}),
		["Status.Bleed"] = table.freeze({
			tickDamageRatio = 0.1,
			bypassDefense = true,
		}),
	}),
}

return table.freeze(Simulation)
