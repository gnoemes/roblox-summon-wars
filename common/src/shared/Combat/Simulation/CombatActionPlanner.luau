local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))
local CombatStatusEngine = require(script.Parent.CombatStatusEngine)

local CombatActionPlanner = {}

local function sortReadySkills(left, right)
	local leftPriority = left.selectionPriority or 0
	local rightPriority = right.selectionPriority or 0
	if leftPriority ~= rightPriority then
		return leftPriority > rightPriority
	end

	return left.skillId < right.skillId
end

function CombatActionPlanner.selectSkill(combatant, runtimeState)
	if CombatStatusEngine.blocksActions(runtimeState) then
		return nil
	end

	local readySkills = {}
	local blocksSkills = CombatStatusEngine.blocksSkills(runtimeState)
	if not blocksSkills then
		for _, skillId in ipairs(combatant.specialSkillIds or {}) do
			local definition = CombatConfig.SkillDefinitions.get(skillId)
			local remainingCooldown = runtimeState.remainingCooldownsBySkillId[skillId] or 0
			if definition.kind == "Active" and remainingCooldown <= 0 then
				table.insert(readySkills, definition)
			end
		end
	end

	if #readySkills > 0 then
		table.sort(readySkills, sortReadySkills)
		return readySkills[1]
	end

	return CombatConfig.SkillDefinitions.get(combatant.basicSkillId)
end

return CombatActionPlanner
