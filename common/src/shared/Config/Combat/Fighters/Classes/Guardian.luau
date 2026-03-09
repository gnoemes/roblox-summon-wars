local ClassDefinition = require(script.Parent.Parent:WaitForChild("ClassDefinition"))
local SkillDefinition = require(script.Parent.Parent.Parent:WaitForChild("SkillDefinition"))

return table.freeze({
	class = ClassDefinition.new({
		classId = "Guardian",
		displayName = "Guardian",
		aggroWeight = 5,
		baseStats = {
			hp = 205,
			damage = 20,
			defense = 8,
			accuracy = 0.8,
			evasion = 0.05,
			critChance = 0.05,
			critDamage = 1.5,
			statusResist = 0.15,
		},
		levelGrowth = {
			hp = 4,
			damage = 0.45,
			defense = 0.18,
			accuracy = 0.004,
			evasion = 0.002,
			critChance = 0.002,
			critDamage = 0.005,
			statusResist = 0.004,
		},
		baseAttackIntervalSeconds = 1.25,
		attackIntervalDeltaPerLevel = -0.01,
		minimumAttackIntervalSeconds = 0.85,
	}),
	skillPool = table.freeze({
		SkillDefinition.new({
			skillId = "Skill.Fighter.GuardianShieldBash",
			displayName = "Shield Bash",
			kind = "Active",
			targetKind = "Enemy",
			triggerKind = "Manual",
			cooldownSeconds = 4,
			damageMultiplier = 1.15,
			healMultiplier = 0,
			statusApplyChance = 0.35,
			appliedStatusIds = { "Status.Stun" },
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
