local Registry = require(script.Parent.Parent.Registry)
local ContentLoader = require(script.Parent.ContentLoader)
local DropTableDefinition = require(script.Parent.DropTableDefinition)

local definitions = {}

local function insertDefinition(definitionId, definition, registryName)
	assert(
		type(definitionId) == "string" and definitionId ~= "",
		string.format("%s is missing its id", registryName)
	)
	assert(
		definitions[definitionId] == nil,
		string.format("Duplicate %s %s", registryName, definitionId)
	)
	definitions[definitionId] = definition
end

local commonFolder = script.Parent:WaitForChild("Common")
for _, dropTable in
	ipairs(
		ContentLoader.flattenArrays(
			ContentLoader.requireModuleChildren(commonFolder:WaitForChild("Drops"))
		)
	)
do
	insertDefinition(dropTable.dropTableId, dropTable, "drop table")
end

local regionsFolder = script.Parent:WaitForChild("Regions")
for _, dropTable in
	ipairs(
		ContentLoader.flattenArrays(ContentLoader.requireRegionChildModules(regionsFolder, "Drops"))
	)
do
	insertDefinition(dropTable.dropTableId, dropTable, "drop table")
end

return Registry.create("DropTables", definitions, "dropTableId", DropTableDefinition.assert)
