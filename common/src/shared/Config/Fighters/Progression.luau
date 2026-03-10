local EXPERIENCE_TO_NEXT_LEVEL = table.freeze({
	35,
	50,
	70,
	95,
	125,
	160,
	200,
	245,
	295,
	350,
	410,
	475,
	545,
	620,
	700,
	785,
	875,
	970,
	1070,
})

local ENEMY_SCORE = table.freeze({
	BaseExperience = 8,
	HpWeight = 0.004,
	DamageWeight = 0.55,
	DefenseWeight = 1.25,
	AccuracyWeight = 8,
	EvasionWeight = 10,
	CritChanceWeight = 12,
	CritDamageBonusWeight = 8,
	TempoWeight = 10,
	SpecialSkillWeight = 4,
	PassiveSkillWeight = 3,
	EliteBonus = 6,
	BossBonus = 18,
	RareBonus = 4,
	UsesPhasesBonus = 8,
	ChestReplacementPenalty = -10,
	DotResponseBonuses = table.freeze({
		Immune = 0.75,
		Vulnerable = 0.5,
	}),
})

local ENCOUNTER_SCORE = table.freeze({
	BaseMultiplier = 1,
	ByExtractionType = table.freeze({
		HuntingGrounds = 1,
		Dungeon = 1.15,
		Raid = 1.3,
	}),
	ByOutcome = table.freeze({
		Victory = 1,
		Defeat = 0.7,
	}),
	RecommendedSquadPowerWeight = 0.004,
	MinimumSquadPowerWeight = 0.005,
})

local FIGHTER_PROGRESSION = table.freeze({
	LevelCap = 20,
	ExperienceToNextLevel = EXPERIENCE_TO_NEXT_LEVEL,
	EncounterExperience = table.freeze({
		EnemyScore = ENEMY_SCORE,
		EncounterScore = ENCOUNTER_SCORE,
		MaxLevelAscensionOverflowRatio = 0.1,
	}),
})

return FIGHTER_PROGRESSION
