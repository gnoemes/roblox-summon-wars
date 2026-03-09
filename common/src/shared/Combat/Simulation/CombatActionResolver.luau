local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatAction = require(script.Parent.Parent.CombatAction)
local CombatActionResult = require(script.Parent.Parent.CombatActionResult)
local CombatMath = require(script.Parent.CombatMath)
local CombatStatusEngine = require(script.Parent.CombatStatusEngine)
local DeterministicRandom = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Utils")
		:WaitForChild("DeterministicRandom")
)

local CombatActionResolver = {}

local function cloneRuntimeState(runtimeState)
	return {
		currentHp = runtimeState.currentHp,
		maxHp = runtimeState.maxHp,
		nextActionAt = runtimeState.nextActionAt,
		remainingCooldownsBySkillId = table.clone(runtimeState.remainingCooldownsBySkillId),
		statusesById = CombatStatusEngine.cloneStatuses(runtimeState.statusesById),
	}
end

local function buildCombatantRef(combatant)
	return {
		combatantId = combatant.combatantId,
		kind = combatant.kind,
	}
end

local function buildEarlyResult(action, sequence, target, outcome, resolvedAt)
	return CombatActionResult.new({
		actionId = action.actionId,
		sequence = sequence,
		actor = action.actor,
		target = if target ~= nil then buildCombatantRef(target) else action.target,
		actionType = action.actionType,
		skillId = action.skillId,
		outcome = outcome,
		hit = false,
		criticalHit = false,
		damageDealt = 0,
		healingDone = 0,
		appliedEffectIds = {},
		defeatedCombatantIds = {},
		resolvedAt = resolvedAt,
	})
end

local function getDotResponseKind(target, statusId)
	local responsesByStatusId = target.dotResponsesByStatusId
	if type(responsesByStatusId) ~= "table" then
		return "Normal"
	end

	local responseKind = responsesByStatusId[statusId]
	if type(responseKind) ~= "string" or responseKind == "" then
		return "Normal"
	end

	return responseKind
end

local function applyStatuses(context, plannedSkill, target, targetState)
	local appliedEffectIds = {}
	if target == nil or targetState == nil or #plannedSkill.appliedStatusIds == 0 then
		return targetState, appliedEffectIds, context.rngState
	end

	for _, statusId in ipairs(plannedSkill.appliedStatusIds) do
		local statusDefinition = context.statusDefinitions.get(statusId)
		local stacksToApply = 0

		if statusDefinition.flags.isDamageOverTime then
			local responseKind = getDotResponseKind(target, statusId)
			if responseKind == "Vulnerable" then
				stacksToApply = 2
			elseif responseKind == "Normal" then
				stacksToApply = 1
			end
		else
			local statusRoll
			statusRoll, context.rngState = DeterministicRandom.nextFloat(context.rngState)
			local statusChance =
				CombatMath.calculateControlChance(plannedSkill, target.computedStats)
			if CombatMath.rollSuccess(statusChance, statusRoll) then
				stacksToApply = 1
			end
		end

		if stacksToApply > 0 then
			local nextStatusesById, appliedStatusIds = CombatStatusEngine.applyStatusStacks(
				targetState,
				statusId,
				stacksToApply,
				context.now
			)
			targetState.statusesById = nextStatusesById
			for _, appliedStatusId in ipairs(appliedStatusIds) do
				table.insert(appliedEffectIds, appliedStatusId)
			end
		end
	end

	table.sort(appliedEffectIds)
	return targetState, appliedEffectIds, context.rngState
end

