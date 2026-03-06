-- ServerScriptService/Main.server.lua
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function requireECS()
	local ecs = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ECS")
	if ecs:IsA("ModuleScript") then
		return require(ecs)
	end
	local init = ecs:WaitForChild("init")
	return require(init)
end

local ECS = requireECS()
local Systems = require(script.Parent:WaitForChild("Systems"))
local HubTeleportService = require(
	script.Parent:WaitForChild("Features"):WaitForChild("Travel"):WaitForChild("HubTeleportService")
)
local HubReturnService = require(
	script.Parent:WaitForChild("Features"):WaitForChild("Travel"):WaitForChild("HubReturnService")
)
local HubPetPresenceService = require(
	script.Parent:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("HubPetPresenceService")
)

HubTeleportService.init()
HubReturnService.init()
HubPetPresenceService.init()

local world = ECS.createWorld()
local events = {
	default = RunService.Heartbeat,
}

ECS.startLoop(world, Systems, events, {
	place = "hub",
	side = "server",
})
