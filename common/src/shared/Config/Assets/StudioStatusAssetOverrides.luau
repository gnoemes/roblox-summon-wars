local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StudioStatusAssetOverrides = {}

function StudioStatusAssetOverrides.getEntries()
	if not RunService:IsStudio() then
		return nil
	end

	local overridesFolder = ReplicatedStorage:FindFirstChild("StudioAssetOverrides")
	if overridesFolder == nil then
		return nil
	end

	local moduleScript = overridesFolder:FindFirstChild("StatusAssetEntries")
	if moduleScript == nil or not moduleScript:IsA("ModuleScript") then
		return nil
	end

	local ok, entries = pcall(require, moduleScript)
	if not ok or type(entries) ~= "table" then
		return nil
	end

	return entries
end

return table.freeze(StudioStatusAssetOverrides)
