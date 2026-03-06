local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer:WaitForChild("PlayerScripts")
local clientShared = playerScripts:WaitForChild("ClientShared")

local DebugMenuController = require(
	clientShared:WaitForChild("Features"):WaitForChild("Debug"):WaitForChild("DebugMenuController")
)

DebugMenuController.init()
