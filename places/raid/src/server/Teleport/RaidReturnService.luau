local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Places = require(Shared:WaitForChild("Config"):WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))
local TeleportData = require(Shared:WaitForChild("Teleport"):WaitForChild("TeleportData"))

local RaidReturnService = {}

local returning = {}

local function computeRewards(_player)
	return {
		credits = 100,
		biomass = 10,
		dna = 3,
	}
end

local function makeReturnData(player, rewards)
	local sessionId = HttpService:GenerateGUID(false)
	local partyUserIds = { player.UserId }
	local createdAt = os.time()

	return TeleportData.buildRaidReturn({
		sessionId = sessionId,
		createdAt = createdAt,
		requestedByUserId = player.UserId,
		partyUserIds = partyUserIds,
		hubPlaceId = Places.Hub,
		raidPlaceId = Places.Raid,
		rewards = rewards,
	})
end

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

	returning[player.UserId] = true

	local ok, err = pcall(function()
		local rewards = computeRewards(player)
		local teleportData = makeReturnData(player, rewards)

		local options = Instance.new("TeleportOptions")
		options:SetTeleportData(teleportData)

		TeleportService:TeleportAsync(Places.Hub, { player }, options)
	end)

	returning[player.UserId] = nil

	if not ok then
		warn("Return to hub failed:", err)
		return { ok = false, error = "TeleportFailed" }
	end

	return { ok = true }
end

function RaidReturnService.init()
	local rf = Remotes.getRemoteFunction(Remotes.ReturnToHub, true)
	rf.OnServerInvoke = returnToHub
end

return RaidReturnService
