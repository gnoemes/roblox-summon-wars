local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(script.Parent.CombatComponents)
local SyntheticCombatFactory = require(script.Parent.SyntheticCombatFactory)
local EncounterPersistencePolicy = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Combat")
		:WaitForChild("Simulation")
		:WaitForChild("EncounterPersistencePolicy")
)

local CombatEncounterService = {}
CombatEncounterService.__index = CombatEncounterService

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

function CombatEncounterService.new(config)
	assert(type(config) == "table", "CombatEncounterService config must be a table")
	assert(config.world ~= nil, "CombatEncounterService requires world")
	assert(config.stateStore ~= nil, "CombatEncounterService requires stateStore")
	assert(config.debugService ~= nil, "CombatEncounterService requires debugService")

	local runtimeState = {
		runsByUserId = {},
		encounterEntityIdsByEncounterId = {},
	}
	config.stateStore:set("CombatRuntime", runtimeState)

	return setmetatable({
		_world = config.world,
		_stateStore = config.stateStore,
		_debugService = config.debugService,
		_runtimeState = runtimeState,
	}, CombatEncounterService)
end

function CombatEncounterService:_despawnEncounter(encounterId)
	for entityId, encounter in self._world:query(Components.Encounter) do
		if encounter.encounterId == encounterId then
			self._world:despawn(entityId)
		end
	end

	for entityId, combatant in self._world:query(Components.Combatant) do
		if combatant.encounterId == encounterId then
			self._world:despawn(entityId)
		end
	end

	self._runtimeState.encounterEntityIdsByEncounterId[encounterId] = nil
end

function CombatEncounterService:_spawnEncounter(player, runState)
	local encounterConfig, fighters, enemy = SyntheticCombatFactory.createEncounter(runState)
	local encounterEntityId = self._world:spawn(Components.Encounter({
		encounterId = encounterConfig.encounterId,
		runInstanceId = runState.runInstanceId,
		ownerUserId = player.UserId,
		extractionType = encounterConfig.extractionType,
		enemyId = encounterConfig.enemyId,
		startedAt = 0,
		elapsedTime = 0,
		state = "Running",
		outcome = nil,
		sequence = 1,
		rngState = math.abs(player.UserId) + runState.encounterIndex + 1,
		journalEntries = {},
		encounterIndex = runState.encounterIndex + 1,
		cleanupQueued = false,
	}))

	for _, fighter in ipairs(fighters) do
		self._world:spawn(
			Components.Combatant({
				encounterId = encounterConfig.encounterId,
				combatantId = fighter.combatantId,
				kind = fighter.kind,
				displayName = fighter.displayName,
				classId = fighter.classId,
				enemyId = nil,
				order = fighter.order,
				aggroWeight = fighter.aggroWeight,
			}),
			Components.CombatantStats({
				computedStats = fighter.computedStats,
			}),
			Components.CombatantAbilities({
				basicSkillId = fighter.basicSkillId,
				specialSkillIds = fighter.specialSkillIds,
				passiveSkillIds = fighter.passiveSkillIds,
			}),
			Components.CombatantRuntime(fighter.runtimeState)
		)
	end

	self._world:spawn(
		Components.Combatant({
			encounterId = encounterConfig.encounterId,
			combatantId = enemy.combatantId,
			kind = enemy.kind,
			displayName = enemy.displayName,
			classId = nil,
			enemyId = enemy.enemyId,
			order = enemy.order,
			aggroWeight = enemy.aggroWeight,
		}),
		Components.CombatantStats({
			computedStats = enemy.computedStats,
		}),
		Components.CombatantAbilities({
			basicSkillId = enemy.basicSkillId,
			specialSkillIds = enemy.specialSkillIds,
			passiveSkillIds = enemy.passiveSkillIds,
		}),
		Components.CombatantRuntime(enemy.runtimeState)
	)

	runState.encounterIndex += 1
	runState.activeEncounterId = encounterConfig.encounterId
	runState.activeEncounterEntityId = encounterEntityId
	self._runtimeState.encounterEntityIdsByEncounterId[encounterConfig.encounterId] =
		encounterEntityId

	return encounterConfig.encounterId
end

function CombatEncounterService:startSyntheticRun(player, extractionType, enemyId)
	self:endRun(player)

	local runState = SyntheticCombatFactory.createRun(player, extractionType, enemyId)
	self._runtimeState.runsByUserId[player.UserId] = runState
	self:_spawnEncounter(player, runState)

	return self:getDebugState(player)
end

function CombatEncounterService:startNextEncounter(player)
	local runState = self._runtimeState.runsByUserId[player.UserId]
	assert(runState ~= nil, "No active synthetic run")
	assert(runState.activeEncounterId == nil, "An encounter is already running")

	local aliveFighters = 0
	for _, state in pairs(runState.persistentFighterStatesByCombatantId) do
		if state.currentHp > 0 then
			aliveFighters += 1
		end
	end
	assert(aliveFighters > 0, "No fighters are alive for the next encounter")

	self:_spawnEncounter(player, runState)

	return self:getDebugState(player)
end

