local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptEditorService = game:GetService("ScriptEditorService")

local TOOLBAR_NAME = "SummonWars"
local BUTTON_NAME = "Skill Assets"
local WIDGET_ID = "SummonWars.SkillAssetBrowser"
local SELECTED_SKILL_SETTING = "SummonWars.SkillAssetBrowser.SelectedSkillId"
local SEARCH_SETTING = "SummonWars.SkillAssetBrowser.Search"
local OVERRIDES_FOLDER_NAME = "StudioAssetOverrides"
local OVERRIDES_MODULE_NAME = "SkillAssetEntries"
local DEFAULT_STATUS = "Sync the Rojo project, then assign Studio overrides for skill icons."

local toolbar = plugin:CreateToolbar(TOOLBAR_NAME)
local toggleButton = toolbar:CreateButton(
	BUTTON_NAME,
	"Open the Skill Asset Browser",
	"rbxassetid://4458901886"
)
toggleButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,
	true,
	false,
	420,
	620,
	360,
	420
)
local widget = plugin:CreateDockWidgetPluginGui(WIDGET_ID, widgetInfo)
widget.Title = BUTTON_NAME

local state = {
	skillRows = {},
	skills = {},
	projectBindingsBySkillId = {},
	overrideBindingsBySkillId = {},
	selectedSkillId = plugin:GetSetting(SELECTED_SKILL_SETTING),
	searchText = plugin:GetSetting(SEARCH_SETTING) or "",
	statusText = DEFAULT_STATUS,
	projectModules = nil,
}

local refs = {}

local function trim(value)
	return string.gsub(value or "", "^%s*(.-)%s*$", "%1")
end

local function escapeLuaString(value)
	return string.format("%q", value)
end

local function normalizeAssetInput(value)
	local trimmed = trim(value)
	if trimmed == "" then
		return nil
	end

	if string.match(trimmed, "^%d+$") ~= nil then
		return tonumber(trimmed)
	end

	return trimmed
end

local function assetIdToDisplay(value)
	if value == nil then
		return ""
	end

	return tostring(value)
end

local function assetIdToImage(value)
	if value == nil then
		return ""
	end

	local stringValue = tostring(value)
	if string.find(stringValue, "://", 1, true) ~= nil then
		return stringValue
	end

	if string.match(stringValue, "^%d+$") ~= nil then
		return string.format("rbxassetid://%s", stringValue)
	end

	return stringValue
end

local function findProjectModules()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if shared == nil then
		return nil, "ReplicatedStorage.Shared was not found. Start Rojo sync first."
	end

	local config = shared:FindFirstChild("Config")
	if config == nil then
		return nil, "ReplicatedStorage.Shared.Config was not found."
	end

	local combat = config:FindFirstChild("Combat")
	local assets = config:FindFirstChild("Assets")
	if combat == nil then
		return nil, "ReplicatedStorage.Shared.Config.Combat was not found."
	end
	if assets == nil then
		return nil, "ReplicatedStorage.Shared.Config.Assets was not found. Sync the latest repo changes."
	end

	local skillDefinitionsModule = combat:FindFirstChild("SkillDefinitions")
	local skillEntriesModule = assets:FindFirstChild("SkillAssetEntries")
	local imageDefaultsModule = assets:FindFirstChild("ImageDefaults")
	if skillDefinitionsModule == nil then
		return nil, "Combat.SkillDefinitions module was not found."
	end
	if skillEntriesModule == nil then
		return nil, "Assets.SkillAssetEntries module was not found."
	end
	if imageDefaultsModule == nil then
		return nil, "Assets.ImageDefaults module was not found. Sync the latest repo changes."
	end

	return {
		skillDefinitionsModule = skillDefinitionsModule,
		projectSkillEntriesModule = skillEntriesModule,
		imageDefaultsModule = imageDefaultsModule,
	}
end

local function readBindings(moduleScript)
	if moduleScript == nil then
		return {}, nil
	end

	local ok, bindings = pcall(require, moduleScript)
	if not ok then
		return nil, string.format("Failed to load %s: %s", moduleScript.Name, tostring(bindings))
	end

	if type(bindings) ~= "table" then
		return nil, string.format("%s must return a table.", moduleScript.Name)
	end

	local normalized = {}
	for skillId, entry in pairs(bindings) do
		if type(skillId) == "string" and type(entry) == "table" then
			normalized[skillId] = entry.iconAssetId
		end
	end

	return normalized, nil
