local Bootstrap = require(script.Parent:WaitForChild("Bootstrap"))

local runtime = Bootstrap.start()

game:BindToClose(function()
	runtime:stop()
end)
