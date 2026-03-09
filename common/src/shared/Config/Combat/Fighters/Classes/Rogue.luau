local ClassDefinition = require(script.Parent.Parent:WaitForChild("ClassDefinition"))
local SkillDefinition = require(script.Parent.Parent.Parent:WaitForChild("SkillDefinition"))

return table.freeze({
	class = ClassDefinition.new({
		classId = "Rogue",
		displayName = "Rogue",
		aggroWeight = 2,
		baseStats = {
			hp = 150,
			damage = 25,
			defense = 4,
			accuracy = 0.84,
			evasion = 0.14,
			critChance = 0.16,
			critDamage = 1.65,
			statusResist = 0.08,
		},
		levelGrowth = {
			hp = 2.2,
			damage = 0.55,
			defense = 0.08,
			accuracy = 0.005,
			evasion = 0.004,
			critChance = 0.004,
			critDamage = 0.008,
			statusResist = 0.002,
		},
		baseAttackIntervalSeconds = 0.9,
		attackIntervalDeltaPerLevel = -0.008,
		minimumAttackIntervalSeconds = 0.6,
	}),
	skillPool = table.freeze({
		SkillDefinition.new({
			skillId = "Skill.Fighter.RoguePoisonEdge",
			displayName = "Poison Edge",
			kind = "Active",
			targetKind = "Enemy",
			triggerKind = "Manual",
			cooldownSeconds = 3,
			damageMultiplier = 1.05,
			healMultiplier = 0,
			statusApplyChance = 0.7,
			appliedStatusIds = { "Status.Poison" },
			flags = {
				isBasicAttack = false,
				isSpecialSkill = true,
				isPassive = false,
				isTriggerBased = false,
				canCrit = true,
				canMiss = true,
				ignoresSilence = false,
			},
		}),
	}),
})
