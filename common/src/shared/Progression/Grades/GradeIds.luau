local GradeDefinitions = require(script.Parent.GradeDefinitions)

local values = {}
local lookup = {}

for _, definition in ipairs(GradeDefinitions.list()) do
	table.insert(values, definition.gradeId)
	lookup[definition.gradeId] = true
end

return table.freeze({
	Values = table.freeze(values),
	Lookup = table.freeze(lookup),
})
