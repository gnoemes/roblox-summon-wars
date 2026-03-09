local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CombatConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Combat"))
local GradeDefinitions = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Progression"):WaitForChild("Grades")
).GradeDefinitions

local COMBAT_VIEW_KEY = "Combat/SyntheticRun"
local REFRESH_INTERVAL_SECONDS = 0.35

local Overlay = {}
Overlay.__index = Overlay

local OUTCOME_LABELS = {
	Resolved = "попал",
	Missed = "промах",
	Blocked = "заблокировано",
	Cancelled = "отмена",
	Invalid = "нет цели",
}

local ACTION_LABELS = {
	BasicAttack = "Базовая атака",
	SpecialSkill = "Скилл",
	StatusTick = "DoT/эффект",
	PassiveTrigger = "Пассивный эффект",
	DeathResolve = "Смерть",
}

local RICH_COLORS = table.freeze({
	Time = "rgb(143,153,173)",
	FighterName = "rgb(123,216,143)",
	EnemyName = "rgb(255,107,107)",
	Kind = "rgb(147,160,184)",
	BasicAttack = "rgb(182,190,206)",
	Skill = "rgb(246,193,119)",
	Passive = "rgb(199,146,234)",
	OutcomeSuccess = "rgb(123,216,143)",
	OutcomeFailure = "rgb(255,107,107)",
	OutcomeMuted = "rgb(170,178,197)",
	StatusPoison = "rgb(152,195,121)",
	StatusBleed = "rgb(224,108,117)",
	StatusStun = "rgb(229,192,123)",
	StatusSilence = "rgb(199,146,234)",
})

local function escapeRichText(value)
	local text = tostring(value)
	text = text:gsub("&", "&amp;")
	text = text:gsub("<", "&lt;")
	text = text:gsub(">", "&gt;")
	return text
end

local function paint(text, colorHex)
	return string.format('<font color="%s">%s</font>', colorHex, escapeRichText(text))
end

local function color3ToRichText(color)
	local red = math.floor(color.R * 255 + 0.5)
	local green = math.floor(color.G * 255 + 0.5)
	local blue = math.floor(color.B * 255 + 0.5)
	return string.format("rgb(%d,%d,%d)", red, green, blue)
end

local function sortedStringKeys(map)
	local keys = {}
	for key in pairs(map or {}) do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

local function tryGet(registry, definitionId)
	if type(definitionId) ~= "string" or definitionId == "" then
		return nil
	end

	if registry.has(definitionId) then
		return registry.get(definitionId)
	end

	return nil
end

local function formatGradeTag(gradeId)
	local definition = tryGet(GradeDefinitions, gradeId)
	if definition == nil then
		return ""
	end

	return " " .. paint(string.format("[%s]", definition.displayName), color3ToRichText(definition.color))
end

local function getStatusColor(statusId)
	if statusId == "Status.Poison" then
		return RICH_COLORS.StatusPoison
	end
	if statusId == "Status.Bleed" then
		return RICH_COLORS.StatusBleed
	end
	if statusId == "Status.Stun" then
		return RICH_COLORS.StatusStun
	end
	if statusId == "Status.Silence" then
		return RICH_COLORS.StatusSilence
	end

	local definition = tryGet(CombatConfig.StatusDefinitions, statusId)
	if definition ~= nil then
		if definition.kind == "DamageOverTime" then
			return RICH_COLORS.StatusPoison
		end
		if definition.kind == "Control" then
			return RICH_COLORS.StatusSilence
		end
	end

	return RICH_COLORS.Skill
end

local function getSkillLabel(skillId, actionType)
	local definition = tryGet(CombatConfig.SkillDefinitions, skillId)
	if definition ~= nil then
		if definition.kind == "BasicAttack" then
			return "Базовая атака"
		end
		return definition.displayName
	end

	local statusDefinition = tryGet(CombatConfig.StatusDefinitions, skillId)
	if statusDefinition ~= nil then
		return string.format("DoT/эффект: %s", statusDefinition.displayName)
	end

	return ACTION_LABELS[actionType] or tostring(actionType)
end

