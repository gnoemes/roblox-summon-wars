local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ReplicationTopics = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("Topics")
)
local Fighters = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Fighters"))

local EnemyDefinitions = SharedConfig.Combat.EnemyDefinitions
local FighterProgression = Fighters.FighterProgression
local FighterExperienceCalculator = Fighters.FighterExperienceCalculator

local FighterProgressionService = {}
FighterProgressionService.__index = FighterProgressionService

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

local function buildParticipantOrder(result)
	local participantIds = {}
	for _, fighterId in ipairs(result.remainingFighterCombatantIds or {}) do
		table.insert(participantIds, fighterId)
	end
	for _, fighterId in ipairs(result.defeatedFighterCombatantIds or {}) do
		table.insert(participantIds, fighterId)
	end
	return participantIds
end

function FighterProgressionService.new(config)
	assert(type(config) == "table", "FighterProgressionService config must be a table")
	assert(
		config.playerSessionService ~= nil,
		"FighterProgressionService requires PlayerSessionService"
	)
	assert(
		config.fighterRosterService ~= nil,
		"FighterProgressionService requires FighterRosterService"
	)
	assert(config.snapshotService ~= nil, "FighterProgressionService requires SnapshotService")
	assert(config.debugService ~= nil, "FighterProgressionService requires DebugService")

	return setmetatable({
		_playerSessionService = config.playerSessionService,
		_fighterRosterService = config.fighterRosterService,
		_snapshotService = config.snapshotService,
		_debugService = config.debugService,
	}, FighterProgressionService)
end

function FighterProgressionService:_publishAndReadModel(player)
	self._snapshotService:publishRegisteredTopic(player, ReplicationTopics.Fighters)
	return self._fighterRosterService:getReadModel(player)
end

function FighterProgressionService:grantDebugExperience(player, fighterId, amount)
	assert(type(fighterId) == "string" and fighterId ~= "", "fighterId must be a non-empty string")
	assert(type(amount) == "number" and amount >= 0, "amount must be a non-negative number")

	self._playerSessionService:mutate(player, "fighters.debug_experience", function(draft)
		local fighterDocument = draft.fighters.byId[fighterId]
		assert(fighterDocument ~= nil, string.format("Unknown fighter %s", tostring(fighterId)))
		local nextProgress = FighterProgression.applyExperience(
			fighterDocument.level,
			fighterDocument.experience,
			amount,
			fighterDocument.ascensionExperience
		)
		fighterDocument.level = nextProgress.level
		fighterDocument.experience = nextProgress.experience
		fighterDocument.ascensionExperience = nextProgress.ascensionExperience
	end)

	return self:_publishAndReadModel(player)
end

function FighterProgressionService:setDebugLevel(player, fighterId, targetLevel)
	assert(type(fighterId) == "string" and fighterId ~= "", "fighterId must be a non-empty string")
	assert(type(targetLevel) == "number" and targetLevel >= 1, "targetLevel must be >= 1")

	local clampedLevel = math.clamp(math.floor(targetLevel), 1, FighterProgression.getLevelCap())
	self._playerSessionService:mutate(player, "fighters.debug_level", function(draft)
		local fighterDocument = draft.fighters.byId[fighterId]
		assert(fighterDocument ~= nil, string.format("Unknown fighter %s", tostring(fighterId)))
		fighterDocument.level = clampedLevel
		fighterDocument.experience = 0
	end)

	return self:_publishAndReadModel(player)
end

