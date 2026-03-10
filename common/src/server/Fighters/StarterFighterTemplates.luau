return table.freeze({
	CurrentSeedVersion = 1,
	RosterCapacity = 20,
	Entries = table.freeze({
		table.freeze({
			classId = "Guardian",
			grade = "Rare",
			level = 3,
			specialSkillId = "Skill.Fighter.GuardianShieldBash",
			activeSkillIds = table.freeze({ "Skill.Fighter.GuardianShieldBash" }),
			sourceTag = "StarterSeed",
		}),
		table.freeze({
			classId = "Rogue",
			grade = "Legendary",
			level = 3,
			specialSkillId = "Skill.Fighter.RoguePoisonEdge",
			activeSkillIds = table.freeze({ "Skill.Fighter.RoguePoisonEdge" }),
			sourceTag = "StarterSeed",
		}),
		table.freeze({
			classId = "Mage",
			grade = "Epic",
			level = 3,
			specialSkillId = "Skill.Fighter.MageArcaneBurst",
			activeSkillIds = table.freeze({ "Skill.Fighter.MageArcaneBurst" }),
			sourceTag = "StarterSeed",
		}),
		table.freeze({
			classId = "Guardian",
			grade = "Uncommon",
			level = 1,
			specialSkillId = "Skill.Fighter.GuardianShieldBash",
			activeSkillIds = table.freeze({ "Skill.Fighter.GuardianShieldBash" }),
			sourceTag = "StarterSeedBench",
		}),
	}),
})
