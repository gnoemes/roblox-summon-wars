local Contract = require(script.Parent.Parent.Parent.Utils.Contract)

export type SkillAssetBindingDefinition = {
	skillId: string,
	iconAssetId: string | number?,
}

local SkillAssetBindingDefinition = {}

function SkillAssetBindingDefinition.assert(value, fieldName)
	fieldName = fieldName or "SkillAssetBindingDefinition"
	Contract.assertTable(value, fieldName)
	Contract.assertString(value.skillId, string.format("%s.skillId", fieldName))
	Contract.assertOptionalAssetId(value.iconAssetId, string.format("%s.iconAssetId", fieldName))

	return value
end

function SkillAssetBindingDefinition.new(data)
	SkillAssetBindingDefinition.assert(data)

	return table.freeze(data)
end

return SkillAssetBindingDefinition
