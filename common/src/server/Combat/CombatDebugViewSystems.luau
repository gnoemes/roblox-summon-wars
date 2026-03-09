local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ECS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ECS"))
local Components = require(script.Parent:WaitForChild("CombatComponents"))

local CombatDebugViewSystems = {}

local function sortRecords(left, right)
	if left.combatant.kind ~= right.combatant.kind then
		return left.combatant.kind < right.combatant.kind
	end

	if left.combatant.order ~= right.combatant.order then
		return left.combatant.order < right.combatant.order
	end

	return left.combatant.combatantId < right.combatant.combatantId
end

local syncCombatDebugViewsSystem = ECS.SystemBuilder.server("Replication", function(world, context)
	local service = context.services:get("CombatDebugViewService")
	service:beginFrame()

	local encountersById = {}
	for _, encounter in world:query(Components.Encounter) do
		encountersById[encounter.encounterId] = {
			encounter = encounter,
			records = {},
		}
	end

	for _, combatant, runtimeState in world:query(Components.Combatant, Components.CombatantRuntime) do
		local bundle = encountersById[combatant.encounterId]
		if bundle ~= nil then
			table.insert(bundle.records, {
				combatant = combatant,
				runtimeState = runtimeState,
			})
		end
	end

	for _, bundle in pairs(encountersById) do
		table.sort(bundle.records, sortRecords)
		service:presentEncounter(bundle.encounter, bundle.records)
	end

	service:endFrame()
end)

function CombatDebugViewSystems.getSystems()
	return {
		syncCombatDebugViewsSystem,
	}
end

return CombatDebugViewSystems
