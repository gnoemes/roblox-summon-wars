local RuntimeConfig = require(script.Parent.Parent.Config.Runtime)

local RealmPhases = {}

local definitionsByRealm = {}
local anchorsByRealm = {}

local function createPhaseAnchor(realm, phaseDefinition)
	local function anchorSystem() end

	return {
		system = anchorSystem,
		event = phaseDefinition.event,
		priority = phaseDefinition.priority,
		realm = realm,
		phase = phaseDefinition.name,
	}
end

local function buildRealmPhaseData(realm, phaseDefinitions)
	local phaseMap = {}
	local anchors = {}

	for _, phaseDefinition in ipairs(phaseDefinitions) do
		local anchor = createPhaseAnchor(realm, phaseDefinition)

		phaseMap[phaseDefinition.name] = {
			definition = phaseDefinition,
			anchor = anchor,
		}

		table.insert(anchors, anchor)
	end

	definitionsByRealm[realm] = phaseMap
	anchorsByRealm[realm] = anchors
end

buildRealmPhaseData(RuntimeConfig.Realms.Server, RuntimeConfig.ECS.ServerPhases)
buildRealmPhaseData(RuntimeConfig.Realms.Client, RuntimeConfig.ECS.ClientPhases)

function RealmPhases.getDefinition(realm, phaseName)
	local realmPhases = definitionsByRealm[realm]
	assert(realmPhases ~= nil, `Unknown realm "{realm}"`)

	local phaseData = realmPhases[phaseName]
	assert(phaseData ~= nil, `Unknown {realm} phase "{phaseName}"`)

	return phaseData.definition
end

function RealmPhases.getAnchor(realm, phaseName)
	local realmPhases = definitionsByRealm[realm]
	assert(realmPhases ~= nil, `Unknown realm "{realm}"`)

	local phaseData = realmPhases[phaseName]
	assert(phaseData ~= nil, `Unknown {realm} phase "{phaseName}"`)

	return phaseData.anchor
end

function RealmPhases.getAnchors(realm)
	local anchors = anchorsByRealm[realm]
	assert(anchors ~= nil, `Unknown realm "{realm}"`)

	return table.clone(anchors)
end

function RealmPhases.prepareSystems(realm, systems)
	local scheduledSystems = RealmPhases.getAnchors(realm)

	for _, system in ipairs(systems) do
		table.insert(scheduledSystems, system)
	end

	return scheduledSystems
end

return RealmPhases
