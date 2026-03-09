local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ECS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ECS"))
local Combat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Combat"))
local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))
local Components = require(script.Parent.CombatComponents)

local CombatStatusEngine = Combat.Simulation.CombatStatusEngine
local CombatTargeting = Combat.Simulation.CombatTargeting
local CombatActionPlanner = Combat.Simulation.CombatActionPlanner
local CombatActionResolver = Combat.Simulation.CombatActionResolver
local EncounterRules = Combat.Simulation.EncounterRules

local CombatSystems = {}

local function appendJournalEntry(encounter, entry)
	local nextEntries = table.clone(encounter.journalEntries)
	table.insert(nextEntries, entry)

	while #nextEntries > CombatConfig.Simulation.Encounter.JournalLimit do
		table.remove(nextEntries, 1)
	end

	return encounter:patch({
		journalEntries = nextEntries,
	})
end

local function getRunningEncounterIds(world)
	local running = {}

	for _, encounter in world:query(Components.Encounter) do
		if encounter.state == "Running" then
			running[encounter.encounterId] = true
		end
	end

	return running
end

local function collectEncounterCombatants(world, encounterId)
	local fighters = {}
	local enemies = {}
	local all = {}

	for entityId, combatant, stats, runtime, abilities in
		world:query(
			Components.Combatant,
			Components.CombatantStats,
			Components.CombatantRuntime,
			Components.CombatantAbilities
		)
	do
		if combatant.encounterId == encounterId then
			local record = {
				entityId = entityId,
				encounterId = encounterId,
				combatantId = combatant.combatantId,
				kind = combatant.kind,
				displayName = combatant.displayName,
				classId = combatant.classId,
				enemyId = combatant.enemyId,
				order = combatant.order,
				aggroWeight = combatant.aggroWeight,
				computedStats = stats.computedStats,
				runtimeState = runtime,
				basicSkillId = abilities.basicSkillId,
				specialSkillIds = abilities.specialSkillIds,
				passiveSkillIds = abilities.passiveSkillIds,
			}
			table.insert(all, record)
			if combatant.kind == "Fighter" then
				table.insert(fighters, record)
			else
				table.insert(enemies, record)
			end
		end
	end

	local function sorter(left, right)
		if left.order ~= right.order then
			return left.order < right.order
		end
		return left.combatantId < right.combatantId
	end

	table.sort(fighters, sorter)
	table.sort(enemies, sorter)
	table.sort(all, sorter)

	return fighters, enemies, all
end

local function patchCombatantRuntime(world, combatant, nextRuntimeState)
	world:insert(combatant.entityId, Components.CombatantRuntime(nextRuntimeState))
end

local function sortReadyCombatants(combatants)
	table.sort(combatants, function(left, right)
		if left.runtimeState.nextActionAt ~= right.runtimeState.nextActionAt then
			return left.runtimeState.nextActionAt < right.runtimeState.nextActionAt
		end

		local leftBias = CombatConfig.Simulation.Encounter.ActionOrderBiasByKind[left.kind] or 99
		local rightBias = CombatConfig.Simulation.Encounter.ActionOrderBiasByKind[right.kind] or 99
		if leftBias ~= rightBias then
			return leftBias < rightBias
		end

		return left.combatantId < right.combatantId
	end)
end

local function decrementCooldowns(runtimeState, deltaTime)
	if next(runtimeState.remainingCooldownsBySkillId) == nil then
		return runtimeState, false
	end

	local nextCooldowns = {}
	local changed = false

	for skillId, remaining in pairs(runtimeState.remainingCooldownsBySkillId) do
		local nextRemaining = math.max(remaining - deltaTime, 0)
		nextCooldowns[skillId] = nextRemaining
		if math.abs(nextRemaining - remaining) > 0.0001 then
			changed = true
		end
	end

	if not changed then
		return runtimeState, false
	end

	return runtimeState:patch({
		remainingCooldownsBySkillId = nextCooldowns,
	}), true
end

