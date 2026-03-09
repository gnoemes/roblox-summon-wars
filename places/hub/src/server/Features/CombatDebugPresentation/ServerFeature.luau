local ServerCombat =
	require(script.Parent.Parent.Parent:WaitForChild("ServerShared"):WaitForChild("Combat"))

local CombatDebugViewService = ServerCombat.CombatDebugViewService
local CombatDebugViewSystems = ServerCombat.CombatDebugViewSystems

return {
	id = "CombatDebugPresentation",

	registerServices = function(context)
		local service = CombatDebugViewService.new()
		context.cleaner:add(service)
		context.services:register("CombatDebugViewService", service)
	end,

	systems = function()
		return CombatDebugViewSystems.getSystems()
	end,
}
