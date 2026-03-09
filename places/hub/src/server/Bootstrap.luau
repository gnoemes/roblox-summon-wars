local ServerRuntime = require(
	script.Parent:WaitForChild("ServerShared"):WaitForChild("Runtime"):WaitForChild("ServerRuntime")
)

local Bootstrap = {}

function Bootstrap.start()
	local runtime = ServerRuntime.new({
		placeId = "hub",
		root = script.Parent,
		featuresFolder = script.Parent:FindFirstChild("Features"),
	})

	runtime:start()

	return runtime
end

return Bootstrap
