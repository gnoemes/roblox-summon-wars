local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Places = require(Shared:WaitForChild("Config"):WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))
local TravelBuilder = require(Shared:WaitForChild("Features"):WaitForChild("Travel"):WaitForChild("TravelBuilder"))
local PartyService = require(
	script.Parent.Parent:WaitForChild("Party"):WaitForChild("PartyService")
)

local HubTeleportService = {}

local teleporting = {}

local function requestRaid(player)
	if not player or not player.Parent then
		return { ok = false, error = "InvalidPlayer" }
	end

	if RunService:IsStudio() then
		return { ok = false, error = "StudioTeleportDisabled" }
	end

	if not PartyService.isLeader(player) then
		return { ok = false, error = "NotPartyLeader" }
	end

	if teleporting[player.UserId] then
		return { ok = false, error = "TeleportInProgress" }
	end

	teleporting[player.UserId] = true

	local ok, result = pcall(function()
		local accessCode = TeleportService:ReserveServer(Places.Raid)
		local teleportData, sessionId = TravelBuilder.buildHubToRaid({
			requestedByUserId = player.UserId,
			partyUserIds = PartyService.getPartyUserIds(player),
		})
		local party = PartyService.getPartyMembers(player)

		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = accessCode
		options:SetTeleportData(teleportData)
		task.wait(1)
		TeleportService:TeleportAsync(Places.Raid, party, options)
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
