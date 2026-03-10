local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cleaner =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Cleaner"))

local SandboxHudPresenter = {}
SandboxHudPresenter.__index = SandboxHudPresenter

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

function SandboxHudPresenter.new(parent, config)
	assert(parent ~= nil, "SandboxHudPresenter requires a parent")
	assert(type(config) == "table", "SandboxHudPresenter config must be a table")
	assert(config.debugClient ~= nil, "SandboxHudPresenter requires DebugClient")
	assert(type(config.getSkillLabel) == "function", "SandboxHudPresenter requires getSkillLabel")
	assert(
		type(config.getOutcomeLabel) == "function",
		"SandboxHudPresenter requires getOutcomeLabel"
	)

	local self = setmetatable({
		_debugClient = config.debugClient,
		_getSkillLabel = config.getSkillLabel,
		_getOutcomeLabel = config.getOutcomeLabel,
		_cleaner = Cleaner.new(),
		_panel = nil,
		_statusLabel = nil,
		_logLabel = nil,
		_enemyList = nil,
		_enemyButtons = {},
		_speedButtons = {},
	}, SandboxHudPresenter)

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -12, 0, 112)
	panel.Size = UDim2.fromOffset(420, 640)
	panel.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	panel.BorderSizePixel = 0
	panel.Parent = parent

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
	selectionTitle.Text = "Enemy (auto-start)"
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

	local speed1Button = self:_createButton(actions, "Speed x1", 1)
	speed1Button.Position = UDim2.fromOffset(0, 136)

	local speed2Button = self:_createButton(actions, "Speed x2", 2)
	speed2Button.Position = UDim2.new(0.5, 6, 0, 136)

	local endButton = self:_createButton(actions, "End Run", 3)
	endButton.Size = UDim2.new(1, 0, 0, 34)
	endButton.Position = UDim2.fromOffset(0, 178)

	self._speedButtons[1] = speed1Button
	self._speedButtons[2] = speed2Button

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
	logFrame.Position = UDim2.fromOffset(0, 342)
	logFrame.Size = UDim2.new(1, 0, 1, -342)
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

	self._panel = panel
	return self
end

function SandboxHudPresenter:getPanel()
	return self._panel
end

function SandboxHudPresenter:_setStatus(text)
	if self._statusLabel ~= nil then
		self._statusLabel.Text = text
	end
end

function SandboxHudPresenter:_createButton(parent, text, layoutOrder)
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

function SandboxHudPresenter:_setButtonActive(button, active)
	if active then
		button.BackgroundColor3 = Color3.fromRGB(86, 109, 168)
	else
		button.BackgroundColor3 = Color3.fromRGB(42, 48, 62)
	end
end

function SandboxHudPresenter:_invokeAction(actionKey, payload)
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

function SandboxHudPresenter:_clearEnemyButtons()
	for enemyId, button in pairs(self._enemyButtons) do
		button:Destroy()
		self._enemyButtons[enemyId] = nil
	end
end

function SandboxHudPresenter:_syncEnemyButtons(snapshot)
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

function SandboxHudPresenter:_buildJournalText(snapshot)
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
					self._getSkillLabel(result.skillId, result.actionType),
					math.floor((result.damageDealt or 0) + 0.5),
					self._getOutcomeLabel(result.outcome)
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

function SandboxHudPresenter:render(snapshot)
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

	local statusText = string.format(
		"Mode: %s | Selected: %s | Speed: x%d",
		tostring(snapshot.mode),
		encounterLabel,
		snapshot.speedScale or 1
	)
	if type(snapshot.lastStartError) == "string" and snapshot.lastStartError ~= "" then
		statusText = string.format("%s | StartError: %s", statusText, snapshot.lastStartError)
	end

	self:_setStatus(statusText)
end

function SandboxHudPresenter:stop()
	self._cleaner:clean()
	self._panel = nil
	self._statusLabel = nil
	self._logLabel = nil
	self._enemyList = nil
	self._enemyButtons = {}
	self._speedButtons = {}
end

return SandboxHudPresenter
