local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local ECS = require(Shared:WaitForChild("ECS"))
local RuntimeConfig = require(Shared:WaitForChild("Config"):WaitForChild("Runtime"))
local FeatureLoader = require(Shared:WaitForChild("Runtime"):WaitForChild("FeatureLoader"))
local ServiceRegistry = require(Shared:WaitForChild("Runtime"):WaitForChild("ServiceRegistry"))
local StateStore = require(Shared:WaitForChild("State"):WaitForChild("StateStore"))
local Cleaner = require(Shared:WaitForChild("Utils"):WaitForChild("Cleaner"))
local NetworkClient =
	require(script.Parent.Parent:WaitForChild("Networking"):WaitForChild("NetworkClient"))
local SnapshotClient =
	require(script.Parent.Parent:WaitForChild("Replication"):WaitForChild("SnapshotClient"))
local DebugClient = require(script.Parent.Parent:WaitForChild("Debug"):WaitForChild("DebugClient"))

local ClientRuntime = {}
ClientRuntime.__index = ClientRuntime

local function callFeatureMethod(feature, methodName, context)
	local method = feature.definition[methodName]

	if method ~= nil then
		method(context)
	end
end

local function collectFeatureSystems(features, context)
	local systems = {}

	for _, feature in ipairs(features) do
		local declaredSystems = feature.definition.systems

		if declaredSystems ~= nil then
			if type(declaredSystems) == "function" then
				declaredSystems = declaredSystems(context)
			end

			assert(
				type(declaredSystems) == "table",
				`Feature "{feature.id}" systems must resolve to an array`
			)

			for _, system in ipairs(declaredSystems) do
				table.insert(systems, system)
			end
		end
	end

	return systems
end

function ClientRuntime.new(config)
	assert(type(config) == "table", "ClientRuntime config must be a table")
	assert(
		type(config.placeId) == "string" and config.placeId ~= "",
		"ClientRuntime requires placeId"
	)
	assert(typeof(config.root) == "Instance", "ClientRuntime requires root instance")

	return setmetatable({
		_config = config,
		_started = false,
	}, ClientRuntime)
end

function ClientRuntime:start()
	assert(not self._started, "ClientRuntime has already been started")

	self._started = true

	local ok, result = xpcall(function()
		local cleaner = Cleaner.new()
		local services = ServiceRegistry.new()
		local stateStore = StateStore.new()
		local network = NetworkClient.new()
		local snapshotClient = SnapshotClient.new({
			network = network,
			stateStore = stateStore,
		})
		local debugClient = DebugClient.new({
			network = network,
			stateStore = stateStore,
		})
		local world = ECS.createWorld()
		local features = FeatureLoader.loadFolder(self._config.featuresFolder, "ClientFeature")
		local context = {
			realm = RuntimeConfig.Realms.Client,
			placeId = self._config.placeId,
			root = self._config.root,
			features = features,
			featuresFolder = self._config.featuresFolder,
			cleaner = cleaner,
			services = services,
			stateStore = stateStore,
			network = network,
			world = world,
			ecs = ECS,
			runtime = self,
		}

		self._cleaner = cleaner
		self._services = services
		self._stateStore = stateStore
		self._network = network
		self._world = world
		self._features = features
		self._context = context

		services:register("StateStore", stateStore)
		services:register("Network", network)
		services:register("SnapshotClient", snapshotClient)
		services:register("DebugClient", debugClient)

		for _, feature in ipairs(features) do
			callFeatureMethod(feature, "registerServices", context)
		end

		services:seal()

		snapshotClient:start()
		debugClient:start()
		cleaner:add(debugClient)
		cleaner:add(snapshotClient)

		context.systems = collectFeatureSystems(features, context)

		for _, feature in ipairs(features) do
			callFeatureMethod(feature, "initialize", context)
		end

		local loop, connections, scheduledSystems =
			ECS.start(RuntimeConfig.Realms.Client, world, context.systems, context)

		self._loop = loop
		self._connections = connections

		context.loop = loop
		context.connections = connections
		context.scheduledSystems = scheduledSystems
		context.stop = function()
			self:stop()
		end

		cleaner:add(function()
			ECS.stop(connections)
		end)

		for _, feature in ipairs(features) do
			callFeatureMethod(feature, "start", context)
		end

		return context
	end, debug.traceback)

	if not ok then
		self:stop()
		error(result, 0)
	end

	return result
end

function ClientRuntime:stop()
	if not self._started then
		return
	end

	if self._features ~= nil and self._context ~= nil then
		for index = #self._features, 1, -1 do
			callFeatureMethod(self._features[index], "stop", self._context)
		end
	end

	if self._cleaner ~= nil then
		self._cleaner:clean()
	end

	self._loop = nil
	self._connections = nil
	self._context = nil
	self._features = nil
	self._world = nil
	self._network = nil
	self._services = nil
	self._stateStore = nil
	self._cleaner = nil
	self._started = false
end

return ClientRuntime
