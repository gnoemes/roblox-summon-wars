local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Places = require(Shared:WaitForChild("Config"):WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))
local TeleportData = require(Shared:WaitForChild("Teleport"):WaitForChild("TeleportData"))

local HubReturnService = {}

local function handleReturn(player)
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData

	if RunService:IsStudio() and teleportData == nil then
		return
	end

	local ok, reason = TeleportData.validateRaidReturn(teleportData, Places)
	if not ok then
		return
	end

	local rewards = teleportData.rewards
	if type(rewards) == "table" then
		local perUser = rewards[player.UserId]
		if type(perUser) ~= "table" then
			perUser = rewards
		end
		player:SetAttribute("RaidRewardsCredits", perUser.credits or 0)
		player:SetAttribute("RaidRewardsBiomass", perUser.biomass or 0)
		player:SetAttribute("RaidRewardsDNA", perUser.dna or 0)
	end
end

function HubReturnService.init()
	Players.PlayerAdded:Connect(handleReturn)

	local clearEvent = Remotes.getRemoteFunction(Remotes.ClearRaidSummary, true)
	if clearEvent then
		clearEvent.OnServerInvoke = function(player)
			player:SetAttribute("RaidRewardsCredits", nil)
			player:SetAttribute("RaidRewardsBiomass", nil)
			player:SetAttribute("RaidRewardsDNA", nil)
			return true
		end
	end
end

return HubReturnService
