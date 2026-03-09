local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RuntimeConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Runtime"))
local SnapshotEnvelope = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Replication")
		:WaitForChild("SnapshotEnvelope")
)

local SnapshotService = {}
SnapshotService.__index = SnapshotService

local function sortedKeys(map)
	local keys = {}

	for key in pairs(map) do
		table.insert(keys, key)
	end

	table.sort(keys)

	return keys
end

function SnapshotService.new(config)
	assert(type(config) == "table", "SnapshotService config must be a table")
	assert(config.network ~= nil, "SnapshotService requires network service")

	local requestAllRemote = config.network:ensureRemoteFunction(
		RuntimeConfig.Networking.Namespaces.Snapshots,
		"RequestAll"
	)
	local pushRemote =
		config.network:ensureRemoteEvent(RuntimeConfig.Networking.Namespaces.Snapshots, "Push")

	return setmetatable({
		_requestAllRemote = requestAllRemote,
		_pushRemote = pushRemote,
		_providers = {},
	}, SnapshotService)
end

function SnapshotService:registerTopic(topic, provider)
	assert(type(topic) == "string" and topic ~= "", "Snapshot topic must be a non-empty string")
	assert(type(provider) == "function", "Snapshot provider must be a function")
	assert(self._providers[topic] == nil, `Snapshot topic "{topic}" is already registered`)

	self._providers[topic] = provider
end

function SnapshotService:getSnapshot(player, topic)
	local provider = self._providers[topic]
	if provider == nil then
		return nil
	end

	local payload, revision, mode = provider(player)
	if payload == nil then
		return nil
	end

	return SnapshotEnvelope.create(topic, revision or 0, payload, mode)
end

function SnapshotService:getAllSnapshots(player)
	local envelopes = {}

	for _, topic in ipairs(sortedKeys(self._providers)) do
		local envelope = self:getSnapshot(player, topic)
		if envelope ~= nil then
			table.insert(envelopes, envelope)
		end
	end

	return envelopes
end

function SnapshotService:publishRegisteredTopic(player, topic)
	local envelope = self:getSnapshot(player, topic)
	if envelope ~= nil then
		self._pushRemote:FireClient(player, envelope)
	end
end

function SnapshotService:publishTopic(player, topic, payload, revision, mode)
	self._pushRemote:FireClient(player, SnapshotEnvelope.create(topic, revision, payload, mode))
end

function SnapshotService:start()
	self._requestAllRemote.OnServerInvoke = function(player)
		return self:getAllSnapshots(player)
	end
end

function SnapshotService:stop()
	self._requestAllRemote.OnServerInvoke = nil
end

return SnapshotService
