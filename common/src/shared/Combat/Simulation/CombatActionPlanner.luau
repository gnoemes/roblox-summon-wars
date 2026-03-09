local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))
local CombatStatusEngine = require(script.Parent.CombatStatusEngine)

local CombatActionPlanner = {}

function CombatActionPlanner.selectSkill(combatant, runtimeState)
	if CombatStatusEngine.blocksActions(runtimeState) then
		return nil
	end

	local blocksSkills = CombatStatusEngine.blocksSkills(runtimeState)
	if not blocksSkills then
		for _, skillId in ipairs(combatant.specialSkillIds or {}) do
			local definition = CombatConfig.SkillDefinitions.get(skillId)
			local remainingCooldown = runtimeState.remainingCooldownsBySkillId[skillId] or 0
			if definition.kind == "Active" and remainingCooldown <= 0 then
				return definition
			end
		end
	end

	return CombatConfig.SkillDefinitions.get(combatant.basicSkillId)
end

return CombatActionPlanner
