local Registry = require(script.Parent.Parent.Parent.Config.Registry)
local GradeDefinition = require(script.Parent.GradeDefinition)

local rawDefinitions = {
	Common = GradeDefinition.new({
		gradeId = "Common",
		displayName = "Common",
		sortOrder = 1,
		color = Color3.fromRGB(244, 247, 255),
	}),
	Uncommon = GradeDefinition.new({
		gradeId = "Uncommon",
		displayName = "Uncommon",
		sortOrder = 2,
		color = Color3.fromRGB(123, 216, 143),
	}),
	Rare = GradeDefinition.new({
		gradeId = "Rare",
		displayName = "Rare",
		sortOrder = 3,
		color = Color3.fromRGB(91, 157, 255),
	}),
	Epic = GradeDefinition.new({
		gradeId = "Epic",
		displayName = "Epic",
		sortOrder = 4,
		color = Color3.fromRGB(199, 146, 234),
	}),
	Legendary = GradeDefinition.new({
		gradeId = "Legendary",
		displayName = "Legendary",
		sortOrder = 5,
		color = Color3.fromRGB(246, 193, 119),
	}),
}

local registry =
	Registry.create("GradeDefinitions", rawDefinitions, "gradeId", GradeDefinition.assert)
local orderedDefinitions = {}

for _, definition in pairs(registry.entries()) do
	table.insert(orderedDefinitions, definition)
end

table.sort(orderedDefinitions, function(left, right)
	if left.sortOrder == right.sortOrder then
		return left.gradeId < right.gradeId
	end

	return left.sortOrder < right.sortOrder
end)

orderedDefinitions = table.freeze(orderedDefinitions)

local api = {}

function api.has(gradeId)
	return registry.has(gradeId)
end

function api.get(gradeId)
	return registry.get(gradeId)
end

function api.list()
	return orderedDefinitions
end

function api.entries()
	return registry.entries()
end

return table.freeze(api)