end

local function readSkills(skillDefinitionsModule)
	local ok, registry = pcall(require, skillDefinitionsModule)
	if not ok then
		return nil, string.format("Failed to load SkillDefinitions: %s", tostring(registry))
	end

	if type(registry) ~= "table" or type(registry.list) ~= "function" then
		return nil, "SkillDefinitions did not return a registry API."
	end

	local skills = {}
	for _, definition in ipairs(registry.list()) do
		table.insert(skills, {
			skillId = definition.skillId,
			displayName = definition.displayName,
			fallbackIconAssetId = definition.iconAssetId,
		})
	end

	table.sort(skills, function(left, right)
		if left.displayName == right.displayName then
			return left.skillId < right.skillId
		end
		return left.displayName < right.displayName
	end)

	return skills, nil
end

local function readPlaceholderImageAssetId(imageDefaultsModule)
	local ok, imageDefaults = pcall(require, imageDefaultsModule)
	if not ok or type(imageDefaults) ~= "table" then
		return nil
	end

	return imageDefaults.PlaceholderImageAssetId
end

local function buildEntriesSource(skills, bindingsBySkillId)
	local lines = {
		"return table.freeze({",
	}
	local wroteEntry = false

	for _, skill in ipairs(skills) do
		local iconAssetId = bindingsBySkillId[skill.skillId]
		if iconAssetId ~= nil then
			wroteEntry = true
			table.insert(lines, string.format("\t[%s] = {", escapeLuaString(skill.skillId)))
			table.insert(lines, string.format("\t\tskillId = %s,", escapeLuaString(skill.skillId)))
			if type(iconAssetId) == "number" then
				table.insert(lines, string.format("\t\ticonAssetId = %d,", iconAssetId))
			else
				table.insert(
					lines,
					string.format("\t\ticonAssetId = %s,", escapeLuaString(tostring(iconAssetId)))
				)
			end
			table.insert(lines, "\t},")
		end
	end

	if not wroteEntry then
		table.insert(lines, "\t-- Plugin-managed studio overrides. Keys must match SkillDefinition.skillId.")
	end

	table.insert(lines, "})")
	return table.concat(lines, "\n")
end

local function setStatus(text)
	state.statusText = text
	if refs.statusLabel ~= nil then
		refs.statusLabel.Text = text
	end
end

local function getSkillById(skillId)
	for _, skill in ipairs(state.skills) do
		if skill.skillId == skillId then
			return skill
		end
	end

	return nil
end

local function getEffectiveAssetId(skill)
	local overrideAssetId = state.overrideBindingsBySkillId[skill.skillId]
	if overrideAssetId ~= nil then
		return overrideAssetId, "Studio override"
	end

	local projectAssetId = state.projectBindingsBySkillId[skill.skillId]
	if projectAssetId ~= nil then
		return projectAssetId, "Project binding"
	end

	if skill.fallbackIconAssetId ~= nil then
		return skill.fallbackIconAssetId, "Definition fallback"
	end

	return state.placeholderImageAssetId, "Global placeholder"
end

local function updatePreview()
	if refs.previewImage == nil or refs.previewText == nil then
		return
	end

	local skill = getSkillById(state.selectedSkillId)
	if skill == nil then
		refs.previewImage.Image = ""
		refs.previewImage.Visible = false
		refs.previewText.Text = "Select a skill"
		refs.previewText.Visible = true
		refs.skillNameLabel.Text = "No skill selected"
		refs.skillIdLabel.Text = "-"
		refs.assetInput.Text = ""
		refs.projectValueLabel.Text = "-"
		refs.fallbackValueLabel.Text = assetIdToDisplay(state.placeholderImageAssetId)
		refs.sourceValueLabel.Text = "-"
		return
	end

	local effectiveAssetId, sourceLabel = getEffectiveAssetId(skill)
	local projectAssetId = state.projectBindingsBySkillId[skill.skillId]
	local overrideAssetId = state.overrideBindingsBySkillId[skill.skillId]
	local imageUri = assetIdToImage(effectiveAssetId)

	refs.skillNameLabel.Text = skill.displayName
	refs.skillIdLabel.Text = skill.skillId
	refs.assetInput.Text = assetIdToDisplay(overrideAssetId)
	refs.projectValueLabel.Text = assetIdToDisplay(projectAssetId)
	refs.fallbackValueLabel.Text = assetIdToDisplay(skill.fallbackIconAssetId or state.placeholderImageAssetId)
	refs.sourceValueLabel.Text = sourceLabel

	if imageUri ~= "" then
		refs.previewImage.Image = imageUri
		refs.previewImage.Visible = true
		refs.previewText.Visible = false
	else
		refs.previewImage.Image = ""
		refs.previewImage.Visible = false
		refs.previewText.Text = "No icon available"
		refs.previewText.Visible = true
	end
