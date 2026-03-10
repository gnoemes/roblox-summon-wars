local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))
local FighterDocument = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("FighterDocument")
)
local FighterCombatSnapshot = require(script.Parent:WaitForChild("FighterCombatSnapshot"))
local FighterMilestones = require(script.Parent:WaitForChild("FighterMilestones"))
local FighterProgression = require(script.Parent:WaitForChild("FighterProgression"))

local ClassDefinitions = CombatConfig.Fighters.ClassDefinitions
local CombatStatsBuilder = CombatConfig.Fighters.CombatStatsBuilder
local SkillDefinitions = CombatConfig.SkillDefinitions

local FighterProjector = {}

local function cloneArray(values)
	return table.clone(values or {})
end

function FighterProjector.buildComputedStats(fighterDocument)
	FighterDocument.assert(fighterDocument)

	return CombatStatsBuilder.buildComputedStats(
		fighterDocument.classId,
		fighterDocument.grade,
		fighterDocument.level,
		{
			baseOverrides = fighterDocument.baseStats,
		}
	)
end

function FighterProjector.getUsableActiveSkillIds(fighterDocument)
	FighterDocument.assert(fighterDocument)

	return FighterMilestones.filterCombatActiveSkillIds(
		fighterDocument.level,
		fighterDocument.activeSkillIds
	)
end

function FighterProjector.buildCombatSnapshot(fighterDocument)
	FighterDocument.assert(fighterDocument)

	local activeSkillIds = FighterProjector.getUsableActiveSkillIds(fighterDocument)

	return FighterCombatSnapshot.new({
		combatantId = fighterDocument.fighterId,
		fighterId = fighterDocument.fighterId,
		classId = fighterDocument.classId,
		grade = fighterDocument.grade,
		level = fighterDocument.level,
		baseStats = fighterDocument.baseStats,
		computedStats = FighterProjector.buildComputedStats(fighterDocument),
		activeSkillIds = table.freeze(activeSkillIds),
		traitId = fighterDocument.traitId,
	})
end

function FighterProjector.buildReadModel(fighterDocument)
	FighterDocument.assert(fighterDocument)

	local classDefinition = ClassDefinitions.get(fighterDocument.classId)
	local milestones = FighterMilestones.getState(fighterDocument.level)
	local progression =
		FighterProgression.getProgressState(fighterDocument.level, fighterDocument.experience)
	local computedStats = FighterProjector.buildComputedStats(fighterDocument)
	local specialSkillDefinition = SkillDefinitions.get(fighterDocument.specialSkillId)
	local usableActiveSkillIds = FighterProjector.getUsableActiveSkillIds(fighterDocument)

	return table.freeze({
		fighterId = fighterDocument.fighterId,
		displayName = classDefinition.displayName,
		classId = fighterDocument.classId,
		grade = fighterDocument.grade,
		level = fighterDocument.level,
		experience = fighterDocument.experience,
		ascensionExperience = fighterDocument.ascensionExperience,
		progression = progression,
		traitId = fighterDocument.traitId,
		subclassId = fighterDocument.subclassId,
		sourceTag = fighterDocument.sourceTag,
		specialSkill = {
			skillId = fighterDocument.specialSkillId,
			displayName = specialSkillDefinition.displayName,
			iconAssetId = specialSkillDefinition.iconAssetId,
			isVisible = milestones.specialSkillVisible,
			isUnlockedForCombat = milestones.specialSkillUnlockedForCombat,
		},
		equippedActiveSkillIds = table.freeze(cloneArray(fighterDocument.activeSkillIds)),
		usableActiveSkillIds = table.freeze(usableActiveSkillIds),
		milestones = milestones,
		stats = {
			hp = computedStats.hp,
			damage = computedStats.damage,
			defense = computedStats.defense,
			attackIntervalSeconds = computedStats.attackIntervalSeconds,
			critChance = computedStats.critChance,
			critDamage = computedStats.critDamage,
		},
		computedStats = computedStats,
	})
end

return FighterProjector
