local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local TravelConfig = require(Shared:WaitForChild("Config"):WaitForChild("Travel"))
local PartyRules = require(Shared:WaitForChild("Features"):WaitForChild("Party"):WaitForChild("PartyRules"))

local TeleportData = {}

TeleportData.Version = 1

function TeleportData.build(params)
	return {
		v = TeleportData.Version,
		direction = TravelConfig.HubToRaid,
		sessionId = params.sessionId,
		createdAt = params.createdAt,
		requestedByUserId = params.requestedByUserId,
		partyUserIds = params.partyUserIds,
		hubPlaceId = params.hubPlaceId,
		raidPlaceId = params.raidPlaceId,
		activePets = params.activePets,
	}
end

function TeleportData.buildRaidReturn(params)
	return {
		v = TeleportData.Version,
		direction = TravelConfig.RaidToHub,
		sessionId = params.sessionId,
		createdAt = params.createdAt,
		requestedByUserId = params.requestedByUserId,
		partyUserIds = params.partyUserIds,
		hubPlaceId = params.hubPlaceId,
		raidPlaceId = params.raidPlaceId,
		rewards = params.rewards,
	}
end

function TeleportData.validate(data, places)
	if type(data) ~= "table" then
		return false, "MissingTeleportData"
	end
	if data.v ~= TeleportData.Version then
		return false, "InvalidVersion"
	end
	if type(data.sessionId) ~= "string" or data.sessionId == "" then
		return false, "MissingSessionId"
	end
	if type(data.createdAt) ~= "number" then
		return false, "MissingCreatedAt"
	end
	if type(data.requestedByUserId) ~= "number" then
		return false, "MissingRequester"
	end
	if type(data.partyUserIds) ~= "table" then
		return false, "MissingParty"
	end
	if data.activePets ~= nil and type(data.activePets) ~= "table" then
		return false, "InvalidActivePets"
	end
	if data.hubPlaceId ~= places.Hub then
		return false, "InvalidHubPlace"
	end
	if data.raidPlaceId ~= places.Raid then
		return false, "InvalidRaidPlace"
	end
	if data.direction ~= TravelConfig.HubToRaid then
		return false, "InvalidDirection"
	end
	if not PartyRules.isLeader(data.requestedByUserId, data.partyUserIds) then
		return false, "RequesterNotLeader"
	end
	return true, nil
end

function TeleportData.validateRaidReturn(data, places)
	if type(data) ~= "table" then
		return false, "MissingTeleportData"
	end
	if data.v ~= TeleportData.Version then
		return false, "InvalidVersion"
	end
	if type(data.sessionId) ~= "string" or data.sessionId == "" then
		return false, "MissingSessionId"
	end
	if type(data.createdAt) ~= "number" then
		return false, "MissingCreatedAt"
	end
	if type(data.requestedByUserId) ~= "number" then
		return false, "MissingRequester"
	end
	if type(data.partyUserIds) ~= "table" then
		return false, "MissingParty"
	end
	if data.hubPlaceId ~= places.Hub then
		return false, "InvalidHubPlace"
	end
	if data.raidPlaceId ~= places.Raid then
		return false, "InvalidRaidPlace"
	end
	if data.direction ~= TravelConfig.RaidToHub then
		return false, "InvalidDirection"
	end
	if not PartyRules.isLeader(data.requestedByUserId, data.partyUserIds) then
		return false, "RequesterNotLeader"
	end
	return true, nil
end

return TeleportData
