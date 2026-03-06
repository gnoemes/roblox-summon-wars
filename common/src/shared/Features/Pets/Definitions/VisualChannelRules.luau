local orderedChannels = {
	"Head",
	"Torso",
	"FullBody",
	"Aura",
	"Accessory",
	"Color",
}

local conflictMap = {
	Head = { "FullBody" },
	Torso = { "FullBody" },
	FullBody = { "Head", "Torso" },
	Aura = {},
	Accessory = {},
	Color = {},
}

local channelSet = {}
for _, channelId in ipairs(orderedChannels) do
	channelSet[channelId] = true
end

local VisualChannelRules = {}

function VisualChannelRules.isValidChannel(channelId)
	return channelSet[channelId] == true
end

function VisualChannelRules.getOrderedChannels()
	return table.clone(orderedChannels)
end

function VisualChannelRules.getConflictsForChannel(channelId)
	local conflicts = conflictMap[channelId]
	if not conflicts then
		return {}
	end
	return table.clone(conflicts)
end

function VisualChannelRules.validateLoadout(loadout)
	local errors = {}
	local activeChannels = {}

	if type(loadout) ~= "table" then
		table.insert(errors, "Visual mutation loadout must be a table")
		return {
			ok = false,
			errors = errors,
		}
	end

	for channelId, mutationId in pairs(loadout) do
		if not VisualChannelRules.isValidChannel(channelId) then
			table.insert(errors, ("Unknown visual mutation channel '%s'"):format(tostring(channelId)))
		elseif mutationId ~= nil then
			activeChannels[channelId] = true
		end
	end

	for channelId in pairs(activeChannels) do
		for _, conflictChannelId in ipairs(conflictMap[channelId]) do
			if activeChannels[conflictChannelId] then
				table.insert(errors, ("Visual mutation channels '%s' and '%s' cannot be active together"):format(channelId, conflictChannelId))
			end
		end
	end

	return {
		ok = #errors == 0,
		errors = errors,
	}
end

return VisualChannelRules
