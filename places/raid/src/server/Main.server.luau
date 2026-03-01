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
local RaidTeleportService = require(script.Parent:WaitForChild("Teleport"):WaitForChild("RaidTeleportService"))
local RaidReturnService = require(script.Parent:WaitForChild("Teleport"):WaitForChild("RaidReturnService"))

RaidTeleportService.init()
RaidReturnService.init()

local world = ECS.createWorld()
local events = {
	default = RunService.Heartbeat,
}

ECS.startLoop(world, Systems, events, {
	place = "raid",
	side = "server",
})