end

local function updateSelection(skillId)
	state.selectedSkillId = skillId
	plugin:SetSetting(SELECTED_SKILL_SETTING, skillId)

	for entrySkillId, row in pairs(state.skillRows) do
		local active = entrySkillId == skillId
		row.Root.BackgroundColor3 = if active
			then Color3.fromRGB(74, 96, 150)
			else Color3.fromRGB(33, 39, 52)
		row.NameLabel.TextColor3 = if active
			then Color3.fromRGB(255, 255, 255)
			else Color3.fromRGB(229, 235, 247)
		row.IdLabel.TextColor3 = if active
			then Color3.fromRGB(228, 236, 255)
			else Color3.fromRGB(140, 154, 184)
		row.AssetLabel.TextColor3 = if active
			then Color3.fromRGB(255, 220, 160)
			else Color3.fromRGB(205, 170, 118)
	end

	updatePreview()
end

local function matchesSearch(skill, searchText)
	if searchText == "" then
		return true
	end

	local loweredSearch = string.lower(searchText)
	return string.find(string.lower(skill.displayName), loweredSearch, 1, true) ~= nil
		or string.find(string.lower(skill.skillId), loweredSearch, 1, true) ~= nil
end

local function rebuildSkillList()
	if refs.skillList == nil then
		return
	end

	for _, child in ipairs(refs.skillList:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "Layout" then
			child:Destroy()
		end
	end
	state.skillRows = {}

	local layoutOrder = 0
	for _, skill in ipairs(state.skills) do
		if matchesSearch(skill, state.searchText) then
			layoutOrder += 1
			local row = Instance.new("TextButton")
			row.Name = skill.skillId
			row.LayoutOrder = layoutOrder
			row.Size = UDim2.new(1, 0, 0, 58)
			row.AutoButtonColor = true
			row.BorderSizePixel = 0
			row.BackgroundColor3 = Color3.fromRGB(33, 39, 52)
			row.Text = ""
			row.Parent = refs.skillList

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = row

			local padding = Instance.new("UIPadding")
			padding.PaddingTop = UDim.new(0, 7)
			padding.PaddingBottom = UDim.new(0, 7)
			padding.PaddingLeft = UDim.new(0, 10)
			padding.PaddingRight = UDim.new(0, 10)
			padding.Parent = row

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "Name"
			nameLabel.BackgroundTransparency = 1
			nameLabel.Size = UDim2.new(1, 0, 0, 18)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 13
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextColor3 = Color3.fromRGB(229, 235, 247)
			nameLabel.Text = skill.displayName
			nameLabel.Parent = row

			local idLabel = Instance.new("TextLabel")
			idLabel.Name = "Id"
			idLabel.BackgroundTransparency = 1
			idLabel.Position = UDim2.fromOffset(0, 20)
			idLabel.Size = UDim2.new(1, 0, 0, 14)
			idLabel.Font = Enum.Font.Code
			idLabel.TextSize = 11
			idLabel.TextXAlignment = Enum.TextXAlignment.Left
			idLabel.TextColor3 = Color3.fromRGB(140, 154, 184)
			idLabel.Text = skill.skillId
			idLabel.Parent = row

			local assetLabel = Instance.new("TextLabel")
			assetLabel.Name = "Asset"
			assetLabel.BackgroundTransparency = 1
			assetLabel.AnchorPoint = Vector2.new(1, 1)
			assetLabel.Position = UDim2.new(1, 0, 1, 0)
			assetLabel.Size = UDim2.new(0.52, 0, 0, 14)
			assetLabel.Font = Enum.Font.GothamMedium
			assetLabel.TextSize = 11
			assetLabel.TextXAlignment = Enum.TextXAlignment.Right
			assetLabel.TextColor3 = Color3.fromRGB(205, 170, 118)
			local effectiveAssetId, sourceLabel = getEffectiveAssetId(skill)
			assetLabel.Text = string.format("%s: %s", sourceLabel, assetIdToDisplay(effectiveAssetId))
			assetLabel.Parent = row

			row.Activated:Connect(function()
				updateSelection(skill.skillId)
			end)

			state.skillRows[skill.skillId] = {
				Root = row,
				NameLabel = nameLabel,
				IdLabel = idLabel,
				AssetLabel = assetLabel,
			}
		end
	end

	if layoutOrder == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "Empty"
		emptyLabel.LayoutOrder = 1
		emptyLabel.Size = UDim2.new(1, 0, 0, 30)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextSize = 13
		emptyLabel.TextColor3 = Color3.fromRGB(150, 161, 184)
		emptyLabel.Text = "No skills match the current search."
		emptyLabel.Parent = refs.skillList
	end

	local selectedSkillId = state.selectedSkillId
	if getSkillById(selectedSkillId) == nil then
		selectedSkillId = state.skills[1] and state.skills[1].skillId or nil
	end
	updateSelection(selectedSkillId)
end

local function getOrCreateOverridesModule()
	local overridesFolder = ReplicatedStorage:FindFirstChild(OVERRIDES_FOLDER_NAME)
	if overridesFolder == nil then
		overridesFolder = Instance.new("Folder")
		overridesFolder.Name = OVERRIDES_FOLDER_NAME
		overridesFolder.Parent = ReplicatedStorage
	end

	local moduleScript = overridesFolder:FindFirstChild(OVERRIDES_MODULE_NAME)
	if moduleScript == nil then
		moduleScript = Instance.new("ModuleScript")
		moduleScript.Name = OVERRIDES_MODULE_NAME
		moduleScript.Parent = overridesFolder
		pcall(function()
			moduleScript.Source = "return table.freeze({})"
		end)
	end

	return moduleScript
end

local function loadProjectState()
	local projectModules, projectError = findProjectModules()
	if projectModules == nil then
		state.projectModules = nil
		state.skills = {}
		state.projectBindingsBySkillId = {}
		state.overrideBindingsBySkillId = {}
		state.placeholderImageAssetId = nil
		setStatus(projectError)
		rebuildSkillList()
		return
	end

	local skills, skillsError = readSkills(projectModules.skillDefinitionsModule)
	if skills == nil then
		state.projectModules = nil
		state.skills = {}
		state.projectBindingsBySkillId = {}
		state.overrideBindingsBySkillId = {}
		state.placeholderImageAssetId = nil
		setStatus(skillsError)
		rebuildSkillList()
		return
	end

	local projectBindingsBySkillId, bindingsError = readBindings(projectModules.projectSkillEntriesModule)
	if projectBindingsBySkillId == nil then
		state.projectModules = nil
		state.skills = skills
		state.projectBindingsBySkillId = {}
		state.overrideBindingsBySkillId = {}
		state.placeholderImageAssetId = nil
		setStatus(bindingsError)
		rebuildSkillList()
		return
	end

	local overridesModule = ReplicatedStorage:FindFirstChild(OVERRIDES_FOLDER_NAME)
	local overrideEntriesModule = nil
	if overridesModule ~= nil then
		overrideEntriesModule = overridesModule:FindFirstChild(OVERRIDES_MODULE_NAME)
	end

	local overrideBindingsBySkillId, overridesError = readBindings(overrideEntriesModule)
	if overrideBindingsBySkillId == nil then
		state.projectModules = nil
		state.skills = skills
		state.projectBindingsBySkillId = projectBindingsBySkillId
		state.overrideBindingsBySkillId = {}
		state.placeholderImageAssetId = nil
		setStatus(overridesError)
		rebuildSkillList()
		return
	end

	state.projectModules = projectModules
	state.skills = skills
	state.projectBindingsBySkillId = projectBindingsBySkillId
	state.overrideBindingsBySkillId = overrideBindingsBySkillId
	state.placeholderImageAssetId = readPlaceholderImageAssetId(projectModules.imageDefaultsModule)
	setStatus(string.format("Loaded %d skills. Saving writes Studio-only overrides.", #skills))
	rebuildSkillList()
end

local function saveOverrides()
	if state.projectModules == nil then
		setStatus("Project modules are unavailable. Sync the Rojo project first.")
		return
	end

	local overrideModule = getOrCreateOverridesModule()
	local source = buildEntriesSource(state.skills, state.overrideBindingsBySkillId)
	local ok, result = pcall(function()
		ChangeHistoryService:SetWaypoint("BeforeStudioSkillAssetOverrides")
		ScriptEditorService:UpdateSourceAsync(overrideModule, function(_oldSource)
			return source
		end)
		ChangeHistoryService:SetWaypoint("AfterStudioSkillAssetOverrides")
	end)

	if not ok then
		setStatus(string.format("Save failed: %s", tostring(result)))
		return
	end

	setStatus("Saved Studio override. Play mode should now use this icon inside Studio.")
	rebuildSkillList()
	updatePreview()
end

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
root.BorderSizePixel = 0
root.Parent = widget

local rootPadding = Instance.new("UIPadding")
rootPadding.PaddingTop = UDim.new(0, 10)
rootPadding.PaddingBottom = UDim.new(0, 10)
rootPadding.PaddingLeft = UDim.new(0, 10)
rootPadding.PaddingRight = UDim.new(0, 10)
rootPadding.Parent = root

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 22)
title.Font = Enum.Font.GothamBold
title.Text = "Skill Asset Browser"
title.TextColor3 = Color3.fromRGB(244, 247, 255)
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = root

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(0, 24)
subtitle.Size = UDim2.new(1, 0, 0, 18)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Studio overrides for combat skill icons"
subtitle.TextColor3 = Color3.fromRGB(154, 167, 196)
subtitle.TextSize = 13
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = root

local searchBox = Instance.new("TextBox")
searchBox.Position = UDim2.fromOffset(0, 52)
searchBox.Size = UDim2.new(1, 0, 0, 32)
searchBox.BackgroundColor3 = Color3.fromRGB(31, 37, 49)
searchBox.BorderSizePixel = 0
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "Search by skill name or id"
searchBox.Text = state.searchText
searchBox.TextColor3 = Color3.fromRGB(244, 247, 255)
searchBox.PlaceholderColor3 = Color3.fromRGB(124, 135, 159)
searchBox.TextSize = 13
searchBox.Parent = root
refs.searchBox = searchBox

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

local columns = Instance.new("Frame")
columns.Position = UDim2.fromOffset(0, 94)
columns.Size = UDim2.new(1, 0, 1, -128)
columns.BackgroundTransparency = 1
columns.Parent = root

local leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0.56, -6, 1, 0)
leftPanel.BackgroundColor3 = Color3.fromRGB(24, 29, 40)
leftPanel.BorderSizePixel = 0
leftPanel.Parent = columns

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 10)
leftCorner.Parent = leftPanel

