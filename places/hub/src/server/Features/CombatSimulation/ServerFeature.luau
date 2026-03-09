local ServerCombat =
	require(script.Parent.Parent.Parent:WaitForChild("ServerShared"):WaitForChild("Combat"))

local CombatSystems = ServerCombat.CombatSystems
local CombatEncounterService = ServerCombat.CombatEncounterService

return {
	id = "CombatSimulation",

	registerServices = function(context)
		context.services:register(
			"CombatEncounterService",
			CombatEncounterService.new({
				world = context.world,
				stateStore = context.stateStore,
				debugService = context.services:get("DebugService"),
			})
		)
	end,

	start = function(context)
		context.services:get("CombatEncounterService"):start()
	end,

	stop = function(context)
		context.services:get("CombatEncounterService"):stop()
	end,

	systems = function()
		return CombatSystems.getSystems()
	end,
}
