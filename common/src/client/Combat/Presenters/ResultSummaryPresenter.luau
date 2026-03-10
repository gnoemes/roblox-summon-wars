local ResultSummaryPresenter = {}
ResultSummaryPresenter.__index = ResultSummaryPresenter

local function getEncounterOutcomeColor(outcome)
	if outcome == "Victory" then
		return Color3.fromRGB(111, 214, 132)
	end
	if outcome == "Defeat" then
		return Color3.fromRGB(232, 96, 96)
	end
	return Color3.fromRGB(178, 188, 210)
end

local function getCombatantDisplayName(labelsById, combatantId)
	local label = labelsById[combatantId]
	if
		type(label) == "table"
		and type(label.displayName) == "string"
		and label.displayName ~= ""
	then
		return label.displayName
	end
	if type(label) == "string" and label ~= "" then
		return label
	end
	return combatantId
end

local function formatCombatantNames(labelsById, combatantIds)
	local names = {}
	for _, combatantId in ipairs(combatantIds or {}) do
		table.insert(names, getCombatantDisplayName(labelsById, combatantId))
	end

	if #names == 0 then
		return "None"
	end

	return table.concat(names, ", ")
end

local function deriveEncounterSurvivorLists(lastEncounter)
	local finalStates = lastEncounter.finalFighterStatesByCombatantId or {}
	local survivors = {}
	local defeated = {}

	for combatantId, fighterState in pairs(finalStates) do
		if type(fighterState) == "table" and (fighterState.currentHp or 0) > 0 then
			table.insert(survivors, combatantId)
		else
			table.insert(defeated, combatantId)
		end
	end

	table.sort(survivors)
	table.sort(defeated)

	if #survivors > 0 or #defeated > 0 then
		return survivors, defeated
	end

	local result = lastEncounter.result
	return if result ~= nil then result.remainingFighterCombatantIds or {} else {},
		if result ~= nil then result.defeatedFighterCombatantIds or {} else {}
end

