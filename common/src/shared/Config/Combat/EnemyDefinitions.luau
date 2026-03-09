local Registry = require(script.Parent.Parent.Registry)
local ContentLoader = require(script.Parent.ContentLoader)
local EnemyDefinition = require(script.Parent.EnemyDefinition)

local definitions = {}

local function insertDefinition(definitionId, definition, registryName)
	assert(
		definitions[definitionId] == nil,
		string.format("Duplicate %s %s", registryName, definitionId)
	)
	definitions[definitionId] = definition
end

local regionsFolder = script.Parent:WaitForChild("Regions")
for _, enemyDefinition in ipairs(ContentLoader.requireRegionChildModules(regionsFolder, "Enemies")) do
	insertDefinition(enemyDefinition.enemyId, enemyDefinition, "enemy definition")
end

return Registry.create("EnemyDefinitions", definitions, "enemyId", EnemyDefinition.assert)
