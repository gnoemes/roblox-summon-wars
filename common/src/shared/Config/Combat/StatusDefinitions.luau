local Registry = require(script.Parent.Parent.Registry)
local StatusDefinition = require(script.Parent.StatusDefinition)

local definitions = {
	["Status.Bleed"] = StatusDefinition.new({
		statusId = "Status.Bleed",
		displayName = "Bleed",
		kind = "DamageOverTime",
		tickIntervalSeconds = 1,
		maxStacks = 10,
		flags = {
			isControl = false,
			isDamageOverTime = true,
			blocksActions = false,
			blocksSkills = false,
			isEncounterScoped = true,
		},
	}),
	["Status.Poison"] = StatusDefinition.new({
		statusId = "Status.Poison",
		displayName = "Poison",
		kind = "DamageOverTime",
		tickIntervalSeconds = 2,
		maxStacks = 10,
		flags = {
			isControl = false,
			isDamageOverTime = true,
			blocksActions = false,
			blocksSkills = false,
			isEncounterScoped = true,
		},
	}),
	["Status.Silence"] = StatusDefinition.new({
		statusId = "Status.Silence",
		displayName = "Silence",
		kind = "Control",
		maxStacks = 1,
		flags = {
			isControl = true,
			isDamageOverTime = false,
			blocksActions = false,
			blocksSkills = true,
			isEncounterScoped = true,
		},
	}),
	["Status.Stun"] = StatusDefinition.new({
		statusId = "Status.Stun",
		displayName = "Stun",
		kind = "Control",
		maxStacks = 1,
		flags = {
			isControl = true,
			isDamageOverTime = false,
			blocksActions = true,
			blocksSkills = true,
			isEncounterScoped = true,
		},
	}),
}

return Registry.create("StatusDefinitions", definitions, "statusId", StatusDefinition.assert)