local function buildEncounterResult(encounter, journalEntries, fighters, enemies)
	local actionResults = {}
	for _, entry in ipairs(journalEntries) do
		if entry.kind == "Action" then
			table.insert(actionResults, entry.actionResult)
		end
	end

	local remainingFighterCombatantIds = {}
	local defeatedFighterCombatantIds = {}
	for _, fighter in ipairs(fighters) do
		if fighter.runtimeState.currentHp > 0 then
			table.insert(remainingFighterCombatantIds, fighter.combatantId)
		else
			table.insert(defeatedFighterCombatantIds, fighter.combatantId)
		end
	end

	local defeatedEnemyCombatantIds = {}
	for _, enemy in ipairs(enemies) do
		if enemy.runtimeState.currentHp <= 0 then
			table.insert(defeatedEnemyCombatantIds, enemy.combatantId)
		end
	end

	return Combat.EncounterResult.new({
		encounterId = encounter.encounterId,
		outcome = encounter.outcome,
		startedAt = encounter.startedAt,
		endedAt = encounter.elapsedTime,
		durationSeconds = math.max(encounter.elapsedTime - encounter.startedAt, 0),
		actionResults = actionResults,
		remainingFighterCombatantIds = remainingFighterCombatantIds,
		defeatedFighterCombatantIds = defeatedFighterCombatantIds,
		defeatedEnemyCombatantIds = defeatedEnemyCombatantIds,
		rewardBundle = nil,
	})
end

local tickEncounterTimeSystem = ECS.SystemBuilder.server("Simulation", function(world, context)
	local deltaTime = context.ecs.useDeltaTime()

	for entityId, encounter in world:query(Components.Encounter) do
		if encounter.state == "Running" then
			world:insert(
				entityId,
				encounter:patch({
					elapsedTime = encounter.elapsedTime + deltaTime,
				})
			)
		end
	end
end)

local tickCooldownsSystem = ECS.SystemBuilder.server("Simulation", function(world)
	local runningEncounterIds = getRunningEncounterIds(world)
	local deltaTime = ECS.useDeltaTime()

	for entityId, combatant, runtime in
		world:query(Components.Combatant, Components.CombatantRuntime)
	do
		if runningEncounterIds[combatant.encounterId] == true and runtime.currentHp > 0 then
			local nextRuntime, changed = decrementCooldowns(runtime, deltaTime)
			if changed then
				world:insert(entityId, nextRuntime)
			end
		end
	end
end, {
	after = { tickEncounterTimeSystem },
})

local tickStatusesSystem = ECS.SystemBuilder.server("Simulation", function(world)
	for encounterEntityId, encounter in world:query(Components.Encounter) do
		if encounter.state == "Running" then
			local nextEncounter = encounter
			local sequence = encounter.sequence
			local _, _, allCombatants = collectEncounterCombatants(world, nextEncounter.encounterId)

			for _, combatant in ipairs(allCombatants) do
				local nextRuntimeState, results, nextSequence = CombatStatusEngine.tickStatuses({
					encounterId = encounter.encounterId,
					combatantId = combatant.combatantId,
					combatantKind = combatant.kind,
					computedStats = combatant.computedStats,
					runtimeState = combatant.runtimeState,
					now = nextEncounter.elapsedTime,
					sequence = sequence,
				})
				sequence = nextSequence
				patchCombatantRuntime(world, combatant, nextRuntimeState)

				for _, result in ipairs(results) do
					nextEncounter = appendJournalEntry(
						nextEncounter,
						Combat.CombatJournalEntry.new({
							kind = "Action",
							at = result.resolvedAt,
							actionResult = result,
						})
					)
				end
			end

			world:insert(
				encounterEntityId,
				nextEncounter:patch({
					sequence = sequence,
				})
			)
		end
	end
end, {
	after = { tickCooldownsSystem },
})

