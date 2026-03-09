local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RuntimeConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Runtime"))

local NetworkClient = {}
NetworkClient.__index = NetworkClient

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

function NetworkClient.new(rootFolderName)
	local folderName = rootFolderName or RuntimeConfig.Networking.RootFolderName

	return setmetatable({
		_rootFolder = ReplicatedStorage:WaitForChild(folderName),
	}, NetworkClient)
end

function NetworkClient:getRootFolder()
	return self._rootFolder
end

function NetworkClient:getNamespace(namespacePath)
	local folder = self._rootFolder

	for _, segment in ipairs(splitNamespace(namespacePath)) do
		folder = folder:WaitForChild(segment)
	end

	return folder
end

function NetworkClient:getRemoteEvent(namespacePath, remoteName)
	return self:getNamespace(namespacePath):WaitForChild(remoteName)
end

function NetworkClient:getRemoteFunction(namespacePath, remoteName)
	return self:getNamespace(namespacePath):WaitForChild(remoteName)
end

return NetworkClient
