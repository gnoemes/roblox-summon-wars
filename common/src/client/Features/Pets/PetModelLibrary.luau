local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetModelLibrary = {}

local MODEL_FOLDER_NAME = "PetModels"

local function getModelFolder()
	local folder = ReplicatedStorage:FindFirstChild(MODEL_FOLDER_NAME)
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

function PetModelLibrary.findTemplate(viewState)
	local folder = getModelFolder()
	if not folder then
		return nil
	end

	local candidates = {
		viewState.definitionId,
		viewState.archetype,
		"Default",
	}

	for _, name in ipairs(candidates) do
		if type(name) == "string" and name ~= "" then
			local template = folder:FindFirstChild(name)
			if template and (template:IsA("Model") or template:IsA("BasePart")) then
				return template
			end
		end
	end

	return nil
end

function PetModelLibrary.getFolderName()
	return MODEL_FOLDER_NAME
end

return PetModelLibrary
