local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Places = require(Shared:WaitForChild("Config"):WaitForChild("Places"))
local PartyRules = require(Shared:WaitForChild("Features"):WaitForChild("Party"):WaitForChild("PartyRules"))
local TeleportData = require(Shared:WaitForChild("Teleport"):WaitForChild("TeleportData"))

local TravelBuilder = {}

local function ensureRequesterInParty(requestedByUserId, partyUserIds)
	local hasRequester = false
	for _, userId in ipairs(partyUserIds) do
		if userId == requestedByUserId then
			hasRequester = true
			break
		end
	end
	if not hasRequester then
		table.insert(partyUserIds, requestedByUserId)
	end
	return PartyRules.normalizePartyUserIds(partyUserIds)
end

function TravelBuilder.buildHubToRaid(params)
	local sessionId = params.sessionId or HttpService:GenerateGUID(false)
	local createdAt = params.createdAt or os.time()
	local partyUserIds = ensureRequesterInParty(params.requestedByUserId, params.partyUserIds or {})

	return TeleportData.build({
		sessionId = sessionId,
		createdAt = createdAt,
		requestedByUserId = params.requestedByUserId,
		partyUserIds = partyUserIds,
		hubPlaceId = Places.Hub,
		raidPlaceId = Places.Raid,
		activePets = params.activePets,
	}), sessionId
end

function TravelBuilder.buildRaidToHub(params)
	local sessionId = params.sessionId or HttpService:GenerateGUID(false)
	local createdAt = params.createdAt or os.time()
	local partyUserIds = ensureRequesterInParty(params.requestedByUserId, params.partyUserIds or {})

	return TeleportData.buildRaidReturn({
		sessionId = sessionId,
		createdAt = createdAt,
		requestedByUserId = params.requestedByUserId,
		partyUserIds = partyUserIds,
		hubPlaceId = Places.Hub,
		raidPlaceId = Places.Raid,
		rewards = params.rewards,
	})
end

return TravelBuilder
