local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PetModelLibrary = require(script.Parent:WaitForChild("PetModelLibrary"))

local PetFollowerRenderer = {}

local renderedByUserId = {}

local function ensureRenderFolder(name)
	local folder = Workspace:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = Workspace
	end
	return folder
end

local function ensurePrimaryPart(model)
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	local firstBasePart = model:FindFirstChildWhichIsA("BasePart", true)
	if firstBasePart then
		model.PrimaryPart = firstBasePart
		return firstBasePart
	end

	return nil
end

local function freezeModel(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end
end

local function createPlaceholderModel(viewState)
	local model = Instance.new("Model")
	model.Name = "PlaceholderPet"

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 2, 2)
	root.Shape = Enum.PartType.Ball
	root.Material = Enum.Material.Neon
	root.Color = if viewState.archetype == "tank"
		then Color3.fromRGB(110, 220, 255)
		elseif viewState.archetype == "ranged_dps"
		then Color3.fromRGB(255, 160, 80)
		else Color3.fromRGB(170, 255, 120)
	root.Parent = model
	model.PrimaryPart = root

	local marker = Instance.new("BillboardGui")
	marker.Name = "Label"
	marker.Size = UDim2.fromOffset(160, 40)
	marker.StudsOffset = Vector3.new(0, 2.5, 0)
	marker.AlwaysOnTop = true
	marker.Parent = root

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = viewState.displayName or viewState.definitionId or "Pet"
	label.Parent = marker

	return model
end

local function buildSignature(viewState)
	return table.concat({
		tostring(viewState.definitionId),
		tostring(viewState.scalePresetId),
		tostring(viewState.displayName),
	}, "|")
end

local function cloneTemplateAsModel(template)
	if not template then
		return nil
	end

	if template:IsA("Model") then
		return template:Clone()
	end

	if template:IsA("BasePart") then
		local model = Instance.new("Model")
		model.Name = template.Name

		local root = template:Clone()
		root.Parent = model
		model.PrimaryPart = root

		return model
	end

	return nil
end

local function buildRenderRecord(userId, viewState, options)
	local template = PetModelLibrary.findTemplate(viewState)
	local model = cloneTemplateAsModel(template) or createPlaceholderModel(viewState)
	model.Name = ("%s_%d"):format(options.modelNamePrefix, userId)

	local primaryPart = ensurePrimaryPart(model)
	if not primaryPart then
		model:Destroy()
		return nil
	end

	freezeModel(model)

	if type(viewState.scale) == "number" and viewState.scale > 0 then
		pcall(function()
			model:ScaleTo(viewState.scale)
		end)
	end

	model.Parent = ensureRenderFolder(options.renderFolderName)

	return {
		model = model,
		lastCFrame = primaryPart.CFrame,
		signature = buildSignature(viewState),
	}
end

local function destroyRenderRecord(userId)
	local record = renderedByUserId[userId]
	if not record then
		return
	end

	if record.model then
		record.model:Destroy()
	end

	renderedByUserId[userId] = nil
end

local function computeDefaultTargetCFrame(record, player, options)
	local character = player.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return nil
	end

	local model = record.model
	local primaryPart = ensurePrimaryPart(model)
	if not primaryPart then
		return nil
	end

	local worldPosition =
		rootPart.CFrame:PointToWorldSpace(Vector3.new(options.sideOffset, 0, options.backOffset))
	local modelHeight = model:GetExtentsSize().Y * 0.5
	local targetPosition =
		Vector3.new(worldPosition.X, rootPart.Position.Y + modelHeight + options.heightOffset, worldPosition.Z)

	return CFrame.lookAt(targetPosition, targetPosition + rootPart.CFrame.LookVector, Vector3.yAxis)
end

local function getOrderedUserIds(snapshot)
	local ordered = {}
	for userId in pairs(snapshot) do
		table.insert(ordered, userId)
	end
	table.sort(ordered, function(a, b)
		return a < b
	end)
	return ordered
end

function PetFollowerRenderer.start(options)
	local registry = options.registry
	assert(type(registry) == "table" and type(registry.getAll) == "function", "PetFollowerRenderer requires a registry")

	RunService:BindToRenderStep(options.renderStepName, options.renderPriority, function()
		local snapshot = registry.getAll()
		local liveUserIds = {}
		local orderedUserIds = getOrderedUserIds(snapshot)
		local userIndexById = {}
		for index, userId in ipairs(orderedUserIds) do
			userIndexById[userId] = index
		end

		for userId, viewState in pairs(snapshot) do
			liveUserIds[userId] = true

			local player = Players:GetPlayerByUserId(userId)
			if not player then
				destroyRenderRecord(userId)
				continue
			end

			local record = renderedByUserId[userId]
			if not record then
				record = buildRenderRecord(userId, viewState, options)
				renderedByUserId[userId] = record
			else
				local nextSignature = buildSignature(viewState)
				if record.signature ~= nextSignature then
					destroyRenderRecord(userId)
					record = buildRenderRecord(userId, viewState, options)
					renderedByUserId[userId] = record
				end
			end

		if record then
			local targetCFrame
			if type(options.computeTargetCFrame) == "function" then
				targetCFrame = options.computeTargetCFrame({
					record = record,
					player = player,
					viewState = viewState,
					userId = userId,
					index = userIndexById[userId],
					orderedUserIds = orderedUserIds,
				})
			else
				targetCFrame = computeDefaultTargetCFrame(record, player, options)
			end
			if targetCFrame then
				record.lastCFrame = record.lastCFrame:Lerp(targetCFrame, options.lerpAlpha)
				record.model:PivotTo(record.lastCFrame)
				end
			end
		end

		for userId in pairs(renderedByUserId) do
			if not liveUserIds[userId] then
				destroyRenderRecord(userId)
			end
		end
	end)
end

return PetFollowerRenderer
