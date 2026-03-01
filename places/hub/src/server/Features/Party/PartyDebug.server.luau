local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))

local function setPartyId(player, value)
	if value == nil or value == "" then
		player:SetAttribute("PartyId", nil)
	else
		player:SetAttribute("PartyId", value)
	end
end

local function handleRequest(player, text)
	local arg = text or ""
	if arg == "" or string.lower(arg) == "off" then
		setPartyId(player, nil)
		print("[PartyDebug] PartyId cleared for", player.UserId)
		return true, "PartyId cleared"
	end

	setPartyId(player, arg)
	print("[PartyDebug] PartyId set for", player.UserId, "->", arg)
	return true, "PartyId set to " .. arg
end

local event = Remotes.getRemoteEvent(Remotes.PartyDebug, true)
event.OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.action ~= "set_party" then
		return
	end
	local ok, msg = handleRequest(player, payload.value)
	event:FireClient(player, {
		action = "ack",
		ok = ok,
		message = msg,
	})
end)
