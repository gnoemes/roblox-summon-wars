local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))
local FighterDocument = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("FighterDocument")
)
local FighterRosterReadModel = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Data")
		:WaitForChild("FighterRosterReadModel")
)
local ReplicationTopics = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("Topics")
)
local Fighters = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Fighters"))
local RuntimeConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Runtime"))
local Cleaner =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Cleaner"))
local StarterFighterTemplates = require(script.Parent:WaitForChild("StarterFighterTemplates"))

local CombatStatsBuilder = CombatConfig.Fighters.CombatStatsBuilder
local FighterProjector = Fighters.FighterProjector
local FighterComparison = Fighters.FighterComparison

local FighterRosterService = {}
FighterRosterService.__index = FighterRosterService

local function buildStarterFighterDocument(player, index, template, nowUnix)
	return FighterDocument.new({
		fighterId = string.format("Fighter:%d:%02d", player.UserId, index),
		classId = template.classId,
		grade = template.grade,
		level = template.level,
		experience = 0,
		ascensionExperience = 0,
		baseStats = CombatStatsBuilder.buildBaseStats(template.classId),
		specialSkillId = template.specialSkillId,
		activeSkillIds = table.freeze(table.clone(template.activeSkillIds)),
		traitId = template.traitId,
		subclassId = template.subclassId,
		sourceTag = template.sourceTag,
		createdAt = nowUnix,
	})
end

function FighterRosterService.new(config)
	assert(type(config) == "table", "FighterRosterService config must be a table")
	assert(config.playerSessionService ~= nil, "FighterRosterService requires PlayerSessionService")
	assert(config.snapshotService ~= nil, "FighterRosterService requires SnapshotService")
	assert(config.debugService ~= nil, "FighterRosterService requires DebugService")
	assert(config.network ~= nil, "FighterRosterService requires Network service")

	return setmetatable({
		_playerSessionService = config.playerSessionService,
		_snapshotService = config.snapshotService,
		_debugService = config.debugService,
		_network = config.network,
		_now = config.now or os.time,
		_cleaner = Cleaner.new(),
		_pendingEnsureByUserId = {},
	}, FighterRosterService)
end

function FighterRosterService:_publish(player)
	self._snapshotService:publishRegisteredTopic(player, ReplicationTopics.Fighters)
end

function FighterRosterService:_buildReadModel(player)
	local profile = self._playerSessionService:readProfile(player)
	return FighterRosterReadModel.fromProfileDocument(profile)
end

function FighterRosterService:_seedStarterRoster(player)
	local nowUnix = self._now()
	local didSeed = false

	self._playerSessionService:mutate(player, "fighters.starter_seed", function(draft)
		local roster = draft.fighters
		if #roster.rosterOrder > 0 then
			if roster.starterSeedVersion < StarterFighterTemplates.CurrentSeedVersion then
				roster.starterSeedVersion = StarterFighterTemplates.CurrentSeedVersion
			end
			if roster.rosterCapacity < StarterFighterTemplates.RosterCapacity then
				roster.rosterCapacity = StarterFighterTemplates.RosterCapacity
			end
			return
		end

		roster.byId = {}
		roster.rosterOrder = {}
		roster.activeTrioFighterIds = {}
		roster.rosterCapacity = StarterFighterTemplates.RosterCapacity
		roster.starterSeedVersion = StarterFighterTemplates.CurrentSeedVersion

		for index, template in ipairs(StarterFighterTemplates.Entries) do
			local fighterDocument = buildStarterFighterDocument(player, index, template, nowUnix)
			roster.byId[fighterDocument.fighterId] = fighterDocument
			table.insert(roster.rosterOrder, fighterDocument.fighterId)
			if index <= 3 then
				table.insert(roster.activeTrioFighterIds, fighterDocument.fighterId)
			end
		end

		didSeed = true
	end)

	if didSeed then
		self:_publish(player)
	end

	return didSeed
end

function FighterRosterService:_ensureStarterRoster(player)
	local session = self._playerSessionService:getOptionalSession(player)
	if session == nil then
		return false
	end

	local roster = session.document.fighters
	if roster == nil or #roster.rosterOrder == 0 then
		return self:_seedStarterRoster(player)
	end

	return false
end

function FighterRosterService:_scheduleEnsureStarterRoster(player)
	local userId = player.UserId
	if self._pendingEnsureByUserId[userId] == true then
		return
	end

	self._pendingEnsureByUserId[userId] = true
	task.spawn(function()
		while player.Parent ~= nil do
			local session = self._playerSessionService:getOptionalSession(player)
			if session ~= nil then
				self._pendingEnsureByUserId[userId] = nil
				self:_ensureStarterRoster(player)
				self:_publish(player)
				return
			end
			task.wait()
		end

		self._pendingEnsureByUserId[userId] = nil
	end)
end

function FighterRosterService:getReadModel(player)
	self:_ensureStarterRoster(player)
	return self:_buildReadModel(player)
end

