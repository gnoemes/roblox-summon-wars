local Registry = require(script.Parent.Parent.Registry)
local EnemyDefinition = require(script.Parent.EnemyDefinition)

local definitions = {}

return Registry.create("EnemyDefinitions", definitions, "enemyId", EnemyDefinition.assert)
