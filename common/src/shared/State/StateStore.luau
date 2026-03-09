local StateStore = {}
StateStore.__index = StateStore

function StateStore.new()
	return setmetatable({
		_namespaces = {},
	}, StateStore)
end

function StateStore:has(namespace)
	return self._namespaces[namespace] ~= nil
end

function StateStore:get(namespace)
	return self._namespaces[namespace]
end

function StateStore:set(namespace, value)
	assert(type(namespace) == "string" and namespace ~= "", "Namespace must be a non-empty string")

	self._namespaces[namespace] = value

	return value
end

function StateStore:getOrCreate(namespace, factory)
	local current = self._namespaces[namespace]

	if current ~= nil then
		return current
	end

	local nextValue

	if factory ~= nil then
		assert(type(factory) == "function", "StateStore factory must be a function")
		nextValue = factory()
	else
		nextValue = {}
	end

	self._namespaces[namespace] = nextValue

	return nextValue
end

function StateStore:list()
	return table.clone(self._namespaces)
end

return StateStore
