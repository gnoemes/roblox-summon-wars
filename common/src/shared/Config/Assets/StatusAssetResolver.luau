local CombatConfig = require(script.Parent.Parent:WaitForChild("Combat"))
local ImageDefaults = require(script.Parent:WaitForChild("ImageDefaults"))
local StatusAssetBindings = require(script.Parent:WaitForChild("StatusAssetBindings"))
local StudioStatusAssetOverrides = require(script.Parent:WaitForChild("StudioStatusAssetOverrides"))

local StatusAssetResolver = {}

local function getStudioOverrideIconAssetId(statusId)
	local entries = StudioStatusAssetOverrides.getEntries()
	if type(entries) ~= "table" then
		return nil
	end

	local entry = entries[statusId]
	if type(entry) ~= "table" then
		return nil
	end

	return entry.iconAssetId
end

function StatusAssetResolver.getIconAssetId(statusId)
	if type(statusId) ~= "string" or statusId == "" then
		return ImageDefaults.PlaceholderImageAssetId
	end

	local studioOverride = getStudioOverrideIconAssetId(statusId)
	if studioOverride ~= nil then
		return studioOverride
	end

	if StatusAssetBindings.has(statusId) then
		local binding = StatusAssetBindings.get(statusId)
		if binding.iconAssetId ~= nil then
			return binding.iconAssetId
		end
	end

	if CombatConfig.StatusDefinitions.has(statusId) then
		local definition = CombatConfig.StatusDefinitions.get(statusId)
		if definition.iconAssetId ~= nil then
			return definition.iconAssetId
		end
	end

	return ImageDefaults.PlaceholderImageAssetId
end

return table.freeze(StatusAssetResolver)
