local Contract = require(script.Parent.Parent.Parent.Utils.Contract)
local SkillKinds = require(script.Parent.SkillKinds)
local SkillTargetKinds = require(script.Parent.SkillTargetKinds)
local SkillTriggerKinds = require(script.Parent.SkillTriggerKinds)
local StatusDefinitions = require(script.Parent.StatusDefinitions)

export type SkillFlags = {
	isBasicAttack: boolean,
	isSpecialSkill: boolean,
	isPassive: boolean,
	isTriggerBased: boolean,
	canCrit: boolean,
	canMiss: boolean,
	ignoresSilence: boolean,
	hitsAllTargets: boolean,
}

export type SkillDefinition = {
	skillId: string,
	displayName: string,
	kind: string,
	targetKind: string,
	triggerKind: string,
	selectionPriority: number?,
	iconAssetId: string | number?,
	cooldownSeconds: number?,
	damageMultiplier: number,
	healMultiplier: number,
	statusApplyChance: number,
	appliedStatusIds: { string },
	flags: SkillFlags,
}

local SkillDefinition = {}

local function normalizeFlags(flags)
	Contract.assertTable(flags, "SkillDefinition.flags")

	local normalizedFlags = table.clone(flags)
	if normalizedFlags.hitsAllTargets == nil then
		normalizedFlags.hitsAllTargets = false
	end

	return normalizedFlags
end

local function assertFlags(value, fieldName)
	Contract.assertTable(value, fieldName)
	Contract.assertBoolean(value.isBasicAttack, string.format("%s.isBasicAttack", fieldName))
	Contract.assertBoolean(value.isSpecialSkill, string.format("%s.isSpecialSkill", fieldName))
	Contract.assertBoolean(value.isPassive, string.format("%s.isPassive", fieldName))
	Contract.assertBoolean(value.isTriggerBased, string.format("%s.isTriggerBased", fieldName))
	Contract.assertBoolean(value.canCrit, string.format("%s.canCrit", fieldName))
	Contract.assertBoolean(value.canMiss, string.format("%s.canMiss", fieldName))
	Contract.assertBoolean(value.ignoresSilence, string.format("%s.ignoresSilence", fieldName))
	Contract.assertBoolean(value.hitsAllTargets, string.format("%s.hitsAllTargets", fieldName))
end

local function assertStatusIds(value, fieldName)
	Contract.assertStringArray(value, fieldName)

	for index, statusId in ipairs(value) do
		assert(
			StatusDefinitions.has(statusId),
			string.format("%s[%d] references unknown status %s", fieldName, index, statusId)
		)
	end
end

function SkillDefinition.assert(value, fieldName)
	fieldName = fieldName or "SkillDefinition"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.skillId, string.format("%s.skillId", fieldName))
	Contract.assertString(value.displayName, string.format("%s.displayName", fieldName))
	Contract.assertEnumValue(value.kind, SkillKinds, string.format("%s.kind", fieldName))
	Contract.assertEnumValue(
		value.targetKind,
		SkillTargetKinds,
		string.format("%s.targetKind", fieldName)
	)
	Contract.assertEnumValue(
		value.triggerKind,
		SkillTriggerKinds,
		string.format("%s.triggerKind", fieldName)
	)
	Contract.assertOptionalNonNegativeNumber(
		value.selectionPriority,
		string.format("%s.selectionPriority", fieldName)
	)
	Contract.assertOptionalAssetId(value.iconAssetId, string.format("%s.iconAssetId", fieldName))
	Contract.assertOptionalNonNegativeNumber(
		value.cooldownSeconds,
		string.format("%s.cooldownSeconds", fieldName)
	)
	Contract.assertNonNegativeNumber(
		value.damageMultiplier,
		string.format("%s.damageMultiplier", fieldName)
	)
	Contract.assertNonNegativeNumber(
		value.healMultiplier,
		string.format("%s.healMultiplier", fieldName)
	)
	Contract.assertNonNegativeNumber(
		value.statusApplyChance,
		string.format("%s.statusApplyChance", fieldName)
	)
	assert(
		value.statusApplyChance <= 1,
		string.format("%s.statusApplyChance must be <= 1", fieldName)
	)
	assertStatusIds(value.appliedStatusIds, string.format("%s.appliedStatusIds", fieldName))
	assertFlags(normalizeFlags(value.flags), string.format("%s.flags", fieldName))

	if value.kind == "BasicAttack" then
		assert(
			value.flags.isBasicAttack,
			string.format("%s must be marked as a basic attack", fieldName)
		)
		assert(
			value.triggerKind == "Manual",
			string.format("%s basic attacks must use the Manual trigger", fieldName)
		)
		assert(
			not value.flags.isSpecialSkill,
			string.format("%s basic attacks cannot be special skills", fieldName)
		)
		assert(
			#value.appliedStatusIds == 0,
			string.format("%s basic attacks should not define built-in statuses", fieldName)
		)
	end

	if value.kind == "Active" then
		assert(
			value.flags.isSpecialSkill,
			string.format("%s active skills must be marked as special skills", fieldName)
		)
		assert(
			value.triggerKind == "Manual",
			string.format("%s active skills must use the Manual trigger", fieldName)
		)
	end

	if value.kind == "Passive" then
		assert(
			value.flags.isPassive,
			string.format("%s passive skills must set flags.isPassive", fieldName)
		)
		assert(
			value.flags.isSpecialSkill,
			string.format(
				"%s passive fighter skills should still count as special skills",
				fieldName
			)
		)
		assert(
			value.triggerKind == "Passive",
			string.format("%s passive skills must use the Passive trigger", fieldName)
		)
		assert(
			value.targetKind == "None" or value.targetKind == "Self",
			string.format("%s passive skills must target None or Self", fieldName)
		)
	end

	if value.kind == "Trigger" then
		assert(
			value.flags.isTriggerBased,
			string.format("%s trigger skills must set flags.isTriggerBased", fieldName)
		)
		assert(
			value.flags.isSpecialSkill,
			string.format("%s trigger fighter skills should count as special skills", fieldName)
		)
		assert(
			value.triggerKind ~= "Manual" and value.triggerKind ~= "Passive",
			string.format("%s trigger skills must use a reactive or interval trigger", fieldName)
		)
	end

	if value.flags.isBasicAttack then
		assert(
			value.kind == "BasicAttack",
			string.format("%s flags.isBasicAttack requires kind BasicAttack", fieldName)
		)
	end

	if value.flags.isPassive then
		assert(
			value.kind == "Passive",
			string.format("%s flags.isPassive requires kind Passive", fieldName)
		)
	end

	if value.flags.isTriggerBased then
		assert(
			value.kind == "Trigger",
			string.format("%s flags.isTriggerBased requires kind Trigger", fieldName)
		)
	end

	return value
end

function SkillDefinition.new(data)
	local normalizedData = table.clone(data)
	normalizedData.flags = normalizeFlags(data.flags)
	SkillDefinition.assert(normalizedData)

	return table.freeze(normalizedData)
end

return SkillDefinition
