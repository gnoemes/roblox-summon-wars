local ClientFighters =
	require(script.Parent.Parent.Parent:WaitForChild("ClientShared"):WaitForChild("Fighters"))
local FighterRuntimeController = require(script.Parent:WaitForChild("FighterRuntimeController"))

local FighterRosterClient = ClientFighters.FighterRosterClient

return {
	id = "FighterRuntime",

	registerServices = function(context)
		context.services:register(
			"FighterRosterClient",
			FighterRosterClient.new({
				network = context.services:get("Network"),
				snapshotClient = context.services:get("SnapshotClient"),
			})
		)
	end,

	start = function(context)
		local controller = FighterRuntimeController.new({
			fighterRosterClient = context.services:get("FighterRosterClient"),
			debugClient = context.services:get("DebugClient"),
		})
		controller:start()
		context.cleaner:add(controller)
	end,
}
