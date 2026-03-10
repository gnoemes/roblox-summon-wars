local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CombatConfig = SharedConfig.Combat

local Text = {}

local function tryGet(registry, id)
	if type(id) ~= "string" or id == "" then
		return nil
	end

	if registry.has(id) then
		return registry.get(id)
	end

	return nil
end

function Text.getSkillLabel(skillId, actionType)
	local definition = tryGet(CombatConfig.SkillDefinitions, skillId)
	if definition ~= nil then
		if definition.kind == "BasicAttack" then
			return "Basic Attack"
		end
		return definition.displayName
	end

	local statusDefinition = tryGet(CombatConfig.StatusDefinitions, skillId)
	if statusDefinition ~= nil then
		return statusDefinition.displayName
	end

	return tostring(actionType or skillId or "Skill")
end

function Text.getOutcomeLabel(outcome)
	if outcome == "Resolved" then
		return "hit"
	end
	if outcome == "Missed" then
		return "miss"
	end
	if outcome == "Blocked" then
		return "blocked"
	end
	if outcome == "Invalid" then
		return "no target"
	end
	if outcome == "Cancelled" then
		return "cancelled"
	end

	return tostring(outcome)
end

return table.freeze(Text)
