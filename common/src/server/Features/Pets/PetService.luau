local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local PetProfile = require(Shared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetProfile"))
local PetValidator = require(Shared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetValidator"))
local PetViewBuilder = require(Shared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetViewBuilder"))
local RaidPetSnapshotBuilder = require(
	Shared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("RaidPetSnapshotBuilder")
)

local PetStateStore = require(script.Parent:WaitForChild("PetStateStore"))

local PetService = {}

local DEFAULT_STARTER_DEFINITION_ID = "guardian"

local function cloneProfile(profile)
	return PetProfile.clone(profile)
end

local function getUserId(target)
	if type(target) == "number" then
		return target
	end
	if typeof(target) == "Instance" and target:IsA("Player") then
		return target.UserId
	end
	return nil
end

local function getOrCreateStarterProfile(userId, definitionId)
	local profile = PetStateStore.getActivePetProfile(userId)
	if profile then
		return cloneProfile(profile)
	end

	local starterProfile = PetProfile.create({
		id = ("starter_%d_%s"):format(userId, definitionId),
		definitionId = definitionId,
	})

	PetStateStore.setActivePetProfile(userId, starterProfile)
	return cloneProfile(starterProfile)
end

function PetService.ensureActivePetProfile(target, definitionId)
	local userId = getUserId(target)
	assert(type(userId) == "number", "PetService.ensureActivePetProfile requires a Player or userId")

	return getOrCreateStarterProfile(userId, definitionId or DEFAULT_STARTER_DEFINITION_ID)
end

function PetService.getActivePetProfile(target)
	local userId = getUserId(target)
	assert(type(userId) == "number", "PetService.getActivePetProfile requires a Player or userId")

	local profile = PetStateStore.getActivePetProfile(userId)
	if not profile then
		return nil
	end

	return cloneProfile(profile)
end

function PetService.setActivePetProfile(target, petProfile)
	local userId = getUserId(target)
	assert(type(userId) == "number", "PetService.setActivePetProfile requires a Player or userId")

	local validation = PetValidator.validate(petProfile)
	if not validation.ok then
		return false, validation.errors
	end

	PetStateStore.setActivePetProfile(userId, cloneProfile(petProfile))
	return true
end

function PetService.clearActivePetProfile(target)
	local userId = getUserId(target)
	assert(type(userId) == "number", "PetService.clearActivePetProfile requires a Player or userId")

	PetStateStore.clearActivePetProfile(userId)
end

function PetService.getActivePetViewState(target, scalePresetId)
	local profile = PetService.getActivePetProfile(target)
	if not profile then
		profile = PetService.ensureActivePetProfile(target)
	end

	return PetViewBuilder.build(profile, {
		scalePresetId = scalePresetId,
	})
end

function PetService.buildRaidPetSnapshot(target, params)
	local profile = PetService.getActivePetProfile(target)
	if not profile then
		profile = PetService.ensureActivePetProfile(target)
	end

	return RaidPetSnapshotBuilder.build(profile, params)
end

return PetService
