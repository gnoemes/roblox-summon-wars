local ContentLoader = {}

local function sortedChildren(container, predicate)
	local children = {}

	for _, child in ipairs(container:GetChildren()) do
		if predicate(child) then
			table.insert(children, child)
		end
	end

	table.sort(children, function(left, right)
		return left.Name < right.Name
	end)

	return children
end

function ContentLoader.getSortedModuleChildren(container)
	return sortedChildren(container, function(child)
		return child:IsA("ModuleScript")
	end)
end

function ContentLoader.getSortedFolders(container)
	return sortedChildren(container, function(child)
		return child:IsA("Folder")
	end)
end

function ContentLoader.requireModuleChildren(container)
	local required = {}

	for _, moduleScript in ipairs(ContentLoader.getSortedModuleChildren(container)) do
		table.insert(required, require(moduleScript))
	end

	return required
end

function ContentLoader.requireRegionChildModules(regionsFolder, childFolderName)
	local required = {}

	for _, regionFolder in ipairs(ContentLoader.getSortedFolders(regionsFolder)) do
		local childFolder = regionFolder:FindFirstChild(childFolderName)
		if childFolder ~= nil then
			for _, moduleScript in ipairs(ContentLoader.getSortedModuleChildren(childFolder)) do
				table.insert(required, require(moduleScript))
			end
		end
	end

	return required
end

function ContentLoader.collectDefinitions(entries, idFieldName)
	local definitions = {}

	for _, entry in ipairs(entries) do
		assert(type(entry) == "table", "Definition entry must be a table")
		local definitionId = entry[idFieldName]
		assert(
			type(definitionId) == "string" and definitionId ~= "",
			string.format("Definition is missing id field %s", idFieldName)
		)
		assert(
			definitions[definitionId] == nil,
			string.format("Duplicate definition id %s", definitionId)
		)
		definitions[definitionId] = entry
	end

	return definitions
end

function ContentLoader.flattenArrays(arrays)
	local flattened = {}

	for _, arrayValue in ipairs(arrays) do
		assert(type(arrayValue) == "table", "Expected an array to flatten")
		for _, entry in ipairs(arrayValue) do
			table.insert(flattened, entry)
		end
	end

	return flattened
end

return ContentLoader
