local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RuntimeConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Runtime"))
local ReplicationTopics = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("Topics")
)

local FighterRosterClient = {}
FighterRosterClient.__index = FighterRosterClient

function FighterRosterClient.new(config)
	assert(type(config) == "table", "FighterRosterClient config must be a table")
	assert(config.network ~= nil, "FighterRosterClient requires Network service")
	assert(config.snapshotClient ~= nil, "FighterRosterClient requires SnapshotClient")

	return setmetatable({
		_snapshotClient = config.snapshotClient,
		_cachedSnapshot = nil,
		_requestRosterRemote = config.network:getRemoteFunction(
			RuntimeConfig.Networking.Namespaces.Fighters,
			"RequestRoster"
		),
		_setActiveTrioRemote = config.network:getRemoteFunction(
			RuntimeConfig.Networking.Namespaces.Fighters,
			"SetActiveTrio"
		),
	}, FighterRosterClient)
end

function FighterRosterClient:getSnapshot()
	return self._snapshotClient:getPayload(ReplicationTopics.Fighters) or self._cachedSnapshot
end

function FighterRosterClient:refresh()
	self._snapshotClient:requestAll()
	local snapshot = self:getSnapshot()
	if snapshot ~= nil then
		return snapshot
	end

	snapshot = self._requestRosterRemote:InvokeServer()
	if type(snapshot) == "table" then
		self._cachedSnapshot = snapshot
	end
	return self:getSnapshot()
end

function FighterRosterClient:subscribe(callback)
	assert(
		type(callback) == "function",
		"FighterRosterClient subscription callback must be a function"
	)

	return self._snapshotClient:subscribe(ReplicationTopics.Fighters, function(envelope)
		self._cachedSnapshot = envelope.payload
		callback(envelope.payload, envelope)
	end)
end

function FighterRosterClient:setActiveTrio(fighterIds)
	assert(type(fighterIds) == "table", "fighterIds must be an array")
	local snapshot = self._setActiveTrioRemote:InvokeServer(fighterIds)
	if type(snapshot) == "table" then
		self._cachedSnapshot = snapshot
	end
	return snapshot
end

function FighterRosterClient:stop()
	return nil
end

return FighterRosterClient
