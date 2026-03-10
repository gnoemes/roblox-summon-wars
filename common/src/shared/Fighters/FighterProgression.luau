local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ProgressionConfig = SharedConfig.Fighters.Progression

local FighterProgression = {}

function FighterProgression.getLevelCap()
	return ProgressionConfig.LevelCap
end

function FighterProgression.isMaxLevel(level)
	return level >= FighterProgression.getLevelCap()
end

function FighterProgression.getExperienceToNextLevel(level)
	if FighterProgression.isMaxLevel(level) then
		return 0
	end

	return ProgressionConfig.ExperienceToNextLevel[level] or 0
end

function FighterProgression.getProgressState(level, experience)
	local isMaxLevel = FighterProgression.isMaxLevel(level)
	local experienceToNextLevel = FighterProgression.getExperienceToNextLevel(level)
	local progressRatio = if isMaxLevel or experienceToNextLevel <= 0
		then 1
		else math.clamp(experience / experienceToNextLevel, 0, 1)

	return {
		level = level,
		experience = experience,
		experienceToNextLevel = experienceToNextLevel,
		progressRatio = progressRatio,
		isMaxLevel = isMaxLevel,
	}
end

function FighterProgression.applyExperience(
	level,
	experience,
	gainedExperience,
	ascensionExperience
)
	assert(
		type(level) == "number" and level >= 1 and level % 1 == 0,
		"level must be a positive integer"
	)
	assert(
		type(experience) == "number" and experience >= 0,
		"experience must be a non-negative number"
	)
	assert(
		type(gainedExperience) == "number" and gainedExperience >= 0,
		"gainedExperience must be a non-negative number"
	)
	assert(
		type(ascensionExperience) == "number" and ascensionExperience >= 0,
		"ascensionExperience must be a non-negative number"
	)

	local nextLevel = level
	local nextExperience = experience
	local nextAscensionExperience = ascensionExperience
	local pendingExperience = gainedExperience
	local levelUps = 0
	local overflowExperience = 0

	while pendingExperience > 0 and not FighterProgression.isMaxLevel(nextLevel) do
		local requiredExperience = FighterProgression.getExperienceToNextLevel(nextLevel)
		local remainingExperience = requiredExperience - nextExperience
		if pendingExperience >= remainingExperience then
			pendingExperience -= remainingExperience
			nextLevel += 1
			nextExperience = 0
			levelUps += 1
		else
			nextExperience += pendingExperience
			pendingExperience = 0
		end
	end

	if pendingExperience > 0 and FighterProgression.isMaxLevel(nextLevel) then
		overflowExperience = pendingExperience
		pendingExperience = 0
		local overflowRatio = ProgressionConfig.EncounterExperience.MaxLevelAscensionOverflowRatio
			or 0
		nextAscensionExperience += math.floor(overflowExperience * overflowRatio + 0.5)
	end

	return {
		level = nextLevel,
		experience = nextExperience,
		ascensionExperience = nextAscensionExperience,
		levelUps = levelUps,
		overflowExperience = overflowExperience,
		leveledUp = levelUps > 0,
		isMaxLevel = FighterProgression.isMaxLevel(nextLevel),
	}
end

return FighterProgression