local function getOutcomeLabel(outcome)
	return OUTCOME_LABELS[outcome] or tostring(outcome)
end

local function getOutcomeColor(outcome)
	if outcome == "Resolved" then
		return RICH_COLORS.OutcomeSuccess
	end
	if outcome == "Missed" or outcome == "Invalid" then
		return RICH_COLORS.OutcomeFailure
	end
	return RICH_COLORS.OutcomeMuted
end

local function getStatusLabel(statusId)
	local definition = tryGet(CombatConfig.StatusDefinitions, statusId)
	if definition ~= nil then
		return definition.displayName
	end

	return tostring(statusId)
end

local function getCombatantColor(kind)
	if kind == "Fighter" then
		return RICH_COLORS.FighterName
	end
	if kind == "Enemy" then
		return RICH_COLORS.EnemyName
	end
	return RICH_COLORS.Kind
end

local function getActionColor(skillId, actionType)
	local definition = tryGet(CombatConfig.SkillDefinitions, skillId)
	if definition ~= nil then
		if definition.kind == "BasicAttack" then
			return RICH_COLORS.BasicAttack
		end
		return RICH_COLORS.Skill
	end

	if actionType == "BasicAttack" then
		return RICH_COLORS.BasicAttack
	end
	if actionType == "StatusTick" then
		return getStatusColor(skillId)
	end
	if actionType == "PassiveTrigger" then
		return RICH_COLORS.Passive
	end

	return RICH_COLORS.Skill
end

local function formatCooldowns(cooldowns)
	local keys = sortedStringKeys(cooldowns)
	if #keys == 0 then
		return paint("готово", RICH_COLORS.Kind)
	end

	local parts = {}
	for _, skillId in ipairs(keys) do
		local label = getSkillLabel(skillId, "SpecialSkill")
		table.insert(
			parts,
			string.format(
				"%s %.1fs",
				paint(label, getActionColor(skillId, "SpecialSkill")),
				cooldowns[skillId]
			)
		)
	end
	return table.concat(parts, ", ")
end

local function formatStatuses(statusesById, now)
	local keys = sortedStringKeys(statusesById)
	if #keys == 0 then
		return paint("-", RICH_COLORS.Kind)
	end

	local parts = {}
	for _, statusId in ipairs(keys) do
		local state = statusesById[statusId]
		local remaining = 0
		if type(state) == "table" and type(state.expiresAt) == "number" then
			remaining = math.max(state.expiresAt - now, 0)
		end
		local stacks = if type(state) == "table" and type(state.stacks) == "number"
			then state.stacks
			else 1
		table.insert(
			parts,
			string.format(
				"%s x%d %.1fs",
				paint(getStatusLabel(statusId), getStatusColor(statusId)),
				stacks,
				remaining
			)
		)
	end
	return table.concat(parts, ", ")
end

local function formatCombatantLines(combatant, elapsedTime)
	local nextIn = math.max((combatant.nextActionAt or 0) - elapsedTime, 0)
	local displayName = paint(combatant.displayName, getCombatantColor(combatant.kind))
	local gradeTag = formatGradeTag(combatant.grade)
	local kind = paint(combatant.kind or "-", RICH_COLORS.Kind)
	local line1 = string.format(
		"- %s%s | %s | HP %.0f/%.0f | next %.2fs | atk %.2fs",
		displayName,
		gradeTag,
		kind,
		combatant.currentHp,
		combatant.maxHp,
		nextIn,
		combatant.attackIntervalSeconds or 0
	)

	local activeSkillLabel = paint("-", RICH_COLORS.Kind)
	if type(combatant.specialSkillIds) == "table" and #combatant.specialSkillIds > 0 then
		local activeParts = {}
		for _, skillId in ipairs(combatant.specialSkillIds) do
			table.insert(
				activeParts,
				paint(getSkillLabel(skillId, "SpecialSkill"), getActionColor(skillId, "SpecialSkill"))
			)
		end
		activeSkillLabel = table.concat(activeParts, ", ")
	end

	local line2 = string.format("  Активные: %s", activeSkillLabel)
	local line3 = string.format(
		"  КД: %s | Эффекты: %s",
		formatCooldowns(combatant.cooldowns),
		formatStatuses(combatant.activeStatuses, elapsedTime)
	)
	return line1, line2, line3
