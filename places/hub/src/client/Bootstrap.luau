local ClientRuntime = require(
	script.Parent:WaitForChild("ClientShared"):WaitForChild("Runtime"):WaitForChild("ClientRuntime")
)

local Bootstrap = {}

function Bootstrap.start()
	local runtime = ClientRuntime.new({
		placeId = "hub",
		root = script.Parent,
		featuresFolder = script.Parent:FindFirstChild("Features"),
	})

	runtime:start()

	return runtime
end

return Bootstrap
