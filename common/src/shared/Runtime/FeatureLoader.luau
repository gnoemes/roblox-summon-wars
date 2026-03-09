local FeatureLoader = {}

local function assertOptionalFunction(definition, featureId, key)
	local value = definition[key]

	if value ~= nil and type(value) ~= "function" then
		error(`Feature "{featureId}" field "{key}" must be a function`, 3)
	end
end

local function validateDefinition(definition, featureId)
	if type(definition) ~= "table" then
		error(`Feature "{featureId}" must return a table`, 3)
	end

	assertOptionalFunction(definition, featureId, "registerServices")
	assertOptionalFunction(definition, featureId, "initialize")
	assertOptionalFunction(definition, featureId, "start")
	assertOptionalFunction(definition, featureId, "stop")

	local systems = definition.systems

	if systems ~= nil and type(systems) ~= "function" and type(systems) ~= "table" then
		error(`Feature "{featureId}" field "systems" must be a function or array`, 3)
	end
end

function FeatureLoader.loadFolder(folder, entryModuleName)
	if folder == nil then
		return {}
	end

	assert(typeof(folder) == "Instance", "Feature folder must be a Roblox instance")
	assert(
		type(entryModuleName) == "string" and entryModuleName ~= "",
		"Entry module name is required"
	)

	local featureFolders = {}
	local seenIds = {}
	local features = {}

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Folder") then
			table.insert(featureFolders, child)
		end
	end

	table.sort(featureFolders, function(left, right)
		return left.Name < right.Name
	end)

	for _, featureFolder in ipairs(featureFolders) do
		local moduleScript = featureFolder:FindFirstChild(entryModuleName)

		if moduleScript ~= nil then
			assert(
				moduleScript:IsA("ModuleScript"),
				`{featureFolder.Name}/{entryModuleName} must be a ModuleScript`
			)

			local definition = require(moduleScript)
			local featureId = definition.id or featureFolder.Name

			assert(
				type(featureId) == "string" and featureId ~= "",
				"Feature id must be a non-empty string"
			)
			assert(seenIds[featureId] == nil, `Feature "{featureId}" is declared more than once`)

			validateDefinition(definition, featureId)

			seenIds[featureId] = true

			table.insert(features, {
				id = featureId,
				folder = featureFolder,
				module = moduleScript,
				definition = definition,
			})
		end
	end

	return features
end

return FeatureLoader
