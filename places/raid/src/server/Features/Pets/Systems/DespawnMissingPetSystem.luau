local Players = game:GetService("Players")

local PetOwner = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PetOwner"))

local function DespawnMissingPetSystem(world)
	local activePlayersByUserId = {}
	for _, player in ipairs(Players:GetPlayers()) do
		activePlayersByUserId[player.UserId] = true
	end

	for entityId, owner in world:query(PetOwner) do
		if not activePlayersByUserId[owner.userId] then
			world:despawn(entityId)
		end
	end
end

return DespawnMissingPetSystem
