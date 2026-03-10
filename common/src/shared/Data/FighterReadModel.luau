local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FighterDocument = require(script.Parent:WaitForChild("FighterDocument"))
local FighterProjector = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Fighters")
		:WaitForChild("FighterProjector")
)

local FighterReadModel = {}

function FighterReadModel.fromDocument(fighterDocument)
	FighterDocument.assert(fighterDocument)

	return FighterProjector.buildReadModel(fighterDocument)
end

return FighterReadModel