end

local function resolveCombatantLabel(combatantRef, labelMap)
	if combatantRef == nil then
		return "-", "-"
	end

	local label = labelMap[combatantRef.combatantId]
	if label ~= nil then
		return label.displayName, label.kind
	end

	return combatantRef.combatantId, combatantRef.kind or "-"
end

local function formatJournalLine(entry, labelMap)
	if entry.kind == "Action" and entry.actionResult ~= nil then
		local result = entry.actionResult
		local actorName, actorKind = resolveCombatantLabel(result.actor, labelMap)
		local targetName, targetKind = resolveCombatantLabel(result.target, labelMap)
		local what = getSkillLabel(result.skillId, result.actionType)
		local damage = math.floor((result.damageDealt or 0) + 0.5)
		local outcome = getOutcomeLabel(result.outcome)
		local line = string.format(
			"- %s %s -> %s | %s | %s | урон %d | результат %s",
			paint(string.format("[%.2f]", entry.at or 0), RICH_COLORS.Time),
			paint(actorName, getCombatantColor(actorKind)),
			paint(targetName, getCombatantColor(targetKind)),
			paint(actorKind, RICH_COLORS.Kind),
			paint(what, getActionColor(result.skillId, result.actionType)),
			damage,
			paint(outcome, getOutcomeColor(result.outcome))
		)
		if type(result.appliedEffectIds) == "table" and #result.appliedEffectIds > 0 then
			local effectLabels = {}
			for _, effectId in ipairs(result.appliedEffectIds) do
				table.insert(effectLabels, paint(getStatusLabel(effectId), getStatusColor(effectId)))
			end
			line ..= string.format(" | эффект %s", table.concat(effectLabels, ", "))
		end
		return line
	end

	if entry.kind == "EncounterEnd" then
		return string.format(
			"- %s Завершение боя | результат %s",
			paint(string.format("[%.2f]", entry.at or 0), RICH_COLORS.Time),
			paint(tostring(entry.encounterOutcome), RICH_COLORS.OutcomeMuted)
		)
	end

	return string.format(
		"- %s %s",
		paint(string.format("[%.2f]", entry.at or 0), RICH_COLORS.Time),
		escapeRichText(tostring(entry.kind))
	)
end
local function buildLabelMap(combatView)
	local labelMap = {}

	for _, combatant in ipairs(combatView.liveCombatants or {}) do
		labelMap[combatant.combatantId] = {
			displayName = combatant.displayName,
			kind = combatant.kind,
		}
	end

	if
		combatView.lastEncounter ~= nil
		and type(combatView.lastEncounter.combatantLabelsById) == "table"
	then
		for combatantId, label in pairs(combatView.lastEncounter.combatantLabelsById) do
			labelMap[combatantId] = label
		end
	end

	return labelMap
end