local function resolveAgainstTarget(context, action, sequence, actorState, target)
	local plannedSkill = context.skillDefinition
	local targetState = nil
	if target ~= nil then
		if target.combatantId == context.actor.combatantId then
			targetState = actorState
		else
			targetState = cloneRuntimeState(target.runtimeState)
		end
	end

	local hitRoll
	hitRoll, context.rngState = DeterministicRandom.nextFloat(context.rngState)
	local hitChance = if plannedSkill.flags.canMiss and target ~= nil
		then CombatMath.calculateHitChance(context.actor.computedStats, target.computedStats)
		else 1
	local didHit = CombatMath.rollSuccess(hitChance, hitRoll)
	local didCrit = false
	local damageDealt = 0
	local healingDone = 0
	local appliedEffectIds = {}
	local defeatedCombatantIds = {}

	if didHit then
		local critRoll
		critRoll, context.rngState = DeterministicRandom.nextFloat(context.rngState)
		didCrit = plannedSkill.flags.canCrit
			and CombatMath.rollSuccess(context.actor.computedStats.critChance, critRoll)
		damageDealt = if plannedSkill.damageMultiplier > 0 and targetState ~= nil
			then CombatMath.calculateDamage(
				context.actor.computedStats,
				target.computedStats,
				plannedSkill,
				didCrit
			)
			else 0
		if targetState ~= nil and damageDealt > 0 then
			targetState.currentHp = math.max(targetState.currentHp - damageDealt, 0)
		end

		local healRecipientState = nil
		if plannedSkill.healMultiplier > 0 then
			if plannedSkill.targetKind == "Self" then
				healRecipientState = actorState
			elseif targetState ~= nil then
				healRecipientState = targetState
			end
		end
		if healRecipientState ~= nil then
			local nextHp = math.min(
				healRecipientState.currentHp
					+ CombatMath.calculateHealing(context.actor.computedStats, plannedSkill),
				healRecipientState.maxHp
			)
			healingDone = math.max(nextHp - healRecipientState.currentHp, 0)
			healRecipientState.currentHp = nextHp
		end

		if targetState ~= nil and #plannedSkill.appliedStatusIds > 0 then
			targetState, appliedEffectIds, context.rngState = applyStatuses({
				now = context.now,
				rngState = context.rngState,
				statusDefinitions = context.statusDefinitions,
			}, plannedSkill, target, targetState)
		end
	end

	if targetState ~= nil and target ~= nil and targetState.currentHp <= 0 then
		targetState.statusesById = {}
		table.insert(defeatedCombatantIds, target.combatantId)
	end

	local result = CombatActionResult.new({
		actionId = action.actionId,
		sequence = sequence,
		actor = action.actor,
		target = if target ~= nil then buildCombatantRef(target) else nil,
		actionType = action.actionType,
		skillId = action.skillId,
		outcome = if didHit then "Resolved" else "Missed",
		hit = didHit,
		criticalHit = didCrit,
		damageDealt = damageDealt,
		healingDone = healingDone,
		appliedEffectIds = appliedEffectIds,
		defeatedCombatantIds = defeatedCombatantIds,
		resolvedAt = context.now,
	})

	local targetStatePatch = nil
	if target ~= nil and target.combatantId ~= context.actor.combatantId and targetState ~= nil then
		targetStatePatch = {
			combatant = target,
			runtimeState = targetState,
		}
	end

	return actorState, targetStatePatch, result, context.rngState
end

function CombatActionResolver.resolveAction(context)
	local actorState = cloneRuntimeState(context.actor.runtimeState)
	local plannedSkill = context.skillDefinition
	local actionType = if plannedSkill.flags.isBasicAttack then "BasicAttack" else "SpecialSkill"
	local targets = context.targets or {}
	local primaryTarget = context.primaryTarget
	if primaryTarget == nil then
		primaryTarget = targets[1]
	end

	local action = CombatAction.new({
		actionId = string.format("%s:action:%d", context.encounterId, context.sequence),
		sequence = context.sequence,
		actor = buildCombatantRef(context.actor),
		target = if primaryTarget ~= nil then buildCombatantRef(primaryTarget) else nil,
		actionType = actionType,
		skillId = plannedSkill.skillId,
		startedAt = context.now,
	})

	if actorState.currentHp <= 0 then
		return {
			action = action,
			results = {
				buildEarlyResult(action, context.sequence, primaryTarget, "Cancelled", context.now),
			},
			actorState = actorState,
			targetStatePatches = {},
			rngState = context.rngState,
		}
	end

	if CombatStatusEngine.blocksActions(actorState) then
		return {
			action = action,
			results = {
				buildEarlyResult(action, context.sequence, primaryTarget, "Blocked", context.now),
			},
			actorState = actorState,
			targetStatePatches = {},
			rngState = context.rngState,
		}
	end

	local requiresTarget = plannedSkill.targetKind ~= "None"
	if requiresTarget and #targets == 0 then
		return {
			action = action,
			results = {
				buildEarlyResult(action, context.sequence, primaryTarget, "Invalid", context.now),
			},
			actorState = actorState,
			targetStatePatches = {},
			rngState = context.rngState,
		}
	end

	local results = {}
	local targetStatePatches = {}
	local nextSequence = context.sequence

	if #targets == 0 then
		local targetStatePatch
		local result
		actorState, targetStatePatch, result, context.rngState =
			resolveAgainstTarget(context, action, nextSequence, actorState, nil)
		table.insert(results, result)
		if targetStatePatch ~= nil then
			table.insert(targetStatePatches, targetStatePatch)
		end
	else
		for _, target in ipairs(targets) do
			local targetStatePatch
			local result
			actorState, targetStatePatch, result, context.rngState =
				resolveAgainstTarget(context, action, nextSequence, actorState, target)
			table.insert(results, result)
			if targetStatePatch ~= nil then
				table.insert(targetStatePatches, targetStatePatch)
			end
			nextSequence = nextSequence + 1
		end
	end

	if plannedSkill.cooldownSeconds ~= nil and plannedSkill.cooldownSeconds > 0 then
		actorState.remainingCooldownsBySkillId[plannedSkill.skillId] = plannedSkill.cooldownSeconds
	end

	return {
		action = action,
		results = results,
		actorState = actorState,
		targetStatePatches = targetStatePatches,
		rngState = context.rngState,
	}
end

return CombatActionResolver