function FighterProgressionService:applyEncounterResult(player, encounterData)
	if player == nil or encounterData == nil or encounterData.result == nil then
		return nil
	end

	local result = encounterData.result
	local participantIds = buildParticipantOrder(result)
	if #participantIds == 0 then
		return nil
	end

	local enemyDefinition = EnemyDefinitions.get(encounterData.enemyId)
	local grantedExperience = FighterExperienceCalculator.calculateEncounterExperience({
		enemyDefinition = enemyDefinition,
		extractionType = encounterData.extractionType,
		outcome = result.outcome,
		recommendedSquadPower = encounterData.recommendedSquadPower,
		minimumSquadPower = encounterData.minimumSquadPower,
		encounterFlags = encounterData.encounterFlags,
		modifiers = encounterData.experienceModifiers,
	})
	local survivorLookup = {}
	for _, fighterId in ipairs(result.remainingFighterCombatantIds or {}) do
		survivorLookup[fighterId] = true
	end

	local awardsByFighterId = {}
	self._playerSessionService:mutate(player, "fighters.encounter_progression", function(draft)
		local roster = draft.fighters
		for _, fighterId in ipairs(participantIds) do
			local fighterDocument = roster.byId[fighterId]
			if fighterDocument ~= nil then
				local beforeLevel = fighterDocument.level
				local beforeExperience = fighterDocument.experience
				local beforeAscensionExperience = fighterDocument.ascensionExperience
				local gainedExperience = if survivorLookup[fighterId] == true
					then grantedExperience
					else 0
				local nextProgress = FighterProgression.applyExperience(
					fighterDocument.level,
					fighterDocument.experience,
					gainedExperience,
					fighterDocument.ascensionExperience
				)
				fighterDocument.level = nextProgress.level
				fighterDocument.experience = nextProgress.experience
				fighterDocument.ascensionExperience = nextProgress.ascensionExperience
				awardsByFighterId[fighterId] = {
					fighterId = fighterId,
					grantedExperience = gainedExperience,
					levelBefore = beforeLevel,
					levelAfter = nextProgress.level,
					experienceBefore = beforeExperience,
					experienceAfter = nextProgress.experience,
					ascensionExperienceBefore = beforeAscensionExperience,
					ascensionExperienceAfter = nextProgress.ascensionExperience,
					leveledUp = nextProgress.leveledUp,
					levelUps = nextProgress.levelUps,
					overflowExperience = nextProgress.overflowExperience,
					isMaxLevel = nextProgress.isMaxLevel,
				}
			end
		end
	end)

	self._snapshotService:publishRegisteredTopic(player, ReplicationTopics.Fighters)

	local runSeedPayload = self._fighterRosterService:getRunSeedPayload(player)
	local readModel = self._fighterRosterService:getReadModel(player)
	local trioById = {}
	for _, fighter in ipairs(readModel.trio or {}) do
		trioById[fighter.fighterId] = fighter
	end

	local fighterAwards = {}
	local levelUpCount = 0
	for _, fighterId in ipairs(participantIds) do
		local award = awardsByFighterId[fighterId]
		if award ~= nil then
			local fighterReadModel = trioById[fighterId]
			if fighterReadModel ~= nil then
				award.displayName = fighterReadModel.displayName
				award.grade = fighterReadModel.grade
				award.progression = clone(fighterReadModel.progression)
			end
			if award.leveledUp then
				levelUpCount += 1
			end
			table.insert(fighterAwards, award)
		end
	end

	return {
		progression = {
			encounterExperience = grantedExperience,
			survivorCount = #(result.remainingFighterCombatantIds or {}),
			participantCount = #participantIds,
			levelUpCount = levelUpCount,
			fighterAwards = fighterAwards,
		},
		nextRunFighterSnapshots = clone(runSeedPayload.fighterSnapshots),
		fighterMetadataByCombatantId = clone(runSeedPayload.fighterMetadataByCombatantId),
		baseFighterStatesByCombatantId = clone(runSeedPayload.baseFighterStatesByCombatantId),
	}
end

function FighterProgressionService:start()
	self._debugService:registerAction("Fighters", "GrantDebugExperience", function(player, payload)
		assert(type(payload) == "table", "Fighters/GrantDebugExperience requires a payload table")
		return self:grantDebugExperience(player, payload.fighterId, payload.amount)
	end)
	self._debugService:registerAction("Fighters", "SetDebugLevel", function(player, payload)
		assert(type(payload) == "table", "Fighters/SetDebugLevel requires a payload table")
		return self:setDebugLevel(player, payload.fighterId, payload.level)
	end)
	return nil
end

function FighterProgressionService:stop()
	return nil
end

return FighterProgressionService
