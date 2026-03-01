local TeleportData = {}

TeleportData.Version = 1

function TeleportData.build(params)
	return {
		v = TeleportData.Version,
		direction = "hub_to_raid",
		sessionId = params.sessionId,
		createdAt = params.createdAt,
		requestedByUserId = params.requestedByUserId,
		partyUserIds = params.partyUserIds,
		hubPlaceId = params.hubPlaceId,
		raidPlaceId = params.raidPlaceId,
	}
end

function TeleportData.buildRaidReturn(params)
	return {
		v = TeleportData.Version,
		direction = "raid_to_hub",
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
	if data.hubPlaceId ~= places.Hub then
		return false, "InvalidHubPlace"
	end
	if data.raidPlaceId ~= places.Raid then
		return false, "InvalidRaidPlace"
	end
	if data.direction ~= "hub_to_raid" then
		return false, "InvalidDirection"
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
	if data.direction ~= "raid_to_hub" then
		return false, "InvalidDirection"
	end
	return true, nil
end

return TeleportData
