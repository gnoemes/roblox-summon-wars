local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Debug"):WaitForChild("DebugConfig")
)
local RuntimeConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Runtime"))

local DebugService = {}
DebugService.__index = DebugService

local function sortedKeys(map)
	local keys = {}

	for key in pairs(map) do
		table.insert(keys, key)
	end

	table.sort(keys)

	return keys
end

local function buildEntryKey(namespace, name)
	assert(
		type(namespace) == "string" and namespace ~= "",
		"Debug namespace must be a non-empty string"
	)
	assert(type(name) == "string" and name ~= "", "Debug name must be a non-empty string")

	return string.format("%s%s%s", namespace, DebugConfig.ViewNamespaceSeparator, name)
end

function DebugService.new(config)
	assert(type(config) == "table", "DebugService config must be a table")
	assert(config.network ~= nil, "DebugService requires network service")

	local requestStateRemote = config.network:ensureRemoteFunction(
		RuntimeConfig.Networking.Namespaces.Debug,
		"RequestState"
	)
	local invokeActionRemote = config.network:ensureRemoteFunction(
		RuntimeConfig.Networking.Namespaces.Debug,
		"InvokeAction"
	)

	return setmetatable({
		_requestStateRemote = requestStateRemote,
		_invokeActionRemote = invokeActionRemote,
		_views = {},
		_actions = {},
	}, DebugService)
end

function DebugService:isEnabledForPlayer(_player)
	return RunService:IsStudio()
end

function DebugService:registerView(namespace, name, provider)
	local entryKey = buildEntryKey(namespace, name)
	assert(type(provider) == "function", "Debug view provider must be a function")
	assert(self._views[entryKey] == nil, `Debug view "{entryKey}" is already registered`)

	self._views[entryKey] = provider

	return entryKey
end

function DebugService:registerAction(namespace, name, callback)
	local entryKey = buildEntryKey(namespace, name)
	assert(type(callback) == "function", "Debug action callback must be a function")
	assert(self._actions[entryKey] == nil, `Debug action "{entryKey}" is already registered`)

	self._actions[entryKey] = callback

	return entryKey
end

function DebugService:getState(player)
	if not self:isEnabledForPlayer(player) then
		return {
			enabled = false,
			views = {},
			actions = {},
		}
	end

	local views = {}
	for _, viewKey in ipairs(sortedKeys(self._views)) do
		local provider = self._views[viewKey]
		local ok, result = pcall(provider, player)
		views[viewKey] = if ok then result else { error = tostring(result) }
	end

	return {
		enabled = true,
		views = views,
		actions = sortedKeys(self._actions),
	}
end

function DebugService:invokeAction(player, actionKey, payload)
	if not self:isEnabledForPlayer(player) then
		return {
			ok = false,
			error = "Debug is disabled for this player",
		}
	end

	local action = self._actions[actionKey]
	if action == nil then
		return {
			ok = false,
			error = string.format("Unknown debug action: %s", tostring(actionKey)),
		}
	end

	local ok, result = pcall(action, player, payload)
	if not ok then
		return {
			ok = false,
			error = tostring(result),
		}
	end

	return {
		ok = true,
		result = result,
	}
end

function DebugService:start()
	self._requestStateRemote.OnServerInvoke = function(player)
		return self:getState(player)
	end

	self._invokeActionRemote.OnServerInvoke = function(player, actionKey, payload)
		return self:invokeAction(player, actionKey, payload)
	end
end

function DebugService:stop()
	self._requestStateRemote.OnServerInvoke = nil
	self._invokeActionRemote.OnServerInvoke = nil
end

return DebugService
