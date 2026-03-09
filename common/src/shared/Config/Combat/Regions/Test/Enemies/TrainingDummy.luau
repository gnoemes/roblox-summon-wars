local EnemyDefinition = require(script.Parent.Parent.Parent.Parent:WaitForChild("EnemyDefinition"))

return EnemyDefinition.new({
	enemyId = "Enemy.TrainingDummy",
	displayName = "Training Dummy",
	tier = "Normal",
	computedStats = {
		hp = 420,
		damage = 18,
		defense = 3,
		accuracy = 0.75,
		evasion = 0.05,
		critChance = 0.05,
		critDamage = 1.5,
		statusResist = 0.05,
		attackIntervalSeconds = 1.2,
	},
	basicAttackSkillId = "Core.BasicAttack",
	specialSkillIds = { "Skill.Enemy.HeavySwipe" },
	passiveSkillIds = {},
	dropTableId = "Drop.None",
	threatTag = "Bruiser",
	flags = {
		isRare = false,
		isChestReplacement = false,
		usesPhases = false,
	},
})
