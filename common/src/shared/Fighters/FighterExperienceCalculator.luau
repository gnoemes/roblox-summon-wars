local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ProgressionConfig = SharedConfig.Fighters.Progression.EncounterExperience

local FighterExperienceCalculator = {}

local function getEncounterFlags(context)
	local enemyDefinition = context.enemyDefinition
	local enemyFlags = if enemyDefinition ~= nil then enemyDefinition.flags or {} else {}
	local encounterFlags = context.encounterFlags or {}
	local tier = if enemyDefinition ~= nil then enemyDefinition.tier else nil

	return {
		isElite = if encounterFlags.isElite ~= nil then encounterFlags.isElite else tier == "Elite",
		isBoss = if encounterFlags.isBoss ~= nil then encounterFlags.isBoss else tier == "Boss",
		isRare = if encounterFlags.isRare ~= nil
			then encounterFlags.isRare
			else enemyFlags.isRare == true,
		isChestReplacement = if encounterFlags.isChestReplacement ~= nil
			then encounterFlags.isChestReplacement
			else enemyFlags.isChestReplacement == true,
		usesPhases = if encounterFlags.usesPhases ~= nil
			then encounterFlags.usesPhases
			else enemyFlags.usesPhases == true,
	}
end

local function calculateEnemyPowerScore(enemyDefinition, encounterFlags)
	local scoreConfig = ProgressionConfig.EnemyScore
	local stats = enemyDefinition.computedStats
	local score = scoreConfig.BaseExperience
		+ stats.hp * scoreConfig.HpWeight
		+ stats.damage * scoreConfig.DamageWeight
		+ stats.defense * scoreConfig.DefenseWeight
		+ stats.accuracy * scoreConfig.AccuracyWeight
		+ stats.evasion * scoreConfig.EvasionWeight
		+ stats.critChance * scoreConfig.CritChanceWeight
		+ math.max(stats.critDamage - 1, 0) * scoreConfig.CritDamageBonusWeight
		+ (1 / math.max(stats.attackIntervalSeconds, 0.05)) * scoreConfig.TempoWeight
		+ #enemyDefinition.specialSkillIds * scoreConfig.SpecialSkillWeight
		+ #enemyDefinition.passiveSkillIds * scoreConfig.PassiveSkillWeight

	if encounterFlags.isElite then
		score += scoreConfig.EliteBonus
	end
	if encounterFlags.isBoss then
		score += scoreConfig.BossBonus
	end
	if encounterFlags.isRare then
		score += scoreConfig.RareBonus
	end
	if encounterFlags.usesPhases then
		score += scoreConfig.UsesPhasesBonus
	end
	if encounterFlags.isChestReplacement then
		score += scoreConfig.ChestReplacementPenalty
	end

	for _, responseKind in pairs(enemyDefinition.dotResponsesByStatusId or {}) do
		score += scoreConfig.DotResponseBonuses[responseKind] or 0
	end

	return score
end

function FighterExperienceCalculator.calculateEncounterExperience(context)
	assert(type(context) == "table", "FighterExperienceCalculator context must be a table")
	assert(type(context.enemyDefinition) == "table", "context.enemyDefinition is required")
	assert(type(context.extractionType) == "string", "context.extractionType is required")
	assert(type(context.outcome) == "string", "context.outcome is required")

	local encounterFlags = getEncounterFlags(context)
	local modifiers = context.modifiers or {}
	local encounterConfig = ProgressionConfig.EncounterScore
	local enemyPowerScore = calculateEnemyPowerScore(context.enemyDefinition, encounterFlags)
	local enemyPowerMultiplier = if type(modifiers.enemyPowerMultiplier) == "number"
		then modifiers.enemyPowerMultiplier
		else 1
	local additionalPowerScore = if type(modifiers.additionalPowerScore) == "number"
		then modifiers.additionalPowerScore
		else 0
	local flatExperienceBonus = if type(modifiers.flatExperienceBonus) == "number"
		then modifiers.flatExperienceBonus
		else 0
	local experienceMultiplier = if type(modifiers.experienceMultiplier) == "number"
		then modifiers.experienceMultiplier
		else 1

	local powerScore = enemyPowerScore * enemyPowerMultiplier + additionalPowerScore
	powerScore += (context.recommendedSquadPower or 0) * encounterConfig.RecommendedSquadPowerWeight
	powerScore += (context.minimumSquadPower or 0) * encounterConfig.MinimumSquadPowerWeight

	local totalExperience = (powerScore + flatExperienceBonus)
		* (encounterConfig.ByExtractionType[context.extractionType] or encounterConfig.BaseMultiplier)
		* (encounterConfig.ByOutcome[context.outcome] or encounterConfig.BaseMultiplier)
		* experienceMultiplier

	return math.max(math.floor(totalExperience + 0.5), 0)
end

return FighterExperienceCalculator
