local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Matter"))

local ECS = {}

function ECS.createWorld()
	return Matter.World.new()
end

function ECS.startLoop(world, systems, events, ...)
	local loop = Matter.Loop.new(world, ...)

	if systems and #systems > 0 then
		loop:scheduleSystems(systems)
	end

	local connections = loop:begin(events)
	return loop, connections
end

return ECS
