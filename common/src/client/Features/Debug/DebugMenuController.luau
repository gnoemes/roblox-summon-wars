local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local DebugConfig = require(Shared:WaitForChild("Features"):WaitForChild("Debug"):WaitForChild("DebugConfig"))
local DebugClient = require(script.Parent:WaitForChild("DebugClient"))
local DebugMenuUi = require(script.Parent:WaitForChild("DebugMenuUi"))

local DebugMenuController = {}

local initialized = false
local menuOpen = false
local statusMessage = ""
local currencyAmountText = tostring(DebugConfig.DefaultGrantAmount)
local partyValueText = ""
local currentState = DebugClient.getState()

local refs = {}

local function getTopInsetY()
	local topLeftInset = select(1, GuiService:GetGuiInset())
	return topLeftInset.Y
end

local function hasAction(state, actionId)
	for _, currentActionId in ipairs(state.supportedActionIds or {}) do
		if currentActionId == actionId then
			return true
		end
	end
	return false
end

local function getViewEnabled(state, viewId)
	return state.activeViews ~= nil and state.activeViews[viewId] == true
end

local function setStatus(text)
	statusMessage = text or ""
	if refs.statusLabel then
		refs.statusLabel.Text = statusMessage
	end
end

local function refreshPanelVisibility()
	local isAvailable = currentState.available == true
	refs.toggleButton.Visible = isAvailable
	refs.panel.Visible = isAvailable and menuOpen
end

local function executeAction(actionId, payload)
	task.spawn(function()
		local ok, response = DebugClient.runAction(actionId, payload)
		setStatus(if response and response.message then response.message else if ok then "OK" else "Failed")
	end)
end

local function executeViewToggle(viewId, enabled)
	task.spawn(function()
		local _, response = DebugClient.setViewEnabled(viewId, enabled)
		setStatus(if response and response.message then response.message else "View updated")
	end)
end

local function updateCanvasSize()
	local absoluteSize = refs.scrollLayout.AbsoluteContentSize
	refs.scrollFrame.CanvasSize = UDim2.fromOffset(0, absoluteSize.Y + 12)
end

local function renderPetSection(parent, state)
	if not hasAction(state, "set_active_pet") then
		return
	end

	local section = DebugMenuUi.createSection(parent, "Pets")
	DebugMenuUi.createTextLabel(
		section,
		("Current: %s"):format(state.currentPetDefinitionId or "-"),
		{
			height = 18,
			textSize = 14,
			color = Color3.fromRGB(200, 200, 200),
		}
	)

	for _, petDefinition in ipairs(state.petDefinitions or {}) do
		DebugMenuUi.createButton(section, petDefinition.displayName or petDefinition.id, function()
			executeAction("set_active_pet", {
				definitionId = petDefinition.id,
			})
		end)
	end
end

