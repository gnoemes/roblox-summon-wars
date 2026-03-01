local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Places = require(Shared:WaitForChild("Config"):WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))
local TeleportData = require(Shared:WaitForChild("Teleport"):WaitForChild("TeleportData"))
local RewardsService = require(script.Parent.Parent:WaitForChild("Rewards"):WaitForChild("RewardsService"))

local MAX_PARTY_SIZE = 4

local function getPartyUserIds(requester)
	local party = {}

	local joinData = requester:GetJoinData()
	local teleportData = joinData and joinData.TeleportData
	if teleportData and type(teleportData.partyUserIds) == "table" then
		for _, userId in ipairs(teleportData.partyUserIds) do
			table.insert(party, userId)
		end
	end

	if #party == 0 then
		return { requester.UserId }
	end

	table.sort(party, function(a, b)
		return a < b
	end)

	if #party > MAX_PARTY_SIZE then
		while #party > MAX_PARTY_SIZE do
			table.remove(party)
		end
	end

	return party
end

local RaidReturnService = {}

local returning = {}

local function makeReturnData(requestedByUserId, partyUserIds, rewards)
	local sessionId = HttpService:GenerateGUID(false)
	local createdAt = os.time()

	return TeleportData.buildRaidReturn({
		sessionId = sessionId,
		createdAt = createdAt,
		requestedByUserId = requestedByUserId,
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

	local partyUserIds = getPartyUserIds(player)
	if partyUserIds[1] ~= player.UserId then
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
			local rewards = RewardsService.getRewardsByUserId(userId) or {
				credits = 0,
				biomass = 0,
				dna = 0,
			}
			rewardsByUser[userId] = rewards
		end

		local teleportData = makeReturnData(player.UserId, partyUserIds, rewardsByUser)

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
