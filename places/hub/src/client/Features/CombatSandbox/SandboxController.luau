local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))
local GradeDefinitions = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Progression"):WaitForChild("Grades")
).GradeDefinitions
local ReplicationTopics = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("Topics")
)
local Cleaner =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Cleaner"))

local SNAPSHOT_TOPIC = ReplicationTopics.CombatSandbox
local FOLLOW_OFFSETS = {
	Vector3.new(-4.25, 0, 4.75),
	Vector3.new(0, 0, 6.4),
	Vector3.new(4.25, 0, 4.75),
}
local COMBAT_OFFSETS = {
	Vector3.new(-6, 0, 4.5),
	Vector3.new(0, 0, 6.75),
	Vector3.new(6, 0, 4.5),
}
local PREVIEW_DISTANCE = 18
local WORLD_BASE_Y_OFFSET = -2.6
local POPUP_LIFETIME = 0.9
local FIGHTER_VIEW_SIZE = Vector3.new(1.85, 2.2, 1.85)
local ENEMY_VIEW_SIZE = Vector3.new(5.4, 6.1, 5.4)

local SandboxController = {}
SandboxController.__index = SandboxController

local function tryGet(registry, id)
	if type(id) ~= "string" or id == "" then
		return nil
	end

	if registry.has(id) then
		return registry.get(id)
	end

	return nil
end

local function getGradeColor(gradeId)
	local definition = tryGet(GradeDefinitions, gradeId)
	if definition ~= nil then
		return definition.color
	end

	return Color3.fromRGB(180, 188, 204)
end

local function getEnemyColor(tier)
	if tier == "Boss" then
		return Color3.fromRGB(214, 82, 82)
	end
	if tier == "Elite" then
		return Color3.fromRGB(244, 170, 84)
	end
	return Color3.fromRGB(128, 132, 146)
end

local function getBarColor(ratio)
	if ratio > 0.6 then
		return Color3.fromRGB(111, 214, 132)
	end
	if ratio > 0.3 then
		return Color3.fromRGB(244, 193, 84)
	end
	return Color3.fromRGB(232, 96, 96)
end

local function getSkillLabel(skillId, actionType)
	local definition = tryGet(CombatConfig.SkillDefinitions, skillId)
	if definition ~= nil then
		if definition.kind == "BasicAttack" then
			return "Basic Attack"
		end
		return definition.displayName
	end

	local statusDefinition = tryGet(CombatConfig.StatusDefinitions, skillId)
	if statusDefinition ~= nil then
		return statusDefinition.displayName
	end

	return tostring(actionType or skillId or "Skill")
end

local function getOutcomeLabel(outcome)
	if outcome == "Resolved" then
		return "hit"
	end
	if outcome == "Missed" then
		return "miss"
	end
	if outcome == "Blocked" then
		return "blocked"
	end
	if outcome == "Invalid" then
		return "no target"
	end
	if outcome == "Cancelled" then
		return "cancelled"
	end

	return tostring(outcome)
end

local function formatEnemyOptionLabel(entry, active)
	local bullet = if active then "●" else "○"
	local tierPrefix = if type(entry.tier) == "string" and entry.tier ~= "Normal"
		then string.format("[%s] ", entry.tier)
		else ""
	return string.format("%s %s%s", bullet, tierPrefix, entry.displayName)
end

local function findEnemyEntry(snapshot, enemyId)
	for _, entry in ipairs(snapshot.availableEnemies or {}) do
		if entry.enemyId == enemyId then
			return entry
		end
	end

	return nil
end

local function createHealthBar(parent)
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

