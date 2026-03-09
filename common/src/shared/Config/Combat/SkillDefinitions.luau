local Registry = require(script.Parent.Parent.Registry)
local ContentLoader = require(script.Parent.ContentLoader)
local SkillDefinition = require(script.Parent.SkillDefinition)
local Fighters = require(script.Parent.Fighters)

local definitions = {}

local function insertDefinition(definitionId, definition, registryName)
	assert(
		definitions[definitionId] == nil,
		string.format("Duplicate %s %s", registryName, definitionId)
	)
	definitions[definitionId] = definition
end

local commonFolder = script.Parent:WaitForChild("Common")
for _, skillDefinition in
	ipairs(ContentLoader.flattenArrays({
		ContentLoader.requireModuleChildren(commonFolder:WaitForChild("Skills")),
	}))
do
	insertDefinition(skillDefinition.skillId, skillDefinition, "skill definition")
end

for _, classPackage in ipairs(Fighters.ClassPackages.list()) do
	for _, skillDefinition in ipairs(classPackage.skillPool) do
		insertDefinition(skillDefinition.skillId, skillDefinition, "skill definition")
	end
end

local regionsFolder = script.Parent:WaitForChild("Regions")
for _, skillDefinition in
	ipairs(ContentLoader.flattenArrays({
		ContentLoader.requireRegionChildModules(regionsFolder, "Skills"),
	}))
do
	insertDefinition(skillDefinition.skillId, skillDefinition, "skill definition")
end

return Registry.create("SkillDefinitions", definitions, "skillId", SkillDefinition.assert)
