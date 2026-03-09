local SkillDefinition = require(script.Parent.Parent.Parent:WaitForChild("SkillDefinition"))

return table.freeze({
	SkillDefinition.new({
		skillId = "Core.BasicAttack",
		displayName = "Basic Attack",
		kind = "BasicAttack",
		targetKind = "Enemy",
		triggerKind = "Manual",
		cooldownSeconds = 0,
		damageMultiplier = 1,
		healMultiplier = 0,
		statusApplyChance = 0,
		appliedStatusIds = {},
		flags = {
			isBasicAttack = true,
			isSpecialSkill = false,
			isPassive = false,
			isTriggerBased = false,
			canCrit = true,
			canMiss = true,
			ignoresSilence = false,
		},
	}),
})