local function renderEconomySection(parent, state)
	if not hasAction(state, "grant_currency") then
		return
	end

	local section = DebugMenuUi.createSection(parent, "Economy")

	local totalLines = {}
	for _, currency in ipairs(state.currencyTypes or {}) do
		local amount = 0
		if type(state.rewardBalances) == "table" then
			amount = state.rewardBalances[currency.id] or 0
		end
		table.insert(totalLines, ("%s: %d"):format(currency.label or currency.id, amount))
	end

	DebugMenuUi.createTextLabel(section, table.concat(totalLines, "\n"), {
		height = 56,
		textSize = 14,
		color = Color3.fromRGB(200, 200, 200),
	})

	local amountBox = DebugMenuUi.createTextBox(section, {
		placeholderText = "Amount",
		text = currencyAmountText,
		clearTextOnFocus = false,
	})

	amountBox.FocusLost:Connect(function()
		currencyAmountText = amountBox.Text
	end)

	local presetRow = DebugMenuUi.createButtonRow(section)
	local presetWidth = 1 / math.max(1, #DebugConfig.GrantAmountPresets) - 0.02
	for _, presetAmount in ipairs(DebugConfig.GrantAmountPresets) do
		DebugMenuUi.createFillButton(presetRow, tostring(presetAmount), presetWidth, function()
			currencyAmountText = tostring(presetAmount)
			amountBox.Text = currencyAmountText
		end, {
			textSize = 14,
		})
	end

	for _, currency in ipairs(state.currencyTypes or {}) do
		DebugMenuUi.createButton(section, ("+ %s"):format(currency.label or currency.id), function()
			local amount = tonumber(amountBox.Text)
			if not amount then
				setStatus("Invalid amount")
				return
			end

			currencyAmountText = amountBox.Text
			executeAction("grant_currency", {
				currencyId = currency.id,
				amount = amount,
			})
		end)
	end
end

local function renderPartySection(parent, state)
	if not hasAction(state, "set_party") then
		return
	end

	local section = DebugMenuUi.createSection(parent, "Party")
	DebugMenuUi.createTextLabel(
		section,
		("Current: %s"):format(state.partyId or "-"),
		{
			height = 18,
			textSize = 14,
			color = Color3.fromRGB(200, 200, 200),
		}
	)

	local input = DebugMenuUi.createTextBox(section, {
		placeholderText = "PartyId",
		text = partyValueText,
		clearTextOnFocus = false,
	})

	input.FocusLost:Connect(function()
		partyValueText = input.Text
	end)

	local row = DebugMenuUi.createButtonRow(section)
	DebugMenuUi.createFillButton(row, "Set", 0.49, function()
		partyValueText = input.Text
		executeAction("set_party", {
			value = input.Text,
		})
	end)
	DebugMenuUi.createFillButton(row, "Clear", 0.49, function()
		partyValueText = ""
		input.Text = ""
		executeAction("set_party", {
			value = "",
		})
	end, {
		backgroundColor3 = Color3.fromRGB(74, 42, 42),
	})
end

local function renderViewsSection(parent, state)
	if #(state.supportedViewIds or {}) == 0 then
		return
	end

	local section = DebugMenuUi.createSection(parent, "Views")
	for _, viewId in ipairs(state.supportedViewIds or {}) do
		local viewConfig = DebugConfig.Views[viewId]
		local enabled = getViewEnabled(state, viewId)
		DebugMenuUi.createButton(section, ("%s [%s]"):format(viewConfig.label or viewId, if enabled then "ON" else "OFF"), function()
			executeViewToggle(viewId, not enabled)
		end, {
			backgroundColor3 = if enabled then Color3.fromRGB(52, 88, 62) else Color3.fromRGB(54, 66, 84),
		})
	end
end

local function renderState(nextState)
	currentState = nextState
	refreshPanelVisibility()

	if not refs.scrollContent then
		return
	end

	DebugMenuUi.clearContainer(refs.scrollContent)

	if currentState.available ~= true then
		DebugMenuUi.createTextLabel(refs.scrollContent, "Debug unavailable", {
			height = 20,
			textSize = 15,
			color = Color3.fromRGB(200, 180, 180),
		})
		updateCanvasSize()
		return
	end

	DebugMenuUi.createTextLabel(
		refs.scrollContent,
		("Place: %s"):format(currentState.place or "-"),
		{
			height = 18,
			textSize = 14,
			color = Color3.fromRGB(200, 200, 200),
		}
	)

	renderPetSection(refs.scrollContent, currentState)
	renderEconomySection(refs.scrollContent, currentState)
	renderPartySection(refs.scrollContent, currentState)
	renderViewsSection(refs.scrollContent, currentState)

	updateCanvasSize()
end

local function createUi()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "DebugMenuGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.AnchorPoint = Vector2.new(1, 0)
	toggleButton.Position = UDim2.new(1, -16, 0, getTopInsetY() + 12)
	toggleButton.Size = UDim2.fromOffset(96, 34)
	toggleButton.BackgroundColor3 = Color3.fromRGB(23, 31, 43)
	toggleButton.TextColor3 = Color3.fromRGB(245, 245, 245)
	toggleButton.Font = Enum.Font.Code
	toggleButton.TextSize = 15
	toggleButton.Text = "Debug"
	toggleButton.Parent = gui

	DebugMenuUi.applyCorner(toggleButton, 8)

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -16, 0, getTopInsetY() + 56)
	panel.Size = UDim2.fromOffset(380, 460)
	panel.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui

	DebugMenuUi.applyCorner(panel, 10)

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Position = UDim2.fromOffset(14, 10)
	header.Size = UDim2.new(1, -28, 0, 22)
	header.Text = "Debug Menu"
	header.TextColor3 = Color3.fromRGB(245, 245, 245)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Font = Enum.Font.Code
	header.TextSize = 17
	header.Parent = panel

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.Position = UDim2.fromOffset(14, 40)
	scrollFrame.Size = UDim2.new(1, -28, 1, -100)
	scrollFrame.CanvasSize = UDim2.fromOffset(0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = panel

	local scrollContent = Instance.new("Frame")
	scrollContent.Name = "Content"
	scrollContent.BackgroundTransparency = 1
	scrollContent.Size = UDim2.new(1, -4, 0, 0)
	scrollContent.AutomaticSize = Enum.AutomaticSize.Y
	scrollContent.Parent = scrollFrame

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingBottom = UDim.new(0, 12)
	scrollPadding.Parent = scrollContent

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.Padding = UDim.new(0, 12)
	scrollLayout.FillDirection = Enum.FillDirection.Vertical
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Parent = scrollContent

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.BackgroundTransparency = 1
	statusLabel.Size = UDim2.new(1, -28, 0, 44)
	statusLabel.Position = UDim2.new(0, 14, 1, -56)
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextYAlignment = Enum.TextYAlignment.Top
	statusLabel.TextWrapped = true
	statusLabel.Font = Enum.Font.Code
	statusLabel.TextSize = 14
	statusLabel.Parent = panel

	toggleButton.Activated:Connect(function()
		menuOpen = not menuOpen
		refreshPanelVisibility()
	end)

	scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

	refs.gui = gui
	refs.toggleButton = toggleButton
	refs.panel = panel
	refs.scrollFrame = scrollFrame
	refs.scrollContent = scrollContent
	refs.scrollLayout = scrollLayout
	refs.statusLabel = statusLabel

	refreshPanelVisibility()
end

function DebugMenuController.init()
	if initialized then
		return
	end

	initialized = true

	createUi()
	DebugClient.init()
	DebugClient.subscribe(renderState)
	setStatus(statusMessage)
end

return DebugMenuController
