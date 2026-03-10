local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local AssetUri =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("AssetUri"))

local CombatConfig = SharedConfig.Combat
local AssetConfig = SharedConfig.Assets

local Widgets = {}

local function tryGet(registry, id)
	if type(id) ~= "string" or id == "" then
		return nil
	end

	if registry.has(id) then
		return registry.get(id)
	end

	return nil
end

local function getStatusIconImage(statusId)
	return AssetUri.fromAssetId(AssetConfig.StatusAssetResolver.getIconAssetId(statusId))
end

function Widgets.createHealthBar(parent)
	local frame = Instance.new("Frame")
	frame.Name = "HealthBar"
	frame.Size = UDim2.new(1, 0, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = frame

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(111, 214, 132)
	fill.BorderSizePixel = 0
	fill.Parent = frame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 5)
	fillCorner.Parent = fill

	local label = Instance.new("TextLabel")
	label.Name = "Value"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(242, 246, 255)
	label.TextSize = 11
	label.Text = "HP"
	label.Parent = frame

	return {
		root = frame,
		fill = fill,
		label = label,
	}
end

function Widgets.createStatusStrip(parent, maxIcons)
	local frame = Instance.new("Frame")
	frame.Name = "StatusStrip"
	frame.Size = UDim2.new(1, 0, 0, 38)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 7)
	layout.Parent = frame

	return {
		root = frame,
		layout = layout,
		slots = {},
		maxIcons = maxIcons or 4,
	}
end

local function ensureStatusSlot(strip, index)
	local slot = strip.slots[index]
	if slot ~= nil then
		return slot
	end

	slot = {}
	local frame = Instance.new("Frame")
	frame.Name = string.format("Status%d", index)
	frame.LayoutOrder = index
	frame.Size = UDim2.fromOffset(36, 36)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = strip.root

	local image = Instance.new("ImageLabel")
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromOffset(34, 34)
	image.BackgroundTransparency = 1
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = frame

	local stack = Instance.new("TextLabel")
	stack.AnchorPoint = Vector2.new(1, 1)
	stack.Position = UDim2.new(1, 2, 1, 2)
	stack.Size = UDim2.fromOffset(22, 16)
	stack.BackgroundTransparency = 1
	stack.Font = Enum.Font.GothamBold
	stack.TextColor3 = Color3.fromRGB(244, 247, 255)
	stack.TextSize = 13
	stack.TextXAlignment = Enum.TextXAlignment.Right
	stack.TextYAlignment = Enum.TextYAlignment.Bottom
	stack.Parent = frame

	slot.frame = frame
	slot.image = image
	slot.stack = stack
	strip.slots[index] = slot
	return slot
end

local function getSortedStatusEntries(activeStatuses)
	local entries = {}
	for statusId, statusState in pairs(activeStatuses or {}) do
		table.insert(entries, {
			statusId = statusId,
			statusState = statusState,
		})
	end

	table.sort(entries, function(left, right)
		return left.statusId < right.statusId
	end)

	return entries
end

function Widgets.syncStatusStrip(strip, activeStatuses, elapsedTime)
	if strip == nil then
		return
	end

	local entries = getSortedStatusEntries(activeStatuses)
	local visibleCount = math.min(#entries, strip.maxIcons)
	local pulseTime = os.clock()

	for index = 1, visibleCount do
		local entry = entries[index]
		local slot = ensureStatusSlot(strip, index)
		local definition = tryGet(CombatConfig.StatusDefinitions, entry.statusId)
		local iconImage = getStatusIconImage(entry.statusId)
		local durationSeconds = if definition ~= nil
				and definition.baseDurationSeconds ~= nil
			then definition.baseDurationSeconds
			else 1
		local remainingSeconds = if type(entry.statusState.expiresAt) == "number"
			then math.max(entry.statusState.expiresAt - (elapsedTime or 0), 0)
			else durationSeconds
		local remainingRatio = math.clamp(remainingSeconds / math.max(durationSeconds, 0.01), 0, 1)
		local pulseStrength = 0.14 + (1 - remainingRatio) * 0.34
		local pulseSpeed = 5.5 + (1 - remainingRatio) * 8.5
		local pulse = (math.sin(pulseTime * pulseSpeed + index * 0.7) * 0.5 + 0.5)
		local pulseScale = 1 + pulse * (0.03 + (1 - remainingRatio) * 0.08)

		slot.frame.Visible = true
		slot.image.Image = iconImage or ""
		slot.image.Size = UDim2.fromOffset(34 * pulseScale, 34 * pulseScale)
		slot.image.ImageTransparency = 0.01 + pulse * pulseStrength
		slot.stack.Text = string.format("x%d", math.max(entry.statusState.stacks or 1, 1))
		slot.stack.TextTransparency = 0.05 + pulse * 0.3
	end

	for index = visibleCount + 1, #strip.slots do
		strip.slots[index].frame.Visible = false
	end

	strip.root.Visible = visibleCount > 0
end

return table.freeze(Widgets)
