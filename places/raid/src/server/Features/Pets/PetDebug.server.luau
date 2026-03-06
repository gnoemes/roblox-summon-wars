local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))
local PetProfile = require(Shared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetProfile"))
local PetDefinitions = require(
	Shared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("Definitions"):WaitForChild("PetDefinitions")
)
local PetService = require(
	ServerScriptService:WaitForChild("ServerShared"):WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetService")
)
local RaidPetPresenceService = require(script.Parent:WaitForChild("RaidPetPresenceService"))

local event = Remotes.getRemoteEvent(Remotes.PetDebug, true)

local function buildProfile(player, definitionId)
	return PetProfile.create({
		id = ("starter_%d_%s"):format(player.UserId, definitionId),
		definitionId = definitionId,
	})
end

event.OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" or payload.action ~= "set_active_definition" then
		return
	end

	local definitionId = payload.definitionId
	if type(definitionId) ~= "string" or PetDefinitions.ById[definitionId] == nil then
		event:FireClient(player, {
			action = "ack",
			message = "Unknown pet. Use guardian | crusher | shooter",
		})
		return
	end

	local ok, errors = PetService.setActivePetProfile(player, buildProfile(player, definitionId))
	if not ok then
		event:FireClient(player, {
			action = "ack",
			message = if type(errors) == "table" then table.concat(errors, "; ") else "Failed to set pet",
		})
		return
	end

	RaidPetPresenceService.refreshPlayer(player)
	event:FireClient(player, {
		action = "ack",
		message = ("Active pet: %s"):format(definitionId),
	})
end)
