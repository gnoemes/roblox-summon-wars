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

local function buildEarlyResult(action, outcome, resolvedAt)
	return CombatActionResult.new({
		actionId = action.actionId,
		sequence = action.sequence,
		actor = action.actor,
		target = action.target,
		actionType = action.actionType,
		skillId = action.skillId,
		outcome = outcome,
		hit = false,
		damageDealt = 0,
		healingDone = 0,
		appliedEffectIds = {},
		defeatedCombatantIds = {},
		resolvedAt = resolvedAt,
	})
end

function CombatActionResolver.resolveAction(context)
	local actorState = cloneRuntimeState(context.actor.runtimeState)
	local targetState = nil
	if context.target ~= nil then
		if context.target.combatantId == context.actor.combatantId then
			targetState = actorState
		else
			targetState = cloneRuntimeState(context.target.runtimeState)
		end
	end
	local plannedSkill = context.skillDefinition
	local actionType = if plannedSkill.flags.isBasicAttack then "BasicAttack" else "SpecialSkill"
	local action = CombatAction.new({
		actionId = string.format("%s:action:%d", context.encounterId, context.sequence),
		sequence = context.sequence,
		actor = buildCombatantRef(context.actor),
		target = if context.target ~= nil then buildCombatantRef(context.target) else nil,
		actionType = actionType,
		skillId = plannedSkill.skillId,
		startedAt = context.now,
	})

	if actorState.currentHp <= 0 then
		return {
			action = action,
			result = buildEarlyResult(action, "Cancelled", context.now),
			actorState = actorState,
			targetState = targetState,
			rngState = context.rngState,
		}
	end

	if CombatStatusEngine.blocksActions(actorState) then
		return {
			action = action,
			result = buildEarlyResult(action, "Blocked", context.now),
			actorState = actorState,
			targetState = targetState,
			rngState = context.rngState,
		}
	end

	local requiresTarget = plannedSkill.targetKind ~= "None"
	if
		requiresTarget
		and (context.target == nil or targetState == nil or targetState.currentHp <= 0)
	then
		return {
			action = action,
			result = buildEarlyResult(action, "Invalid", context.now),
			actorState = actorState,
			targetState = targetState,
			rngState = context.rngState,
		}
	end

	local hitRoll
	hitRoll, context.rngState = DeterministicRandom.nextFloat(context.rngState)
	local hitChance = if plannedSkill.flags.canMiss and context.target ~= nil
		then CombatMath.calculateHitChance(
			context.actor.computedStats,
			context.target.computedStats
		)
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
				context.target.computedStats,
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
			local statusRoll
			statusRoll, context.rngState = DeterministicRandom.nextFloat(context.rngState)
			local statusChance =
				CombatMath.calculateStatusChance(plannedSkill, context.target.computedStats)
			if CombatMath.rollSuccess(statusChance, statusRoll) then
				targetState.statusesById, appliedEffectIds = CombatStatusEngine.applyStatuses(
					targetState,
					plannedSkill.appliedStatusIds,
					context.now
				)
			end
		end
	end

	if targetState ~= nil and targetState.currentHp <= 0 then
		table.insert(defeatedCombatantIds, context.target.combatantId)
	end

	if plannedSkill.cooldownSeconds ~= nil and plannedSkill.cooldownSeconds > 0 then
		actorState.remainingCooldownsBySkillId[plannedSkill.skillId] = plannedSkill.cooldownSeconds
	end

	local result = CombatActionResult.new({
		actionId = action.actionId,
		sequence = action.sequence,
		actor = action.actor,
		target = action.target,
		actionType = action.actionType,
		skillId = action.skillId,
		outcome = if didHit then "Resolved" else "Missed",
		hit = didHit,
		damageDealt = damageDealt,
		healingDone = healingDone,
		appliedEffectIds = appliedEffectIds,
		defeatedCombatantIds = defeatedCombatantIds,
		resolvedAt = context.now,
	})

	return {
		action = action,
		result = result,
		actorState = actorState,
		targetState = targetState,
		rngState = context.rngState,
	}
end

return CombatActionResolver
