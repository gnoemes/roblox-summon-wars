local Contract = {}

local function formatFieldName(fieldName)
	if fieldName == nil or fieldName == "" then
		return "value"
	end

	return fieldName
end

function Contract.assertTable(value, fieldName)
	assert(type(value) == "table", string.format("%s must be a table", formatFieldName(fieldName)))

	return value
end

function Contract.assertString(value, fieldName)
	assert(
		type(value) == "string" and value ~= "",
		string.format("%s must be a non-empty string", formatFieldName(fieldName))
	)

	return value
end

function Contract.assertOptionalString(value, fieldName)
	if value ~= nil then
		Contract.assertString(value, fieldName)
	end

	return value
end

function Contract.assertBoolean(value, fieldName)
	assert(
		type(value) == "boolean",
		string.format("%s must be a boolean", formatFieldName(fieldName))
	)

	return value
end

function Contract.assertColor3(value, fieldName)
	assert(
		typeof(value) == "Color3",
		string.format("%s must be a Color3", formatFieldName(fieldName))
	)

	return value
end

function Contract.assertNumber(value, fieldName)
	assert(
		type(value) == "number",
		string.format("%s must be a number", formatFieldName(fieldName))
	)

	return value
end

function Contract.assertOptionalNumber(value, fieldName)
	if value ~= nil then
		Contract.assertNumber(value, fieldName)
	end

	return value
end

function Contract.assertNonNegativeNumber(value, fieldName)
	Contract.assertNumber(value, fieldName)
	assert(value >= 0, string.format("%s must be >= 0", formatFieldName(fieldName)))

	return value
end

function Contract.assertOptionalNonNegativeNumber(value, fieldName)
	if value ~= nil then
		Contract.assertNonNegativeNumber(value, fieldName)
	end

	return value
end

function Contract.assertPositiveNumber(value, fieldName)
	Contract.assertNumber(value, fieldName)
	assert(value > 0, string.format("%s must be > 0", formatFieldName(fieldName)))

	return value
end

function Contract.assertOptionalPositiveNumber(value, fieldName)
	if value ~= nil then
		Contract.assertPositiveNumber(value, fieldName)
	end

	return value
end

function Contract.assertInteger(value, fieldName)
	Contract.assertNumber(value, fieldName)
	assert(value % 1 == 0, string.format("%s must be an integer", formatFieldName(fieldName)))

	return value
end

function Contract.assertPositiveInteger(value, fieldName)
	Contract.assertInteger(value, fieldName)
	assert(value > 0, string.format("%s must be > 0", formatFieldName(fieldName)))

	return value
end

function Contract.assertArray(value, fieldName)
	Contract.assertTable(value, fieldName)

	for key in pairs(value) do
		assert(
			type(key) == "number" and key % 1 == 0 and key >= 1,
			string.format("%s must be an array", formatFieldName(fieldName))
		)
	end

	return value
end

function Contract.assertStringArray(value, fieldName)
	Contract.assertArray(value, fieldName)

	for index, entry in ipairs(value) do
		Contract.assertString(entry, string.format("%s[%d]", formatFieldName(fieldName), index))
	end

	return value
end

function Contract.assertDictionary(value, fieldName)
	Contract.assertTable(value, fieldName)

	for key in pairs(value) do
		assert(
			type(key) == "string" and key ~= "",
			string.format("%s must use non-empty string keys", formatFieldName(fieldName))
		)
	end

	return value
end

function Contract.assertStringNumberDictionary(value, fieldName)
	Contract.assertDictionary(value, fieldName)

	for key, entryValue in pairs(value) do
		Contract.assertNonNegativeNumber(
			entryValue,
			string.format("%s.%s", formatFieldName(fieldName), key)
		)
	end

	return value
end

function Contract.assertStringIntegerDictionary(value, fieldName)
	Contract.assertDictionary(value, fieldName)

	for key, entryValue in pairs(value) do
		Contract.assertInteger(entryValue, string.format("%s.%s", formatFieldName(fieldName), key))
		assert(
			entryValue >= 0,
			string.format("%s.%s must be >= 0", formatFieldName(fieldName), key)
		)
	end

	return value
end

function Contract.assertEnumValue(value, enumDefinition, fieldName)
	Contract.assertString(value, fieldName)
	assert(
		type(enumDefinition) == "table" and type(enumDefinition.Lookup) == "table",
		"Invalid enum definition"
	)
	assert(
		enumDefinition.Lookup[value] == true,
		string.format("%s must be one of the declared enum values", formatFieldName(fieldName))
	)

	return value
end

function Contract.assertOptionalEnumValue(value, enumDefinition, fieldName)
	if value ~= nil then
		Contract.assertEnumValue(value, enumDefinition, fieldName)
	end

	return value
end

return Contract
