local Contract = require(script.Parent.Parent.Utils.Contract)

local Registry = {}

local function freezeTable(value)
	if table.isfrozen(value) then
		return value
	end

	return table.freeze(value)
end

function Registry.create(registryName, rawDefinitions, idFieldName, assertDefinition)
	Contract.assertString(registryName, "registryName")
	Contract.assertDictionary(rawDefinitions, string.format("%s.rawDefinitions", registryName))
	Contract.assertString(idFieldName, string.format("%s.idFieldName", registryName))
	assert(
		type(assertDefinition) == "function",
		string.format("%s.assertDefinition must be a function", registryName)
	)

	local definitionsById = {}
	local orderedDefinitions = {}

	for definitionId, definition in pairs(rawDefinitions) do
		assertDefinition(definition, string.format("%s[%s]", registryName, definitionId))

		local declaredId = definition[idFieldName]
		Contract.assertString(
			declaredId,
			string.format("%s[%s].%s", registryName, definitionId, idFieldName)
		)
		assert(
			declaredId == definitionId,
			string.format(
				"%s[%s].%s must match the registry key",
				registryName,
				definitionId,
				idFieldName
			)
		)

		local frozenDefinition = freezeTable(definition)
		definitionsById[definitionId] = frozenDefinition
		table.insert(orderedDefinitions, frozenDefinition)
	end

	table.sort(orderedDefinitions, function(left, right)
		return left[idFieldName] < right[idFieldName]
	end)

	orderedDefinitions = freezeTable(orderedDefinitions)
	definitionsById = freezeTable(definitionsById)

	local api = {}

	function api.has(definitionId)
		return type(definitionId) == "string" and definitionsById[definitionId] ~= nil
	end

	function api.get(definitionId)
		Contract.assertString(definitionId, string.format("%s.definitionId", registryName))

		local definition = definitionsById[definitionId]
		assert(definition ~= nil, string.format("%s is missing %s", registryName, definitionId))

		return definition
	end

	function api.list()
		return orderedDefinitions
	end

	function api.entries()
		return definitionsById
	end

	return table.freeze(api)
end

return Registry
