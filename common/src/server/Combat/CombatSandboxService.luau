local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))
local ReplicationTopics = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("Topics")
)
local ExtractionTypeIds = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Extractions")
		:WaitForChild("ExtractionTypeIds")
)
local Cleaner =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Cleaner"))
local SyntheticScenarioPresets = require(
	script.Parent
		:WaitForChild("Scenarios")
		:WaitForChild("Test")
		:WaitForChild("SyntheticScenarioPresets")
)

local EnemyDefinitions = CombatConfig.EnemyDefinitions
local ClassDefinitions = CombatConfig.Fighters.ClassDefinitions
local CombatStatsBuilder = CombatConfig.Fighters.CombatStatsBuilder

local DEFAULT_EXTRACTION_TYPE = ExtractionTypeIds.Values[1]
local PUBLISH_INTERVAL_SECONDS = 0.1

local CombatSandboxService = {}
CombatSandboxService.__index = CombatSandboxService

local function clone(value)
	if type(value) ~= "table" then
		return value
	end

	local cloned = {}
	for key, entry in pairs(value) do
		cloned[key] = clone(entry)
	end
	return cloned
end

local function buildAvailableEnemies()
	local seen = {}
	local enemyIds = {}

	for _, enemyId in pairs(SyntheticScenarioPresets.DefaultEnemyIdByExtractionType) do
		if seen[enemyId] ~= true then
			seen[enemyId] = true
			table.insert(enemyIds, enemyId)
		end
	end

	table.sort(enemyIds)

	local entries = {}
	for _, enemyId in ipairs(enemyIds) do
		local definition = EnemyDefinitions.get(enemyId)
		table.insert(entries, {
			enemyId = definition.enemyId,
			displayName = definition.displayName,
			tier = definition.tier,
			threatTag = definition.threatTag,
		})
	end

	return table.freeze(entries)
end

local AVAILABLE_ENEMIES = buildAvailableEnemies()

local function buildCombatantLookup(entries)
	local lookup = {}
	for _, entry in ipairs(entries or {}) do
		lookup[entry.combatantId] = entry
	end
	return lookup
end

local function getCombatantDisplayName(labelsById, combatantId)
	local label = labelsById[combatantId]
	if
		type(label) == "table"
		and type(label.displayName) == "string"
		and label.displayName ~= ""
	then
		return label.displayName
	end
	if type(label) == "string" and label ~= "" then
		return label
	end
	return combatantId
end

local function deriveEncounterSurvivorLists(lastEncounter)
	local finalStates = lastEncounter.finalFighterStatesByCombatantId or {}
	local survivors = {}
	local defeated = {}

	for combatantId, fighterState in pairs(finalStates) do
		if type(fighterState) == "table" and (fighterState.currentHp or 0) > 0 then
			table.insert(survivors, combatantId)
		else
			table.insert(defeated, combatantId)
		end
	end

	table.sort(survivors)
	table.sort(defeated)

	if #survivors > 0 or #defeated > 0 then
		return survivors, defeated
	end

	local result = lastEncounter.result
	return if result ~= nil then result.remainingFighterCombatantIds or {} else {},
		if result ~= nil then result.defeatedFighterCombatantIds or {} else {}
end

local function mapCombatantNames(labelsById, combatantIds)
	local names = {}
	for _, combatantId in ipairs(combatantIds or {}) do
		table.insert(names, getCombatantDisplayName(labelsById, combatantId))
	end
	return names
end

function CombatSandboxService.new(config)
	assert(type(config) == "table", "CombatSandboxService config must be a table")
	assert(config.snapshotService ~= nil, "CombatSandboxService requires snapshot service")
	assert(config.debugService ~= nil, "CombatSandboxService requires debug service")
	assert(config.stateStore ~= nil, "CombatSandboxService requires state store")

	local sandboxStatesByUserId = {}
	config.stateStore:set("CombatSandbox", sandboxStatesByUserId)

	return setmetatable({
		_snapshotService = config.snapshotService,
		_debugService = config.debugService,
		_stateStore = config.stateStore,
		_statesByUserId = sandboxStatesByUserId,
		_encounterService = nil,
		_fighterRosterService = nil,
		_cleaner = Cleaner.new(),
		_publishAccumulator = 0,
	}, CombatSandboxService)
end

function CombatSandboxService:_ensurePlayerState(player)
	local state = self._statesByUserId[player.UserId]
	if state ~= nil then
		return state
	end

	state = {
		selectedEnemyId = AVAILABLE_ENEMIES[1].enemyId,
		extractionType = DEFAULT_EXTRACTION_TYPE,
		speedScale = 1,
		revision = 0,
		lastStartError = nil,
	}
	self._statesByUserId[player.UserId] = state

	return state
