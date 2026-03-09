local CombatConfig = require(script.Parent.Parent:WaitForChild("Combat"))
local ImageDefaults = require(script.Parent:WaitForChild("ImageDefaults"))
local SkillAssetBindings = require(script.Parent:WaitForChild("SkillAssetBindings"))
local StudioSkillAssetOverrides = require(script.Parent:WaitForChild("StudioSkillAssetOverrides"))

local SkillAssetResolver = {}

local function getStudioOverrideIconAssetId(skillId)
	local entries = StudioSkillAssetOverrides.getEntries()
	if type(entries) ~= "table" then
		return nil
	end

	local entry = entries[skillId]
	if type(entry) ~= "table" then
		return nil
	end

	return entry.iconAssetId
end

function SkillAssetResolver.getIconAssetId(skillId)
	if type(skillId) ~= "string" or skillId == "" then
		return ImageDefaults.PlaceholderImageAssetId
	end

	local studioOverride = getStudioOverrideIconAssetId(skillId)
	if studioOverride ~= nil then
		return studioOverride
	end

	if SkillAssetBindings.has(skillId) then
		local binding = SkillAssetBindings.get(skillId)
		if binding.iconAssetId ~= nil then
			return binding.iconAssetId
		end
	end

	if CombatConfig.SkillDefinitions.has(skillId) then
		local definition = CombatConfig.SkillDefinitions.get(skillId)
		if definition.iconAssetId ~= nil then
			return definition.iconAssetId
		end
	end

	return ImageDefaults.PlaceholderImageAssetId
end

return table.freeze(SkillAssetResolver)
