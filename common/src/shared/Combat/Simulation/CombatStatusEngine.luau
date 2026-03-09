local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatActionResult = require(script.Parent.Parent.CombatActionResult)
local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))
local CombatMath = require(script.Parent.CombatMath)

local CombatStatusEngine = {}

local function cloneStatuses(statusesById)
	local cloned = {}

	for statusId, state in pairs(statusesById or {}) do
		cloned[statusId] = {
			statusId = statusId,
			stacks = state.stacks,
			expiresAt = state.expiresAt,
			nextTickAt = state.nextTickAt,
		}
	end

	return cloned
end

local function isAlive(runtimeState)
	return runtimeState.currentHp > 0
end

local function sortStatusIds(statusesById)
	local statusIds = {}

	for statusId in pairs(statusesById) do
		table.insert(statusIds, statusId)
	end

	table.sort(statusIds)

	return statusIds
end

function CombatStatusEngine.cloneStatuses(statusesById)
	return cloneStatuses(statusesById)
end

function CombatStatusEngine.hasStatus(runtimeState, statusId)
	return runtimeState.statusesById[statusId] ~= nil
end

function CombatStatusEngine.blocksActions(runtimeState)
	for statusId in pairs(runtimeState.statusesById) do
		if CombatConfig.StatusDefinitions.get(statusId).flags.blocksActions then
			return true
		end
	end

	return false
end

function CombatStatusEngine.blocksSkills(runtimeState)
	for statusId in pairs(runtimeState.statusesById) do
		if CombatConfig.StatusDefinitions.get(statusId).flags.blocksSkills then
			return true
		end
	end

	return false
end

function CombatStatusEngine.pruneExpired(runtimeState, now)
	local statusesById = cloneStatuses(runtimeState.statusesById)
	local removedStatusIds = {}

	for statusId, statusState in pairs(statusesById) do
		if statusState.expiresAt <= now then
			statusesById[statusId] = nil
			table.insert(removedStatusIds, statusId)
		end
	end

	table.sort(removedStatusIds)

	return statusesById, removedStatusIds
end

function CombatStatusEngine.applyStatuses(runtimeState, statusIds, now)
	local statusesById = cloneStatuses(runtimeState.statusesById)
	local appliedStatusIds = {}

	for _, statusId in ipairs(statusIds) do
		local definition = CombatConfig.StatusDefinitions.get(statusId)
		local current = statusesById[statusId]

		if current == nil then
			statusesById[statusId] = {
				statusId = statusId,
				stacks = 1,
				expiresAt = now + definition.baseDurationSeconds,
				nextTickAt = if definition.tickIntervalSeconds ~= nil
					then now + definition.tickIntervalSeconds
					else nil,
			}
		else
			current.stacks = math.min(current.stacks + 1, definition.maxStacks)
			current.expiresAt = now + definition.baseDurationSeconds
			if definition.tickIntervalSeconds ~= nil and current.nextTickAt == nil then
				current.nextTickAt = now + definition.tickIntervalSeconds
			end
		end

		table.insert(appliedStatusIds, statusId)
	end

	table.sort(appliedStatusIds)

	return statusesById, appliedStatusIds
end

function CombatStatusEngine.tickStatuses(context)
	local runtimeState = context.runtimeState
	local statusesById = cloneStatuses(runtimeState.statusesById)
	local results = {}
	local currentHp = runtimeState.currentHp
	local nextSequence = context.sequence

	for _, statusId in ipairs(sortStatusIds(statusesById)) do
		local statusState = statusesById[statusId]
		local definition = CombatConfig.StatusDefinitions.get(statusId)

		while
			statusState ~= nil
			and statusState.nextTickAt ~= nil
			and statusState.nextTickAt <= context.now
		do
			if not isAlive({ currentHp = currentHp }) then
				break
			end

			local tuning = CombatConfig.Simulation.Statuses[statusId]
			local damage = 0
			if tuning ~= nil then
				damage = CombatMath.calculateDotDamage(
					context.computedStats.hp,
					statusState.stacks,
					tuning.tickDamageRatio
				)
			end

			currentHp = math.max(currentHp - damage, 0)

			local defeatedIds = {}
			if currentHp <= 0 then
				table.insert(defeatedIds, context.combatantId)
			end

			table.insert(
				results,
				CombatActionResult.new({
					actionId = string.format("%s:status:%d", context.encounterId, nextSequence),
					sequence = nextSequence,
					actor = {
						combatantId = context.combatantId,
						kind = context.combatantKind,
					},
					target = {
						combatantId = context.combatantId,
						kind = context.combatantKind,
					},
					actionType = "StatusTick",
					skillId = statusId,
					outcome = "Resolved",
					hit = true,
					damageDealt = damage,
					appliedEffectIds = { statusId },
					defeatedCombatantIds = defeatedIds,
					resolvedAt = statusState.nextTickAt,
				})
			)
			nextSequence += 1

			statusState.nextTickAt += definition.tickIntervalSeconds
			if statusState.expiresAt <= statusState.nextTickAt then
				break
			end
		end
	end

	for statusId, statusState in pairs(statusesById) do
		if statusState.expiresAt <= context.now then
			statusesById[statusId] = nil
		end
	end

	return {
		currentHp = currentHp,
		maxHp = runtimeState.maxHp,
		remainingCooldownsBySkillId = table.clone(runtimeState.remainingCooldownsBySkillId),
		statusesById = statusesById,
		nextActionAt = runtimeState.nextActionAt,
	},
		results,
		nextSequence
end

return CombatStatusEngine