local function formatProgressionAwards(lastEncounter)
	local progression = lastEncounter.progression
	if type(progression) ~= "table" or type(progression.fighterAwards) ~= "table" then
		return "XP: None", "Level Ups: None"
	end

	local xpParts = {}
	local levelParts = {}
	for _, award in ipairs(progression.fighterAwards) do
		local displayName = award.displayName or award.fighterId or "Fighter"
		table.insert(xpParts, string.format("%s +%d", displayName, award.grantedExperience or 0))
		if award.leveledUp == true then
			table.insert(
				levelParts,
				string.format(
					"%s %d→%d",
					displayName,
					award.levelBefore or 0,
					award.levelAfter or 0
				)
			)
		end
	end

	return string.format("XP: %s", if #xpParts > 0 then table.concat(xpParts, ", ") else "None"),
		string.format(
			"Level Ups: %s",
			if #levelParts > 0 then table.concat(levelParts, ", ") else "None"
		)
end

function ResultSummaryPresenter.new(parent)
	assert(parent ~= nil, "ResultSummaryPresenter requires a parent")

	local self = setmetatable({}, ResultSummaryPresenter)

	local frame = Instance.new("Frame")
	frame.Name = "ResultSummary"
	frame.Position = UDim2.fromOffset(0, 226)
	frame.Size = UDim2.new(1, 0, 0, 108)
	frame.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent

	local summaryCorner = Instance.new("UICorner")
	summaryCorner.CornerRadius = UDim.new(0, 10)
	summaryCorner.Parent = frame

	local summaryPadding = Instance.new("UIPadding")
	summaryPadding.PaddingTop = UDim.new(0, 8)
	summaryPadding.PaddingBottom = UDim.new(0, 8)
	summaryPadding.PaddingLeft = UDim.new(0, 10)
	summaryPadding.PaddingRight = UDim.new(0, 10)
	summaryPadding.Parent = frame

	local summaryTitle = Instance.new("TextLabel")
	summaryTitle.Size = UDim2.new(0.4, 0, 0, 18)
	summaryTitle.BackgroundTransparency = 1
	summaryTitle.Font = Enum.Font.GothamBold
	summaryTitle.Text = "Last Result"
	summaryTitle.TextColor3 = Color3.fromRGB(244, 247, 255)
	summaryTitle.TextSize = 13
	summaryTitle.TextXAlignment = Enum.TextXAlignment.Left
	summaryTitle.Parent = frame

	local outcomeLabel = Instance.new("TextLabel")
	outcomeLabel.AnchorPoint = Vector2.new(1, 0)
	outcomeLabel.Position = UDim2.fromScale(1, 0)
	outcomeLabel.Size = UDim2.new(0.35, 0, 0, 18)
	outcomeLabel.BackgroundTransparency = 1
	outcomeLabel.Font = Enum.Font.GothamBold
	outcomeLabel.Text = "Victory"
	outcomeLabel.TextColor3 = Color3.fromRGB(111, 214, 132)
	outcomeLabel.TextSize = 13
	outcomeLabel.TextXAlignment = Enum.TextXAlignment.Right
	outcomeLabel.Parent = frame

	local summaryMeta = Instance.new("TextLabel")
	summaryMeta.Position = UDim2.fromOffset(0, 18)
	summaryMeta.Size = UDim2.new(1, 0, 0, 16)
	summaryMeta.BackgroundTransparency = 1
	summaryMeta.Font = Enum.Font.GothamMedium
	summaryMeta.Text = "HuntingGrounds • 0.00s • survivors 3/3"
	summaryMeta.TextColor3 = Color3.fromRGB(168, 181, 204)
	summaryMeta.TextSize = 11
	summaryMeta.TextXAlignment = Enum.TextXAlignment.Left
	summaryMeta.Parent = frame

	local summarySurvivors = Instance.new("TextLabel")
	summarySurvivors.Position = UDim2.fromOffset(0, 38)
	summarySurvivors.Size = UDim2.new(1, 0, 0, 14)
	summarySurvivors.BackgroundTransparency = 1
	summarySurvivors.Font = Enum.Font.Gotham
	summarySurvivors.Text = "Alive: None"
	summarySurvivors.TextColor3 = Color3.fromRGB(214, 220, 232)
	summarySurvivors.TextSize = 11
	summarySurvivors.TextXAlignment = Enum.TextXAlignment.Left
	summarySurvivors.Parent = frame

	local summaryDefeated = Instance.new("TextLabel")
	summaryDefeated.Position = UDim2.fromOffset(0, 52)
	summaryDefeated.Size = UDim2.new(1, 0, 0, 14)
	summaryDefeated.BackgroundTransparency = 1
	summaryDefeated.Font = Enum.Font.Gotham
	summaryDefeated.Text = "Down: None"
	summaryDefeated.TextColor3 = Color3.fromRGB(152, 166, 194)
	summaryDefeated.TextSize = 11
	summaryDefeated.TextXAlignment = Enum.TextXAlignment.Left
	summaryDefeated.Parent = frame

	local summaryExperience = Instance.new("TextLabel")
	summaryExperience.Position = UDim2.fromOffset(0, 68)
	summaryExperience.Size = UDim2.new(1, 0, 0, 14)
	summaryExperience.BackgroundTransparency = 1
	summaryExperience.Font = Enum.Font.Gotham
	summaryExperience.Text = "XP: None"
	summaryExperience.TextColor3 = Color3.fromRGB(214, 220, 232)
	summaryExperience.TextSize = 11
	summaryExperience.TextXAlignment = Enum.TextXAlignment.Left
	summaryExperience.Parent = frame

	local summaryLevels = Instance.new("TextLabel")
	summaryLevels.Position = UDim2.fromOffset(0, 82)
	summaryLevels.Size = UDim2.new(1, 0, 0, 14)
	summaryLevels.BackgroundTransparency = 1
	summaryLevels.Font = Enum.Font.Gotham
	summaryLevels.Text = "Level Ups: None"
	summaryLevels.TextColor3 = Color3.fromRGB(152, 166, 194)
	summaryLevels.TextSize = 11
	summaryLevels.TextXAlignment = Enum.TextXAlignment.Left
	summaryLevels.Parent = frame

	self._frame = frame
	self._outcome = outcomeLabel
	self._meta = summaryMeta
	self._survivors = summarySurvivors
	self._defeated = summaryDefeated
	self._experience = summaryExperience
	self._levels = summaryLevels

	return self
end

function ResultSummaryPresenter:render(snapshot)
	local lastEncounter = if snapshot ~= nil then snapshot.lastEncounter else nil
	if lastEncounter == nil or lastEncounter.outcome == nil then
		self._frame.Visible = false
		return
	end

	local labelsById = lastEncounter.combatantLabelsById or {}
	local result = lastEncounter.result
	local survivors = lastEncounter.aliveCombatantIds
	local defeated = lastEncounter.downCombatantIds
	if type(survivors) ~= "table" or type(defeated) ~= "table" then
		survivors, defeated = deriveEncounterSurvivorLists(lastEncounter)
	end

	local aliveNames = if type(lastEncounter.aliveDisplayNames) == "table"
		then lastEncounter.aliveDisplayNames
		else nil
	local downNames = if type(lastEncounter.downDisplayNames) == "table"
		then lastEncounter.downDisplayNames
		else nil
	local survivorCount = if type(lastEncounter.survivorCount) == "number"
		then lastEncounter.survivorCount
		else #survivors
	local durationSeconds = if result ~= nil then result.durationSeconds or 0 else 0

	self._frame.Visible = true
	self._outcome.Text = tostring(lastEncounter.outcome)
	self._outcome.TextColor3 = getEncounterOutcomeColor(lastEncounter.outcome)
	self._meta.Text = string.format(
		"%s • %.2fs • survivors %d/3",
		tostring(snapshot.extractionType or "-"),
		durationSeconds,
		survivorCount
	)
	self._survivors.Text = string.format(
		"Alive: %s",
		if aliveNames ~= nil and #aliveNames > 0
			then table.concat(aliveNames, ", ")
			else formatCombatantNames(labelsById, survivors)
	)
	self._defeated.Text = string.format(
		"Down: %s",
		if downNames ~= nil and #downNames > 0
			then table.concat(downNames, ", ")
			else formatCombatantNames(labelsById, defeated)
	)

	local xpText, levelText = formatProgressionAwards(lastEncounter)
	self._experience.Text = xpText
	self._levels.Text = levelText
end

return ResultSummaryPresenter
