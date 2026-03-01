local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Places = require(Shared:WaitForChild("Config"):WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))
local TeleportData = require(Shared:WaitForChild("Teleport"):WaitForChild("TeleportData"))

local HubTeleportService = {}

local teleporting = {}

local function makeTeleportData(player)
	local sessionId = HttpService:GenerateGUID(false)
	local partyUserIds = { player.UserId }
	local createdAt = os.time()

	return TeleportData.build({
		sessionId = sessionId,
		createdAt = createdAt,
		requestedByUserId = player.UserId,
		partyUserIds = partyUserIds,
		hubPlaceId = Places.Hub,
		raidPlaceId = Places.Raid,
	}), sessionId
end

local function requestRaid(player)
	if not player or not player.Parent then
		return { ok = false, error = "InvalidPlayer" }
	end

	if RunService:IsStudio() then
		return { ok = false, error = "StudioTeleportDisabled" }
	end

	if teleporting[player.UserId] then
		return { ok = false, error = "TeleportInProgress" }
	end

	teleporting[player.UserId] = true

	local ok, result = pcall(function()
		local accessCode = TeleportService:ReserveServer(Places.Raid)
		local teleportData, sessionId = makeTeleportData(player)

		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = accessCode
		options:SetTeleportData(teleportData)

		TeleportService:TeleportAsync(Places.Raid, { player }, options)
		return sessionId
	end)

	teleporting[player.UserId] = nil

	if not ok then
		warn("Teleport failed:", result)
		return { ok = false, error = "TeleportFailed" }
	end

	return { ok = true, sessionId = result }
end

function HubTeleportService.init()
	if RunService:IsStudio() then
		warn("HubTeleportService: running in Studio")
	end

	local rf = Remotes.getRemoteFunction(Remotes.RequestRaid, true)
	rf.OnServerInvoke = requestRaid
	game:SetAttribute("HubTeleportReady", true)
end

return HubTeleportService
