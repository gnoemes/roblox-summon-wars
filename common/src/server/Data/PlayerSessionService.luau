local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileDocument = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("ProfileDocument")
)
local ProfileReadModel = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("ProfileReadModel")
)
local ReplicationTopics = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("Topics")
)
local Cleaner =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Cleaner"))

local PlayerSessionService = {}
PlayerSessionService.__index = PlayerSessionService

local function getPlayerKey(player)
	return player.UserId
end

function PlayerSessionService.new(config)
	assert(type(config) == "table", "PlayerSessionService config must be a table")
	assert(config.repository ~= nil, "PlayerSessionService requires repository")
	assert(config.snapshotService ~= nil, "PlayerSessionService requires snapshot service")
	assert(config.debugService ~= nil, "PlayerSessionService requires debug service")
	assert(config.stateStore ~= nil, "PlayerSessionService requires state store")

	local sessionsByUserId = {}
	config.stateStore:set("PlayerSessions", sessionsByUserId)

	return setmetatable({
		_repository = config.repository,
		_snapshotService = config.snapshotService,
		_debugService = config.debugService,
		_stateStore = config.stateStore,
		_sessionsByPlayer = {},
		_sessionsByUserId = sessionsByUserId,
		_cleaner = Cleaner.new(),
		_now = config.now or os.time,
	}, PlayerSessionService)
end

function PlayerSessionService:_buildDebugSummary()
	local sessions = {}

	for userId, session in pairs(self._sessionsByUserId) do
		table.insert(sessions, {
			userId = userId,
			dirty = session.isDirty,
			revision = session.document.meta.profileRevision,
			wallets = ProfileReadModel.fromDocument(session.document).wallets,
			resources = ProfileReadModel.fromDocument(session.document).resources,
		})
	end

	table.sort(sessions, function(left, right)
		return left.userId < right.userId
	end)

	return {
		count = #sessions,
		sessions = sessions,
		storedProfiles = self._repository:getStoredUserIds(),
	}
end

function PlayerSessionService:_publishProfile(player)
	self._snapshotService:publishRegisteredTopic(player, ReplicationTopics.Profile)
end

function PlayerSessionService:_loadPlayer(player)
	local document = self._repository:loadProfile(getPlayerKey(player))
	local session = {
		player = player,
		document = document,
		loadedAt = self._now(),
		isDirty = false,
	}

	self._sessionsByPlayer[player] = session
	self._sessionsByUserId[getPlayerKey(player)] = session
	self:_publishProfile(player)

	return session
end

function PlayerSessionService:_saveSession(session)
	self._repository:saveProfile(session.player.UserId, session.document)
	session.isDirty = false
end

function PlayerSessionService:_saveAndReleasePlayer(player)
	local session = self._sessionsByPlayer[player]
	if session == nil then
		return
	end

	self:_saveSession(session)
	self._sessionsByPlayer[player] = nil
	self._sessionsByUserId[getPlayerKey(player)] = nil
end

function PlayerSessionService:start()
	self._snapshotService:registerTopic(ReplicationTopics.Profile, function(player)
		local session = self:getOptionalSession(player)
		if session == nil then
			return nil
		end

		return ProfileReadModel.fromDocument(session.document),
			session.document.meta.profileRevision,
			"replace"
	end)

	self._debugService:registerView("Runtime", "PlayerSessions", function()
		return self:_buildDebugSummary()
	end)

	self._debugService:registerAction("Runtime", "SaveAllProfiles", function()
		return {
			savedCount = self:saveAll(),
		}
	end)

	self._cleaner:add(Players.PlayerAdded:Connect(function(player)
		self:_loadPlayer(player)
	end))

	self._cleaner:add(Players.PlayerRemoving:Connect(function(player)
		self:_saveAndReleasePlayer(player)
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		self:_loadPlayer(player)
	end
end

function PlayerSessionService:getOptionalSession(player)
	return self._sessionsByPlayer[player]
end

function PlayerSessionService:getSession(player)
	local session = self:getOptionalSession(player)
	assert(session ~= nil, `No session is loaded for player {player.Name}`)

	return session
end

function PlayerSessionService:readProfile(player)
	return ProfileDocument.clone(self:getSession(player).document)
end

function PlayerSessionService:mutate(player, reason, mutator)
	assert(type(mutator) == "function", "PlayerSessionService mutator must be a function")

	local session = self:getSession(player)
	mutator(session.document)
	ProfileDocument.touch(session.document, self._now())
	ProfileDocument.appendEconomyEntry(session.document, {
		at = self._now(),
		revision = session.document.meta.profileRevision,
		bucket = "mutations",
		key = reason or "unspecified",
		delta = 0,
		balance = 0,
		reason = reason or "unspecified",
	})
	session.isDirty = true
	self:_publishProfile(player)

	return ProfileDocument.clone(session.document)
end

function PlayerSessionService:adjustWallet(player, walletId, delta, reason)
	local session = self:getSession(player)
	local balance, revision = ProfileDocument.adjustCounter(
		session.document,
		"wallets",
		walletId,
		delta,
		reason,
		self._now()
	)

	session.isDirty = true
	self:_publishProfile(player)

	return balance, revision
end

function PlayerSessionService:adjustResource(player, resourceId, delta, reason)
	local session = self:getSession(player)
	local balance, revision = ProfileDocument.adjustCounter(
		session.document,
		"resources",
		resourceId,
		delta,
		reason,
		self._now()
	)

	session.isDirty = true
	self:_publishProfile(player)

	return balance, revision
end

function PlayerSessionService:savePlayer(player)
	local session = self:getOptionalSession(player)
	if session == nil then
		return false
	end

	self:_saveSession(session)
	return true
end

function PlayerSessionService:saveAll()
	local savedCount = 0

	for _, session in pairs(self._sessionsByPlayer) do
		self:_saveSession(session)
		savedCount += 1
	end

	return savedCount
end

function PlayerSessionService:stop()
	self:saveAll()
	self._cleaner:clean()
end

return PlayerSessionService
