local ClassDefinition = require(script.Parent.Parent:WaitForChild("ClassDefinition"))
local SkillDefinition = require(script.Parent.Parent.Parent:WaitForChild("SkillDefinition"))

return table.freeze({
	class = ClassDefinition.new({
		classId = "Mage",
		displayName = "Mage",
		aggroWeight = 1,
		baseStats = {
			hp = 145,
			damage = 29,
			defense = 3,
			accuracy = 0.86,
			evasion = 0.07,
			critChance = 0.1,
			critDamage = 1.75,
			statusResist = 0.1,
		},
		levelGrowth = {
			hp = 2,
			damage = 0.7,
			defense = 0.05,
			accuracy = 0.006,
			evasion = 0.002,
			critChance = 0.003,
			critDamage = 0.01,
			statusResist = 0.003,
		},
		baseAttackIntervalSeconds = 1.05,
		attackIntervalDeltaPerLevel = -0.006,
		minimumAttackIntervalSeconds = 0.75,
	}),
	skillPool = table.freeze({
		SkillDefinition.new({
			skillId = "Skill.Fighter.MageArcaneBurst",
			displayName = "Arcane Burst",
			kind = "Active",
			targetKind = "Enemy",
			triggerKind = "Manual",
			cooldownSeconds = 5,
			damageMultiplier = 1.4,
			healMultiplier = 0,
			statusApplyChance = 0,
			appliedStatusIds = {},
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
