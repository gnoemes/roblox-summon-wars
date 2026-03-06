local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))

local DebugClient = {}

local initialized = false
local getStateRemote = nil
local commandRemote = nil
local listeners = {}
local currentState = {
	available = false,
	place = nil,
	supportedActionIds = {},
	supportedViewIds = {},
	activeViews = {},
}

local function cloneValue(value)
	if type(value) ~= "table" then
		return value
	end

	if #value > 0 then
		local clonedArray = table.clone(value)
		for index, entry in ipairs(clonedArray) do
			clonedArray[index] = cloneValue(entry)
		end
		return clonedArray
	end

	local clonedDictionary = {}
	for key, entry in pairs(value) do
		clonedDictionary[key] = cloneValue(entry)
	end
	return clonedDictionary
end

local function notifyListeners()
	local snapshot = DebugClient.getState()
	for _, listener in ipairs(listeners) do
		task.spawn(listener, snapshot)
	end
end

local function setState(nextState)
	if type(nextState) ~= "table" then
		return
	end

	currentState = cloneValue(nextState)
	notifyListeners()
end

local function getRemotesFolder()
	return ReplicatedStorage:WaitForChild(Remotes.FolderName, 10)
end

function DebugClient.init()
	if initialized then
		return
	end

	initialized = true

	local remotesFolder = getRemotesFolder()
	if not remotesFolder then
		return
	end

	getStateRemote = remotesFolder:WaitForChild(Remotes.GetDebugState, 10)
	commandRemote = remotesFolder:WaitForChild(Remotes.DebugCommand, 10)

	DebugClient.refreshState()
end

function DebugClient.getState()
	return cloneValue(currentState)
end

function DebugClient.subscribe(listener)
	assert(type(listener) == "function", "DebugClient listener must be a function")
	table.insert(listeners, listener)
	listener(DebugClient.getState())

	return function()
		local index = table.find(listeners, listener)
		if index then
			table.remove(listeners, index)
		end
	end
end

function DebugClient.refreshState()
	if not initialized then
		DebugClient.init()
	end
	if not getStateRemote then
		return false, "Debug state remote not ready"
	end

	local ok, response = pcall(function()
		return getStateRemote:InvokeServer()
	end)
	if not ok or type(response) ~= "table" then
		return false, "Failed to fetch debug state"
	end

	setState(response)
	return true, response
end

function DebugClient.runAction(actionId, payload)
	if not initialized then
		DebugClient.init()
	end
	if not commandRemote then
		return false, {
			ok = false,
			message = "Debug command remote not ready",
			state = DebugClient.getState(),
		}
	end

	local request = cloneValue(payload or {})
	request.actionId = actionId

	local ok, response = pcall(function()
		return commandRemote:InvokeServer(request)
	end)
	if not ok or type(response) ~= "table" then
		return false, {
			ok = false,
			message = "Failed to run debug action",
			state = DebugClient.getState(),
		}
	end

	if type(response.state) == "table" then
		setState(response.state)
	end

	return response.ok == true, response
end

function DebugClient.setViewEnabled(viewId, enabled)
	if not initialized then
		DebugClient.init()
	end
	if not commandRemote then
		return false, {
			ok = false,
			message = "Debug command remote not ready",
			state = DebugClient.getState(),
		}
	end

	local ok, response = pcall(function()
		return commandRemote:InvokeServer({
			command = "set_view_enabled",
			viewId = viewId,
			enabled = enabled == true,
		})
	end)
	if not ok or type(response) ~= "table" then
		return false, {
			ok = false,
			message = "Failed to update debug view",
			state = DebugClient.getState(),
		}
	end

	if type(response.state) == "table" then
		setState(response.state)
	end

	return response.ok == true, response
end

function DebugClient.isViewEnabled(viewId)
	return currentState.activeViews ~= nil and currentState.activeViews[viewId] == true
end

return DebugClient
