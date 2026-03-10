local Players = game:GetService("Players")

local FighterWorldPresenter = {}
FighterWorldPresenter.__index = FighterWorldPresenter

local function createWorldView(folder, name, width, height, withBillboard, dependencies)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder

	local billboard = nil
	local nameLabel = nil
	local healthBar = nil
	local statusStrip = nil

	if withBillboard ~= false then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "Billboard"
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 0
		billboard.MaxDistance = 120
		billboard.Size = UDim2.fromOffset(width, height)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.85, 0)
		billboard.Parent = part

		local container = Instance.new("Frame")
		container.Name = "Container"
		container.Size = UDim2.fromScale(1, 1)
		container.BackgroundTransparency = 1
		container.BorderSizePixel = 0
		container.Parent = billboard

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 2)
		padding.PaddingBottom = UDim.new(0, 2)
		padding.PaddingLeft = UDim.new(0, 4)
		padding.PaddingRight = UDim.new(0, 4)
		padding.Parent = container

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.Padding = UDim.new(0, 2)
		layout.Parent = container

		nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.LayoutOrder = 1
		nameLabel.Size = UDim2.new(1, 0, 0, 15)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.fromRGB(244, 247, 255)
		nameLabel.TextStrokeTransparency = 0.4
		nameLabel.TextSize = 12
		nameLabel.Text = name
		nameLabel.Parent = container

		healthBar = dependencies.createHealthBar(container)
		healthBar.root.LayoutOrder = 2
		healthBar.root.Size = UDim2.new(1, 0, 0, 11)
		healthBar.label.TextSize = 10

		statusStrip = dependencies.createStatusStrip(container, 4)
		statusStrip.root.LayoutOrder = 3
	end

	return {
		part = part,
		billboard = billboard,
		nameLabel = nameLabel,
		healthBar = healthBar,
		statusStrip = statusStrip,
		_healthAlpha = 0,
	}
end

local function getMotionOffset(index, mode)
	local timeNow = os.clock()
	local phase = timeNow * 2.15 + index * 0.9
	if mode == "CombatEncounter" then
		return Vector3.new(0, math.sin(phase) * 0.08, 0)
	end

	return Vector3.new(
		math.cos(phase * 0.55) * 0.35,
		0.12 + math.sin(phase) * 0.16,
		math.sin(phase * 0.7) * 0.22
	)
end

function FighterWorldPresenter.new(config)
	assert(type(config) == "table", "FighterWorldPresenter config must be a table")
	assert(config.folder ~= nil, "FighterWorldPresenter requires a folder")
	assert(
		type(config.createHealthBar) == "function",
		"FighterWorldPresenter requires createHealthBar"
	)
	assert(
		type(config.createStatusStrip) == "function",
		"FighterWorldPresenter requires createStatusStrip"
	)
	assert(
		type(config.syncStatusStrip) == "function",
		"FighterWorldPresenter requires syncStatusStrip"
	)
	assert(type(config.getBarColor) == "function", "FighterWorldPresenter requires getBarColor")
	assert(type(config.getGradeColor) == "function", "FighterWorldPresenter requires getGradeColor")
	assert(type(config.getEnemyColor) == "function", "FighterWorldPresenter requires getEnemyColor")

	return setmetatable({
		_folder = config.folder,
		_createHealthBar = config.createHealthBar,
		_createStatusStrip = config.createStatusStrip,
		_syncStatusStrip = config.syncStatusStrip,
		_getBarColor = config.getBarColor,
		_getGradeColor = config.getGradeColor,
		_getEnemyColor = config.getEnemyColor,
		_followOffsets = config.followOffsets,
		_combatOffsets = config.combatOffsets,
		_previewDistance = config.previewDistance,
		_worldBaseYOffset = config.worldBaseYOffset,
		_fighterViewSize = config.fighterViewSize,
		_enemyViewSize = config.enemyViewSize,
		_fighterViews = {},
		_enemyView = nil,
		_currentCombatAnchor = nil,
		_combatAnchorEncounterId = nil,
	}, FighterWorldPresenter)
end

function FighterWorldPresenter:_ensureWorldViews(snapshot)
	for index, fighter in ipairs(snapshot.trio or {}) do
		local view = self._fighterViews[index]
		if view == nil then
			view = createWorldView(self._folder, string.format("Fighter%d", index), 132, 66, true, {
				createHealthBar = self._createHealthBar,
				createStatusStrip = self._createStatusStrip,
			})
			self._fighterViews[index] = view
		end

		view._combatantId = fighter.combatantId
	end

	if self._enemyView == nil then
		self._enemyView = createWorldView(self._folder, "Enemy", 0, 0, false, {
			createHealthBar = self._createHealthBar,
			createStatusStrip = self._createStatusStrip,
		})
		self._enemyView.part.Material = Enum.Material.Neon
	end
end

function FighterWorldPresenter:_hideWorldViews()
	for _, view in pairs(self._fighterViews) do
		view.part.Transparency = 1
		if view.billboard ~= nil then
			view.billboard.Enabled = false
		end
	end

	if self._enemyView ~= nil then
		self._enemyView.part.Transparency = 1
		if self._enemyView.billboard ~= nil then
			self._enemyView.billboard.Enabled = false
		end
	end
end

function FighterWorldPresenter:_getRootPart()
	local player = Players.LocalPlayer
	local character = player.Character
	if character == nil then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

