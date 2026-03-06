local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Matter"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SkillDefinitions = require(
	Shared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("Definitions"):WaitForChild("SkillDefinitions")
)

local SkillLoadout = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillLoadout"))
local SkillCooldowns = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillCooldowns"))
local SkillRuntimeState = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillRuntimeState"))
local ResolvedStats = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ResolvedStats"))

local function AutoSkillSystem(world)
	local now = os.clock()

	for entityId, loadout, cooldowns, runtimeState, resolvedStats in
		world:query(SkillLoadout, SkillCooldowns, SkillRuntimeState, ResolvedStats)
	do
		local nextCooldowns = nil
		local nextLastActivatedAt = nil
		local nextActivationCounts = nil

		for _, skillId in ipairs(loadout.skillIds) do
			local skill = SkillDefinitions.ById[skillId]
			if skill and skill.executionMode == "auto_cooldown" then
				local remainingCooldown = cooldowns.bySkillId[skillId] or 0
				if remainingCooldown <= 0 then
					nextCooldowns = nextCooldowns or table.clone(cooldowns.bySkillId)
					nextLastActivatedAt = nextLastActivatedAt or table.clone(runtimeState.lastActivatedAtBySkillId)
					nextActivationCounts = nextActivationCounts or table.clone(runtimeState.activationCountsBySkillId)

					local cooldownDuration = skill.cooldown or 0
					local cdr = resolvedStats.values.cooldownReduction or 0
					nextCooldowns[skillId] = math.max(0, cooldownDuration * math.max(0, 1 - cdr))
					nextLastActivatedAt[skillId] = now
					nextActivationCounts[skillId] = (nextActivationCounts[skillId] or 0) + 1
				end
			end
		end

		if nextCooldowns then
			world:insert(entityId, cooldowns:patch({
				bySkillId = nextCooldowns,
			}))
		end

		if nextLastActivatedAt then
			world:insert(entityId, runtimeState:patch({
				lastActivatedAtBySkillId = nextLastActivatedAt,
				activationCountsBySkillId = nextActivationCounts,
			}))
		end
	end
end

return AutoSkillSystem
