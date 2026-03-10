local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local AssetUri =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("AssetUri"))
local GradeDefinitions = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Progression"):WaitForChild("Grades")
).GradeDefinitions
local Fighters = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Fighters"))
local Cleaner =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Cleaner"))

local AssetConfig = SharedConfig.Assets
local FighterComparison = Fighters.FighterComparison
local FighterMilestones = Fighters.FighterMilestones

local PANEL_WIDTH = 420
local PANEL_MARGIN = 12
local PANEL_TOP = 112
local PANEL_BOTTOM_MARGIN = 12
local HEADER_HEIGHT = 64
local TRIO_SECTION_HEIGHT = 192
local INSPECT_SECTION_HEIGHT = 318
local SECTION_GAP = 12

local FighterRuntimeController = {}
FighterRuntimeController.__index = FighterRuntimeController

local function cloneArray(values)
	return table.clone(values or {})
end

local function tryGetGradeDefinition(gradeId)
	if type(gradeId) == "string" and GradeDefinitions.has(gradeId) then
		return GradeDefinitions.get(gradeId)
	end

	return nil
end

local function getGradeColor(gradeId)
	local definition = tryGetGradeDefinition(gradeId)
	if definition ~= nil then
		return definition.color
	end

	return Color3.fromRGB(214, 220, 232)
end

local function colorToHex(color)
	local r = math.clamp(math.floor(color.R * 255 + 0.5), 0, 255)
	local g = math.clamp(math.floor(color.G * 255 + 0.5), 0, 255)
	local b = math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function richText(text, color)
	return string.format('<font color="%s">%s</font>', colorToHex(color), text)
end

local function findRosterEntry(snapshot, fighterId)
	if snapshot == nil or fighterId == nil then
		return nil
	end

	for _, fighter in ipairs(snapshot.roster or {}) do
		if fighter.fighterId == fighterId then
			return fighter
		end
	end

	return nil
end

local function formatSkillState(fighter)
	if fighter == nil or fighter.specialSkill == nil then
		return "No special skill"
	end

	local skill = fighter.specialSkill
	if not skill.isVisible then
		return "Special hidden"
	end

	if skill.isUnlockedForCombat then
		return string.format("%s | Combat ready", skill.displayName)
	end

	return string.format(
		"%s | Unlocks at Lv.%d",
		skill.displayName,
		FighterMilestones.getSpecialSkillUnlockLevel()
	)
end

local function formatProgressText(fighter)
	if fighter == nil or fighter.progression == nil then
		return "XP unavailable"
	end

	if fighter.progression.isMaxLevel then
		return "MAX"
	end

	return string.format(
		"XP %d/%d",
		fighter.progression.experience,
		fighter.progression.experienceToNextLevel
	)
end

local function formatMilestonesText(fighter)
	if fighter == nil or fighter.milestones == nil then
		return "Milestones unavailable"
	end

	return string.format(
		"Lv3 Skill %s • Lv10 Spike %s • Lv15 Mod %s • Lv20 Capstone %s",
		if fighter.milestones.specialSkillUnlockedForCombat then "Ready" else "Pending",
		if fighter.milestones.classSpikeUnlocked then "Ready" else "Pending",
		if fighter.milestones.specialSkillModifierUnlocked then "Ready" else "Pending",
		if fighter.milestones.subclassCapstoneUnlocked then "Ready" else "Pending"
	)
end

local function formatStatLine(fighter)
	if fighter == nil then
		return "Stats unavailable"
	end

	return string.format(
		"HP %d   ATK %d   DEF %d   SPD %.2fs",
		fighter.stats.hp,
		fighter.stats.damage,
		fighter.stats.defense,
		fighter.stats.attackIntervalSeconds
	)
end

local function formatMetricLine(label, outcome)
	local suffix = "="
	local color = Color3.fromRGB(152, 166, 194)
	if outcome == "better" then
		suffix = "↑"
		color = Color3.fromRGB(111, 214, 132)
	elseif outcome == "worse" then
		suffix = "↓"
		color = Color3.fromRGB(232, 96, 96)
	end

	return string.format("%s %s", richText(label, color), richText(suffix, color))
end

