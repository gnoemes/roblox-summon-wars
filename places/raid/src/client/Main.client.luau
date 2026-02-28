local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ECS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ECS"))
local Systems = require(script.Parent:WaitForChild("Systems"))

local world = ECS.createWorld()
local events = {
	default = RunService.RenderStepped,
}

ECS.startLoop(world, Systems, events, {
	place = "raid",
	side = "client",
})
