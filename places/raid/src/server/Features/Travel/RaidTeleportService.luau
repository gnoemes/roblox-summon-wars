local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Places = require(Shared:WaitForChild("Config"):WaitForChild("Places"))
local TeleportData = require(Shared:WaitForChild("Teleport"):WaitForChild("TeleportData"))
local RewardsService = require(
	script.Parent.Parent:WaitForChild("Rewards"):WaitForChild("RewardsService")
)
local PetService = require(
	game:GetService("ServerScriptService"):WaitForChild("ServerShared"):WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetService")
)

local RaidTeleportService = {}

local function validateJoin(player)
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData

	if RunService:IsStudio() and teleportData == nil then
		PetService.ensureActivePetProfile(player)
		RewardsService.grantTestRewards(player)
		return true
	end

	local ok, reason = TeleportData.validate(teleportData, Places)
	if not ok then
		return false, reason
	end

	local inParty = false
	for _, userId in ipairs(teleportData.partyUserIds) do
		if userId == player.UserId then
			inParty = true
			break
		end
	end
	if not inParty then
		return false, "PlayerNotInParty"
	end

	local activePets = teleportData.activePets
	if type(activePets) == "table" and type(activePets[player.UserId]) == "table" then
		local okSet, errors = PetService.setActivePetProfile(player, activePets[player.UserId])
		if not okSet then
			return false, if type(errors) == "table" then table.concat(errors, "; ") else "InvalidPetProfile"
		end
	else
		PetService.ensureActivePetProfile(player)
	end

	RewardsService.grantTestRewards(player)
	player:SetAttribute("RaidSessionId", teleportData.sessionId)
	player:SetAttribute("RaidRequestedBy", teleportData.requestedByUserId)
	return true
end

function RaidTeleportService.init()
	Players.PlayerAdded:Connect(function(player)
		local ok, reason = validateJoin(player)
		if not ok then
			warn("Invalid teleport data for player", player.UserId, reason)
			player:Kick("Teleport validation failed")
		end
	end)
end

return RaidTeleportService