end

function CombatSandboxService:_getDebugRunState(player)
	if self._encounterService == nil then
		return {
			hasRun = false,
			liveCombatants = {},
			persistentFighters = {},
		}
	end

	return self._encounterService:getDebugState(player)
end

function CombatSandboxService:_buildTrioSnapshot(player, debugState)
	local liveByCombatantId = buildCombatantLookup(debugState.liveCombatants)
	local persistentByCombatantId = debugState.persistentFighters or {}
	local trio = {}
	local elapsedTime = if debugState.activeEncounter ~= nil
		then debugState.activeEncounter.elapsedTime or 0
		else 0
	local trioEntries = nil

	if self._fighterRosterService ~= nil then
		local rosterReadModel = self._fighterRosterService:getReadModel(player)
		if
			type(rosterReadModel) == "table"
			and type(rosterReadModel.trio) == "table"
			and #rosterReadModel.trio > 0
		then
			trioEntries = rosterReadModel.trio
		end
	end

	if trioEntries ~= nil then
		for _, fighter in ipairs(trioEntries) do
			local liveState = liveByCombatantId[fighter.fighterId]
			local persistentState = persistentByCombatantId[fighter.fighterId]
			local currentHp = fighter.computedStats.hp
			local maxHp = fighter.computedStats.hp

			if persistentState ~= nil then
				currentHp = persistentState.currentHp or currentHp
				maxHp = persistentState.maxHp or maxHp
			end

			if liveState ~= nil then
				currentHp = liveState.currentHp or currentHp
				maxHp = liveState.maxHp or maxHp
			end

			table.insert(trio, {
				combatantId = fighter.fighterId,
				displayName = fighter.displayName,
				classId = fighter.classId,
				grade = fighter.grade,
				level = fighter.level,
				specialSkill = clone(fighter.specialSkill),
				currentHp = currentHp,
				maxHp = maxHp,
				attackIntervalSeconds = fighter.stats.attackIntervalSeconds,
				specialSkillIds = clone(fighter.usableActiveSkillIds),
				nextActionInSeconds = if liveState ~= nil
						and liveState.nextActionAt ~= nil
					then math.max(liveState.nextActionAt - elapsedTime, 0)
					else nil,
				activeStatuses = if liveState ~= nil then clone(liveState.activeStatuses) else {},
				cooldowns = if liveState ~= nil then clone(liveState.cooldowns) else {},
			})
		end

		return trio
	end

	for _, spec in ipairs(SyntheticScenarioPresets.DefaultFighterTrio) do
		local fighterSnapshot = CombatStatsBuilder.buildFighterSnapshot(spec)
		local classDefinition = ClassDefinitions.get(fighterSnapshot.classId)
		local liveState = liveByCombatantId[fighterSnapshot.combatantId]
		local persistentState = persistentByCombatantId[fighterSnapshot.combatantId]
		local currentHp = fighterSnapshot.computedStats.hp
		local maxHp = fighterSnapshot.computedStats.hp

		if persistentState ~= nil then
			currentHp = persistentState.currentHp or currentHp
			maxHp = persistentState.maxHp or maxHp
		end

		if liveState ~= nil then
			currentHp = liveState.currentHp or currentHp
			maxHp = liveState.maxHp or maxHp
		end

		table.insert(trio, {
			combatantId = fighterSnapshot.combatantId,
			displayName = classDefinition.displayName,
			classId = fighterSnapshot.classId,
			grade = fighterSnapshot.grade,
			level = fighterSnapshot.level,
			currentHp = currentHp,
			maxHp = maxHp,
			attackIntervalSeconds = fighterSnapshot.computedStats.attackIntervalSeconds,
			specialSkillIds = clone(fighterSnapshot.activeSkillIds),
			nextActionInSeconds = if liveState ~= nil and liveState.nextActionAt ~= nil
				then math.max(liveState.nextActionAt - elapsedTime, 0)
				else nil,
			activeStatuses = if liveState ~= nil then clone(liveState.activeStatuses) else {},
			cooldowns = if liveState ~= nil then clone(liveState.cooldowns) else {},
		})
	end

	table.sort(trio, function(left, right)
		return left.combatantId < right.combatantId
	end)

	return trio
end

