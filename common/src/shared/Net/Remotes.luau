local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {
	FolderName = "Remotes",
	RequestRaid = "RequestRaid",
	ReturnToHub = "ReturnToHub",
	ClearRaidSummary = "ClearRaidSummary",
	PartyDebug = "PartyDebug",
	PetDebug = "PetDebug",
	GetHubPetViewStates = "GetHubPetViewStates",
	HubPetViewStateUpdated = "HubPetViewStateUpdated",
	GetRaidPetViewStates = "GetRaidPetViewStates",
	RaidPetViewStateUpdated = "RaidPetViewStateUpdated",
}

local function getFolder(create: boolean)
	local folder = ReplicatedStorage:FindFirstChild(Remotes.FolderName)
	if not folder and create then
		folder = Instance.new("Folder")
		folder.Name = Remotes.FolderName
		folder.Parent = ReplicatedStorage
	end
	return folder
end

function Remotes.getRemoteFunction(name: string, create: boolean)
	local folder = getFolder(create)
	if not folder then
		return nil
	end

	local remote = folder:FindFirstChild(name)
	if not remote and create then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
	end

	return remote
end

function Remotes.getRemoteEvent(name: string, create: boolean)
	local folder = getFolder(create)
	if not folder then
		return nil
	end

	local remote = folder:FindFirstChild(name)
	if not remote and create then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end

	return remote
end

return Remotes
