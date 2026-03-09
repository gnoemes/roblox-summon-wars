local Registry = require(script.Parent.Parent.Registry)
local StatusAssetBindingDefinition = require(script.Parent.StatusAssetBindingDefinition)

local definitions = require(script.Parent:WaitForChild("StatusAssetEntries"))

return Registry.create(
	"StatusAssetBindings",
	definitions,
	"statusId",
	StatusAssetBindingDefinition.assert
)
