local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileDocument = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("ProfileDocument")
)

local MemoryPlayerDataRepository = {}
MemoryPlayerDataRepository.__index = MemoryPlayerDataRepository

function MemoryPlayerDataRepository.new(config)
	config = config or {}

	return setmetatable({
		_documents = {},
		_now = config.now or os.time,
	}, MemoryPlayerDataRepository)
end

function MemoryPlayerDataRepository:loadProfile(userId)
	local document = self._documents[userId]

	return ProfileDocument.reconcile(document, userId, self._now())
end

function MemoryPlayerDataRepository:saveProfile(userId, document)
	local persistedDocument =
		ProfileDocument.reconcile(ProfileDocument.clone(document), userId, self._now())
	self._documents[userId] = persistedDocument

	return ProfileDocument.clone(persistedDocument)
end

function MemoryPlayerDataRepository:getStoredUserIds()
	local userIds = {}

	for userId in pairs(self._documents) do
		table.insert(userIds, userId)
	end

	table.sort(userIds)

	return userIds
end

return MemoryPlayerDataRepository