local skillList = Instance.new("ScrollingFrame")
skillList.Name = "SkillList"
skillList.Size = UDim2.fromScale(1, 1)
skillList.BackgroundTransparency = 1
skillList.BorderSizePixel = 0
skillList.AutomaticCanvasSize = Enum.AutomaticSize.Y
skillList.CanvasSize = UDim2.new()
skillList.ScrollBarThickness = 6
skillList.Parent = leftPanel
refs.skillList = skillList

local skillListPadding = Instance.new("UIPadding")
skillListPadding.PaddingTop = UDim.new(0, 10)
skillListPadding.PaddingBottom = UDim.new(0, 10)
skillListPadding.PaddingLeft = UDim.new(0, 10)
skillListPadding.PaddingRight = UDim.new(0, 10)
skillListPadding.Parent = skillList

local skillListLayout = Instance.new("UIListLayout")
skillListLayout.Name = "Layout"
skillListLayout.FillDirection = Enum.FillDirection.Vertical
skillListLayout.Padding = UDim.new(0, 8)
skillListLayout.Parent = skillList

local rightPanel = Instance.new("Frame")
rightPanel.AnchorPoint = Vector2.new(1, 0)
rightPanel.Position = UDim2.new(1, 0, 0, 0)
rightPanel.Size = UDim2.new(0.44, 0, 1, 0)
rightPanel.BackgroundColor3 = Color3.fromRGB(24, 29, 40)
rightPanel.BorderSizePixel = 0
rightPanel.Parent = columns

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 10)
rightCorner.Parent = rightPanel

