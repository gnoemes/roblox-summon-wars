local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Contract =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Contract"))
local BaseCombatStats = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Stats"):WaitForChild("BaseCombatStats")
)
local ClassIds = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Fighters"):WaitForChild("ClassIds")
)
local GradeIds = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Progression")
		:WaitForChild("Grades")
		:WaitForChild("GradeIds")
)
local FighterLoadoutRules = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Fighters")
		:WaitForChild("FighterLoadoutRules")
)

export type FighterDocument = {
	fighterId: string,
	classId: string,
	grade: string,
	level: number,
	experience: number,
	ascensionExperience: number,
	baseStats: BaseCombatStats.BaseCombatStats,
	specialSkillId: string,
	activeSkillIds: { string },
	traitId: string?,
	subclassId: string?,
	sourceTag: string?,
	createdAt: number,
}

local FighterDocument = {}

function FighterDocument.reconcile(rawDocument, fighterId)
	local document = {
		fighterId = fighterId,
		classId = rawDocument.classId,
		grade = rawDocument.grade,
		level = if type(rawDocument.level) == "number" and rawDocument.level >= 1
			then math.floor(rawDocument.level)
			else 1,
		experience = if type(rawDocument.experience) == "number"
				and rawDocument.experience >= 0
			then rawDocument.experience
			else 0,
		ascensionExperience = if type(rawDocument.ascensionExperience) == "number"
				and rawDocument.ascensionExperience >= 0
			then rawDocument.ascensionExperience
			else 0,
		baseStats = rawDocument.baseStats,
		specialSkillId = rawDocument.specialSkillId,
		activeSkillIds = table.clone(rawDocument.activeSkillIds or {}),
		traitId = rawDocument.traitId,
		subclassId = rawDocument.subclassId,
		sourceTag = rawDocument.sourceTag,
		createdAt = if type(rawDocument.createdAt) == "number"
				and rawDocument.createdAt >= 0
			then rawDocument.createdAt
			else 0,
	}

	return FighterDocument.new(document)
end

function FighterDocument.assert(value, fieldName)
	fieldName = fieldName or "FighterDocument"

	Contract.assertTable(value, fieldName)
	Contract.assertString(value.fighterId, string.format("%s.fighterId", fieldName))
	Contract.assertEnumValue(value.classId, ClassIds, string.format("%s.classId", fieldName))
	Contract.assertEnumValue(value.grade, GradeIds, string.format("%s.grade", fieldName))
	Contract.assertPositiveInteger(value.level, string.format("%s.level", fieldName))
	Contract.assertNonNegativeNumber(value.experience, string.format("%s.experience", fieldName))
	Contract.assertNonNegativeNumber(
		value.ascensionExperience,
		string.format("%s.ascensionExperience", fieldName)
	)
	BaseCombatStats.assert(value.baseStats, string.format("%s.baseStats", fieldName))
	Contract.assertString(value.specialSkillId, string.format("%s.specialSkillId", fieldName))
	Contract.assertStringArray(value.activeSkillIds, string.format("%s.activeSkillIds", fieldName))
	FighterLoadoutRules.assertActiveOnlySpecialLoadout(
		value.classId,
		value.specialSkillId,
		value.activeSkillIds,
		fieldName
	)
	Contract.assertOptionalString(value.traitId, string.format("%s.traitId", fieldName))
	Contract.assertOptionalString(value.subclassId, string.format("%s.subclassId", fieldName))
	Contract.assertOptionalString(value.sourceTag, string.format("%s.sourceTag", fieldName))
	Contract.assertNonNegativeNumber(value.createdAt, string.format("%s.createdAt", fieldName))

	return value
end

function FighterDocument.new(data)
	FighterDocument.assert(data)

	return table.freeze(data)
end

return FighterDocument
