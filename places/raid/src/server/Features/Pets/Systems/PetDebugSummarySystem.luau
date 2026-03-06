local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PetIdentity = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PetIdentity"))
local PetOwner = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PetOwner"))
local SkillLoadout = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillLoadout"))
local SkillCooldowns = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillCooldowns"))
local SkillRuntimeState = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillRuntimeState"))
local DebugService = require(
	ServerScriptService:WaitForChild("ServerShared"):WaitForChild("Features"):WaitForChild("Debug"):WaitForChild("DebugService")
)

local function findLastActivatedSkill(lastActivatedAtBySkillId)
	local lastSkillId = nil
	local lastActivatedAt = -math.huge

	for skillId, activatedAt in pairs(lastActivatedAtBySkillId) do
		if type(activatedAt) == "number" and activatedAt > lastActivatedAt then
			lastActivatedAt = activatedAt
			lastSkillId = skillId
		end
	end

	return lastSkillId
end

local function buildSummary(identity, loadout, cooldowns, runtimeState)
	local lines = {
		("Pet: %s"):format(identity.displayName or identity.definitionId or identity.petId),
	}

	local lastSkillId = findLastActivatedSkill(runtimeState.lastActivatedAtBySkillId)
	table.insert(lines, ("Last skill: %s"):format(lastSkillId or "-"))

	for _, skillId in ipairs(loadout.skillIds) do
		local remaining = cooldowns.bySkillId[skillId] or 0
		local activationCount = runtimeState.activationCountsBySkillId[skillId] or 0
		table.insert(lines, ("%s | cd %.1f | casts %d"):format(skillId, remaining, activationCount))
	end

	return table.concat(lines, "\n")
end

local function PetDebugSummarySystem(world)
	for _entityId, identity, owner, loadout, cooldowns, runtimeState in
		world:query(PetIdentity, PetOwner, SkillLoadout, SkillCooldowns, SkillRuntimeState)
	do
		local player = Players:GetPlayerByUserId(owner.userId)
		if player then
			if not DebugService.isViewEnabled(player, "raid_pet_runtime") then
				if player:GetAttribute("RaidPetDebugSummary") ~= nil then
					player:SetAttribute("RaidPetDebugSummary", nil)
				end
				continue
			end

			local summary = buildSummary(identity, loadout, cooldowns, runtimeState)
			local pipelineStatus = player:GetAttribute("RaidPetPipelineStatus")
			if type(pipelineStatus) == "string" and pipelineStatus ~= "" then
				summary = ("%s\n%s"):format(pipelineStatus, summary)
			end
			if player:GetAttribute("RaidPetDebugSummary") ~= summary then
				player:SetAttribute("RaidPetDebugSummary", summary)
			end
		end
	end
end

return PetDebugSummarySystem