local rightPadding = Instance.new("UIPadding")
rightPadding.PaddingTop = UDim.new(0, 12)
rightPadding.PaddingBottom = UDim.new(0, 12)
rightPadding.PaddingLeft = UDim.new(0, 12)
rightPadding.PaddingRight = UDim.new(0, 12)
rightPadding.Parent = rightPanel

local rightLayout = Instance.new("UIListLayout")
rightLayout.FillDirection = Enum.FillDirection.Vertical
rightLayout.Padding = UDim.new(0, 8)
rightLayout.Parent = rightPanel

local selectionTitle = Instance.new("TextLabel")
selectionTitle.BackgroundTransparency = 1
selectionTitle.Size = UDim2.new(1, 0, 0, 20)
selectionTitle.Font = Enum.Font.GothamBold
selectionTitle.Text = "Selected Skill"
selectionTitle.TextColor3 = Color3.fromRGB(244, 247, 255)
selectionTitle.TextSize = 14
selectionTitle.TextXAlignment = Enum.TextXAlignment.Left
selectionTitle.Parent = rightPanel

local skillNameLabel = Instance.new("TextLabel")
skillNameLabel.BackgroundTransparency = 1
skillNameLabel.Size = UDim2.new(1, 0, 0, 18)
skillNameLabel.Font = Enum.Font.GothamMedium
skillNameLabel.Text = "No skill selected"
skillNameLabel.TextColor3 = Color3.fromRGB(221, 228, 244)
skillNameLabel.TextSize = 13
skillNameLabel.TextXAlignment = Enum.TextXAlignment.Left
skillNameLabel.Parent = rightPanel
refs.skillNameLabel = skillNameLabel

