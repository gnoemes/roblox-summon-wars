local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExtractionTypeIds = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Extractions")
		:WaitForChild("ExtractionTypeIds")
)

local SyntheticScenarioPresets = {
	DefaultEnemyIdByExtractionType = table.freeze({
		[ExtractionTypeIds.Values[1]] = "Enemy.TrainingDummy",
		[ExtractionTypeIds.Values[2]] = "Enemy.VenomBrute",
		[ExtractionTypeIds.Values[3]] = "Enemy.ArenaTyrant",
	}),
	DefaultFighterTrio = table.freeze({
		table.freeze({
			fighterId = "Synthetic.Guardian.01",
			classId = "Guardian",
			grade = "Rare",
			level = 10,
			activeSkillIds = table.freeze({ "Skill.Fighter.GuardianShieldBash" }),
			traitId = nil,
		}),
		table.freeze({
			fighterId = "Synthetic.Rogue.01",
			classId = "Rogue",
			grade = "Legendary",
			level = 10,
			activeSkillIds = table.freeze({ "Skill.Fighter.RoguePoisonEdge" }),
			traitId = nil,
		}),
		table.freeze({
			fighterId = "Synthetic.Mage.01",
			classId = "Mage",
			grade = "Epic",
			level = 10,
			activeSkillIds = table.freeze({ "Skill.Fighter.MageArcaneBurst" }),
			traitId = nil,
		}),
	}),
}

return table.freeze(SyntheticScenarioPresets)
