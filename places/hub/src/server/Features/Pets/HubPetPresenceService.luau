local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))
local PetService = require(
	game:GetService("ServerScriptService"):WaitForChild("ServerShared"):WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetService")
)

local HubPetPresenceService = {}

local function buildPayloadForPlayer(player)
	local viewState, errors = PetService.getActivePetViewState(player, "hub_follower")
	if not viewState then
		warn(
			("Failed to build hub pet view state for user %d: %s"):format(
				player.UserId,
				if type(errors) == "table" then table.concat(errors, "; ") else "unknown error"
			)
		)
		return nil
	end

	viewState.ownerUserId = player.UserId
	return viewState
end

local function buildSnapshot()
	local snapshot = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local payload = buildPayloadForPlayer(player)
		if payload then
			snapshot[player.UserId] = payload
		end
	end
	return snapshot
end

local function broadcastUpdate(player)
	local event = Remotes.getRemoteEvent(Remotes.HubPetViewStateUpdated, true)
	local payload = buildPayloadForPlayer(player)
	if payload then
		event:FireAllClients({
			action = "upsert",
			userId = player.UserId,
			viewState = payload,
		})
	end
end

local function broadcastRemoval(userId)
	local event = Remotes.getRemoteEvent(Remotes.HubPetViewStateUpdated, true)
	event:FireAllClients({
		action = "remove",
		userId = userId,
	})
end

local function handlePlayerAdded(player)
	PetService.ensureActivePetProfile(player)
	broadcastUpdate(player)
end

function HubPetPresenceService.refreshPlayer(player)
	PetService.ensureActivePetProfile(player)
	broadcastUpdate(player)
end

function HubPetPresenceService.init()
	local rf = Remotes.getRemoteFunction(Remotes.GetHubPetViewStates, true)
	rf.OnServerInvoke = function(requestingPlayer)
		PetService.ensureActivePetProfile(requestingPlayer)
		return buildSnapshot()
	end

	Players.PlayerAdded:Connect(handlePlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		broadcastRemoval(player.UserId)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		handlePlayerAdded(player)
	end
end

return HubPetPresenceService