local function buildCompareText(selectedFighter, targetFighter)
	if selectedFighter == nil or targetFighter == nil then
		return richText("Select a fighter and trio slot to compare.", Color3.fromRGB(152, 166, 194))
	end

	if selectedFighter.fighterId == targetFighter.fighterId then
		return richText(
			"Selected fighter already occupies this slot.",
			Color3.fromRGB(152, 166, 194)
		)
	end

	local comparison = FighterComparison.compare(selectedFighter, targetFighter)
	local lines = {
		formatMetricLine("Grade", comparison.grade),
		formatMetricLine("Level", comparison.level),
		formatMetricLine("HP", comparison.stats.hp),
		formatMetricLine("Damage", comparison.stats.damage),
		formatMetricLine("Defense", comparison.stats.defense),
		formatMetricLine("Speed", comparison.stats.attackIntervalSeconds),
	}
	return table.concat(lines, "\n")
end

local function createSectionFrame(parent, yOffset, height)
	local frame = Instance.new("Frame")
	frame.Position = UDim2.fromOffset(0, yOffset)
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.BackgroundColor3 = Color3.fromRGB(18, 23, 33)
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = frame

	return frame
end

local function createSectionTitle(parent, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(244, 247, 255)
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function createCardButton(parent, name)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.Text = ""
	button.BackgroundColor3 = Color3.fromRGB(28, 35, 49)
	button.BorderSizePixel = 0
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(48, 58, 80)
	stroke.Thickness = 1
	stroke.Parent = button

	return button, stroke
end

local function createTrioSlot(parent, index)
	local button, stroke = createCardButton(parent, string.format("Slot%d", index))
	button.Size = UDim2.new(1, 0, 0, 38)
	button.Position = UDim2.fromOffset(0, 28 + (index - 1) * 44)

	local slotLabel = Instance.new("TextLabel")
	slotLabel.Size = UDim2.fromOffset(54, 38)
	slotLabel.BackgroundTransparency = 1
	slotLabel.Font = Enum.Font.GothamBold
	slotLabel.Text = string.format("%d", index)
	slotLabel.TextColor3 = Color3.fromRGB(152, 166, 194)
	slotLabel.TextSize = 14
	slotLabel.Parent = button

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.fromOffset(56, 4)
	nameLabel.Size = UDim2.new(1, -68, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(244, 247, 255)
	nameLabel.TextSize = 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = button

	local metaLabel = Instance.new("TextLabel")
	metaLabel.Position = UDim2.fromOffset(56, 20)
	metaLabel.Size = UDim2.new(1, -68, 0, 14)
	metaLabel.BackgroundTransparency = 1
	metaLabel.Font = Enum.Font.Gotham
	metaLabel.TextColor3 = Color3.fromRGB(152, 166, 194)
	metaLabel.TextSize = 11
	metaLabel.TextXAlignment = Enum.TextXAlignment.Left
	metaLabel.Parent = button

	return {
		button = button,
		stroke = stroke,
		slotLabel = slotLabel,
		nameLabel = nameLabel,
		metaLabel = metaLabel,
	}
end

local function createRosterEntry(parent, index)
	local button, stroke = createCardButton(parent, string.format("RosterEntry%d", index))
	button.Size = UDim2.new(1, -8, 0, 58)
	button.Position = UDim2.fromOffset(4, (index - 1) * 64)

	local icon = Instance.new("ImageLabel")
	icon.Position = UDim2.fromOffset(10, 10)
	icon.Size = UDim2.fromOffset(36, 36)
	icon.BackgroundColor3 = Color3.fromRGB(24, 31, 44)
	icon.BorderSizePixel = 0
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = button

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = icon

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.fromOffset(54, 8)
	nameLabel.Size = UDim2.new(1, -112, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(244, 247, 255)
	nameLabel.TextSize = 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = button

	local metaLabel = Instance.new("TextLabel")
	metaLabel.Position = UDim2.fromOffset(54, 26)
	metaLabel.Size = UDim2.new(1, -112, 0, 14)
	metaLabel.BackgroundTransparency = 1
	metaLabel.Font = Enum.Font.Gotham
	metaLabel.TextColor3 = Color3.fromRGB(168, 181, 204)
	metaLabel.TextSize = 11
	metaLabel.TextXAlignment = Enum.TextXAlignment.Left
	metaLabel.Parent = button

	local skillLabel = Instance.new("TextLabel")
	skillLabel.Position = UDim2.fromOffset(54, 40)
	skillLabel.Size = UDim2.new(1, -112, 0, 12)
	skillLabel.BackgroundTransparency = 1
	skillLabel.Font = Enum.Font.Gotham
	skillLabel.TextColor3 = Color3.fromRGB(142, 154, 176)
	skillLabel.TextSize = 10
	skillLabel.TextXAlignment = Enum.TextXAlignment.Left
	skillLabel.Parent = button

	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.AnchorPoint = Vector2.new(1, 0.5)
	badgeLabel.Position = UDim2.new(1, -12, 0.5, 0)
	badgeLabel.Size = UDim2.fromOffset(44, 18)
	badgeLabel.BackgroundTransparency = 1
	badgeLabel.Font = Enum.Font.GothamBold
	badgeLabel.TextSize = 10
	badgeLabel.TextXAlignment = Enum.TextXAlignment.Right
	badgeLabel.Parent = button

	return {
		button = button,
		stroke = stroke,
		icon = icon,
		nameLabel = nameLabel,
		metaLabel = metaLabel,
		skillLabel = skillLabel,
		badgeLabel = badgeLabel,
	}
end

function FighterRuntimeController.new(config)
	assert(type(config) == "table", "FighterRuntimeController config must be a table")
	assert(
		config.fighterRosterClient ~= nil,
		"FighterRuntimeController requires FighterRosterClient"
	)
	assert(config.debugClient ~= nil, "FighterRuntimeController requires DebugClient")

	return setmetatable({
		_fighterRosterClient = config.fighterRosterClient,
		_debugClient = config.debugClient,
		_cleaner = Cleaner.new(),
		_snapshot = nil,
		_selectedFighterId = nil,
		_focusedTrioSlotIndex = 1,
		_screenGui = nil,
		_statusLabel = nil,
		_summaryLabel = nil,
		_trioSlots = {},
		_assignButton = nil,
		_assignButtonStroke = nil,
		_inspectRefs = nil,
		_rosterScroll = nil,
		_rosterEntries = {},
	}, FighterRuntimeController)
end

function FighterRuntimeController:_setStatus(text, color)
	if self._statusLabel == nil then
		return
	end

	self._statusLabel.Text = text
	self._statusLabel.TextColor3 = color or Color3.fromRGB(152, 166, 194)
end

function FighterRuntimeController:_ensureSelection(snapshot)
	if snapshot == nil then
		self._selectedFighterId = nil
		return
	end

	if
		self._selectedFighterId ~= nil
		and findRosterEntry(snapshot, self._selectedFighterId) ~= nil
	then
		return
	end

	local focusedId = snapshot.activeTrioFighterIds[self._focusedTrioSlotIndex]
	if focusedId ~= nil and findRosterEntry(snapshot, focusedId) ~= nil then
		self._selectedFighterId = focusedId
		return
	end

	local first = snapshot.roster[1]
	self._selectedFighterId = if first ~= nil then first.fighterId else nil
	self._focusedTrioSlotIndex = math.clamp(self._focusedTrioSlotIndex, 1, 3)
end

function FighterRuntimeController:_buildNextTrioFighterIds(snapshot)
	local selectedFighterId = self._selectedFighterId
	if snapshot == nil or selectedFighterId == nil then
		return nil, "Select a fighter first."
	end

	local selectedFighter = findRosterEntry(snapshot, selectedFighterId)
	if selectedFighter == nil then
		return nil, "Selected fighter is no longer in roster."
	end

	local nextIds = cloneArray(snapshot.activeTrioFighterIds)
	if #nextIds ~= 3 then
		return nil, "Active trio is not initialized."
	end

	local targetIndex = math.clamp(self._focusedTrioSlotIndex, 1, 3)
	local existingIndex = nil
	for index, fighterId in ipairs(nextIds) do
		if fighterId == selectedFighterId then
			existingIndex = index
			break
		end
	end

	if existingIndex ~= nil then
		nextIds[existingIndex], nextIds[targetIndex] = nextIds[targetIndex], nextIds[existingIndex]
	else
		nextIds[targetIndex] = selectedFighterId
	end

	local changed = false
	for index = 1, 3 do
		if nextIds[index] ~= snapshot.activeTrioFighterIds[index] then
			changed = true
			break
		end
	end

	if not changed then
		return nil, "Selected fighter already occupies that trio layout."
	end

	return nextIds
end

function FighterRuntimeController:_assignSelectedToFocusedSlot()
	local nextIds, errorText = self:_buildNextTrioFighterIds(self._snapshot)
	if nextIds == nil then
		self:_setStatus(errorText or "Unable to update trio.", Color3.fromRGB(232, 96, 96))
		return
	end

	self:_setStatus("Updating active trio...", Color3.fromRGB(168, 192, 255))
	local ok, result = pcall(function()
		return self._fighterRosterClient:setActiveTrio(nextIds)
	end)

	if not ok then
		self:_setStatus(
			string.format("Trio update failed: %s", tostring(result)),
			Color3.fromRGB(232, 96, 96)
		)
		return
	end

	if type(result) == "table" then
		self:_onSnapshot(result)
		self:_setStatus("Active trio updated.", Color3.fromRGB(111, 214, 132))
	else
		self:_setStatus("Active trio update requested.", Color3.fromRGB(111, 214, 132))
	end
end

function FighterRuntimeController:_refreshSnapshot()
	local snapshot = self._fighterRosterClient:refresh()
	self:_onSnapshot(snapshot)
end

function FighterRuntimeController:_invokeDebugProgressAction(actionKey, payload, successText)
	self:_setStatus("Applying debug progression...", Color3.fromRGB(168, 192, 255))
	local ok, result = pcall(function()
		return self._debugClient:invokeAction(actionKey, payload)
	end)

	if not ok then
		self:_setStatus(
			string.format("Debug progression failed: %s", tostring(result)),
			Color3.fromRGB(232, 96, 96)
		)
		return
	end

	self:_refreshSnapshot()
	if type(result) == "table" and result.ok == false then
		self:_setStatus(
			string.format("Debug progression error: %s", tostring(result.error)),
			Color3.fromRGB(232, 96, 96)
		)
		return
	end

	self:_setStatus(successText, Color3.fromRGB(111, 214, 132))
end

function FighterRuntimeController:_grantSelectedExperience(amount)
	if self._selectedFighterId == nil then
		self:_setStatus("Select a fighter first.", Color3.fromRGB(232, 96, 96))
		return
	end

	self:_invokeDebugProgressAction("Fighters/GrantDebugExperience", {
		fighterId = self._selectedFighterId,
		amount = amount,
	}, string.format("Granted +%d XP.", amount))
end

function FighterRuntimeController:_setSelectedLevel(level)
	if self._selectedFighterId == nil then
		self:_setStatus("Select a fighter first.", Color3.fromRGB(232, 96, 96))
		return
	end

	self:_invokeDebugProgressAction("Fighters/SetDebugLevel", {
		fighterId = self._selectedFighterId,
		level = level,
	}, string.format("Set fighter to Lv.%d.", level))
end

function FighterRuntimeController:_updateSummary(snapshot)
	if self._summaryLabel == nil then
		return
	end

	if snapshot == nil then
		self._summaryLabel.Text = "Waiting for roster snapshot..."
		return
	end

	self._summaryLabel.Text = string.format(
		"Roster %d/%d   |   Active Trio %d/3",
		snapshot.rosterCount or 0,
		snapshot.rosterCapacity or 0,
		#(snapshot.activeTrioFighterIds or {})
	)
end

function FighterRuntimeController:_updateTrioSection(snapshot)
	for index, slot in ipairs(self._trioSlots) do
		local fighterId = if snapshot ~= nil then snapshot.activeTrioFighterIds[index] else nil
		local fighter = if fighterId ~= nil then findRosterEntry(snapshot, fighterId) else nil
		local isFocused = index == self._focusedTrioSlotIndex

		slot.stroke.Color = if isFocused
			then Color3.fromRGB(109, 146, 244)
			else Color3.fromRGB(48, 58, 80)
		slot.stroke.Thickness = if isFocused then 2 else 1
		slot.button.BackgroundColor3 = if isFocused
			then Color3.fromRGB(34, 42, 60)
			else Color3.fromRGB(28, 35, 49)

		if fighter ~= nil then
			slot.nameLabel.Text = fighter.displayName
			slot.nameLabel.TextColor3 = getGradeColor(fighter.grade)
			slot.metaLabel.Text = string.format(
				"Lv.%d • %s • %s",
				fighter.level,
				formatProgressText(fighter),
				if fighter.specialSkill.isUnlockedForCombat then "Skill Ready" else "Skill Locked"
			)
		else
			slot.nameLabel.Text = "Empty slot"
			slot.nameLabel.TextColor3 = Color3.fromRGB(244, 247, 255)
			slot.metaLabel.Text = "No fighter assigned"
		end
	end
end

function FighterRuntimeController:_updateInspectSection(snapshot)
	local refs = self._inspectRefs
	if refs == nil then
		return
	end

	local selected = findRosterEntry(snapshot, self._selectedFighterId)
	local compareTarget = nil
	if snapshot ~= nil then
		compareTarget =
			findRosterEntry(snapshot, snapshot.activeTrioFighterIds[self._focusedTrioSlotIndex])
	end

	if selected == nil then
		refs.name.Text = "No fighter selected"
		refs.name.TextColor3 = Color3.fromRGB(244, 247, 255)
		refs.meta.Text = "Select a roster entry to inspect it."
		refs.skill.Text = ""
		refs.stats.Text = ""
		refs.milestones.Text = ""
		refs.compare.RichText = false
		refs.compare.Text = ""
		refs.icon.Image = ""
		refs.icon.ImageTransparency = 1
		refs.icon.BackgroundTransparency = 1
		return
	end

	local gradeDefinition = tryGetGradeDefinition(selected.grade)
	refs.name.Text = selected.displayName
	refs.name.TextColor3 = getGradeColor(selected.grade)
	refs.meta.Text = string.format(
		"%s • %s • Lv.%d • %s%s",
		selected.classId,
		if gradeDefinition ~= nil then gradeDefinition.displayName else selected.grade,
		selected.level,
		formatProgressText(selected),
		if selected.isInActiveTrio then " • In Active Trio" else " • Bench"
	)
	refs.skill.Text = formatSkillState(selected)
	refs.stats.Text = formatStatLine(selected)
	refs.milestones.Text = formatMilestonesText(selected)
	refs.compare.RichText = true
	refs.compare.Text = buildCompareText(selected, compareTarget)
	refs.compare.TextColor3 = Color3.fromRGB(244, 247, 255)

	local skillIconUri = AssetUri.fromAssetId(
		AssetConfig.SkillAssetResolver.getIconAssetId(selected.specialSkill.skillId)
	)
	refs.icon.Image = skillIconUri or ""
	refs.icon.ImageTransparency = if skillIconUri ~= nil then 0 else 1
	refs.icon.BackgroundTransparency = if skillIconUri ~= nil then 0.08 else 1
end

function FighterRuntimeController:_ensureRosterEntries(snapshot)
	local rosterCount = if snapshot ~= nil then #snapshot.roster else 0
	for index = #self._rosterEntries + 1, rosterCount do
		local stableIndex = index
		local entry = createRosterEntry(self._rosterScroll, stableIndex)
		self._rosterEntries[stableIndex] = entry
		self._cleaner:add(entry.button.Activated:Connect(function()
			local fighter = nil
			if self._snapshot ~= nil then
				fighter = self._snapshot.roster[stableIndex]
			end
			if fighter ~= nil then
				self._selectedFighterId = fighter.fighterId
				self:_render(self._snapshot)
			end
		end))
	end

	for index = rosterCount + 1, #self._rosterEntries do
		self._rosterEntries[index].button.Visible = false
	end
end

function FighterRuntimeController:_updateRosterSection(snapshot)
	if self._rosterScroll == nil then
		return
	end

	self:_ensureRosterEntries(snapshot)

	local roster = if snapshot ~= nil then snapshot.roster else {}
	for index, fighter in ipairs(roster) do
		local entry = self._rosterEntries[index]
		local isSelected = fighter.fighterId == self._selectedFighterId
		entry.button.Visible = true
		entry.button.Position = UDim2.fromOffset(4, (index - 1) * 64)
		entry.stroke.Color = if isSelected
			then Color3.fromRGB(109, 146, 244)
			else if fighter.isInActiveTrio
				then Color3.fromRGB(74, 106, 179)
				else Color3.fromRGB(48, 58, 80)
		entry.stroke.Thickness = if isSelected then 2 else 1
		entry.button.BackgroundColor3 = if isSelected
			then Color3.fromRGB(34, 42, 60)
			else Color3.fromRGB(28, 35, 49)
		entry.nameLabel.Text = fighter.displayName
		entry.nameLabel.TextColor3 = getGradeColor(fighter.grade)
		entry.metaLabel.Text = string.format(
			"%s • Lv.%d • %s",
			fighter.classId,
			fighter.level,
			formatProgressText(fighter)
		)
		entry.skillLabel.Text = formatSkillState(fighter)
		entry.badgeLabel.Text = if fighter.isInActiveTrio then "TRIO" else "BENCH"
		entry.badgeLabel.TextColor3 = if fighter.isInActiveTrio
			then Color3.fromRGB(111, 214, 132)
			else Color3.fromRGB(152, 166, 194)
		entry.icon.Image = AssetUri.fromAssetId(
			AssetConfig.SkillAssetResolver.getIconAssetId(fighter.specialSkill.skillId)
		) or ""
		entry.icon.ImageTransparency = 0
	end

	self._rosterScroll.CanvasSize = UDim2.fromOffset(0, #roster * 64)
end

function FighterRuntimeController:_render(snapshot)
	self:_updateSummary(snapshot)
	self:_updateTrioSection(snapshot)
	self:_updateInspectSection(snapshot)
	self:_updateRosterSection(snapshot)

	if self._assignButton ~= nil then
		local canAssign = snapshot ~= nil and self._selectedFighterId ~= nil
		self._assignButton.AutoButtonColor = canAssign
		self._assignButton.TextTransparency = if canAssign then 0 else 0.35
		self._assignButtonStroke.Color = if canAssign
			then Color3.fromRGB(74, 106, 179)
			else Color3.fromRGB(52, 58, 76)
	end

	if snapshot == nil then
		self:_setStatus("Waiting for fighters snapshot...")
	elseif (snapshot.rosterCount or 0) == 0 then
		self:_setStatus(
			"Roster loaded, but no fighters are seeded yet.",
			Color3.fromRGB(244, 193, 84)
		)
	else
		self:_setStatus("Fighters runtime ready.", Color3.fromRGB(111, 214, 132))
	end
end

function FighterRuntimeController:_onSnapshot(snapshot)
	self._snapshot = snapshot
	self:_ensureSelection(snapshot)
	self:_render(snapshot)
end

function FighterRuntimeController:start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FighterRuntimeGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 940
	screenGui.Parent = playerGui
	self._screenGui = screenGui
	self._cleaner:add(screenGui)

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Position = UDim2.fromOffset(PANEL_MARGIN, PANEL_TOP)
	panel.Size = UDim2.new(0, PANEL_WIDTH, 1, -(PANEL_TOP + PANEL_BOTTOM_MARGIN))
	panel.BackgroundColor3 = Color3.fromRGB(14, 18, 27)
	panel.BorderSizePixel = 0
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = panel

	local panelPadding = Instance.new("UIPadding")
	panelPadding.PaddingTop = UDim.new(0, 12)
	panelPadding.PaddingBottom = UDim.new(0, 12)
	panelPadding.PaddingLeft = UDim.new(0, 12)
	panelPadding.PaddingRight = UDim.new(0, 12)
	panelPadding.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Fighters"
	title.TextColor3 = Color3.fromRGB(244, 247, 255)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local status = Instance.new("TextLabel")
	status.Position = UDim2.fromOffset(0, 32)
	status.Size = UDim2.new(1, 0, 0, 18)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.Gotham
	status.Text = "Waiting for fighters snapshot..."
	status.TextColor3 = Color3.fromRGB(152, 166, 194)
	status.TextSize = 13
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = panel
	self._statusLabel = status

	local summary = Instance.new("TextLabel")
	summary.Position = UDim2.fromOffset(0, 50)
	summary.Size = UDim2.new(1, 0, 0, 14)
	summary.BackgroundTransparency = 1
	summary.Font = Enum.Font.GothamMedium
	summary.Text = "Roster"
	summary.TextColor3 = Color3.fromRGB(178, 188, 210)
	summary.TextSize = 12
	summary.TextXAlignment = Enum.TextXAlignment.Left
	summary.Parent = panel
	self._summaryLabel = summary

	local trioSection = createSectionFrame(panel, HEADER_HEIGHT, TRIO_SECTION_HEIGHT)
	createSectionTitle(trioSection, "Active Trio")
	for index = 1, 3 do
		local stableIndex = index
		local slot = createTrioSlot(trioSection, stableIndex)
		table.insert(self._trioSlots, slot)
		self._cleaner:add(slot.button.Activated:Connect(function()
			self._focusedTrioSlotIndex = stableIndex
			self:_render(self._snapshot)
		end))
	end

	local assignButton, assignStroke = createCardButton(trioSection, "AssignSelected")
	assignButton.Position = UDim2.fromOffset(0, 28 + 3 * 44)
	assignButton.Size = UDim2.new(1, 0, 0, 34)
	assignButton.Text = "Assign Selected To Focus Slot"
	assignButton.Font = Enum.Font.GothamBold
	assignButton.TextSize = 12
	assignButton.TextColor3 = Color3.fromRGB(244, 247, 255)
	self._assignButton = assignButton
	self._assignButtonStroke = assignStroke
	self._cleaner:add(assignButton.Activated:Connect(function()
		self:_assignSelectedToFocusedSlot()
	end))

	local inspectY = HEADER_HEIGHT + TRIO_SECTION_HEIGHT + SECTION_GAP
	local inspectSection = createSectionFrame(panel, inspectY, INSPECT_SECTION_HEIGHT)
	createSectionTitle(inspectSection, "Inspect")

	local inspectIcon = Instance.new("ImageLabel")
	inspectIcon.Position = UDim2.fromOffset(0, 28)
	inspectIcon.Size = UDim2.fromOffset(46, 46)
	inspectIcon.BackgroundColor3 = Color3.fromRGB(24, 31, 44)
	inspectIcon.BorderSizePixel = 0
	inspectIcon.ScaleType = Enum.ScaleType.Fit
	inspectIcon.Parent = inspectSection
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 10)
	iconCorner.Parent = inspectIcon

	local inspectName = Instance.new("TextLabel")
	inspectName.Position = UDim2.fromOffset(58, 28)
	inspectName.Size = UDim2.new(1, -58, 0, 18)
	inspectName.BackgroundTransparency = 1
	inspectName.Font = Enum.Font.GothamBold
	inspectName.Text = "No fighter selected"
	inspectName.TextColor3 = Color3.fromRGB(244, 247, 255)
	inspectName.TextSize = 15
	inspectName.TextXAlignment = Enum.TextXAlignment.Left
	inspectName.Parent = inspectSection

	local inspectMeta = Instance.new("TextLabel")
	inspectMeta.Position = UDim2.fromOffset(58, 48)
	inspectMeta.Size = UDim2.new(1, -58, 0, 16)
	inspectMeta.BackgroundTransparency = 1
	inspectMeta.Font = Enum.Font.Gotham
	inspectMeta.TextColor3 = Color3.fromRGB(168, 181, 204)
	inspectMeta.TextSize = 12
	inspectMeta.TextXAlignment = Enum.TextXAlignment.Left
	inspectMeta.Parent = inspectSection

	local inspectSkill = Instance.new("TextLabel")
	inspectSkill.Position = UDim2.fromOffset(0, 84)
	inspectSkill.Size = UDim2.new(1, 0, 0, 18)
	inspectSkill.BackgroundTransparency = 1
	inspectSkill.Font = Enum.Font.GothamMedium
	inspectSkill.TextColor3 = Color3.fromRGB(228, 198, 106)
	inspectSkill.TextSize = 12
	inspectSkill.TextXAlignment = Enum.TextXAlignment.Left
	inspectSkill.Parent = inspectSection

	local inspectStats = Instance.new("TextLabel")
	inspectStats.Position = UDim2.fromOffset(0, 108)
	inspectStats.Size = UDim2.new(1, 0, 0, 18)
	inspectStats.BackgroundTransparency = 1
	inspectStats.Font = Enum.Font.Code
	inspectStats.TextColor3 = Color3.fromRGB(212, 220, 236)
	inspectStats.TextSize = 12
	inspectStats.TextXAlignment = Enum.TextXAlignment.Left
	inspectStats.Parent = inspectSection

	local milestonesLabel = Instance.new("TextLabel")
	milestonesLabel.Position = UDim2.fromOffset(0, 132)
	milestonesLabel.Size = UDim2.new(1, 0, 0, 32)
	milestonesLabel.BackgroundTransparency = 1
	milestonesLabel.Font = Enum.Font.Gotham
	milestonesLabel.TextColor3 = Color3.fromRGB(168, 181, 204)
	milestonesLabel.TextSize = 11
	milestonesLabel.TextWrapped = true
	milestonesLabel.TextXAlignment = Enum.TextXAlignment.Left
	milestonesLabel.TextYAlignment = Enum.TextYAlignment.Top
	milestonesLabel.Parent = inspectSection

	local xp25Button, xp25Stroke = createCardButton(inspectSection, "GrantXp25")
	xp25Button.Position = UDim2.fromOffset(0, 170)
	xp25Button.Size = UDim2.new(0.5, -6, 0, 30)
	xp25Button.Text = "+25 XP"
	xp25Button.Font = Enum.Font.GothamBold
	xp25Button.TextSize = 12
	xp25Button.TextColor3 = Color3.fromRGB(244, 247, 255)
	xp25Stroke.Color = Color3.fromRGB(74, 106, 179)
	self._cleaner:add(xp25Button.Activated:Connect(function()
		self:_grantSelectedExperience(25)
	end))

	local xp100Button, xp100Stroke = createCardButton(inspectSection, "GrantXp100")
	xp100Button.Position = UDim2.new(0.5, 6, 0, 170)
	xp100Button.Size = UDim2.new(0.5, -6, 0, 30)
	xp100Button.Text = "+100 XP"
	xp100Button.Font = Enum.Font.GothamBold
	xp100Button.TextSize = 12
	xp100Button.TextColor3 = Color3.fromRGB(244, 247, 255)
	xp100Stroke.Color = Color3.fromRGB(74, 106, 179)
	self._cleaner:add(xp100Button.Activated:Connect(function()
		self:_grantSelectedExperience(100)
	end))

	local lv3Button, lv3Stroke = createCardButton(inspectSection, "SetLv3")
	lv3Button.Position = UDim2.fromOffset(0, 206)
	lv3Button.Size = UDim2.new(0.5, -6, 0, 30)
	lv3Button.Text = "Set Lv.3"
	lv3Button.Font = Enum.Font.GothamBold
	lv3Button.TextSize = 12
	lv3Button.TextColor3 = Color3.fromRGB(244, 247, 255)
	lv3Stroke.Color = Color3.fromRGB(74, 106, 179)
	self._cleaner:add(lv3Button.Activated:Connect(function()
		self:_setSelectedLevel(3)
	end))

	local lv10Button, lv10Stroke = createCardButton(inspectSection, "SetLv10")
	lv10Button.Position = UDim2.new(0.5, 6, 0, 206)
	lv10Button.Size = UDim2.new(0.5, -6, 0, 30)
	lv10Button.Text = "Set Lv.10"
	lv10Button.Font = Enum.Font.GothamBold
	lv10Button.TextSize = 12
	lv10Button.TextColor3 = Color3.fromRGB(244, 247, 255)
	lv10Stroke.Color = Color3.fromRGB(74, 106, 179)
	self._cleaner:add(lv10Button.Activated:Connect(function()
		self:_setSelectedLevel(10)
	end))

	local compareTitle = Instance.new("TextLabel")
	compareTitle.Position = UDim2.fromOffset(0, 244)
	compareTitle.Size = UDim2.new(1, 0, 0, 16)
	compareTitle.BackgroundTransparency = 1
	compareTitle.Font = Enum.Font.GothamBold
	compareTitle.Text = "Compare vs Focused Trio Slot"
	compareTitle.TextColor3 = Color3.fromRGB(244, 247, 255)
	compareTitle.TextSize = 12
	compareTitle.TextXAlignment = Enum.TextXAlignment.Left
	compareTitle.Parent = inspectSection

	local compareLabel = Instance.new("TextLabel")
	compareLabel.Position = UDim2.fromOffset(0, 264)
	compareLabel.Size = UDim2.new(1, 0, 0, 44)
	compareLabel.BackgroundTransparency = 1
	compareLabel.Font = Enum.Font.GothamMedium
	compareLabel.RichText = true
	compareLabel.Text = ""
	compareLabel.TextColor3 = Color3.fromRGB(244, 247, 255)
	compareLabel.TextSize = 12
	compareLabel.TextWrapped = false
	compareLabel.TextXAlignment = Enum.TextXAlignment.Left
	compareLabel.TextYAlignment = Enum.TextYAlignment.Top
	compareLabel.Parent = inspectSection

	self._inspectRefs = {
		icon = inspectIcon,
		name = inspectName,
		meta = inspectMeta,
		skill = inspectSkill,
		stats = inspectStats,
		milestones = milestonesLabel,
		compare = compareLabel,
	}

	local rosterY = inspectY + INSPECT_SECTION_HEIGHT + SECTION_GAP
	local rosterSection = createSectionFrame(panel, rosterY, 0)
	rosterSection.Size = UDim2.new(1, 0, 1, -(rosterY + 12))
	createSectionTitle(rosterSection, "Roster")

	local rosterScroll = Instance.new("ScrollingFrame")
	rosterScroll.Position = UDim2.fromOffset(0, 26)
	rosterScroll.Size = UDim2.new(1, 0, 1, -26)
	rosterScroll.BackgroundTransparency = 1
	rosterScroll.BorderSizePixel = 0
	rosterScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	rosterScroll.ScrollBarThickness = 6
	rosterScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	rosterScroll.Parent = rosterSection
	self._rosterScroll = rosterScroll

	self._cleaner:add(self._fighterRosterClient:subscribe(function(snapshot)
		self:_onSnapshot(snapshot)
	end))

	local initialSnapshot = self._fighterRosterClient:getSnapshot()
	if initialSnapshot == nil then
		initialSnapshot = self._fighterRosterClient:refresh()
	end
	self:_onSnapshot(initialSnapshot)
end

function FighterRuntimeController:stop()
	self._cleaner:clean()
	self._snapshot = nil
	self._selectedFighterId = nil
	self._focusedTrioSlotIndex = 1
	self._screenGui = nil
	self._statusLabel = nil
	self._summaryLabel = nil
	self._trioSlots = {}
	self._assignButton = nil
	self._assignButtonStroke = nil
	self._inspectRefs = nil
	self._rosterScroll = nil
	self._rosterEntries = {}
end

return FighterRuntimeController
