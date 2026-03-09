local Contract = require(script.Parent.Parent.Parent.Utils.Contract)
local StatusKinds = require(script.Parent.StatusKinds)

export type StatusFlags = {
	isControl: boolean,
	isDamageOverTime: boolean,
	blocksActions: boolean,
	blocksSkills: boolean,
	isEncounterScoped: boolean,
}

export type StatusDefinition = {
	statusId: string,
	displayName: string,
	kind: string,
	iconAssetId: string | number?,
	baseDurationSeconds: number,
	tickIntervalSeconds: number?,
	maxStacks: number,
	flags: StatusFlags,
}

local StatusDefinition = {}

local function assertFlags(value, fieldName)
	Contract.assertTable(value, fieldName)
	Contract.assertBoolean(value.isControl, string.format("%s.isControl", fieldName))
	Contract.assertBoolean(value.isDamageOverTime, string.format("%s.isDamageOverTime", fieldName))
	Contract.assertBoolean(value.blocksActions, string.format("%s.blocksActions", fieldName))
	Contract.assertBoolean(value.blocksSkills, string.format("%s.blocksSkills", fieldName))
	Contract.assertBoolean(
		value.isEncounterScoped,
		string.format("%s.isEncounterScoped", fieldName)
	)
end

function StatusDefinition.assert(value, fieldName)
	fieldName = fieldName or "StatusDefinition"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.statusId, string.format("%s.statusId", fieldName))
	Contract.assertString(value.displayName, string.format("%s.displayName", fieldName))
	Contract.assertEnumValue(value.kind, StatusKinds, string.format("%s.kind", fieldName))
	Contract.assertOptionalAssetId(value.iconAssetId, string.format("%s.iconAssetId", fieldName))
	Contract.assertPositiveNumber(
		value.baseDurationSeconds,
		string.format("%s.baseDurationSeconds", fieldName)
	)
	Contract.assertOptionalPositiveNumber(
		value.tickIntervalSeconds,
		string.format("%s.tickIntervalSeconds", fieldName)
	)
	Contract.assertPositiveInteger(value.maxStacks, string.format("%s.maxStacks", fieldName))
	assertFlags(value.flags, string.format("%s.flags", fieldName))

	if value.flags.isDamageOverTime then
		assert(
			value.kind == "DamageOverTime",
			string.format("%s.kind must be DamageOverTime when the status ticks", fieldName)
		)
		assert(
			value.tickIntervalSeconds ~= nil,
			string.format(
				"%s.tickIntervalSeconds is required for DamageOverTime statuses",
				fieldName
			)
		)
	else
		assert(
			value.tickIntervalSeconds == nil,
			string.format(
				"%s.tickIntervalSeconds is only allowed for DamageOverTime statuses",
				fieldName
			)
		)
	end

	if value.flags.isControl then
		assert(
			value.kind == "Control",
			string.format("%s.kind must be Control when flags.isControl is true", fieldName)
		)
		assert(
			value.flags.blocksActions or value.flags.blocksSkills,
			string.format("%s control statuses must block actions or skills", fieldName)
		)
	end

	if value.flags.blocksActions or value.flags.blocksSkills then
		assert(
			value.flags.isControl,
			string.format("%s blocking flags require flags.isControl", fieldName)
		)
	end

	return value
end

function StatusDefinition.new(data)
	StatusDefinition.assert(data)

	return table.freeze(data)
end

return StatusDefinition
