local Contract = require(script.Parent.Parent.Parent.Utils.Contract)

export type GradeDefinition = {
	gradeId: string,
	displayName: string,
	sortOrder: number,
	color: Color3,
}

local GradeDefinition = {}

function GradeDefinition.assert(value, fieldName)
	fieldName = fieldName or "GradeDefinition"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.gradeId, string.format("%s.gradeId", fieldName))
	Contract.assertString(value.displayName, string.format("%s.displayName", fieldName))
	Contract.assertPositiveInteger(value.sortOrder, string.format("%s.sortOrder", fieldName))
	Contract.assertColor3(value.color, string.format("%s.color", fieldName))

	return value
end

function GradeDefinition.new(data)
	GradeDefinition.assert(data)

	return table.freeze(data)
end

return GradeDefinition