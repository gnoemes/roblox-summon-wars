local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PetService = require(
	ServerScriptService:WaitForChild("ServerShared"):WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetService")
)

local PetIdentity = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PetIdentity"))
local PetOwner = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PetOwner"))
local ResolvedStats = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ResolvedStats"))
local HealthState = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("HealthState"))
local SkillLoadout = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillLoadout"))
local SkillCooldowns = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillCooldowns"))
local MutationLoadout = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("MutationLoadout"))
local VisualLoadout = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("VisualLoadout"))
local CommandState = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("CommandState"))
local SkillRuntimeState = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillRuntimeState"))
local PetFactory = require(script.Parent.Parent:WaitForChild("PetFactory"))

local function SpawnActivePetSystem(world)
	local spawnedEntityIdByUserId = {}
	local spawnedIdentityByUserId = {}
	for entityId, owner, identity in world:query(PetOwner, PetIdentity) do
		spawnedEntityIdByUserId[owner.userId] = entityId
		spawnedIdentityByUserId[owner.userId] = identity
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local snapshot, errors = PetService.buildRaidPetSnapshot(player, {
			ownerUserId = player.UserId,
		})
		if not snapshot then
			player:SetAttribute(
				"RaidPetPipelineStatus",
				("Spawn failed: %s"):format(
					if type(errors) == "table" then table.concat(errors, "; ") else "unknown snapshot error"
				)
			)
			warn(
				("Failed to build raid pet snapshot for user %d: %s"):format(
					player.UserId,
					if type(errors) == "table" then table.concat(errors, "; ") else "unknown error"
				)
			)
			continue
		end

		local existingEntityId = spawnedEntityIdByUserId[player.UserId]
		local existingIdentity = spawnedIdentityByUserId[player.UserId]
		local requiresRefresh = existingEntityId ~= nil
			and existingIdentity ~= nil
			and (existingIdentity.petId ~= snapshot.petId or existingIdentity.definitionId ~= snapshot.definitionId)

		if existingEntityId == nil or requiresRefresh then
			player:SetAttribute("RaidPetPipelineStatus", "Spawn: syncing raid pet snapshot")
			local okSpawn, spawnError = pcall(function()
				local nextComponents = PetFactory.buildComponents(snapshot, {
					PetIdentity = PetIdentity,
					PetOwner = PetOwner,
					ResolvedStats = ResolvedStats,
					HealthState = HealthState,
					SkillLoadout = SkillLoadout,
					SkillCooldowns = SkillCooldowns,
					MutationLoadout = MutationLoadout,
					VisualLoadout = VisualLoadout,
					CommandState = CommandState,
					SkillRuntimeState = SkillRuntimeState,
				})

				if existingEntityId == nil then
					world:spawn(table.unpack(nextComponents))
				else
					world:replace(existingEntityId, table.unpack(nextComponents))
				end
			end)

			if okSpawn then
				if existingEntityId == nil then
					player:SetAttribute("RaidPetPipelineStatus", ("Spawned ECS pet '%s'"):format(snapshot.definitionId))
				else
					player:SetAttribute("RaidPetPipelineStatus", ("Updated ECS pet '%s'"):format(snapshot.definitionId))
				end
			else
				player:SetAttribute(
					"RaidPetPipelineStatus",
					("Spawn failed: %s"):format(tostring(spawnError))
				)
				warn(("Failed to spawn ECS pet for user %d: %s"):format(player.UserId, tostring(spawnError)))
			end
		end
	end
end

return SpawnActivePetSystem
