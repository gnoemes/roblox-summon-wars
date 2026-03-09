local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

function ServiceRegistry.new()
	return setmetatable({
		_isSealed = false,
		_services = {},
	}, ServiceRegistry)
end

function ServiceRegistry:register(name, service)
	assert(type(name) == "string" and name ~= "", "Service name must be a non-empty string")
	assert(not self._isSealed, "Cannot register services after registry has been sealed")
	assert(self._services[name] == nil, `Service "{name}" is already registered`)

	self._services[name] = service

	return service
end

function ServiceRegistry:has(name)
	return self._services[name] ~= nil
end

function ServiceRegistry:get(name)
	local service = self._services[name]
	assert(service ~= nil, `Unknown service "{name}"`)

	return service
end

function ServiceRegistry:getOptional(name)
	return self._services[name]
end

function ServiceRegistry:seal()
	if self._isSealed then
		return
	end

	self._isSealed = true
	table.freeze(self._services)
end

function ServiceRegistry:list()
	return table.clone(self._services)
end

return ServiceRegistry
