local RunService = game:GetService("RunService")

local SandboxController = require(script.Parent:WaitForChild("SandboxController"))

return {
	id = "CombatSandbox",

	start = function(context)
		if not RunService:IsStudio() then
			return
		end

		local controller = SandboxController.new({
			snapshotClient = context.services:get("SnapshotClient"),
			debugClient = context.services:get("DebugClient"),
		})
		controller:start()
		context.cleaner:add(controller)
	end,
}
