local RunService = game:GetService("RunService")

local Overlay = require(script.Parent:WaitForChild("Overlay"))

return {
	id = "CombatDebugOverlay",

	start = function(context)
		if not RunService:IsStudio() then
			return
		end

		local overlay = Overlay.new({
			debugClient = context.services:get("DebugClient"),
		})
		overlay:start()
		context.cleaner:add(overlay)
	end,
}