function CombatSandboxService:_buildEnemySnapshot(state, debugState)
	local definition = EnemyDefinitions.get(state.selectedEnemyId)
	local liveEnemy = nil

	for _, combatant in ipairs(debugState.liveCombatants or {}) do
		if combatant.kind == "Enemy" then
			liveEnemy = combatant
			break
		end
	end

	local currentHp = definition.computedStats.hp
	local maxHp = definition.computedStats.hp

	if liveEnemy ~= nil then
		currentHp = liveEnemy.currentHp or currentHp
		maxHp = liveEnemy.maxHp or maxHp
	end

	local tierLabel = if definition.tier == "Normal"
		then ""
		else string.format("[%s] ", definition.tier)

	return {
		enemyId = definition.enemyId,
		displayName = definition.displayName,
		tier = definition.tier,
		title = string.format("%s%s", tierLabel, definition.displayName),
		threatTag = definition.threatTag,
		currentHp = currentHp,
		maxHp = maxHp,
		hpRatio = if maxHp > 0 then math.clamp(currentHp / maxHp, 0, 1) else 0,
		activeStatuses = if liveEnemy ~= nil then clone(liveEnemy.activeStatuses) else {},
	}
end

function CombatSandboxService:_buildJournalEntries(debugState)
	if debugState.activeEncounter ~= nil and debugState.activeEncounter.journalEntries ~= nil then
		return clone(debugState.activeEncounter.journalEntries)
	end

	if debugState.lastEncounter ~= nil and debugState.lastEncounter.journalEntries ~= nil then
		return clone(debugState.lastEncounter.journalEntries)
	end

	return {}
end

function CombatSandboxService:_buildLastEncounterSummary(debugState)
	if debugState.lastEncounter == nil then
		return nil
	end

	local labelsById = debugState.lastEncounter.combatantLabelsById or {}
	local survivors, defeated = deriveEncounterSurvivorLists(debugState.lastEncounter)

	return {
		encounterId = debugState.lastEncounter.encounterId,
		outcome = if debugState.lastEncounter.result ~= nil
			then debugState.lastEncounter.result.outcome
			else nil,
		result = clone(debugState.lastEncounter.result),
		journalEntries = clone(debugState.lastEncounter.journalEntries or {}),
		combatantLabelsById = clone(labelsById),
		finalFighterStatesByCombatantId = clone(
			debugState.lastEncounter.finalFighterStatesByCombatantId or {}
		),
		aliveCombatantIds = clone(survivors),
		downCombatantIds = clone(defeated),
		aliveDisplayNames = mapCombatantNames(labelsById, survivors),
		downDisplayNames = mapCombatantNames(labelsById, defeated),
		survivorCount = #survivors,
		progression = clone(debugState.lastEncounter.progression),
	}
end

function CombatSandboxService:_buildActiveEncounterSummary(debugState)
	if debugState.activeEncounter == nil then
		return nil
	end

	return {
		encounterId = debugState.activeEncounter.encounterId,
		state = debugState.activeEncounter.state,
		elapsedTime = debugState.activeEncounter.elapsedTime,
		journalEntries = clone(debugState.activeEncounter.journalEntries or {}),
	}
end

function CombatSandboxService:_buildSnapshot(player)
	local state = self:_ensurePlayerState(player)
	local debugState = self:_getDebugRunState(player)
	local activeEncounter = debugState.activeEncounter
	local activeEncounterId = debugState.activeEncounterId

	return {
		mode = if activeEncounterId ~= nil then "CombatEncounter" else "FollowPlayer",
		speedScale = state.speedScale,
		extractionType = state.extractionType,
		selectedEnemyId = state.selectedEnemyId,
		availableEnemies = clone(AVAILABLE_ENEMIES),
		lastStartError = state.lastStartError,
		activeEncounterId = activeEncounterId,
		encounterState = if activeEncounter ~= nil then activeEncounter.state else nil,
		elapsedTime = if activeEncounter ~= nil then activeEncounter.elapsedTime or 0 else 0,
		trio = self:_buildTrioSnapshot(player, debugState),
		enemy = if activeEncounterId ~= nil
			then self:_buildEnemySnapshot(state, debugState)
			else nil,
		activeEncounter = self:_buildActiveEncounterSummary(debugState),
		lastEncounter = self:_buildLastEncounterSummary(debugState),
		journalEntries = self:_buildJournalEntries(debugState),
	}
end

function CombatSandboxService:_publishSnapshot(player)
	local state = self:_ensurePlayerState(player)
	state.revision += 1
	self._snapshotService:publishRegisteredTopic(player, ReplicationTopics.CombatSandbox)
end

function CombatSandboxService:getTimeScaleForUserId(userId)
	local state = self._statesByUserId[userId]
	if state == nil then
		return 1
	end

	return state.speedScale or 1
end

