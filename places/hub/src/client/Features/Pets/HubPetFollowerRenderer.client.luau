local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer:WaitForChild("PlayerScripts")
local clientShared = playerScripts:WaitForChild("ClientShared")

local HubPetRegistry = require(script.Parent:WaitForChild("HubPetRegistry"))
local PetFollowerRenderer = require(
	clientShared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetFollowerRenderer")
)

PetFollowerRenderer.start({
	registry = HubPetRegistry,
	renderStepName = "HubPetFollowerRenderer",
	renderPriority = Enum.RenderPriority.Character.Value + 1,
	renderFolderName = "ClientPetFollowers",
	modelNamePrefix = "PetFollower",
	sideOffset = 2,
	backOffset = 3.5,
	heightOffset = -1.5,
	lerpAlpha = 0.18,
})
