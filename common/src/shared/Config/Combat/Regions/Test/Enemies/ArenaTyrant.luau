local EnemyDefinition = require(script.Parent.Parent.Parent.Parent:WaitForChild("EnemyDefinition"))

return EnemyDefinition.new({
	enemyId = "Enemy.ArenaTyrant",
	displayName = "Arena Tyrant",
	tier = "Boss",
	computedStats = {
		hp = 1300,
		damage = 24,
		defense = 7,
		accuracy = 0.85,
		evasion = 0.1,
		critChance = 0.1,
		critDamage = 1.5,
		statusResist = 0.18,
		attackIntervalSeconds = 0.95,
	},
	basicAttackSkillId = "Core.BasicAttack",
	specialSkillIds = {
		"Skill.Enemy.CrushingSlam",
		"Skill.Enemy.ExecutionRush",
	},
	passiveSkillIds = { "Skill.Enemy.BattleFocus" },
	dropTableId = "Drop.None",
	threatTag = "Boss",
	flags = {
		isRare = false,
		isChestReplacement = false,
		usesPhases = false,
	},
})
