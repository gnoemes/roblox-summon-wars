local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer:WaitForChild("PlayerScripts")
local clientShared = playerScripts:WaitForChild("ClientShared")

local RaidPetRegistry = require(script.Parent:WaitForChild("RaidPetRegistry"))
local PetFollowerRenderer = require(
	clientShared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetFollowerRenderer")
)

local spawnStatesByUserId = {}

local function getCharacterRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function getOrCreateSpawnCFrame(player, userId, slotIndex)
	local cached = spawnStatesByUserId[userId]
	if cached and cached.lockedToCharacter then
		return cached.cframe
	end

	local rootPart = getCharacterRootPart(player)
	if rootPart then
		local rightOffset = 6 + (slotIndex - 1) * 4
		local forwardOffset = -10
		local worldPosition =
			rootPart.CFrame:PointToWorldSpace(Vector3.new(rightOffset, 0, forwardOffset))
		local resolved = CFrame.lookAt(worldPosition, worldPosition + rootPart.CFrame.LookVector, Vector3.yAxis)
		spawnStatesByUserId[userId] = {
			cframe = resolved,
			lockedToCharacter = true,
		}
		return resolved
	else
		local fallbackPosition = Vector3.new((slotIndex - 1) * 4, 0, 0)
		local fallback = CFrame.lookAt(fallbackPosition, fallbackPosition + Vector3.zAxis, Vector3.yAxis)
		spawnStatesByUserId[userId] = {
			cframe = fallback,
			lockedToCharacter = false,
		}
		return fallback
	end
end

PetFollowerRenderer.start({
	registry = RaidPetRegistry,
	renderStepName = "RaidPetFollowerRenderer",
	renderPriority = Enum.RenderPriority.Character.Value + 1,
	renderFolderName = "ClientRaidPets",
	modelNamePrefix = "RaidPet",
	sideOffset = 0,
	backOffset = 0,
	heightOffset = 0,
	lerpAlpha = 0.22,
	computeTargetCFrame = function(context)
		local slotIndex = context.index or 1
		local baseCFrame = getOrCreateSpawnCFrame(context.player, context.userId, slotIndex)
		local modelHeight = context.record.model:GetExtentsSize().Y * 0.5
		return baseCFrame + Vector3.new(0, modelHeight, 0)
	end,
})