local function createWorldView(folder, name, width, height, withBillboard)
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

	if withBillboard ~= false then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "Billboard"
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 0
		billboard.MaxDistance = 120
		billboard.Size = UDim2.fromOffset(width, height)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.9, 0)
		billboard.Parent = part

		local container = Instance.new("Frame")
		container.Name = "Container"
		container.Size = UDim2.fromScale(1, 1)
		container.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
		container.BackgroundTransparency = 0.18
		container.BorderSizePixel = 0
		container.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = container

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 6)
		padding.PaddingBottom = UDim.new(0, 6)
		padding.PaddingLeft = UDim.new(0, 6)
		padding.PaddingRight = UDim.new(0, 6)
		padding.Parent = container

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.Padding = UDim.new(0, 3)
		layout.Parent = container

		nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(1, 0, 0, 16)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.fromRGB(244, 247, 255)
		nameLabel.TextSize = 12
		nameLabel.Text = name
		nameLabel.Parent = container

		healthBar = createHealthBar(container)
		healthBar.root.Size = UDim2.new(1, 0, 0, 11)
		healthBar.label.TextSize = 10
	end

	return {
		part = part,
		billboard = billboard,
		nameLabel = nameLabel,
		healthBar = healthBar,
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

function SandboxController.new(config)
	assert(type(config) == "table", "SandboxController config must be a table")
	assert(config.snapshotClient ~= nil, "SandboxController requires SnapshotClient")
	assert(config.debugClient ~= nil, "SandboxController requires DebugClient")

	return setmetatable({
		_snapshotClient = config.snapshotClient,
		_debugClient = config.debugClient,
		_cleaner = Cleaner.new(),
		_snapshot = nil,
		_statusLabel = nil,
		_logLabel = nil,
		_enemyHeader = nil,
		_screenGui = nil,
		_worldFolder = nil,
		_enemyList = nil,
		_fighterViews = {},
		_enemyView = nil,
		_enemyButtons = {},
		_speedButtons = {},
		_processedActionIds = {},
		_lastEncounterId = nil,
		_currentCombatAnchor = nil,
	}, SandboxController)
end

function SandboxController:_setStatus(text)
	if self._statusLabel ~= nil then
		self._statusLabel.Text = text
	end
end

function SandboxController:_createButton(parent, text, layoutOrder)
	local button = Instance.new("TextButton")
	button.Name = text:gsub("%s+", "")
	button.LayoutOrder = layoutOrder
	button.AutoButtonColor = true
	button.Size = UDim2.new(0.5, -6, 0, 34)
	button.BackgroundColor3 = Color3.fromRGB(42, 48, 62)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = Color3.fromRGB(244, 247, 255)
	button.TextSize = 13
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

function SandboxController:_setButtonActive(button, active)
	if active then
		button.BackgroundColor3 = Color3.fromRGB(86, 109, 168)
	else
		button.BackgroundColor3 = Color3.fromRGB(42, 48, 62)
	end
end

function SandboxController:_invokeAction(actionKey, payload)
	self:_setStatus(string.format("Invoking %s...", actionKey))
	local ok, result = pcall(function()
		return self._debugClient:invokeAction(actionKey, payload)
	end)

	if not ok then
		self:_setStatus(string.format("Action failed: %s", tostring(result)))
		return
	end

	if result.ok == true then
		self:_setStatus(string.format("Action ok: %s", actionKey))
	else
		self:_setStatus(string.format("Action error: %s", tostring(result.error)))
	end
end

function SandboxController:_clearEnemyButtons()
	for enemyId, button in pairs(self._enemyButtons) do
		button:Destroy()
		self._enemyButtons[enemyId] = nil
	end
end

function SandboxController:_syncEnemyButtons(snapshot)
	if self._enemyList == nil then
		return
	end

	local availableEnemies = snapshot.availableEnemies or {}
	local existingCount = 0
	for _ in pairs(self._enemyButtons) do
		existingCount += 1
	end

	local shouldRebuild = existingCount ~= #availableEnemies
	if not shouldRebuild then
		for _, entry in ipairs(availableEnemies) do
			if self._enemyButtons[entry.enemyId] == nil then
				shouldRebuild = true
				break
			end
		end
	end

	if shouldRebuild then
		self:_clearEnemyButtons()
		for index, entry in ipairs(availableEnemies) do
			local button =
				self:_createButton(self._enemyList, formatEnemyOptionLabel(entry, false), index)
			button.Size = UDim2.new(1, 0, 0, 30)
			button.TextXAlignment = Enum.TextXAlignment.Left

			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 12)
			padding.PaddingRight = UDim.new(0, 12)
			padding.Parent = button

			self._enemyButtons[entry.enemyId] = button
			self._cleaner:add(button.Activated:Connect(function()
				self:_invokeAction("CombatSandbox/SelectEnemy", {
					enemyId = entry.enemyId,
				})
			end))
		end
	end

	for _, entry in ipairs(availableEnemies) do
		local button = self._enemyButtons[entry.enemyId]
		if button ~= nil then
			local active = snapshot.selectedEnemyId == entry.enemyId
			button.Text = formatEnemyOptionLabel(entry, active)
			self:_setButtonActive(button, active)
		end
	end
