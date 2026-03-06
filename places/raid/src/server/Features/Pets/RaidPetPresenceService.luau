local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))
local PetService = require(
	game:GetService("ServerScriptService"):WaitForChild("ServerShared"):WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetService")
)

local RaidPetPresenceService = {}

local function buildPayloadForPlayer(player)
	local viewState, errors = PetService.getActivePetViewState(player, "raid_full")
	if not viewState then
		player:SetAttribute(
			"RaidPetPipelineStatus",
			("Presence failed: %s"):format(
				if type(errors) == "table" then table.concat(errors, "; ") else "view state build failed"
			)
		)
		warn(
			("Failed to build raid pet view state for user %d: %s"):format(
				player.UserId,
				if type(errors) == "table" then table.concat(errors, "; ") else "unknown error"
			)
		)
		return nil
	end

	viewState.ownerUserId = player.UserId
	player:SetAttribute("RaidPetPipelineStatus", ("Presence ready: %s"):format(viewState.definitionId))
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
	local event = Remotes.getRemoteEvent(Remotes.RaidPetViewStateUpdated, true)
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
	local event = Remotes.getRemoteEvent(Remotes.RaidPetViewStateUpdated, true)
	event:FireAllClients({
		action = "remove",
		userId = userId,
	})
end

local function handlePlayerAdded(player)
	PetService.ensureActivePetProfile(player)
	player:SetAttribute("RaidPetPipelineStatus", "Presence: active pet profile ensured")
	broadcastUpdate(player)
end

function RaidPetPresenceService.refreshPlayer(player)
	PetService.ensureActivePetProfile(player)
	player:SetAttribute("RaidPetPipelineStatus", "Presence: pet view state refreshed")
	broadcastUpdate(player)
end

function RaidPetPresenceService.init()
	local rf = Remotes.getRemoteFunction(Remotes.GetRaidPetViewStates, true)
	rf.OnServerInvoke = function(requestingPlayer)
		PetService.ensureActivePetProfile(requestingPlayer)
		requestingPlayer:SetAttribute("RaidPetPipelineStatus", "Presence: raid snapshot requested by client")
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

return RaidPetPresenceService
