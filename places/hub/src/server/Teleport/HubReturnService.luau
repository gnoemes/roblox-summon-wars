local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Places = require(Shared:WaitForChild("Config"):WaitForChild("Places"))
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
		player:SetAttribute("RaidRewardsCredits", rewards.credits or 0)
		player:SetAttribute("RaidRewardsBiomass", rewards.biomass or 0)
		player:SetAttribute("RaidRewardsDNA", rewards.dna or 0)
	end
end

function HubReturnService.init()
	Players.PlayerAdded:Connect(handleReturn)
end

return HubReturnService