function CombatEncounterService:completeEncounter(encounterId, payload)
	local ownerUserId = payload.ownerUserId
	local runState = self._runtimeState.runsByUserId[ownerUserId]
	if runState == nil or runState.activeEncounterId ~= encounterId then
		return
	end

	runState.activeEncounterId = nil
	runState.activeEncounterEntityId = nil
	runState.lastEncounter = {
		encounterId = encounterId,
		result = payload.result,
		journalEntries = payload.journalEntries,
		combatantLabelsById = payload.combatantLabelsById,
	}
	table.insert(runState.completedEncounterIds, encounterId)
	runState.persistentFighterStatesByCombatantId = EncounterPersistencePolicy.apply(
		runState.extractionType,
		runState.baseFighterStatesByCombatantId,
		payload.finalFighterStatesByCombatantId
	)

	if runState.extractionType == "HuntingGrounds" and payload.result.outcome == "Victory" then
		local player = Players:GetPlayerByUserId(ownerUserId)
		if player ~= nil then
			self:_spawnEncounter(player, runState)
		end
	end
end

function CombatEncounterService:queueEncounterCleanup(encounterId)
	self:_despawnEncounter(encounterId)
end

function CombatEncounterService:endRun(player)
	local runState = self._runtimeState.runsByUserId[player.UserId]
	if runState == nil then
		return false
	end

	if runState.activeEncounterId ~= nil then
		self:_despawnEncounter(runState.activeEncounterId)
	end

	self._runtimeState.runsByUserId[player.UserId] = nil
	return true
end

function CombatEncounterService:getRun(player)
	return self._runtimeState.runsByUserId[player.UserId]
end

function CombatEncounterService:getDebugState(player)
	local runState = self:getRun(player)
	if runState == nil then
		return {
			hasRun = false,
		}
	end

	local activeEncounter = nil
	if
		runState.activeEncounterEntityId ~= nil
		and self._world:contains(runState.activeEncounterEntityId)
	then
		activeEncounter = self._world:get(runState.activeEncounterEntityId, Components.Encounter)
	end

	local fighterMetadataByCombatantId = runState.fighterMetadataByCombatantId or {}

	local liveCombatants = {}
	if runState.activeEncounterId ~= nil then
		for _, combatant, stats, abilities, runtime in
			self._world:query(
				Components.Combatant,
				Components.CombatantStats,
				Components.CombatantAbilities,
				Components.CombatantRuntime
			)
		do
			if combatant.encounterId == runState.activeEncounterId then
				local fighterMetadata = fighterMetadataByCombatantId[combatant.combatantId]
				table.insert(liveCombatants, {
					combatantId = combatant.combatantId,
					kind = combatant.kind,
					displayName = combatant.displayName,
					grade = if fighterMetadata ~= nil then fighterMetadata.grade else nil,
					currentHp = runtime.currentHp,
					maxHp = runtime.maxHp,
					nextActionAt = runtime.nextActionAt,
					attackIntervalSeconds = stats.computedStats.attackIntervalSeconds,
					basicSkillId = abilities.basicSkillId,
					specialSkillIds = clone(abilities.specialSkillIds),
					passiveSkillIds = clone(abilities.passiveSkillIds),
					activeStatuses = clone(runtime.statusesById),
					cooldowns = clone(runtime.remainingCooldownsBySkillId),
				})
			end
		end
	end

	table.sort(liveCombatants, function(left, right)
		return left.combatantId < right.combatantId
	end)

	local persistentFighters = {}
	for combatantId, fighterState in pairs(runState.persistentFighterStatesByCombatantId) do
		local fighterMetadata = fighterMetadataByCombatantId[combatantId]
		persistentFighters[combatantId] = {
			combatantId = combatantId,
			displayName = if fighterMetadata ~= nil
				then fighterMetadata.displayName
				else combatantId,
			grade = if fighterMetadata ~= nil then fighterMetadata.grade else nil,
			currentHp = fighterState.currentHp,
			maxHp = fighterState.maxHp,
		}
	end

	return {
		hasRun = true,
		runInstanceId = runState.runInstanceId,
		extractionType = runState.extractionType,
		enemyId = runState.enemyId,
		encounterIndex = runState.encounterIndex,
		activeEncounterId = runState.activeEncounterId,
		persistentFighters = persistentFighters,
		activeEncounter = if activeEncounter ~= nil
			then {
				encounterId = activeEncounter.encounterId,
				elapsedTime = activeEncounter.elapsedTime,
				state = activeEncounter.state,
				journalEntries = clone(activeEncounter.journalEntries),
			}
			else nil,
		liveCombatants = liveCombatants,
		lastEncounter = clone(runState.lastEncounter),
	}
end

function CombatEncounterService:start()
	self._debugService:registerView("Combat", "SyntheticRun", function(player)
		return self:getDebugState(player)
	end)

	self._debugService:registerAction("Combat", "StartSyntheticHuntingGrounds", function(player)
		return self:startSyntheticRun(player, "HuntingGrounds", nil)
	end)

	self._debugService:registerAction("Combat", "StartSyntheticDungeon", function(player)
		return self:startSyntheticRun(player, "Dungeon", nil)
	end)

	self._debugService:registerAction("Combat", "StartSyntheticRaid", function(player)
		return self:startSyntheticRun(player, "Raid", nil)
	end)

	self._debugService:registerAction("Combat", "StartNextEncounter", function(player)
		return self:startNextEncounter(player)
	end)

	self._debugService:registerAction("Combat", "EndRun", function(player)
		self:endRun(player)
		return self:getDebugState(player)
	end)
end

function CombatEncounterService:stop()
	for userId, runState in pairs(self._runtimeState.runsByUserId) do
		if runState.activeEncounterId ~= nil then
			self:_despawnEncounter(runState.activeEncounterId)
		end
		self._runtimeState.runsByUserId[userId] = nil
	end
end

return CombatEncounterService
