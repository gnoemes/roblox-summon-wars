local EnemyDefinition = require(script.Parent.Parent.Parent.Parent:WaitForChild("EnemyDefinition"))

return EnemyDefinition.new({
	enemyId = "Enemy.VenomBrute",
	displayName = "Venom Brute",
	tier = "Elite",
	computedStats = {
		hp = 7800,
		damage = 45,
		defense = 5,
		accuracy = 0.8,
		evasion = 0.08,
		critChance = 0.08,
		critDamage = 1.5,
		statusResist = 0.12,
		attackIntervalSeconds = 1.05,
	},
	basicAttackSkillId = "Core.BasicAttack",
	specialSkillIds = {
		"Skill.Enemy.HeavySwipe",
		"Skill.Enemy.VenomBite",
	},
	passiveSkillIds = {},
	dropTableId = "Drop.None",
	threatTag = "Poison",
	dotResponsesByStatusId = {
		["Status.Poison"] = "Immune",
	},
	flags = {
		isRare = false,
		isChestReplacement = false,
		usesPhases = false,
	},
})
