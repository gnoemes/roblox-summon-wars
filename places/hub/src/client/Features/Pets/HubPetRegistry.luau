local HubPetRegistry = {}

local petViewStatesByUserId = {}

local function cloneDictionary(map)
	local out = {}
	for key, value in pairs(map) do
		out[key] = value
	end
	return out
end

local function cloneViewState(viewState)
	local cloned = cloneDictionary(viewState)
	cloned.stats = cloneDictionary(viewState.stats or {})
	cloned.visualMutations = cloneDictionary(viewState.visualMutations or {})
	cloned.cosmetics = cloneDictionary(viewState.cosmetics or {})
	cloned.skillIds = if type(viewState.skillIds) == "table" then table.clone(viewState.skillIds) else {}
	cloned.combatMutationIds =
		if type(viewState.combatMutationIds) == "table" then table.clone(viewState.combatMutationIds) else {}
	return cloned
end

function HubPetRegistry.getAll()
	local snapshot = {}
	for userId, viewState in pairs(petViewStatesByUserId) do
		snapshot[userId] = cloneViewState(viewState)
	end
	return snapshot
end

function HubPetRegistry.getByUserId(userId)
	local viewState = petViewStatesByUserId[userId]
	if not viewState then
		return nil
	end
	return cloneViewState(viewState)
end

function HubPetRegistry.upsert(userId, viewState)
	petViewStatesByUserId[userId] = cloneViewState(viewState)
end

function HubPetRegistry.remove(userId)
	petViewStatesByUserId[userId] = nil
end

function HubPetRegistry.clear()
	table.clear(petViewStatesByUserId)
end

return HubPetRegistry
