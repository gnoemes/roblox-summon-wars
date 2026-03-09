local Registry = require(script.Parent.Parent.Registry)
local DropTableDefinition = require(script.Parent.DropTableDefinition)

local definitions = {
	["Drop.None"] = DropTableDefinition.new({
		dropTableId = "Drop.None",
		guaranteedEntries = {},
		weightedEntries = {},
		rolls = 0,
	}),
}

return Registry.create("DropTables", definitions, "dropTableId", DropTableDefinition.assert)
