local Registry = require(script.Parent.Parent.Parent.Registry)
local ClassPackages = require(script.ClassPackages)
local ClassDefinition = require(script.ClassDefinition)

local definitions = {}
for classId, package in pairs(ClassPackages.entries()) do
	definitions[classId] = package.class
end

return Registry.create("ClassDefinitions", definitions, "classId", ClassDefinition.assert)
