local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Matter"))
local RuntimeConfig = require(script.Parent:WaitForChild("Config"):WaitForChild("Runtime"))
local RealmPhases = require(script:WaitForChild("RealmPhases"))
local SystemBuilder = require(script:WaitForChild("SystemBuilder"))

local ECS = {}

local function createDefaultEvents(realm)
	if realm == RuntimeConfig.Realms.Server then
		return {
			default = RunService.Heartbeat,
		}
	end

	if realm == RuntimeConfig.Realms.Client then
		assert(RunService:IsClient(), "Client ECS events can only be created on the client")

		return {
			default = RunService.Heartbeat,
			RenderStepped = RunService.RenderStepped,
		}
	end

	error(`Unknown ECS realm "{realm}"`)
end

function ECS.createWorld()
	return Matter.World.new()
end

function ECS.createLoop(world, ...)
	return Matter.Loop.new(world, ...)
end

function ECS.schedule(realm, loop, systems)
	local scheduledSystems = RealmPhases.prepareSystems(realm, systems or {})
	loop:scheduleSystems(scheduledSystems)

	return scheduledSystems
end

function ECS.begin(realm, loop, events)
	return loop:begin(events or createDefaultEvents(realm))
end

function ECS.start(realm, world, systems, ...)
	local loop = ECS.createLoop(world, ...)
	local scheduledSystems = ECS.schedule(realm, loop, systems or {})
	local connections = ECS.begin(realm, loop)

	return loop, connections, scheduledSystems
end

function ECS.stop(connections)
	for _, connection in pairs(connections or {}) do
		if connection ~= nil and type(connection.Disconnect) == "function" then
			connection:Disconnect()
		end
	end
end

ECS.World = Matter.World
ECS.Loop = Matter.Loop
ECS.component = Matter.component
ECS.merge = Matter.merge
ECS.None = Matter.None
ECS.useEvent = Matter.useEvent
ECS.useDeltaTime = Matter.useDeltaTime
ECS.useThrottle = Matter.useThrottle
ECS.useHookState = Matter.useHookState
ECS.useCurrentSystem = Matter.useCurrentSystem
ECS.SystemBuilder = SystemBuilder
ECS.RealmPhases = RealmPhases
ECS.Realms = RuntimeConfig.Realms

return table.freeze(ECS)
