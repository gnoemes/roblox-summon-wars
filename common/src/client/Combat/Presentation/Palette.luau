local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GradeDefinitions = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Progression"):WaitForChild("Grades")
).GradeDefinitions

local Palette = {}

local function tryGet(registry, id)
	if type(id) ~= "string" or id == "" then
		return nil
	end

	if registry.has(id) then
		return registry.get(id)
	end

	return nil
end

function Palette.getGradeColor(gradeId)
	local definition = tryGet(GradeDefinitions, gradeId)
	if definition ~= nil then
		return definition.color
	end

	return Color3.fromRGB(180, 188, 204)
end

function Palette.getEnemyColor(tier)
	if tier == "Boss" then
		return Color3.fromRGB(214, 82, 82)
	end
	if tier == "Elite" then
		return Color3.fromRGB(244, 170, 84)
	end
	return Color3.fromRGB(128, 132, 146)
end

function Palette.getBarColor(ratio)
	if ratio > 0.6 then
		return Color3.fromRGB(111, 214, 132)
	end
	if ratio > 0.3 then
		return Color3.fromRGB(244, 193, 84)
	end
	return Color3.fromRGB(232, 96, 96)
end

return table.freeze(Palette)