function FighterRosterService:getRunSeedPayload(player)
	self:_ensureStarterRoster(player)
	local profile = self._playerSessionService:readProfile(player)
	local payload = {
		fighterSnapshots = {},
		fighterMetadataByCombatantId = {},
		baseFighterStatesByCombatantId = {},
	}

	for _, fighterId in ipairs(profile.fighters.activeTrioFighterIds or {}) do
		local fighterDocument = profile.fighters.byId[fighterId]
		assert(
			fighterDocument ~= nil,
			string.format("Active trio fighter %s is missing", tostring(fighterId))
		)

		local combatSnapshot = FighterProjector.buildCombatSnapshot(fighterDocument)
		local fighterReadModel = FighterProjector.buildReadModel(fighterDocument)
		table.insert(payload.fighterSnapshots, combatSnapshot)
		payload.fighterMetadataByCombatantId[combatSnapshot.combatantId] = {
			combatantId = combatSnapshot.combatantId,
			displayName = fighterReadModel.displayName,
			classId = combatSnapshot.classId,
			grade = combatSnapshot.grade,
			level = combatSnapshot.level,
		}
		payload.baseFighterStatesByCombatantId[combatSnapshot.combatantId] = {
			combatantId = combatSnapshot.combatantId,
			maxHp = combatSnapshot.computedStats.hp,
			currentHp = combatSnapshot.computedStats.hp,
		}
	end

	assert(#payload.fighterSnapshots == 3, "Active trio must contain exactly 3 fighters")
	return payload
end

function FighterRosterService:getActiveTrioCombatSnapshots(player)
	return self:getRunSeedPayload(player).fighterSnapshots
end

function FighterRosterService:setActiveTrio(player, fighterIds)
	assert(type(fighterIds) == "table", "fighterIds must be an array")
	assert(#fighterIds == 3, "Active trio must contain exactly 3 fighters")

	local seen = {}
	self._playerSessionService:mutate(player, "fighters.set_active_trio", function(draft)
		local roster = draft.fighters
		for _, fighterId in ipairs(fighterIds) do
			assert(
				type(fighterId) == "string" and fighterId ~= "",
				"fighterId must be a non-empty string"
			)
			assert(
				roster.byId[fighterId] ~= nil,
				string.format("Unknown fighter %s", tostring(fighterId))
			)
			assert(
				seen[fighterId] == nil,
				string.format("Duplicate trio fighter %s", tostring(fighterId))
			)
			seen[fighterId] = true
		end

		roster.activeTrioFighterIds = table.clone(fighterIds)
	end)

	self:_publish(player)
	return self:getReadModel(player)
end

function FighterRosterService:getComparison(player, leftFighterId, rightFighterId)
	local readModel = self:getReadModel(player)
	local left = nil
	local right = nil

	for _, fighter in ipairs(readModel.roster) do
		if fighter.fighterId == leftFighterId then
			left = fighter
		elseif fighter.fighterId == rightFighterId then
			right = fighter
		end
	end

	assert(left ~= nil, string.format("Unknown left fighter %s", tostring(leftFighterId)))
	assert(right ~= nil, string.format("Unknown right fighter %s", tostring(rightFighterId)))

	return FighterComparison.compare(left, right)
end

function FighterRosterService:start()
	local requestRosterRemote = self._network:ensureRemoteFunction(
		RuntimeConfig.Networking.Namespaces.Fighters,
		"RequestRoster"
	)
	requestRosterRemote.OnServerInvoke = function(player)
		return self:getReadModel(player)
	end

	local setActiveTrioRemote = self._network:ensureRemoteFunction(
		RuntimeConfig.Networking.Namespaces.Fighters,
		"SetActiveTrio"
	)
	setActiveTrioRemote.OnServerInvoke = function(player, fighterIds)
		return self:setActiveTrio(player, fighterIds)
	end

	self._snapshotService:registerTopic(ReplicationTopics.Fighters, function(player)
		local session = self._playerSessionService:getOptionalSession(player)
		if session == nil then
			return nil
		end

		return FighterRosterReadModel.fromProfileDocument(session.document),
			session.document.meta.profileRevision,
			"replace"
	end)

	self._debugService:registerView("Fighters", "Roster", function(player)
		return self:getReadModel(player)
	end)
	self._debugService:registerAction("Fighters", "SetActiveTrio", function(player, payload)
		assert(type(payload) == "table", "Fighters/SetActiveTrio requires a payload table")
		assert(type(payload.fighterIds) == "table", "Fighters/SetActiveTrio requires fighterIds")
		return self:setActiveTrio(player, payload.fighterIds)
	end)
	self._debugService:registerAction("Fighters", "CompareRosterPair", function(player, payload)
		assert(type(payload) == "table", "Fighters/CompareRosterPair requires a payload table")
		return self:getComparison(player, payload.leftFighterId, payload.rightFighterId)
	end)

	self._cleaner:add(Players.PlayerAdded:Connect(function(player)
		self:_scheduleEnsureStarterRoster(player)
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		self:_scheduleEnsureStarterRoster(player)
	end
end

function FighterRosterService:stop()
	self._cleaner:clean()
	table.clear(self._pendingEnsureByUserId)
end

return FighterRosterService
