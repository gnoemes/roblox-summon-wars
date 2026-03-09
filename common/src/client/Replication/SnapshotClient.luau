local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RuntimeConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Runtime"))
local Signal =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Signal"))
local Cleaner =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Cleaner"))

local SnapshotClient = {}
SnapshotClient.__index = SnapshotClient

local function shouldApplyEnvelope(currentEnvelope, nextEnvelope)
	if currentEnvelope == nil then
		return true
	end

	local currentRevision = currentEnvelope.revision
	local nextRevision = nextEnvelope.revision
	if type(currentRevision) ~= "number" or type(nextRevision) ~= "number" then
		return true
	end

	return nextRevision >= currentRevision
end

function SnapshotClient.new(config)
	assert(type(config) == "table", "SnapshotClient config must be a table")
	assert(config.network ~= nil, "SnapshotClient requires network service")
	assert(config.stateStore ~= nil, "SnapshotClient requires state store")

	local requestAllRemote = config.network:getRemoteFunction(
		RuntimeConfig.Networking.Namespaces.Snapshots,
		"RequestAll"
	)
	local pushRemote =
		config.network:getRemoteEvent(RuntimeConfig.Networking.Namespaces.Snapshots, "Push")

	return setmetatable({
		_stateStore = config.stateStore,
		_requestAllRemote = requestAllRemote,
		_pushRemote = pushRemote,
		_changed = Signal.new(),
		_topicSignals = {},
		_cleaner = Cleaner.new(),
	}, SnapshotClient)
end

function SnapshotClient:_getSnapshotBucket()
	return self._stateStore:getOrCreate("Snapshots")
end

function SnapshotClient:_applyEnvelope(envelope)
	local bucket = self:_getSnapshotBucket()
	local currentEnvelope = bucket[envelope.topic]
	if not shouldApplyEnvelope(currentEnvelope, envelope) then
		return
	end

	bucket[envelope.topic] = envelope

	self._changed:Fire(envelope.topic, envelope)

	local signal = self._topicSignals[envelope.topic]
	if signal ~= nil then
		signal:Fire(envelope)
	end
end

function SnapshotClient:start()
	self._cleaner:add(self._pushRemote.OnClientEvent:Connect(function(envelope)
		self:_applyEnvelope(envelope)
	end))

	local envelopes = self._requestAllRemote:InvokeServer()
	if type(envelopes) == "table" then
		for _, envelope in ipairs(envelopes) do
			self:_applyEnvelope(envelope)
		end
	end
end

function SnapshotClient:getEnvelope(topic)
	return self:_getSnapshotBucket()[topic]
end

function SnapshotClient:getPayload(topic)
	local envelope = self:getEnvelope(topic)
	if envelope == nil then
		return nil
	end

	return envelope.payload
end

function SnapshotClient:subscribe(topic, callback)
	assert(type(callback) == "function", "Snapshot subscription callback must be a function")

	local signal = self._topicSignals[topic]
	if signal == nil then
		signal = Signal.new()
		self._topicSignals[topic] = signal
	end

	return signal:Connect(callback)
end

function SnapshotClient:stop()
	for topic, signal in pairs(self._topicSignals) do
		signal:Destroy()
		self._topicSignals[topic] = nil
	end

	self._changed:Destroy()
	self._cleaner:clean()
end

return SnapshotClient
