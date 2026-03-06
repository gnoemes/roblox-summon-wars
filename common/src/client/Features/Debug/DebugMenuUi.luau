local DebugMenuUi = {}

function DebugMenuUi.clearContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

function DebugMenuUi.createTextLabel(parent, text, options)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, options and options.height or 20)
	label.Text = text
	label.TextColor3 = options and options.color or Color3.fromRGB(225, 225, 225)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = options and options.textYAlignment or Enum.TextYAlignment.Center
	label.TextWrapped = options == nil or options.textWrapped ~= false
	label.Font = Enum.Font.Code
	label.TextSize = options and options.textSize or 15
	label.Parent = parent
	return label
end

function DebugMenuUi.applyCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
	return corner
end

function DebugMenuUi.createButton(parent, text, onActivated, options)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.Size = UDim2.new(1, 0, 0, options and options.height or 34)
	button.BackgroundColor3 = options and options.backgroundColor3 or Color3.fromRGB(54, 66, 84)
	button.TextColor3 = options and options.textColor3 or Color3.fromRGB(245, 245, 245)
	button.Font = Enum.Font.Code
	button.TextSize = options and options.textSize or 15
	button.Text = text
	button.Parent = parent

	DebugMenuUi.applyCorner(button, 8)
	button.Activated:Connect(onActivated)
	return button
end

function DebugMenuUi.createSection(parent, titleText)
	local section = Instance.new("Frame")
	section.BackgroundTransparency = 1
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.Size = UDim2.new(1, 0, 0, 0)
	section.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = section

	DebugMenuUi.createTextLabel(section, titleText, {
		height = 20,
		textSize = 16,
		color = Color3.fromRGB(255, 227, 160),
	})

	return section
end

function DebugMenuUi.createButtonRow(parent)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 34)
	row.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	return row
end

function DebugMenuUi.createFillButton(parent, text, widthScale, onActivated, options)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.Size = UDim2.new(widthScale, 0, 1, 0)
	button.BackgroundColor3 = options and options.backgroundColor3 or Color3.fromRGB(54, 66, 84)
	button.TextColor3 = options and options.textColor3 or Color3.fromRGB(245, 245, 245)
	button.Font = Enum.Font.Code
	button.TextSize = options and options.textSize or 15
	button.Text = text
	button.Parent = parent

	DebugMenuUi.applyCorner(button, 8)
	button.Activated:Connect(onActivated)
	return button
end

function DebugMenuUi.createTextBox(parent, options)
	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(1, 0, 0, options and options.height or 34)
	textBox.BackgroundColor3 = options and options.backgroundColor3 or Color3.fromRGB(30, 38, 50)
	textBox.TextColor3 = options and options.textColor3 or Color3.fromRGB(245, 245, 245)
	textBox.Font = Enum.Font.Code
	textBox.TextSize = options and options.textSize or 15
	textBox.PlaceholderText = options and options.placeholderText or ""
	textBox.Text = options and options.text or ""
	textBox.ClearTextOnFocus = options == nil or options.clearTextOnFocus ~= false
	textBox.Parent = parent

	DebugMenuUi.applyCorner(textBox, 8)
	return textBox
end

return DebugMenuUi
