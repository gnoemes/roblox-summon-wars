local RuntimeConfig = require(script.Parent.Parent.Config.Runtime)
local RealmPhases = require(script.Parent.RealmPhases)

local SystemBuilder = {}

local function buildDependencies(realm, phaseName, after)
	local dependencies = {
		RealmPhases.getAnchor(realm, phaseName),
	}

	if after == nil then
		return dependencies
	end

	assert(type(after) == "table", "SystemBuilder 'after' option must be an array")

	for _, dependency in ipairs(after) do
		table.insert(dependencies, dependency)
	end

	return dependencies
end

local function buildSystem(realm, phaseName, systemCallback, options)
	assert(type(systemCallback) == "function", "System callback must be a function")

	local phaseDefinition = RealmPhases.getDefinition(realm, phaseName)
	local after = nil

	if options ~= nil then
		assert(type(options) == "table", "SystemBuilder options must be a table")
		after = options.after
	end

	return {
		system = systemCallback,
		event = phaseDefinition.event,
		after = buildDependencies(realm, phaseName, after),
	}
end

function SystemBuilder.server(phaseName, systemCallback, options)
	return buildSystem(RuntimeConfig.Realms.Server, phaseName, systemCallback, options)
end

function SystemBuilder.client(phaseName, systemCallback, options)
	return buildSystem(RuntimeConfig.Realms.Client, phaseName, systemCallback, options)
end

return SystemBuilder
