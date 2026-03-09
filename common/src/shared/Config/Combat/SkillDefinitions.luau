local Registry = require(script.Parent.Parent.Registry)
local SkillDefinition = require(script.Parent.SkillDefinition)

local definitions = {
	["Core.BasicAttack"] = SkillDefinition.new({
		skillId = "Core.BasicAttack",
		displayName = "Basic Attack",
		kind = "BasicAttack",
		targetKind = "Enemy",
		triggerKind = "Manual",
		cooldownSeconds = 0,
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
}

return Registry.create("SkillDefinitions", definitions, "skillId", SkillDefinition.assert)