local skillIdLabel = Instance.new("TextLabel")
skillIdLabel.BackgroundTransparency = 1
skillIdLabel.Size = UDim2.new(1, 0, 0, 28)
skillIdLabel.Font = Enum.Font.Code
skillIdLabel.Text = "-"
skillIdLabel.TextColor3 = Color3.fromRGB(133, 146, 173)
skillIdLabel.TextSize = 12
skillIdLabel.TextWrapped = true
skillIdLabel.TextXAlignment = Enum.TextXAlignment.Left
skillIdLabel.TextYAlignment = Enum.TextYAlignment.Top
skillIdLabel.Parent = rightPanel
refs.skillIdLabel = skillIdLabel

local previewFrame = Instance.new("Frame")
previewFrame.Size = UDim2.new(1, 0, 0, 120)
previewFrame.BackgroundColor3 = Color3.fromRGB(31, 37, 49)
previewFrame.BorderSizePixel = 0
previewFrame.Parent = rightPanel

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0, 10)
previewCorner.Parent = previewFrame

local previewImage = Instance.new("ImageLabel")
previewImage.AnchorPoint = Vector2.new(0.5, 0.5)
previewImage.Position = UDim2.fromScale(0.5, 0.5)
previewImage.Size = UDim2.fromOffset(88, 88)
previewImage.BackgroundTransparency = 1
previewImage.ScaleType = Enum.ScaleType.Fit
previewImage.Visible = false
previewImage.Parent = previewFrame
refs.previewImage = previewImage

local previewText = Instance.new("TextLabel")
previewText.AnchorPoint = Vector2.new(0.5, 0.5)
previewText.Position = UDim2.fromScale(0.5, 0.5)
previewText.Size = UDim2.new(1, -20, 0, 20)
previewText.BackgroundTransparency = 1
previewText.Font = Enum.Font.GothamMedium
previewText.Text = "No icon available"
previewText.TextColor3 = Color3.fromRGB(160, 172, 196)
previewText.TextSize = 13
previewText.Parent = previewFrame
refs.previewText = previewText

