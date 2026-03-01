local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Places = require(Shared:WaitForChild("Config"):WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))
local TeleportData = require(Shared:WaitForChild("Teleport"):WaitForChild("TeleportData"))
local PartyRules = require(Shared:WaitForChild("Features"):WaitForChild("Party"):WaitForChild("PartyRules"))
local TravelBuilder = require(Shared:WaitForChild("Features"):WaitForChild("Travel"):WaitForChild("TravelBuilder"))
local RewardsService = require(
	script.Parent.Parent:WaitForChild("Rewards"):WaitForChild("RewardsService")
)

local function getPartyUserIds(requester)
	local joinData = requester:GetJoinData()
	local teleportData = joinData and joinData.TeleportData
	local party = teleportData and teleportData.partyUserIds
	return PartyRules.normalizePartyUserIds(party or { requester.UserId })
end

local RaidReturnService = {}

local returning = {}

local function returnToHub(player)
	if not player or not player.Parent then
		return { ok = false, error = "InvalidPlayer" }
	end

	if RunService:IsStudio() then
		return { ok = false, error = "StudioTeleportDisabled" }
	end

	if returning[player.UserId] then
		return { ok = false, error = "TeleportInProgress" }
	end

	local partyUserIds = getPartyUserIds(player)
	if not PartyRules.isLeader(player.UserId, partyUserIds) then
		return { ok = false, error = "NotPartyLeader" }
	end

	returning[player.UserId] = true

	local ok, err = pcall(function()
		local partyPlayers = { player }
		for _, userId in ipairs(partyUserIds) do
			if userId ~= player.UserId then
				local member = Players:GetPlayerByUserId(userId)
				if member then
					table.insert(partyPlayers, member)
				end
			end
		end

		local rewardsByUser = {}
		for _, userId in ipairs(partyUserIds) do
			local rewards = RewardsService.getRewardsByUserId(userId)
			if not rewards then
				rewards = RewardsService.buildEmptyRewards()
			end
			rewardsByUser[userId] = rewards
		end

		local teleportData = TravelBuilder.buildRaidToHub({
			requestedByUserId = player.UserId,
			partyUserIds = partyUserIds,
			rewards = rewardsByUser,
		})

		local options = Instance.new("TeleportOptions")
		options:SetTeleportData(teleportData)

		TeleportService:TeleportAsync(Places.Hub, partyPlayers, options)
	end)

	returning[player.UserId] = nil

	if not ok then
		warn("Return to hub failed:", err)
		return { ok = false, error = "TeleportFailed" }
	end

	for _, userId in ipairs(partyUserIds) do
		RewardsService.clearRewardsByUserId(userId)
	end
	return { ok = true }
end

function RaidReturnService.init()
	local rf = Remotes.getRemoteFunction(Remotes.ReturnToHub, true)
	rf.OnServerInvoke = returnToHub
end

return RaidReturnService
