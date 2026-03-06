local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))
local HubPetRegistry = require(script.Parent:WaitForChild("HubPetRegistry"))

local SNAPSHOT_RETRY_COUNT = 10
local SNAPSHOT_RETRY_DELAY = 0.5

local function getRemotesFolder()
	return ReplicatedStorage:WaitForChild(Remotes.FolderName, 10)
end

local function hydrateSnapshot(snapshot)
	HubPetRegistry.clear()

	if type(snapshot) ~= "table" then
		return
	end

	for userId, viewState in pairs(snapshot) do
		if type(userId) == "number" and type(viewState) == "table" then
			HubPetRegistry.upsert(userId, viewState)
		end
	end
end

local function requestInitialSnapshot()
	local remotesFolder = getRemotesFolder()
	if not remotesFolder then
		return false
	end

	local rf = remotesFolder:WaitForChild(Remotes.GetHubPetViewStates, 10)
	if not rf then
		return false
	end

	local ok, snapshot = pcall(function()
		return rf:InvokeServer()
	end)
	if ok and type(snapshot) == "table" then
		hydrateSnapshot(snapshot)
		return true
	end

	return false
end

local function attachUpdateListener()
	local remotesFolder = getRemotesFolder()
	if not remotesFolder then
		return
	end

	local event = remotesFolder:WaitForChild(Remotes.HubPetViewStateUpdated, 10)
	if not event then
		return
	end

	event.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end

		if payload.action == "upsert" and type(payload.userId) == "number" and type(payload.viewState) == "table" then
			HubPetRegistry.upsert(payload.userId, payload.viewState)
		elseif payload.action == "remove" and type(payload.userId) == "number" then
			HubPetRegistry.remove(payload.userId)
		end
	end)
end

attachUpdateListener()

task.spawn(function()
	for _ = 1, SNAPSHOT_RETRY_COUNT do
		if requestInitialSnapshot() then
			return
		end

		task.wait(SNAPSHOT_RETRY_DELAY)
	end
end)
