local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))
local EncounterConfig = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Extractions")
		:WaitForChild("EncounterConfig")
)
local SyntheticScenarioPresets = require(
	script.Parent
		:WaitForChild("Scenarios")
		:WaitForChild("Test")
		:WaitForChild("SyntheticScenarioPresets")
)

local EnemyDefinitions = CombatConfig.EnemyDefinitions
local ClassDefinitions = CombatConfig.Fighters.ClassDefinitions
local CombatStatsBuilder = CombatConfig.Fighters.CombatStatsBuilder

local SyntheticCombatFactory = {}

local function deepClone(value)
	if type(value) ~= "table" then
		return value
	end

	local cloned = {}
	for key, entry in pairs(value) do
		cloned[key] = deepClone(entry)
	end
	return cloned
end

function SyntheticCombatFactory.createRun(player, extractionType, enemyId)
	local selectedEnemyId = enemyId
		or SyntheticScenarioPresets.DefaultEnemyIdByExtractionType[extractionType]
	assert(
		type(selectedEnemyId) == "string" and selectedEnemyId ~= "",
		"Synthetic enemyId is required"
	)
	local enemyDefinition = EnemyDefinitions.get(selectedEnemyId)
	local runInstanceId = string.format("Run:%d:%s", player.UserId, extractionType)
	local fighterSnapshots = {}
	local baseFighterStatesByCombatantId = {}
	local fighterMetadataByCombatantId = {}

	for _, spec in ipairs(SyntheticScenarioPresets.DefaultFighterTrio) do
		local snapshot = CombatStatsBuilder.buildFighterSnapshot(spec)
		local classDefinition = ClassDefinitions.get(snapshot.classId)
		table.insert(fighterSnapshots, snapshot)
		baseFighterStatesByCombatantId[snapshot.combatantId] = {
			combatantId = snapshot.combatantId,
			maxHp = snapshot.computedStats.hp,
			currentHp = snapshot.computedStats.hp,
		}
		fighterMetadataByCombatantId[snapshot.combatantId] = {
			combatantId = snapshot.combatantId,
			displayName = classDefinition.displayName,
			classId = snapshot.classId,
			grade = snapshot.grade,
		}
	end

	table.sort(fighterSnapshots, function(left, right)
		return left.combatantId < right.combatantId
	end)

	return {
		runInstanceId = runInstanceId,
		ownerUserId = player.UserId,
		extractionType = extractionType,
		enemyId = enemyDefinition.enemyId,
		fighterSnapshots = fighterSnapshots,
		fighterMetadataByCombatantId = deepClone(fighterMetadataByCombatantId),
		baseFighterStatesByCombatantId = deepClone(baseFighterStatesByCombatantId),
		persistentFighterStatesByCombatantId = deepClone(baseFighterStatesByCombatantId),
		encounterIndex = 0,
		activeEncounterId = nil,
		activeEncounterEntityId = nil,
		lastEncounter = nil,
		completedEncounterIds = {},
	}
end

function SyntheticCombatFactory.createEncounter(runState)
	local encounterIndex = runState.encounterIndex + 1
	local encounterId = string.format("%s:Encounter:%d", runState.runInstanceId, encounterIndex)
	local enemyDefinition = EnemyDefinitions.get(runState.enemyId)
	local encounterConfig = EncounterConfig.new({
		encounterId = encounterId,
		extractionType = runState.extractionType,
		enemyId = runState.enemyId,
		runInstanceId = runState.runInstanceId,
		stageLabel = string.format("Synthetic %d", encounterIndex),
		recommendedSquadPower = nil,
		minimumSquadPower = nil,
		flags = {
			isElite = enemyDefinition.tier == "Elite",
			isRare = enemyDefinition.flags.isRare,
			isBoss = enemyDefinition.tier == "Boss",
			isChestReplacement = enemyDefinition.flags.isChestReplacement,
		},
	})
	local fighters = {}

	for index, snapshot in ipairs(runState.fighterSnapshots) do
		local persistentState = runState.persistentFighterStatesByCombatantId[snapshot.combatantId]
		local classDefinition = ClassDefinitions.get(snapshot.classId)
		table.insert(fighters, {
			combatantId = snapshot.combatantId,
			kind = "Fighter",
			displayName = classDefinition.displayName,
			classId = snapshot.classId,
			order = index,
			aggroWeight = classDefinition.aggroWeight,
			computedStats = deepClone(snapshot.computedStats),
			basicSkillId = CombatConfig.Simulation.DefaultBasicSkillId,
			specialSkillIds = deepClone(snapshot.activeSkillIds),
			passiveSkillIds = {},
			runtimeState = {
				currentHp = persistentState.currentHp,
				maxHp = persistentState.maxHp,
				nextActionAt = snapshot.computedStats.attackIntervalSeconds,
				remainingCooldownsBySkillId = {},
				statusesById = {},
			},
		})
	end

	local enemyCombatantId = string.format("%s:Enemy:%d", runState.runInstanceId, encounterIndex)
	local enemy = {
		combatantId = enemyCombatantId,
		kind = "Enemy",
		displayName = enemyDefinition.displayName,
		enemyId = enemyDefinition.enemyId,
		order = 1,
		aggroWeight = 0,
		computedStats = deepClone(enemyDefinition.computedStats),
		basicSkillId = enemyDefinition.basicAttackSkillId,
		specialSkillIds = deepClone(enemyDefinition.specialSkillIds),
		passiveSkillIds = deepClone(enemyDefinition.passiveSkillIds),
		runtimeState = {
			currentHp = enemyDefinition.computedStats.hp,
			maxHp = enemyDefinition.computedStats.hp,
			nextActionAt = enemyDefinition.computedStats.attackIntervalSeconds,
			remainingCooldownsBySkillId = {},
			statusesById = {},
		},
	}

	return encounterConfig, fighters, enemy
end

return SyntheticCombatFactory
