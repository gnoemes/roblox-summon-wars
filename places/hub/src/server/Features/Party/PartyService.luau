local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PartyRules = require(Shared:WaitForChild("Features"):WaitForChild("Party"):WaitForChild("PartyRules"))

local PartyService = {}

local function getPartyId(player)
	local value = player:GetAttribute("PartyId")
	if type(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

function PartyService.getPartyLeader(leader)
	local members = PartyService.getPartyMembers(leader)
	if #members == 0 then
		return leader
	end

	local userIds = PartyService.getPartyUserIds(leader)
	local leaderUserId = PartyRules.getLeaderId(userIds)
	if not leaderUserId then
		return leader
	end

	for _, player in ipairs(members) do
		if player.UserId == leaderUserId then
			return player
		end
	end

	return leader
end

function PartyService.isLeader(player)
	local userIds = PartyService.getPartyUserIds(player)
	return PartyRules.isLeader(player.UserId, userIds)
end

function PartyService.getPartyMembers(leader)
	local partyId = getPartyId(leader)
	if not partyId then
		return { leader }
	end

	local members = {}
	for _, player in Players:GetPlayers() do
		if getPartyId(player) == partyId then
			table.insert(members, player)
		end
	end

	table.sort(members, function(a, b)
		return a.UserId < b.UserId
	end)

	if #members > PartyRules.MAX_PARTY_SIZE then
		while #members > PartyRules.MAX_PARTY_SIZE do
			table.remove(members)
		end
	end

	if #members == 0 then
		return { leader }
	end

	return members
end

function PartyService.getPartyUserIds(leader)
	local members = PartyService.getPartyMembers(leader)
	local ids = table.create(#members)
	for i, player in ipairs(members) do
		ids[i] = player.UserId
	end
	return PartyRules.normalizePartyUserIds(ids)
end

return PartyService