local bindingLabel = Instance.new("TextLabel")
bindingLabel.BackgroundTransparency = 1
bindingLabel.Size = UDim2.new(1, 0, 0, 16)
bindingLabel.Font = Enum.Font.GothamBold
bindingLabel.Text = "Studio Override Asset ID"
bindingLabel.TextColor3 = Color3.fromRGB(244, 247, 255)
bindingLabel.TextSize = 12
bindingLabel.TextXAlignment = Enum.TextXAlignment.Left
bindingLabel.Parent = rightPanel

local assetInput = Instance.new("TextBox")
assetInput.Size = UDim2.new(1, 0, 0, 32)
assetInput.BackgroundColor3 = Color3.fromRGB(31, 37, 49)
assetInput.BorderSizePixel = 0
assetInput.ClearTextOnFocus = false
assetInput.PlaceholderText = "e.g. 1234567890"
assetInput.Text = ""
assetInput.TextColor3 = Color3.fromRGB(244, 247, 255)
assetInput.PlaceholderColor3 = Color3.fromRGB(124, 135, 159)
assetInput.TextSize = 13
assetInput.Parent = rightPanel
refs.assetInput = assetInput

local assetCorner = Instance.new("UICorner")
assetCorner.CornerRadius = UDim.new(0, 8)
assetCorner.Parent = assetInput

local projectLabel = Instance.new("TextLabel")
projectLabel.BackgroundTransparency = 1
projectLabel.Size = UDim2.new(1, 0, 0, 16)
projectLabel.Font = Enum.Font.Gotham
projectLabel.Text = "Project binding"
projectLabel.TextColor3 = Color3.fromRGB(160, 172, 196)
projectLabel.TextSize = 12
projectLabel.TextXAlignment = Enum.TextXAlignment.Left
projectLabel.Parent = rightPanel

local projectValueLabel = Instance.new("TextLabel")
projectValueLabel.BackgroundTransparency = 1
projectValueLabel.Size = UDim2.new(1, 0, 0, 16)
projectValueLabel.Font = Enum.Font.Code
projectValueLabel.Text = "-"
projectValueLabel.TextColor3 = Color3.fromRGB(212, 186, 128)
projectValueLabel.TextSize = 12
projectValueLabel.TextXAlignment = Enum.TextXAlignment.Left
projectValueLabel.Parent = rightPanel
refs.projectValueLabel = projectValueLabel

local fallbackLabel = Instance.new("TextLabel")
fallbackLabel.BackgroundTransparency = 1
fallbackLabel.Size = UDim2.new(1, 0, 0, 16)
fallbackLabel.Font = Enum.Font.Gotham
fallbackLabel.Text = "Definition or global fallback"
fallbackLabel.TextColor3 = Color3.fromRGB(160, 172, 196)
fallbackLabel.TextSize = 12
fallbackLabel.TextXAlignment = Enum.TextXAlignment.Left
fallbackLabel.Parent = rightPanel

local fallbackValueLabel = Instance.new("TextLabel")
fallbackValueLabel.BackgroundTransparency = 1
fallbackValueLabel.Size = UDim2.new(1, 0, 0, 16)
fallbackValueLabel.Font = Enum.Font.Code
fallbackValueLabel.Text = "-"
fallbackValueLabel.TextColor3 = Color3.fromRGB(212, 186, 128)
fallbackValueLabel.TextSize = 12
fallbackValueLabel.TextXAlignment = Enum.TextXAlignment.Left
fallbackValueLabel.Parent = rightPanel
refs.fallbackValueLabel = fallbackValueLabel

local sourceLabel = Instance.new("TextLabel")
sourceLabel.BackgroundTransparency = 1
sourceLabel.Size = UDim2.new(1, 0, 0, 16)
sourceLabel.Font = Enum.Font.Gotham
sourceLabel.Text = "Effective source"
sourceLabel.TextColor3 = Color3.fromRGB(160, 172, 196)
sourceLabel.TextSize = 12
sourceLabel.TextXAlignment = Enum.TextXAlignment.Left
sourceLabel.Parent = rightPanel

