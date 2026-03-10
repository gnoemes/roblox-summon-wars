local EnemyHeaderPresenter = {}
EnemyHeaderPresenter.__index = EnemyHeaderPresenter

function EnemyHeaderPresenter.new(parent, dependencies)
	assert(parent ~= nil, "EnemyHeaderPresenter requires a parent")
	assert(type(dependencies) == "table", "EnemyHeaderPresenter requires dependencies")
	assert(
		type(dependencies.createHealthBar) == "function",
		"EnemyHeaderPresenter requires createHealthBar"
	)
	assert(
		type(dependencies.createStatusStrip) == "function",
		"EnemyHeaderPresenter requires createStatusStrip"
	)
	assert(
		type(dependencies.syncStatusStrip) == "function",
		"EnemyHeaderPresenter requires syncStatusStrip"
	)
	assert(
		type(dependencies.getBarColor) == "function",
		"EnemyHeaderPresenter requires getBarColor"
	)

	local self = setmetatable({
		_syncStatusStrip = dependencies.syncStatusStrip,
		_getBarColor = dependencies.getBarColor,
	}, EnemyHeaderPresenter)

	local frame = Instance.new("Frame")
	frame.Name = "EnemyHeader"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 12)
	frame.Size = UDim2.fromOffset(360, 124)
	frame.BackgroundColor3 = Color3.fromRGB(17, 22, 30)
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = frame

	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingTop = UDim.new(0, 10)
	headerPadding.PaddingBottom = UDim.new(0, 10)
	headerPadding.PaddingLeft = UDim.new(0, 12)
	headerPadding.PaddingRight = UDim.new(0, 12)
	headerPadding.Parent = frame

	local headerLayout = Instance.new("UIListLayout")
	headerLayout.FillDirection = Enum.FillDirection.Vertical
	headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	headerLayout.Padding = UDim.new(0, 6)
	headerLayout.Parent = frame

	local title = Instance.new("TextLabel")
	title.LayoutOrder = 1
	title.Size = UDim2.new(1, 0, 0, 22)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(244, 247, 255)
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "[Elite] Stone Golem"
	title.Parent = frame

	local bar = dependencies.createHealthBar(frame)
	bar.root.LayoutOrder = 2
	bar.root.Size = UDim2.new(1, 0, 0, 16)
	bar.label.TextSize = 12

	local tag = Instance.new("TextLabel")
	tag.LayoutOrder = 3
	tag.Size = UDim2.new(1, 0, 0, 14)
	tag.BackgroundTransparency = 1
	tag.Font = Enum.Font.GothamMedium
	tag.TextColor3 = Color3.fromRGB(178, 188, 210)
	tag.TextSize = 14
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.Text = "[Tanky]"
	tag.Parent = frame

	local statusStrip = dependencies.createStatusStrip(frame, 6)
	statusStrip.root.LayoutOrder = 4
	statusStrip.layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	self._frame = frame
	self._title = title
	self._fill = bar.fill
	self._value = bar.label
	self._tag = tag
	self._statusStrip = statusStrip

	return self
end

function EnemyHeaderPresenter:render(snapshot)
	local enemy = if snapshot ~= nil then snapshot.enemy else nil
	if enemy == nil then
		self._frame.Visible = false
		return
	end

	self._frame.Visible = true
	self._title.Text = enemy.title or enemy.displayName
	self._tag.Text = if type(enemy.threatTag) == "string" and enemy.threatTag ~= ""
		then string.format("[%s]", enemy.threatTag)
		else "[Standard]"

	local ratio = if enemy.maxHp > 0 then math.clamp(enemy.currentHp / enemy.maxHp, 0, 1) else 0
	self._fill.Size = UDim2.fromScale(ratio, 1)
	self._fill.BackgroundColor3 = self._getBarColor(ratio)
	self._value.Text = string.format("%d / %d", enemy.currentHp or 0, enemy.maxHp or 0)
	self._syncStatusStrip(self._statusStrip, enemy.activeStatuses or {}, snapshot.elapsedTime or 0)
end

return EnemyHeaderPresenter
