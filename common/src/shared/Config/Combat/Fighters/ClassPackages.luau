local ContentLoader = require(script.Parent.Parent.ContentLoader)
local ClassDefinition = require(script.Parent:WaitForChild("ClassDefinition"))

local function assertClassPackage(value, fieldName)
	assert(type(value) == "table", string.format("%s must be a table", fieldName))
	ClassDefinition.assert(value.class, string.format("%s.class", fieldName))
	assert(
		type(value.skillPool) == "table",
		string.format("%s.skillPool must be an array", fieldName)
	)

	for index, skillDefinition in ipairs(value.skillPool) do
		assert(
			type(skillDefinition) == "table",
			string.format("%s.skillPool[%d] must be a table", fieldName, index)
		)
	end
	return value
end

local rawPackages = {}
for _, package in ipairs(ContentLoader.requireModuleChildren(script.Parent:WaitForChild("Classes"))) do
	assertClassPackage(package, "ClassPackages.entry")
	local classId = package.class.classId
	assert(rawPackages[classId] == nil, string.format("Duplicate class package %s", classId))
	rawPackages[classId] = package
end

local orderedPackages = {}
for classId, package in pairs(rawPackages) do
	table.insert(
		orderedPackages,
		table.freeze({
			classId = classId,
			package = package,
		})
	)
end

table.sort(orderedPackages, function(left, right)
	return left.classId < right.classId
end)

local frozenPackages = table.freeze(rawPackages)

local api = {}

function api.has(classId)
	return type(classId) == "string" and frozenPackages[classId] ~= nil
end

function api.get(classId)
	return frozenPackages[classId]
end

function api.list()
	local packages = {}
	for _, entry in ipairs(orderedPackages) do
		table.insert(packages, entry.package)
	end
	return table.freeze(packages)
end

function api.entries()
	return frozenPackages
end

return table.freeze(api)
