local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))

local rf = Remotes.getRemoteFunction(Remotes.RequestRaid, true)
if rf then
	print("[Hub] Remotes ready:", rf:GetFullName())
	game:SetAttribute("HubRemotesReady", true)
else
	warn("[Hub] Remotes setup failed")
end