function CombatSandboxService:selectEnemy(player, enemyId)
	local state = self:_ensurePlayerState(player)
	EnemyDefinitions.get(enemyId)
	state.selectedEnemyId = enemyId
	state.lastStartError = nil

	if self._encounterService == nil then
		self:_publishSnapshot(player)
		return self:_buildSnapshot(player)
	end

	self._encounterService:endRun(player)
	return self:startEncounter(player)
end

function CombatSandboxService:setSpeedScale(player, speedScale)
	assert(speedScale == 1 or speedScale == 2, "Sandbox speed scale must be 1 or 2")
	local state = self:_ensurePlayerState(player)
	state.speedScale = speedScale
	self:_publishSnapshot(player)
	return self:_buildSnapshot(player)
end

function CombatSandboxService:startEncounter(player)
	local state = self:_ensurePlayerState(player)
	assert(self._encounterService ~= nil, "CombatEncounterService is not attached")

	local runOptions = nil
	if self._fighterRosterService ~= nil then
		local ok, result = pcall(function()
			return self._fighterRosterService:getRunSeedPayload(player)
		end)
		if ok then
			runOptions = result
			state.lastStartError = nil
		else
			state.lastStartError = tostring(result)
		end
	end

	local ok, result = pcall(function()
		return self._encounterService:startRun(
			player,
			state.extractionType,
			state.selectedEnemyId,
			runOptions
		)
	end)
	if not ok then
		state.lastStartError = tostring(result)
		self._encounterService:startSyntheticRun(
			player,
			state.extractionType,
			state.selectedEnemyId
		)
	end

	self:_publishSnapshot(player)
	return self:_buildSnapshot(player)
end

function CombatSandboxService:endRun(player)
	if self._encounterService ~= nil then
		self._encounterService:endRun(player)
	end
	self:_publishSnapshot(player)
	return self:_buildSnapshot(player)
end

function CombatSandboxService:start(encounterService, fighterRosterService)
	assert(encounterService ~= nil, "CombatSandboxService requires CombatEncounterService")
	self._encounterService = encounterService
	self._fighterRosterService = fighterRosterService

	self._snapshotService:registerTopic(ReplicationTopics.CombatSandbox, function(player)
		local state = self:_ensurePlayerState(player)
		return self:_buildSnapshot(player), state.revision, "replace"
	end)

	self._debugService:registerAction("CombatSandbox", "SelectEnemy", function(player, payload)
		assert(type(payload) == "table", "CombatSandbox/SelectEnemy requires a payload table")
		assert(
			type(payload.enemyId) == "string",
			"CombatSandbox/SelectEnemy requires payload.enemyId"
		)
		return self:selectEnemy(player, payload.enemyId)
	end)
	self._debugService:registerAction("CombatSandbox", "SelectTrainingDummy", function(player)
		return self:selectEnemy(player, "Enemy.TrainingDummy")
	end)
	self._debugService:registerAction("CombatSandbox", "SelectVenomBrute", function(player)
		return self:selectEnemy(player, "Enemy.VenomBrute")
	end)
	self._debugService:registerAction("CombatSandbox", "SelectArenaTyrant", function(player)
		return self:selectEnemy(player, "Enemy.ArenaTyrant")
	end)
	self._debugService:registerAction("CombatSandbox", "StartEncounter", function(player)
		return self:startEncounter(player)
	end)
	self._debugService:registerAction("CombatSandbox", "SetSpeed1x", function(player)
		return self:setSpeedScale(player, 1)
	end)
	self._debugService:registerAction("CombatSandbox", "SetSpeed2x", function(player)
		return self:setSpeedScale(player, 2)
	end)
	self._debugService:registerAction("CombatSandbox", "EndRun", function(player)
		return self:endRun(player)
	end)

	self._cleaner:add(Players.PlayerRemoving:Connect(function(player)
		self._statesByUserId[player.UserId] = nil
	end))

	self._cleaner:add(RunService.Heartbeat:Connect(function(deltaTime)
		self._publishAccumulator += deltaTime
		if self._publishAccumulator < PUBLISH_INTERVAL_SECONDS then
			return
		end

		self._publishAccumulator = 0
		for _, player in ipairs(Players:GetPlayers()) do
			if self._statesByUserId[player.UserId] ~= nil then
				self:_publishSnapshot(player)
			end
		end
	end))
end

function CombatSandboxService:stop()
	self._cleaner:clean()
	self._encounterService = nil
	self._fighterRosterService = nil
	self._publishAccumulator = 0
	for userId in pairs(self._statesByUserId) do
		self._statesByUserId[userId] = nil
	end
end

return CombatSandboxService
