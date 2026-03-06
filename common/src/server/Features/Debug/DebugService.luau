local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local DebugConfig = require(Shared:WaitForChild("Features"):WaitForChild("Debug"):WaitForChild("DebugConfig"))
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))

local DebugStateStore = require(script.Parent:WaitForChild("DebugStateStore"))

local DebugService = {}

local initialized = false
local registeredPlaceId = nil
local actionHandlers = {}
local stateBuilders = {}
local supportedViews = {}

local function isDebugAvailable()
	return DebugConfig.isAvailable(RunService:IsStudio())
end

local function buildOrderedActionIds()
	local actionIds = {}
	for _, actionId in ipairs(DebugConfig.ActionOrder) do
		if actionHandlers[actionId] ~= nil then
			table.insert(actionIds, actionId)
		end
	end
	return actionIds
end

local function buildOrderedViewIds()
	local viewIds = {}
	for _, viewId in ipairs(DebugConfig.ViewOrder) do
		if supportedViews[viewId] == true then
			table.insert(viewIds, viewId)
		end
	end
	return viewIds
end

function DebugService.buildState(player)
	local state = {
		available = isDebugAvailable(),
		place = registeredPlaceId,
		supportedActionIds = buildOrderedActionIds(),
		supportedViewIds = buildOrderedViewIds(),
		activeViews = DebugStateStore.getViews(player.UserId),
	}

	for _, builder in ipairs(stateBuilders) do
		builder(player, state)
	end

	return state
end

local function buildResponse(player, ok, message)
	return {
		ok = ok,
		message = message,
		state = DebugService.buildState(player),
	}
end

local function handleSetViewEnabled(player, payload)
	local viewId = payload.viewId
	if type(viewId) ~= "string" or supportedViews[viewId] ~= true then
		return false, "Unknown debug view"
	end

	local enabled = payload.enabled == true
	DebugStateStore.setViewEnabled(player.UserId, viewId, enabled)

	return true, if enabled then ("View enabled: %s"):format(viewId) else ("View disabled: %s"):format(viewId)
end

local function handleAction(player, payload)
	local actionId = payload.actionId
	if type(actionId) ~= "string" then
		return false, "Missing actionId"
	end

	local handler = actionHandlers[actionId]
	if handler == nil then
		return false, "Unsupported debug action"
	end

	local ok, message = handler(player, payload)
	return ok == true, message
end

function DebugService.handleCommand(player, payload)
	if not isDebugAvailable() then
		return buildResponse(player, false, "Debug unavailable")
	end

	if type(payload) ~= "table" then
		return buildResponse(player, false, "Invalid debug payload")
	end

	local ok, message
	if payload.command == "set_view_enabled" then
		ok, message = handleSetViewEnabled(player, payload)
	else
		ok, message = handleAction(player, payload)
	end

	return buildResponse(player, ok, message)
end

function DebugService.init(params)
	if initialized then
		return
	end

	initialized = true
	registeredPlaceId = if params and type(params.place) == "string" then params.place else "unknown"

	local getStateRemote = Remotes.getRemoteFunction(Remotes.GetDebugState, true)
	getStateRemote.OnServerInvoke = function(player)
		return DebugService.buildState(player)
	end

	local commandRemote = Remotes.getRemoteFunction(Remotes.DebugCommand, true)
	commandRemote.OnServerInvoke = function(player, payload)
		return DebugService.handleCommand(player, payload)
	end

	Players.PlayerRemoving:Connect(function(player)
		DebugStateStore.clear(player.UserId)
	end)
end

function DebugService.registerAction(actionId, handler)
	assert(DebugConfig.Actions[actionId] ~= nil, ("Unknown debug action '%s'"):format(tostring(actionId)))
	assert(type(handler) == "function", "Debug action handler must be a function")

	actionHandlers[actionId] = handler
end

function DebugService.registerStateBuilder(builder)
	assert(type(builder) == "function", "Debug state builder must be a function")
	table.insert(stateBuilders, builder)
end

function DebugService.registerView(viewId)
	assert(DebugConfig.Views[viewId] ~= nil, ("Unknown debug view '%s'"):format(tostring(viewId)))
	supportedViews[viewId] = true
end

function DebugService.isViewEnabled(player, viewId)
	return DebugStateStore.isViewEnabled(player.UserId, viewId)
end

return DebugService
