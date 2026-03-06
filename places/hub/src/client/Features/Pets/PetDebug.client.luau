local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer:WaitForChild("PlayerScripts")
local clientShared = playerScripts:WaitForChild("ClientShared")

local PetDebugClient = require(
	clientShared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetDebugClient")
)

PetDebugClient.init(localPlayer)