function FighterWorldPresenter:_updateView(
	view,
	position,
	size,
	color,
	title,
	nameColor,
	currentHp,
	maxHp,
	activeStatuses,
	elapsedTime,
	showHealthBar
)
	view.part.Size = size
	view.part.CFrame = CFrame.new(position + Vector3.new(0, size.Y * 0.5, 0))
	view.part.Color = color
	view.part.Transparency = 0

	if view.billboard ~= nil then
		view.billboard.Enabled = true
	end
	if view.nameLabel ~= nil then
		view.nameLabel.Text = title
		view.nameLabel.TextColor3 = nameColor or Color3.fromRGB(244, 247, 255)
	end

	if view.healthBar ~= nil then
		local ratio = if maxHp > 0 then math.clamp(currentHp / maxHp, 0, 1) else 0
		view.healthBar.fill.Size = UDim2.fromScale(ratio, 1)
		view.healthBar.fill.BackgroundColor3 = self._getBarColor(ratio)
		view.healthBar.label.Text = string.format("%d / %d", currentHp, maxHp)

		local targetAlpha = if showHealthBar then 0 else 1
		view._healthAlpha = view._healthAlpha or targetAlpha
		view._healthAlpha += (targetAlpha - view._healthAlpha) * 0.22
		if math.abs(targetAlpha - view._healthAlpha) < 0.02 then
			view._healthAlpha = targetAlpha
		end

		view.healthBar.root.BackgroundTransparency = 0.08 + view._healthAlpha * 0.92
		view.healthBar.fill.BackgroundTransparency = view._healthAlpha
		view.healthBar.label.TextTransparency = view._healthAlpha
	end

	self._syncStatusStrip(view.statusStrip, activeStatuses or {}, elapsedTime or 0)
end

function FighterWorldPresenter:_resolveEnemyAnchor(rootPart, mode, encounterId)
	if mode == "CombatEncounter" then
		if self._combatAnchorEncounterId ~= encounterId or self._currentCombatAnchor == nil then
			if rootPart ~= nil then
				self._currentCombatAnchor = rootPart.Position
					+ rootPart.CFrame.LookVector * self._previewDistance
			else
				self._currentCombatAnchor = Vector3.new(0, self._worldBaseYOffset, 0)
			end
			self._combatAnchorEncounterId = encounterId
		end

		return self._currentCombatAnchor
	end

	self._currentCombatAnchor = nil
	self._combatAnchorEncounterId = nil
	if rootPart == nil then
		return nil
	end

	return rootPart.Position + rootPart.CFrame.LookVector * self._previewDistance
end

function FighterWorldPresenter:render(snapshot)
	if snapshot == nil then
		self:_hideWorldViews()
		return
	end

	self:_ensureWorldViews(snapshot)

	local rootPart = self:_getRootPart()
	if rootPart == nil and snapshot.mode ~= "CombatEncounter" then
		self:_hideWorldViews()
		return
	end

	local enemyAnchor =
		self:_resolveEnemyAnchor(rootPart, snapshot.mode, snapshot.activeEncounterId)
	if enemyAnchor == nil then
		self:_hideWorldViews()
		return
	end

	local playerBasis = if rootPart ~= nil then rootPart.CFrame else CFrame.new(enemyAnchor)
	for index, fighter in ipairs(snapshot.trio or {}) do
		local view = self._fighterViews[index]
		local offset = if snapshot.mode == "CombatEncounter"
			then self._combatOffsets[index]
			else self._followOffsets[index]
		local motionOffset = getMotionOffset(index, snapshot.mode)
		local worldPosition = if snapshot.mode == "CombatEncounter"
			then enemyAnchor + offset + motionOffset + Vector3.new(0, self._worldBaseYOffset, 0)
			else playerBasis:PointToWorldSpace(offset + motionOffset) + Vector3.new(
				0,
				self._worldBaseYOffset,
				0
			)
		self:_updateView(
			view,
			worldPosition,
			self._fighterViewSize,
			self._getGradeColor(fighter.grade),
			fighter.displayName,
			self._getGradeColor(fighter.grade),
			math.floor((fighter.currentHp or 0) + 0.5),
			math.floor((fighter.maxHp or 0) + 0.5),
			fighter.activeStatuses,
			snapshot.elapsedTime,
			snapshot.mode == "CombatEncounter"
				or math.floor((fighter.currentHp or 0) + 0.5)
					< math.floor((fighter.maxHp or 0) + 0.5)
		)
	end

	if snapshot.enemy ~= nil and self._enemyView ~= nil and snapshot.mode == "CombatEncounter" then
		self:_updateView(
			self._enemyView,
			enemyAnchor + Vector3.new(0, self._worldBaseYOffset, 0),
			self._enemyViewSize,
			self._getEnemyColor(snapshot.enemy.tier),
			snapshot.enemy.displayName,
			Color3.fromRGB(244, 247, 255),
			math.floor((snapshot.enemy.currentHp or 0) + 0.5),
			math.floor((snapshot.enemy.maxHp or 0) + 0.5),
			snapshot.enemy.activeStatuses,
			snapshot.elapsedTime,
			true
		)
	elseif self._enemyView ~= nil then
		self._enemyView.part.Transparency = 1
		if self._enemyView.billboard ~= nil then
			self._enemyView.billboard.Enabled = false
		end
	end
end

function FighterWorldPresenter:getPopupParent(combatantId, snapshot)
	for _, view in pairs(self._fighterViews) do
		if view._combatantId == combatantId then
			return view.part
		end
	end

	if self._enemyView ~= nil and snapshot ~= nil and snapshot.enemy ~= nil then
		local enemyId = snapshot.enemy.enemyId
		if
			combatantId == enemyId
			or (snapshot.activeEncounterId ~= nil and combatantId:find(":Enemy:") ~= nil)
		then
			return self._enemyView.part
		end
	end

	return nil
end

function FighterWorldPresenter:stop()
	self._fighterViews = {}
	self._enemyView = nil
	self._currentCombatAnchor = nil
	self._combatAnchorEncounterId = nil
end

return FighterWorldPresenter
