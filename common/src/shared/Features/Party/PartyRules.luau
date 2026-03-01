local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PartyConfig = require(Shared:WaitForChild("Config"):WaitForChild("Party"))

local PartyRules = {}

PartyRules.MAX_PARTY_SIZE = PartyConfig.MaxPartySize

local function normalize(userIds)
	if type(userIds) ~= "table" then
		return {}
	end

	local seen = {}
	local out = {}
	for _, userId in ipairs(userIds) do
		if type(userId) == "number" and not seen[userId] then
			seen[userId] = true
			table.insert(out, userId)
		end
	end

	table.sort(out, function(a, b)
		return a < b
	end)

	while #out > PartyRules.MAX_PARTY_SIZE do
		table.remove(out)
	end

	return out
end

function PartyRules.normalizePartyUserIds(userIds)
	return normalize(userIds)
end

function PartyRules.getLeaderId(userIds)
	local list = normalize(userIds)
	return list[1]
end

function PartyRules.isLeader(userId, userIds)
	return userId == PartyRules.getLeaderId(userIds)
end

return PartyRules
