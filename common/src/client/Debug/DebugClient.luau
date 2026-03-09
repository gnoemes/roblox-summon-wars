local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RuntimeConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Runtime"))
local Signal =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Signal"))

local DebugClient = {}
DebugClient.__index = DebugClient

function DebugClient.new(config)
	assert(type(config) == "table", "DebugClient config must be a table")
	assert(config.network ~= nil, "DebugClient requires network service")
	assert(config.stateStore ~= nil, "DebugClient requires state store")

	local requestStateRemote =
		config.network:getRemoteFunction(RuntimeConfig.Networking.Namespaces.Debug, "RequestState")
	local invokeActionRemote =
		config.network:getRemoteFunction(RuntimeConfig.Networking.Namespaces.Debug, "InvokeAction")

	return setmetatable({
		_stateStore = config.stateStore,
		_requestStateRemote = requestStateRemote,
		_invokeActionRemote = invokeActionRemote,
		_changed = Signal.new(),
	}, DebugClient)
end

function DebugClient:start()
	self:refresh()
end

function DebugClient:getState()
	return self._stateStore:get("DebugState")
end

function DebugClient:refresh()
	local state = self._requestStateRemote:InvokeServer()
	self._stateStore:set("DebugState", state)
	self._changed:Fire(state)

	return state
end

function DebugClient:invokeAction(actionKey, payload)
	local result = self._invokeActionRemote:InvokeServer(actionKey, payload)
	self:refresh()

	return result
end

function DebugClient:subscribe(callback)
	assert(type(callback) == "function", "DebugClient subscription callback must be a function")

	return self._changed:Connect(callback)
end

function DebugClient:stop()
	self._changed:Destroy()
end

return DebugClient
