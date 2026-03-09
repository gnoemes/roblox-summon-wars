local DropTableDefinition = require(script.Parent.Parent.Parent:WaitForChild("DropTableDefinition"))

return table.freeze({
	DropTableDefinition.new({
		dropTableId = "Drop.None",
		guaranteedEntries = {},
		weightedEntries = {},
		rolls = 0,
	}),
})
