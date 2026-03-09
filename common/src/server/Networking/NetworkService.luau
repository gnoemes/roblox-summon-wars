local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RuntimeConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Runtime"))

local NetworkService = {}
NetworkService.__index = NetworkService

local function ensureChild(parent, className, name)
	local child = parent:FindFirstChild(name)

	if child == nil then
		child = Instance.new(className)
		child.Name = name
		child.Parent = parent
	else
		assert(
			child.ClassName == className,
			`{child:GetFullName()} is expected to be a {className}`
		)
	end

	return child
end

local function splitNamespace(namespacePath)
	assert(
		type(namespacePath) == "string" and namespacePath ~= "",
		"Namespace path must be a non-empty string"
	)

	local segments = {}

	for _, segment in ipairs(string.split(namespacePath, "/")) do
		assert(segment ~= "", "Namespace path cannot contain empty segments")
		table.insert(segments, segment)
	end

	return segments
end

function NetworkService.new(rootFolderName)
	local folderName = rootFolderName or RuntimeConfig.Networking.RootFolderName
	local rootFolder = ensureChild(ReplicatedStorage, "Folder", folderName)

	return setmetatable({
		_rootFolder = rootFolder,
	}, NetworkService)
end

function NetworkService:getRootFolder()
	return self._rootFolder
end

function NetworkService:getNamespace(namespacePath)
	local folder = self._rootFolder

	for _, segment in ipairs(splitNamespace(namespacePath)) do
		folder = ensureChild(folder, "Folder", segment)
	end

	return folder
end

function NetworkService:ensureRemoteEvent(namespacePath, remoteName)
	local namespace = self:getNamespace(namespacePath)

	return ensureChild(namespace, "RemoteEvent", remoteName)
end

function NetworkService:ensureRemoteFunction(namespacePath, remoteName)
	local namespace = self:getNamespace(namespacePath)

	return ensureChild(namespace, "RemoteFunction", remoteName)
end

return NetworkService