local function buildStateText(state)
	if state == nil then
		return "Debug state is not available yet."
	end

	if state.enabled ~= true then
		return "Debug is disabled for this player."
	end

	local combatView = state.views and state.views[COMBAT_VIEW_KEY]
	if combatView == nil then
		return "Combat/SyntheticRun view is not registered."
	end

	if combatView.error ~= nil then
		return string.format("Combat/SyntheticRun error:\n%s", tostring(combatView.error))
	end

	if combatView.hasRun ~= true then
		return "No active synthetic run."
	end

	local lines = {}
	local activeEncounter = combatView.activeEncounter
	local elapsedTime = if activeEncounter ~= nil then (activeEncounter.elapsedTime or 0) else 0
	local labelMap = buildLabelMap(combatView)
	local headerLines = {
		string.format("Run: %s", combatView.runInstanceId or "-"),
		string.format("Extraction: %s", combatView.extractionType or "-"),
		string.format("Enemy: %s", combatView.enemyId or "-"),
		string.format("Encounter index: %s", tostring(combatView.encounterIndex)),
		string.format("Active encounter: %s", tostring(combatView.activeEncounterId)),
	}

	for _, line in ipairs(headerLines) do
		table.insert(lines, line)
	end

	if activeEncounter ~= nil then
		table.insert(
			lines,
			string.format("Elapsed: %.2f | State: %s", elapsedTime, tostring(activeEncounter.state))
		)
	end

	table.insert(lines, "")
	table.insert(lines, "Live combatants:")
	for _, combatant in ipairs(combatView.liveCombatants or {}) do
		local line1, line2, line3 = formatCombatantLines(combatant, elapsedTime)
		table.insert(lines, line1)
		table.insert(lines, line2)
		table.insert(lines, line3)
	end

	table.insert(lines, "")
	table.insert(lines, "Persistent fighters:")
	local persistentIds = sortedStringKeys(combatView.persistentFighters or {})
	for _, combatantId in ipairs(persistentIds) do
		local fighterState = combatView.persistentFighters[combatantId]
		local label = labelMap[combatantId]
		local displayName = fighterState.displayName
			or (if label ~= nil then label.displayName else combatantId)
		local displayNameText = paint(displayName, RICH_COLORS.FighterName)
		local gradeTag = formatGradeTag(fighterState.grade)
		table.insert(
			lines,
			string.format(
				"- %s%s | HP %.0f/%.0f",
				displayNameText,
				gradeTag,
				fighterState.currentHp or 0,
				fighterState.maxHp or 0
			)
		)
	end

	local journalEntries = nil
	if activeEncounter ~= nil then
		journalEntries = activeEncounter.journalEntries
	elseif combatView.lastEncounter ~= nil then
		journalEntries = combatView.lastEncounter.journalEntries
	end

	if journalEntries ~= nil then
		table.insert(lines, "")
		table.insert(lines, "Journal:")
		local startIndex = math.max(#journalEntries - 23, 1)
		for index = startIndex, #journalEntries do
			table.insert(lines, formatJournalLine(journalEntries[index], labelMap))
		end
	end

	return table.concat(lines, "\n")
end

local function createButton(parent, text, layoutOrder)
	local button = Instance.new("TextButton")
	button.Name = text:gsub("%s+", "")
	button.LayoutOrder = layoutOrder
	button.AutoButtonColor = true
	button.Size = UDim2.new(0.5, -6, 0, 32)
	button.BackgroundColor3 = Color3.fromRGB(38, 44, 58)
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

function Overlay.new(config)
	assert(type(config) == "table", "Overlay config must be a table")
	assert(config.debugClient ~= nil, "Overlay requires DebugClient")

	return setmetatable({
		_debugClient = config.debugClient,
		_connections = {},
		_alive = false,
		_statusLabel = nil,
		_outputLabel = nil,
		_screenGui = nil,
	}, Overlay)
end

function Overlay:_setStatus(text)
	if self._statusLabel ~= nil then
		self._statusLabel.Text = text
	end
end

function Overlay:_render(state)
	if self._outputLabel ~= nil then
		self._outputLabel.Text = buildStateText(state)
	end
end

function Overlay:_track(connection)
	table.insert(self._connections, connection)
	return connection
end

function Overlay:_invokeAction(actionKey)
	self:_setStatus(string.format("Invoking %s...", actionKey))
	local ok, result = pcall(function()
		return self._debugClient:invokeAction(actionKey)
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

function Overlay:start()
	if self._alive or not RunService:IsStudio() then
		return
	end

	self._alive = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CombatDebugOverlay"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 1000
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Position = UDim2.fromOffset(12, 12)
	frame.Size = UDim2.fromOffset(860, 720)
	frame.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(54, 62, 82)
	stroke.Thickness = 1
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Combat Debug"
	title.TextColor3 = Color3.fromRGB(244, 247, 255)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Position = UDim2.fromOffset(0, 32)
	status.Size = UDim2.new(1, 0, 0, 20)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.Gotham
	status.Text = "Ready"
	status.TextColor3 = Color3.fromRGB(156, 171, 200)
	status.TextSize = 13
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = frame
	self._statusLabel = status

	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.Position = UDim2.fromOffset(0, 60)
	actions.Size = UDim2.new(1, 0, 0, 112)
	actions.BackgroundTransparency = 1
	actions.Parent = frame

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -6, 0, 32)
	grid.CellPadding = UDim2.fromOffset(12, 8)
	grid.FillDirectionMaxCells = 2
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = actions

	local buttonSpecs = {
		{ text = "Refresh", action = nil },
		{ text = "Start HG", action = "Combat/StartSyntheticHuntingGrounds" },
		{ text = "Start Dungeon", action = "Combat/StartSyntheticDungeon" },
		{ text = "Start Raid", action = "Combat/StartSyntheticRaid" },
		{ text = "Next Encounter", action = "Combat/StartNextEncounter" },
		{ text = "End Run", action = "Combat/EndRun" },
	}

	for index, spec in ipairs(buttonSpecs) do
		local button = createButton(actions, spec.text, index)
		self:_track(button.Activated:Connect(function()
			if spec.action == nil then
				self:_setStatus("Refreshing...")
				local ok, err = pcall(function()
					self._debugClient:refresh()
				end)
				if ok then
					self:_setStatus("Refresh ok")
				else
					self:_setStatus(string.format("Refresh failed: %s", tostring(err)))
				end
				return
			end

			self:_invokeAction(spec.action)
		end))
	end

	local outputFrame = Instance.new("Frame")
	outputFrame.Name = "OutputFrame"
	outputFrame.Position = UDim2.fromOffset(0, 184)
	outputFrame.Size = UDim2.new(1, 0, 1, -184)
	outputFrame.BackgroundColor3 = Color3.fromRGB(11, 14, 22)
	outputFrame.BorderSizePixel = 0
	outputFrame.Parent = frame

	local outputCorner = Instance.new("UICorner")
	outputCorner.CornerRadius = UDim.new(0, 10)
	outputCorner.Parent = outputFrame

	local outputPadding = Instance.new("UIPadding")
	outputPadding.PaddingTop = UDim.new(0, 8)
	outputPadding.PaddingBottom = UDim.new(0, 8)
	outputPadding.PaddingLeft = UDim.new(0, 8)
	outputPadding.PaddingRight = UDim.new(0, 8)
	outputPadding.Parent = outputFrame

	local scrolling = Instance.new("ScrollingFrame")
	scrolling.Name = "Scrolling"
	scrolling.Size = UDim2.fromScale(1, 1)
	scrolling.BackgroundTransparency = 1
	scrolling.BorderSizePixel = 0
	scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrolling.CanvasSize = UDim2.new()
	scrolling.ScrollBarThickness = 6
	scrolling.Parent = outputFrame

	local output = Instance.new("TextLabel")
	output.Name = "Output"
	output.Size = UDim2.new(1, -4, 0, 0)
	output.AutomaticSize = Enum.AutomaticSize.Y
	output.BackgroundTransparency = 1
	output.Font = Enum.Font.Code
	output.Text = "Waiting for debug state..."
	output.TextColor3 = Color3.fromRGB(220, 228, 245)
	output.TextSize = 14
	output.TextWrapped = false
	output.RichText = true
	output.TextXAlignment = Enum.TextXAlignment.Left
	output.TextYAlignment = Enum.TextYAlignment.Top
	output.Parent = scrolling
	self._outputLabel = output

	self:_track(self._debugClient:subscribe(function(state)
		self:_render(state)
	end))

	self:_render(self._debugClient:getState())

	task.spawn(function()
		while self._alive do
			task.wait(REFRESH_INTERVAL_SECONDS)
			local ok, err = pcall(function()
				self._debugClient:refresh()
			end)
			if not ok then
				self:_setStatus(string.format("Refresh failed: %s", tostring(err)))
			end
		end
	end)
end

function Overlay:stop()
	self._alive = false

	for index = #self._connections, 1, -1 do
		self._connections[index]:Disconnect()
		self._connections[index] = nil
	end

	if self._screenGui ~= nil then
		self._screenGui:Destroy()
		self._screenGui = nil
	end

	self._statusLabel = nil
	self._outputLabel = nil
end

return Overlay
