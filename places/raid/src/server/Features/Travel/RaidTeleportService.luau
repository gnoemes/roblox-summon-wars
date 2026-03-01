local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Places = require(Shared:WaitForChild("Config"):WaitForChild("Places"))
local TeleportData = require(Shared:WaitForChild("Teleport"):WaitForChild("TeleportData"))
local RewardsService = require(
	script.Parent.Parent:WaitForChild("Rewards"):WaitForChild("RewardsService")
)

local RaidTeleportService = {}

local function validateJoin(player)
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData

	if RunService:IsStudio() and teleportData == nil then
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
