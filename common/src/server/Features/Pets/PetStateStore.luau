local PetStateStore = {}

local activePetProfilesByUserId = {}

function PetStateStore.getActivePetProfile(userId)
	return activePetProfilesByUserId[userId]
end

function PetStateStore.setActivePetProfile(userId, petProfile)
	activePetProfilesByUserId[userId] = petProfile
end

function PetStateStore.clearActivePetProfile(userId)
	activePetProfilesByUserId[userId] = nil
end

return PetStateStore