end

function SandboxController:_buildJournalText(snapshot)
	local lines = {}
	for _, entry in ipairs(snapshot.journalEntries or {}) do
		if entry.kind == "Action" and entry.actionResult ~= nil then
			local result = entry.actionResult
			local actor = if result.actor ~= nil then result.actor.combatantId else "-"
			local target = if result.target ~= nil then result.target.combatantId else "-"
			local actorLabel = actor
			local targetLabel = target

			for _, fighter in ipairs(snapshot.trio or {}) do
				if fighter.combatantId == actor then
					actorLabel = fighter.displayName
				elseif fighter.combatantId == target then
					targetLabel = fighter.displayName
				end
			end

			if snapshot.enemy ~= nil then
				if actor == snapshot.enemy.enemyId or actor == snapshot.activeEncounterId then
					actorLabel = snapshot.enemy.displayName
				end
				if result.actor ~= nil and result.actor.kind == "Enemy" then
					actorLabel = snapshot.enemy.displayName
				end
				if result.target ~= nil and result.target.kind == "Enemy" then
					targetLabel = snapshot.enemy.displayName
				end
			end

			table.insert(
				lines,
				string.format(
					"[%0.2f] %s -> %s | %s | dmg %d | %s",
					entry.at or 0,
					actorLabel,
					targetLabel,
					getSkillLabel(result.skillId, result.actionType),
					math.floor((result.damageDealt or 0) + 0.5),
					getOutcomeLabel(result.outcome)
				)
			)
		elseif entry.kind == "EncounterEnd" then
			table.insert(
				lines,
				string.format(
					"[%0.2f] Encounter end | %s",
					entry.at or 0,
					tostring(entry.encounterOutcome)
				)
			)
		end
	end

	if #lines == 0 then
		return "No combat log yet."
	end

	local startIndex = math.max(#lines - 25, 1)
	return table.concat(lines, "\n", startIndex, #lines)
end

function SandboxController:_renderEnemyHeader(snapshot)
	if self._enemyHeader == nil then
		return
	end

	local enemy = snapshot.enemy
	if enemy == nil then
		self._enemyHeader.frame.Visible = false
		return
	end

	self._enemyHeader.frame.Visible = true
	self._enemyHeader.title.Text = enemy.title or enemy.displayName
	self._enemyHeader.tag.Text = if type(enemy.threatTag) == "string"
			and enemy.threatTag ~= ""
		then string.format("[%s]", enemy.threatTag)
		else "[Standard]"

	local ratio = if enemy.maxHp > 0 then math.clamp(enemy.currentHp / enemy.maxHp, 0, 1) else 0
	self._enemyHeader.fill.Size = UDim2.fromScale(ratio, 1)
	self._enemyHeader.fill.BackgroundColor3 = getBarColor(ratio)
	self._enemyHeader.value.Text = string.format("%d / %d", enemy.currentHp or 0, enemy.maxHp or 0)
end

function SandboxController:_renderPanel(snapshot)
	self:_syncEnemyButtons(snapshot)

	if self._logLabel ~= nil then
		self._logLabel.Text = self:_buildJournalText(snapshot)
	end

	for speedScale, button in pairs(self._speedButtons) do
		self:_setButtonActive(button, snapshot.speedScale == speedScale)
	end

	local selectedEnemy = findEnemyEntry(snapshot, snapshot.selectedEnemyId)
	local selectedEnemyLabel = if selectedEnemy ~= nil then selectedEnemy.displayName else "-"
	local encounterLabel = if snapshot.enemy ~= nil
		then snapshot.enemy.displayName
		else selectedEnemyLabel

	self:_setStatus(
		string.format(
			"Mode: %s | Selected: %s | Speed: x%d",
			tostring(snapshot.mode),
			encounterLabel,
			snapshot.speedScale or 1
		)
	)
end

function SandboxController:_ensureWorldViews(snapshot)
	for index, fighter in ipairs(snapshot.trio or {}) do
		local view = self._fighterViews[index]
		if view == nil then
			view =
				createWorldView(self._worldFolder, string.format("Fighter%d", index), 136, 42, true)
			self._fighterViews[index] = view
		end

		view._combatantId = fighter.combatantId
	end

	if self._enemyView == nil then
		self._enemyView = createWorldView(self._worldFolder, "Enemy", 0, 0, false)
		self._enemyView.part.Material = Enum.Material.Neon
	end
end

function SandboxController:_hideWorldViews()
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

function SandboxController:_getRootPart()
	local player = Players.LocalPlayer
	local character = player.Character
	if character == nil then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

function SandboxController:_updateView(view, position, size, color, title, currentHp, maxHp)
	view.part.Size = size
	view.part.CFrame = CFrame.new(position + Vector3.new(0, size.Y * 0.5, 0))
	view.part.Color = color
	view.part.Transparency = 0

	if view.billboard ~= nil then
		view.billboard.Enabled = true
	end
	if view.nameLabel ~= nil then
		view.nameLabel.Text = title
	end

	if view.healthBar ~= nil then
		local ratio = if maxHp > 0 then math.clamp(currentHp / maxHp, 0, 1) else 0
		view.healthBar.fill.Size = UDim2.fromScale(ratio, 1)
		view.healthBar.fill.BackgroundColor3 = getBarColor(ratio)
		view.healthBar.label.Text = string.format("%d / %d", currentHp, maxHp)
	end
end

function SandboxController:_resolveEnemyAnchor(rootPart, mode, encounterId)
	if mode == "CombatEncounter" then
		if self._lastEncounterId ~= encounterId or self._currentCombatAnchor == nil then
			if rootPart ~= nil then
				self._currentCombatAnchor = rootPart.Position
					+ rootPart.CFrame.LookVector * PREVIEW_DISTANCE
			else
				self._currentCombatAnchor = Vector3.new(0, WORLD_BASE_Y_OFFSET, 0)
			end
		end

		return self._currentCombatAnchor
	end

	self._currentCombatAnchor = nil
	if rootPart == nil then
		return nil
	end

	return rootPart.Position + rootPart.CFrame.LookVector * PREVIEW_DISTANCE
end

function SandboxController:_updateWorld(snapshot)
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
			then COMBAT_OFFSETS[index]
			else FOLLOW_OFFSETS[index]
		local motionOffset = getMotionOffset(index, snapshot.mode)
		local worldPosition = if snapshot.mode == "CombatEncounter"
			then enemyAnchor + offset + motionOffset + Vector3.new(0, WORLD_BASE_Y_OFFSET, 0)
			else playerBasis:PointToWorldSpace(offset + motionOffset) + Vector3.new(
				0,
				WORLD_BASE_Y_OFFSET,
				0
			)
		self:_updateView(
			view,
			worldPosition,
			FIGHTER_VIEW_SIZE,
			getGradeColor(fighter.grade),
			fighter.displayName,
			math.floor((fighter.currentHp or 0) + 0.5),
			math.floor((fighter.maxHp or 0) + 0.5)
		)
	end

	if snapshot.enemy ~= nil and self._enemyView ~= nil and snapshot.mode == "CombatEncounter" then
		self:_updateView(
			self._enemyView,
			enemyAnchor + Vector3.new(0, WORLD_BASE_Y_OFFSET, 0),
			ENEMY_VIEW_SIZE,
			getEnemyColor(snapshot.enemy.tier),
			snapshot.enemy.displayName,
			math.floor((snapshot.enemy.currentHp or 0) + 0.5),
			math.floor((snapshot.enemy.maxHp or 0) + 0.5)
		)
	elseif self._enemyView ~= nil then
		self._enemyView.part.Transparency = 1
		if self._enemyView.billboard ~= nil then
			self._enemyView.billboard.Enabled = false
		end
	end
end

function SandboxController:_getPopupParent(combatantId)
	for _, view in pairs(self._fighterViews) do
		if view._combatantId == combatantId then
			return view.part
		end
	end

	if self._enemyView ~= nil and self._snapshot ~= nil and self._snapshot.enemy ~= nil then
		local enemyId = self._snapshot.enemy.enemyId
		if
			combatantId == enemyId
			or (self._snapshot.activeEncounterId ~= nil and combatantId:find(":Enemy:") ~= nil)
		then
			return self._enemyView.part
		end
	end

	return nil
end

function SandboxController:_spawnSkillPopup(combatantId, labelText)
	local adornee = self:_getPopupParent(combatantId)
	if adornee == nil then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SkillPopup"
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Size = UDim2.fromOffset(140, 34)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 7.2, 0)
	billboard.Parent = adornee

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(246, 193, 119)
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(20, 24, 34)
	label.TextSize = 12
	label.Text = labelText
	label.Parent = frame

	task.delay(POPUP_LIFETIME, function()
		if billboard.Parent ~= nil then
			billboard:Destroy()
		end
	end)
end

function SandboxController:_processJournalEntries(snapshot)
	if self._lastEncounterId ~= snapshot.activeEncounterId then
		self._processedActionIds = {}
		self._lastEncounterId = snapshot.activeEncounterId
	end

	for _, entry in ipairs(snapshot.journalEntries or {}) do
		if entry.kind == "Action" and entry.actionResult ~= nil then
			local result = entry.actionResult
			local actionId = result.actionId
				or string.format(
					"%s:%s:%s",
					tostring(entry.at),
					tostring(result.actor and result.actor.combatantId),
					tostring(result.skillId)
				)
			if self._processedActionIds[actionId] ~= true then
				self._processedActionIds[actionId] = true
				if result.actionType == "SpecialSkill" and result.actor ~= nil then
					self:_spawnSkillPopup(
						result.actor.combatantId,
						getSkillLabel(result.skillId, result.actionType)
					)
				end
			end
		end
	end
end

function SandboxController:_onSnapshot(snapshot)
	self._snapshot = snapshot
	if snapshot == nil then
		return
	end

	self:_renderEnemyHeader(snapshot)
	self:_renderPanel(snapshot)
	self:_processJournalEntries(snapshot)
end

function SandboxController:start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	self._worldFolder = Instance.new("Folder")
	self._worldFolder.Name = "CombatSandboxClientViews"
	self._worldFolder.Parent = Workspace
	self._cleaner:add(self._worldFolder)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CombatSandboxGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 950
	screenGui.Parent = playerGui
	self._screenGui = screenGui
	self._cleaner:add(screenGui)

	local header = Instance.new("Frame")
	header.Name = "EnemyHeader"
	header.AnchorPoint = Vector2.new(0.5, 0)
	header.Position = UDim2.new(0.5, 0, 0, 12)
	header.Size = UDim2.fromOffset(360, 88)
	header.BackgroundColor3 = Color3.fromRGB(17, 22, 30)
	header.BorderSizePixel = 0
	header.Parent = screenGui

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingTop = UDim.new(0, 10)
	headerPadding.PaddingBottom = UDim.new(0, 10)
	headerPadding.PaddingLeft = UDim.new(0, 12)
	headerPadding.PaddingRight = UDim.new(0, 12)
	headerPadding.Parent = header

	local headerLayout = Instance.new("UIListLayout")
	headerLayout.FillDirection = Enum.FillDirection.Vertical
	headerLayout.Padding = UDim.new(0, 6)
	headerLayout.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 22)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(244, 247, 255)
	title.TextSize = 20
	title.Text = "[Elite] Stone Golem"
	title.Parent = header

	local bar = createHealthBar(header)
	bar.root.Size = UDim2.new(1, 0, 0, 16)
	bar.label.TextSize = 12

	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.new(1, 0, 0, 18)
	tag.BackgroundTransparency = 1
	tag.Font = Enum.Font.GothamMedium
	tag.TextColor3 = Color3.fromRGB(178, 188, 210)
	tag.TextSize = 14
	tag.Text = "[Tanky]"
	tag.Parent = header

	self._enemyHeader = {
		frame = header,
		title = title,
		fill = bar.fill,
		value = bar.label,
		tag = tag,
	}

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -12, 0, 112)
	panel.Size = UDim2.fromOffset(420, 640)
	panel.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	panel.BorderSizePixel = 0
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local panelPadding = Instance.new("UIPadding")
	panelPadding.PaddingTop = UDim.new(0, 12)
	panelPadding.PaddingBottom = UDim.new(0, 12)
	panelPadding.PaddingLeft = UDim.new(0, 12)
	panelPadding.PaddingRight = UDim.new(0, 12)
	panelPadding.Parent = panel

	local panelTitle = Instance.new("TextLabel")
	panelTitle.Size = UDim2.new(1, 0, 0, 28)
	panelTitle.BackgroundTransparency = 1
	panelTitle.Font = Enum.Font.GothamBold
	panelTitle.Text = "Combat Sandbox"
	panelTitle.TextColor3 = Color3.fromRGB(244, 247, 255)
	panelTitle.TextSize = 18
	panelTitle.TextXAlignment = Enum.TextXAlignment.Left
	panelTitle.Parent = panel

	local status = Instance.new("TextLabel")
	status.Position = UDim2.fromOffset(0, 32)
	status.Size = UDim2.new(1, 0, 0, 20)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.Gotham
	status.Text = "Ready"
	status.TextColor3 = Color3.fromRGB(156, 171, 200)
	status.TextSize = 13
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = panel
	self._statusLabel = status

	local actions = Instance.new("Frame")
	actions.Position = UDim2.fromOffset(0, 64)
	actions.Size = UDim2.new(1, 0, 0, 188)
	actions.BackgroundTransparency = 1
	actions.Parent = panel

	local selectionTitle = Instance.new("TextLabel")
	selectionTitle.Size = UDim2.new(1, 0, 0, 18)
	selectionTitle.BackgroundTransparency = 1
	selectionTitle.Font = Enum.Font.GothamBold
	selectionTitle.Text = "Enemy"
	selectionTitle.TextColor3 = Color3.fromRGB(244, 247, 255)
	selectionTitle.TextSize = 13
	selectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	selectionTitle.Parent = actions

	local enemyList = Instance.new("Frame")
	enemyList.Name = "EnemyList"
	enemyList.Position = UDim2.fromOffset(0, 24)
	enemyList.Size = UDim2.new(1, 0, 0, 104)
	enemyList.BackgroundTransparency = 1
	enemyList.Parent = actions
	self._enemyList = enemyList

	local enemyListLayout = Instance.new("UIListLayout")
	enemyListLayout.FillDirection = Enum.FillDirection.Vertical
	enemyListLayout.Padding = UDim.new(0, 7)
	enemyListLayout.Parent = enemyList

	local startButton = self:_createButton(actions, "Start Encounter", 1)
	startButton.Size = UDim2.new(1, 0, 0, 34)
	startButton.Position = UDim2.fromOffset(0, 136)

	local speed1Button = self:_createButton(actions, "Speed x1", 2)
	speed1Button.Position = UDim2.fromOffset(0, 178)

	local speed2Button = self:_createButton(actions, "Speed x2", 3)
	speed2Button.Position = UDim2.new(0.5, 6, 0, 178)

	local endButton = self:_createButton(actions, "End Run", 4)
	endButton.Size = UDim2.new(1, 0, 0, 34)
	endButton.Position = UDim2.fromOffset(0, 220)

	self._speedButtons[1] = speed1Button
	self._speedButtons[2] = speed2Button

	self._cleaner:add(startButton.Activated:Connect(function()
		self:_invokeAction("CombatSandbox/StartEncounter")
	end))
	self._cleaner:add(speed1Button.Activated:Connect(function()
		self:_invokeAction("CombatSandbox/SetSpeed1x")
	end))
	self._cleaner:add(speed2Button.Activated:Connect(function()
		self:_invokeAction("CombatSandbox/SetSpeed2x")
	end))
	self._cleaner:add(endButton.Activated:Connect(function()
		self:_invokeAction("CombatSandbox/EndRun")
	end))

	local logFrame = Instance.new("Frame")
	logFrame.Position = UDim2.fromOffset(0, 268)
	logFrame.Size = UDim2.new(1, 0, 1, -268)
	logFrame.BackgroundColor3 = Color3.fromRGB(11, 14, 22)
	logFrame.BorderSizePixel = 0
	logFrame.Parent = panel

	local logCorner = Instance.new("UICorner")
	logCorner.CornerRadius = UDim.new(0, 10)
	logCorner.Parent = logFrame

	local scrolling = Instance.new("ScrollingFrame")
	scrolling.Size = UDim2.fromScale(1, 1)
	scrolling.BackgroundTransparency = 1
	scrolling.BorderSizePixel = 0
	scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrolling.CanvasSize = UDim2.new()
	scrolling.ScrollBarThickness = 6
	scrolling.Parent = logFrame

	local logLabel = Instance.new("TextLabel")
	logLabel.Size = UDim2.new(1, -8, 0, 0)
	logLabel.AutomaticSize = Enum.AutomaticSize.Y
	logLabel.BackgroundTransparency = 1
	logLabel.Font = Enum.Font.Code
	logLabel.Text = "Waiting for sandbox snapshot..."
	logLabel.TextColor3 = Color3.fromRGB(220, 228, 245)
	logLabel.TextSize = 14
	logLabel.TextWrapped = false
	logLabel.TextXAlignment = Enum.TextXAlignment.Left
	logLabel.TextYAlignment = Enum.TextYAlignment.Top
	logLabel.Parent = scrolling
	self._logLabel = logLabel

	self._cleaner:add(self._snapshotClient:subscribe(SNAPSHOT_TOPIC, function(envelope)
		self:_onSnapshot(envelope.payload)
	end))
	self._cleaner:add(RunService.RenderStepped:Connect(function()
		self:_updateWorld(self._snapshot)
	end))

	self:_onSnapshot(self._snapshotClient:getPayload(SNAPSHOT_TOPIC))
end

function SandboxController:stop()
	self._cleaner:clean()
	self._snapshot = nil
	self._statusLabel = nil
	self._logLabel = nil
	self._enemyHeader = nil
	self._screenGui = nil
	self._worldFolder = nil
	self._enemyList = nil
	self._fighterViews = {}
	self._enemyView = nil
	self._enemyButtons = {}
	self._speedButtons = {}
	self._processedActionIds = {}
	self._lastEncounterId = nil
	self._currentCombatAnchor = nil
end

return SandboxController
