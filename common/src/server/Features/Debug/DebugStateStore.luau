local DebugStateStore = {}

local viewsByUserId = {}

local function cloneDictionary(map)
	local out = {}
	for key, value in pairs(map or {}) do
		out[key] = value
	end
	return out
end

function DebugStateStore.getViews(userId)
	return cloneDictionary(viewsByUserId[userId])
end

function DebugStateStore.setViewEnabled(userId, viewId, enabled)
	local state = viewsByUserId[userId]
	if not state then
		state = {}
		viewsByUserId[userId] = state
	end

	if enabled then
		state[viewId] = true
	else
		state[viewId] = nil
	end
end

function DebugStateStore.isViewEnabled(userId, viewId)
	local state = viewsByUserId[userId]
	return state ~= nil and state[viewId] == true
end

function DebugStateStore.clear(userId)
	viewsByUserId[userId] = nil
end

return DebugStateStore
