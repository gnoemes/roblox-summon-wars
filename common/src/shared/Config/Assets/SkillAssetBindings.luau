local Registry = require(script.Parent.Parent.Registry)
local SkillAssetBindingDefinition = require(script.Parent.SkillAssetBindingDefinition)

local definitions = require(script.Parent:WaitForChild("SkillAssetEntries"))

return Registry.create(
	"SkillAssetBindings",
	definitions,
	"skillId",
	SkillAssetBindingDefinition.assert
)
