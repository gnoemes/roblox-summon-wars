local Bootstrap = require(script.Parent:WaitForChild("Bootstrap"))

local runtime = Bootstrap.start()

script.Destroying:Connect(function()
	runtime:stop()
end)