local sourceValueLabel = Instance.new("TextLabel")
sourceValueLabel.BackgroundTransparency = 1
sourceValueLabel.Size = UDim2.new(1, 0, 0, 16)
sourceValueLabel.Font = Enum.Font.GothamMedium
sourceValueLabel.Text = "-"
sourceValueLabel.TextColor3 = Color3.fromRGB(244, 247, 255)
sourceValueLabel.TextSize = 12
sourceValueLabel.TextXAlignment = Enum.TextXAlignment.Left
sourceValueLabel.Parent = rightPanel
refs.sourceValueLabel = sourceValueLabel

local buttons = Instance.new("Frame")
buttons.Size = UDim2.new(1, 0, 0, 68)
buttons.BackgroundTransparency = 1
buttons.Parent = rightPanel

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0.5, -4, 0, 32)
saveButton.BackgroundColor3 = Color3.fromRGB(81, 111, 172)
saveButton.BorderSizePixel = 0
saveButton.Font = Enum.Font.GothamBold
saveButton.Text = "Save Override"
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.TextSize = 13
saveButton.Parent = buttons

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 8)
saveCorner.Parent = saveButton

local clearButton = Instance.new("TextButton")
clearButton.AnchorPoint = Vector2.new(1, 0)
clearButton.Position = UDim2.new(1, 0, 0, 0)
clearButton.Size = UDim2.new(0.5, -4, 0, 32)
clearButton.BackgroundColor3 = Color3.fromRGB(55, 61, 76)
clearButton.BorderSizePixel = 0
clearButton.Font = Enum.Font.GothamBold
clearButton.Text = "Clear Override"
clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
clearButton.TextSize = 13
clearButton.Parent = buttons

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 8)
clearCorner.Parent = clearButton

local infoLabel = Instance.new("TextLabel")
infoLabel.Position = UDim2.fromOffset(0, 40)
infoLabel.Size = UDim2.new(1, 0, 0, 24)
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.Gotham
infoLabel.Text = "These overrides are Studio-only. Commit project bindings separately if needed."
infoLabel.TextColor3 = Color3.fromRGB(160, 172, 196)
infoLabel.TextSize = 11
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = buttons

local statusLabel = Instance.new("TextLabel")
statusLabel.AnchorPoint = Vector2.new(0, 1)
statusLabel.Position = UDim2.new(0, 0, 1, -2)
statusLabel.Size = UDim2.new(1, 0, 0, 24)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = state.statusText
statusLabel.TextColor3 = Color3.fromRGB(154, 167, 196)
statusLabel.TextSize = 12
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Bottom
statusLabel.Parent = root
refs.statusLabel = statusLabel

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	state.searchText = searchBox.Text
	plugin:SetSetting(SEARCH_SETTING, state.searchText)
	rebuildSkillList()
end)

assetInput.FocusLost:Connect(function(enterPressed)
	if not enterPressed then
		return
	end

	if state.selectedSkillId == nil then
		setStatus("Select a skill first.")
		return
	end

	state.overrideBindingsBySkillId[state.selectedSkillId] = normalizeAssetInput(assetInput.Text)
	rebuildSkillList()
	updatePreview()
end)

saveButton.Activated:Connect(function()
	if state.selectedSkillId == nil then
		setStatus("Select a skill first.")
		return
	end

	state.overrideBindingsBySkillId[state.selectedSkillId] = normalizeAssetInput(assetInput.Text)
	saveOverrides()
end)

clearButton.Activated:Connect(function()
	if state.selectedSkillId == nil then
		setStatus("Select a skill first.")
		return
	end

	state.overrideBindingsBySkillId[state.selectedSkillId] = nil
	assetInput.Text = ""
	saveOverrides()
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggleButton:SetActive(widget.Enabled)
	if widget.Enabled then
		loadProjectState()
	end
end)

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	toggleButton:SetActive(widget.Enabled)
	if widget.Enabled then
		loadProjectState()
	end
end)

loadProjectState()
if state.selectedSkillId == nil and state.skills[1] ~= nil then
	updateSelection(state.skills[1].skillId)
else
	updateSelection(state.selectedSkillId)
end
updatePreview()
