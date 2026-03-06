local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local DebugOverlayHost = {}

local panelsById = {}
local screenGui = nil

local function getTopInsetY()
	local topLeftInset = select(1, GuiService:GetGuiInset())
	return topLeftInset.Y
end

local function ensureScreenGui()
	if screenGui then
		return screenGui
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DebugOverlayGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	return screenGui
end

local function layoutPanelsForSide(side)
	local visiblePanels = {}
	for _, panel in pairs(panelsById) do
		if panel.side == side and panel.visible then
			table.insert(visiblePanels, panel)
		end
	end

	table.sort(visiblePanels, function(a, b)
		if a.order == b.order then
			return a.id < b.id
		end
		return a.order < b.order
	end)

	local currentY = getTopInsetY() + 12
	for _, panel in ipairs(visiblePanels) do
		if side == "right" then
			panel.frame.Position = UDim2.new(1, -panel.width - 12, 0, currentY)
		else
			panel.frame.Position = UDim2.new(0, 12, 0, currentY)
		end

		currentY += panel.height + 12
	end
end

local function layoutPanels()
	layoutPanelsForSide("left")
	layoutPanelsForSide("right")
end

function DebugOverlayHost.mountTextPanel(options)
	local parentGui = ensureScreenGui()
	local id = options.id

	local frame = Instance.new("Frame")
	frame.Name = id
	frame.Size = UDim2.fromOffset(options.width or 320, options.height or 140)
	frame.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
	frame.BackgroundTransparency = 0.18
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parentGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(10, 8)
	title.Size = UDim2.new(1, -20, 0, 20)
	title.Text = options.title or "Debug"
	title.TextColor3 = Color3.fromRGB(240, 240, 240)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.Parent = frame

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(10, 32)
	body.Size = UDim2.new(1, -20, 1, -42)
	body.TextColor3 = Color3.fromRGB(220, 220, 220)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = false
	body.TextScaled = false
	body.TextSize = 16
	body.Font = Enum.Font.Code
	body.Text = options.initialText or ""
	body.Parent = frame

	local panel = {
		id = id,
		frame = frame,
		body = body,
		width = options.width or 320,
		height = options.height or 140,
		order = options.order or 100,
		side = options.side or "left",
		visible = false,
	}

	panelsById[id] = panel
	layoutPanels()

	return {
		setVisible = function(visible)
			panel.visible = visible == true
			panel.frame.Visible = panel.visible
			layoutPanels()
		end,
		setBodyText = function(text)
			panel.body.Text = text or ""
		end,
		destroy = function()
			panelsById[id] = nil
			panel.frame:Destroy()
			layoutPanels()
		end,
	}
end

return DebugOverlayHost
