local RunService = game:GetService("RunService")

local ServerCombat =
	require(script.Parent.Parent.Parent:WaitForChild("ServerShared"):WaitForChild("Combat"))

local CombatSandboxService = ServerCombat.CombatSandboxService

return {
	id = "CombatSandbox",

	registerServices = function(context)
		if not RunService:IsStudio() then
			return
		end

		context.services:register(
			"CombatSandboxService",
			CombatSandboxService.new({
				snapshotService = context.services:get("SnapshotService"),
				debugService = context.services:get("DebugService"),
				stateStore = context.stateStore,
			})
		)
	end,

	start = function(context)
		if not RunService:IsStudio() then
			return
		end

		local service = context.services:getOptional("CombatSandboxService")
		if service == nil then
			return
		end

		service:start(context.services:get("CombatEncounterService"))
		context.cleaner:add(service)
	end,
}
