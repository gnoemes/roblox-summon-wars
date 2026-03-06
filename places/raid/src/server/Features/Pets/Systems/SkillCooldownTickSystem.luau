local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Matter"))

local SkillCooldowns = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillCooldowns"))

local function SkillCooldownTickSystem(world)
	local deltaTime = Matter.useDeltaTime()

	for entityId, cooldowns in world:query(SkillCooldowns) do
		local nextValues = {}
		local changed = false

		for skillId, remaining in pairs(cooldowns.bySkillId) do
			local nextRemaining = math.max(0, remaining - deltaTime)
			nextValues[skillId] = nextRemaining
			if nextRemaining ~= remaining then
				changed = true
			end
		end

		if changed then
			world:insert(entityId, cooldowns:patch({
				bySkillId = nextValues,
			}))
		end
	end
end

return SkillCooldownTickSystem