local resolveActionsSystem = ECS.SystemBuilder.server("Simulation", function(world)
	for encounterEntityId, encounter in world:query(Components.Encounter) do
		if encounter.state == "Running" then
			local nextEncounter = encounter
			local actionsResolved = 0

			while actionsResolved < CombatConfig.Simulation.Encounter.MaxActionCatchUpPerFrame do
				local fighters, enemies, allCombatants =
					collectEncounterCombatants(world, nextEncounter.encounterId)
				local outcome = EncounterRules.getOutcome(fighters, enemies)
				if outcome ~= nil then
					break
				end

				local readyCombatants = {}
				for _, combatant in ipairs(allCombatants) do
					if
						combatant.runtimeState.currentHp > 0
						and combatant.runtimeState.nextActionAt <= nextEncounter.elapsedTime
					then
						table.insert(readyCombatants, combatant)
					end
				end

				if #readyCombatants == 0 then
					break
				end

				sortReadyCombatants(readyCombatants)
				local actor = readyCombatants[1]
				local skillDefinition = CombatActionPlanner.selectSkill(actor, actor.runtimeState)
					or CombatConfig.SkillDefinitions.get(actor.basicSkillId)
				local target = nil
				local nextRngState = nextEncounter.rngState

				if actor.kind == "Fighter" then
					target = CombatTargeting.selectEnemyTarget(enemies)
				else
					target, nextRngState =
						CombatTargeting.selectFighterTarget(fighters, nextRngState)
				end

				local resolved = CombatActionResolver.resolveAction({
					encounterId = encounter.encounterId,
					sequence = nextEncounter.sequence,
					now = nextEncounter.elapsedTime,
					actor = actor,
					target = target,
					skillDefinition = skillDefinition,
					rngState = nextRngState,
				})

				resolved.actorState.nextActionAt = actor.runtimeState.nextActionAt
					+ actor.computedStats.attackIntervalSeconds
				patchCombatantRuntime(world, actor, resolved.actorState)
				if target ~= nil and resolved.targetState ~= nil then
					patchCombatantRuntime(world, target, resolved.targetState)
				end

				nextEncounter = appendJournalEntry(
					nextEncounter,
					Combat.CombatJournalEntry.new({
						kind = "Action",
						at = resolved.result.resolvedAt,
						actionResult = resolved.result,
					})
				)
				nextEncounter = nextEncounter:patch({
					sequence = nextEncounter.sequence + 1,
					rngState = resolved.rngState,
				})
				world:insert(encounterEntityId, nextEncounter)

				actionsResolved += 1

				local postFighters, postEnemies =
					collectEncounterCombatants(world, nextEncounter.encounterId)
				local postOutcome = EncounterRules.getOutcome(postFighters, postEnemies)
				if postOutcome ~= nil then
					break
				end
			end
		end
	end
end, {
	after = { tickStatusesSystem },
})

local finalizeEncountersSystem = ECS.SystemBuilder.server("Cleanup", function(world, context)
	local encounterService = context.services:get("CombatEncounterService")

	for entityId, encounter in world:query(Components.Encounter) do
		if encounter.state == "Running" then
			local fighters, enemies = collectEncounterCombatants(world, encounter.encounterId)
			local outcome = EncounterRules.getOutcome(fighters, enemies)
			if outcome ~= nil then
				local journalEntries = table.clone(encounter.journalEntries)
				table.insert(
					journalEntries,
					Combat.CombatJournalEntry.new({
						kind = "EncounterEnd",
						at = encounter.elapsedTime,
						encounterOutcome = outcome,
					})
				)

				local finalizedEncounter = encounter:patch({
					state = "Completed",
					outcome = outcome,
					journalEntries = journalEntries,
					cleanupQueued = true,
				})
				world:insert(entityId, finalizedEncounter)

				local finalFighterStatesByCombatantId = {}
				for _, fighter in ipairs(fighters) do
					finalFighterStatesByCombatantId[fighter.combatantId] = {
						combatantId = fighter.combatantId,
						currentHp = fighter.runtimeState.currentHp,
						maxHp = fighter.runtimeState.maxHp,
					}
				end

				encounterService:completeEncounter(encounter.encounterId, {
					ownerUserId = encounter.ownerUserId,
					result = buildEncounterResult(
						finalizedEncounter,
						journalEntries,
						fighters,
						enemies
					),
					journalEntries = journalEntries,
					finalFighterStatesByCombatantId = finalFighterStatesByCombatantId,
				})
			end
		end
	end
end, {
	after = { resolveActionsSystem },
})

local cleanupEncountersSystem = ECS.SystemBuilder.server("Cleanup", function(world, context)
	local encounterService = context.services:get("CombatEncounterService")
	local cleanupEncounterIds = {}

	for _, encounter in world:query(Components.Encounter) do
		if encounter.state == "Completed" and encounter.cleanupQueued then
			table.insert(cleanupEncounterIds, encounter.encounterId)
		end
	end

	for _, encounterId in ipairs(cleanupEncounterIds) do
		encounterService:queueEncounterCleanup(encounterId)
	end
end, {
	after = { finalizeEncountersSystem },
})

function CombatSystems.getSystems()
	return {
		tickEncounterTimeSystem,
		tickCooldownsSystem,
		tickStatusesSystem,
		resolveActionsSystem,
		finalizeEncountersSystem,
		cleanupEncountersSystem,
	}
end

return CombatSystems
