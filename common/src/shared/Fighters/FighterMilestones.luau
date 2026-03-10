local FighterMilestones = {}

local SPECIAL_SKILL_VISIBLE_LEVEL = 1
local SPECIAL_SKILL_UNLOCK_LEVEL = 3
local CLASS_SPIKE_LEVEL = 10
local SPECIAL_SKILL_MODIFIER_LEVEL = 15
local SUBCLASS_CAPSTONE_LEVEL = 20

local function cloneArray(values)
	return table.clone(values or {})
end

function FighterMilestones.getSpecialSkillVisibleLevel()
	return SPECIAL_SKILL_VISIBLE_LEVEL
end

function FighterMilestones.getSpecialSkillUnlockLevel()
	return SPECIAL_SKILL_UNLOCK_LEVEL
end

function FighterMilestones.getState(level)
	assert(
		type(level) == "number" and level >= 1 and level % 1 == 0,
		"level must be a positive integer"
	)

	return {
		specialSkillVisible = level >= SPECIAL_SKILL_VISIBLE_LEVEL,
		specialSkillUnlockedForCombat = level >= SPECIAL_SKILL_UNLOCK_LEVEL,
		classSpikeUnlocked = level >= CLASS_SPIKE_LEVEL,
		specialSkillModifierUnlocked = level >= SPECIAL_SKILL_MODIFIER_LEVEL,
		subclassCapstoneUnlocked = level >= SUBCLASS_CAPSTONE_LEVEL,
	}
end

function FighterMilestones.filterCombatActiveSkillIds(level, activeSkillIds)
	if level < SPECIAL_SKILL_UNLOCK_LEVEL then
		return {}
	end

	return cloneArray(activeSkillIds)
end

return FighterMilestones
