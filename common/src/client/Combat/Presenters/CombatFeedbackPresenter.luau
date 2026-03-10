local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SharedConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CombatConfig = SharedConfig.Combat
local AssetConfig = SharedConfig.Assets
local AssetUri =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("AssetUri"))

local POPUP_START_OFFSET_Y = 2.4
local POPUP_END_OFFSET_Y = 3.8
local POPUP_RISE_TIME = 0.18
local POPUP_HOLD_TIME = 0.24
local POPUP_FADE_IN_TIME = 0.08
local POPUP_FADE_OUT_TIME = 0.14
local POPUP_LIFETIME = POPUP_RISE_TIME + POPUP_HOLD_TIME + POPUP_FADE_OUT_TIME
local DAMAGE_POPUP_FADE_IN_TIME = 0.06
local DAMAGE_POPUP_HOLD_TIME = 0.16
local DAMAGE_POPUP_FADE_OUT_TIME = 0.2
local DAMAGE_POPUP_LIFETIME = DAMAGE_POPUP_FADE_IN_TIME
	+ DAMAGE_POPUP_HOLD_TIME
	+ DAMAGE_POPUP_FADE_OUT_TIME

local CombatFeedbackPresenter = {}
CombatFeedbackPresenter.__index = CombatFeedbackPresenter

local function tryGet(registry, id)
	if type(id) ~= "string" or id == "" then
		return nil
	end

	if registry.has(id) then
		return registry.get(id)
	end

	return nil
end

local function getSkillIconImage(skillId)
	return AssetUri.fromAssetId(AssetConfig.SkillAssetResolver.getIconAssetId(skillId))
end

local function getStatusIconImage(statusId)
	return AssetUri.fromAssetId(AssetConfig.StatusAssetResolver.getIconAssetId(statusId))
end

local function getDamagePopupStyle(result)
	if result == nil then
		return nil
	end

	local targetKind = if result.target ~= nil then result.target.kind else nil
	if result.healingDone > 0 then
		return {
			text = string.format("+%d", result.healingDone),
			color = Color3.fromRGB(111, 214, 132),
			startOffset = Vector3.new(-0.8, 2.45, 0),
			endOffset = Vector3.new(-1.05, 3.2, 0),
			textSize = 21,
			billboardSize = Vector2.new(92, 34),
		}
	end

	if result.damageDealt <= 0 then
		return nil
	end

	local isEnemyTarget = targetKind == "Enemy"
	local baseTextSize = if isEnemyTarget then 30 else 21
	local critTextSize = if isEnemyTarget then 34 else 24
	local billboardSize = if isEnemyTarget then Vector2.new(132, 48) else Vector2.new(92, 34)

	if result.actionType == "StatusTick" then
		return {
			text = string.format("-%d", result.damageDealt),
			color = Color3.fromRGB(232, 96, 96),
			startOffset = if isEnemyTarget
				then Vector3.new(3.65, 1.18, 0)
				else Vector3.new(1.55, 1.52, 0),
			endOffset = if isEnemyTarget
				then Vector3.new(4.25, 0.18, 0)
				else Vector3.new(1.82, 0.7, 0),
			textSize = baseTextSize,
			billboardSize = if isEnemyTarget then Vector2.new(212, 52) else Vector2.new(116, 34),
			iconImage = getStatusIconImage(result.skillId),
			iconSize = if isEnemyTarget then 22 else 18,
		}
	end

	local baseColor = if result.criticalHit
		then Color3.fromRGB(244, 170, 84)
		else if isEnemyTarget
			then Color3.fromRGB(244, 247, 255)
			else Color3.fromRGB(232, 96, 96)

	return {
		text = tostring(result.damageDealt),
		color = baseColor,
		startOffset = Vector3.new(0.82, 1.9, 0),
		endOffset = Vector3.new(1.04, 1.05, 0),
		textSize = if result.criticalHit then critTextSize else baseTextSize,
		billboardSize = billboardSize,
	}
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

function CombatFeedbackPresenter.new(config)
	assert(type(config) == "table", "CombatFeedbackPresenter config must be a table")
	assert(
		type(config.resolvePopupParent) == "function",
		"CombatFeedbackPresenter requires resolvePopupParent"
	)

	return setmetatable({
		_resolvePopupParent = config.resolvePopupParent,
		_processedActionIds = {},
		_processedValueResultIds = {},
		_lastEncounterId = nil,
		_preloadedIcons = {},
	}, CombatFeedbackPresenter)
end

function CombatFeedbackPresenter:preload()
	local contentIds = {}

	for _, definition in ipairs(CombatConfig.SkillDefinitions.list()) do
		local imageUri =
			AssetUri.fromAssetId(AssetConfig.SkillAssetResolver.getIconAssetId(definition.skillId))
		if imageUri ~= nil and self._preloadedIcons[imageUri] ~= true then
			self._preloadedIcons[imageUri] = true
			table.insert(contentIds, imageUri)
		end
	end

	for _, definition in ipairs(CombatConfig.StatusDefinitions.list()) do
		local imageUri = AssetUri.fromAssetId(
			AssetConfig.StatusAssetResolver.getIconAssetId(definition.statusId)
		)
		if imageUri ~= nil and self._preloadedIcons[imageUri] ~= true then
			self._preloadedIcons[imageUri] = true
			table.insert(contentIds, imageUri)
		end
	end

	if #contentIds == 0 then
		return
	end

	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(contentIds)
		end)
	end)
end

function CombatFeedbackPresenter:_syncSkillPopupContent(imageLabel, fallbackLabel)
	local hasImage = imageLabel ~= nil
	if hasImage then
		imageLabel.Visible = true
		imageLabel.ImageTransparency = 1
		fallbackLabel.Visible = false
		fallbackLabel.TextTransparency = 1
		return imageLabel, "ImageTransparency"
	end

	fallbackLabel.Visible = true
	fallbackLabel.TextTransparency = 1
	return fallbackLabel, "TextTransparency"
end

function CombatFeedbackPresenter:_animateSkillPopup(billboard, visual, transparencyProperty)
	local riseTween = TweenService:Create(
		billboard,
		TweenInfo.new(POPUP_RISE_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{
			StudsOffsetWorldSpace = Vector3.new(0, POPUP_END_OFFSET_Y, 0),
		}
	)
	local fadeInTween = TweenService:Create(
		visual,
		TweenInfo.new(POPUP_FADE_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			[transparencyProperty] = 0,
		}
	)
	local fadeOutTween = TweenService:Create(
		visual,
		TweenInfo.new(POPUP_FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			[transparencyProperty] = 1,
		}
	)

	riseTween:Play()
	fadeInTween:Play()

	task.delay(POPUP_RISE_TIME + POPUP_HOLD_TIME, function()
		if billboard.Parent ~= nil then
			fadeOutTween:Play()
		end
	end)

	task.delay(POPUP_LIFETIME, function()
		if billboard.Parent ~= nil then
			billboard:Destroy()
		end
	end)
end

function CombatFeedbackPresenter:_animateValuePopup(billboard, label, startOffset, endOffset)
	billboard.StudsOffsetWorldSpace = startOffset
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1

	local moveTween = TweenService:Create(
		billboard,
		TweenInfo.new(
			DAMAGE_POPUP_FADE_IN_TIME + DAMAGE_POPUP_HOLD_TIME + DAMAGE_POPUP_FADE_OUT_TIME,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.Out
		),
		{
			StudsOffsetWorldSpace = endOffset,
		}
	)
	local fadeInTween = TweenService:Create(
		label,
		TweenInfo.new(DAMAGE_POPUP_FADE_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			TextTransparency = 0,
			TextStrokeTransparency = 0.35,
		}
	)
	local fadeOutTween = TweenService:Create(
		label,
		TweenInfo.new(DAMAGE_POPUP_FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)

	moveTween:Play()
	fadeInTween:Play()

	task.delay(DAMAGE_POPUP_FADE_IN_TIME + DAMAGE_POPUP_HOLD_TIME, function()
		if billboard.Parent ~= nil then
			fadeOutTween:Play()
		end
	end)

	task.delay(DAMAGE_POPUP_LIFETIME, function()
		if billboard.Parent ~= nil then
			billboard:Destroy()
		end
	end)
end

function CombatFeedbackPresenter:_spawnSkillPopup(snapshot, combatantId, skillId, labelText)
	local adornee = self._resolvePopupParent(combatantId, snapshot)
	if adornee == nil then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SkillPopup"
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Size = UDim2.fromOffset(64, 64)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, POPUP_START_OFFSET_Y, 0)
	billboard.Parent = adornee

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local fallbackLabel = Instance.new("TextLabel")
	fallbackLabel.Size = UDim2.fromScale(1, 1)
	fallbackLabel.BackgroundTransparency = 1
	fallbackLabel.Font = Enum.Font.GothamBold
	fallbackLabel.TextColor3 = Color3.fromRGB(244, 247, 255)
	fallbackLabel.TextSize = 12
	fallbackLabel.TextWrapped = true
	fallbackLabel.Text = labelText
	fallbackLabel.Parent = frame

	local image = nil
	local iconImage = getSkillIconImage(skillId)
	if iconImage ~= nil then
		image = Instance.new("ImageLabel")
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.Size = UDim2.fromOffset(50, 50)
		image.BackgroundTransparency = 1
		image.Image = iconImage
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = frame
	end

	local visual, transparencyProperty = self:_syncSkillPopupContent(image, fallbackLabel)
	self:_animateSkillPopup(billboard, visual, transparencyProperty)
end

function CombatFeedbackPresenter:_spawnValuePopup(snapshot, combatantId, result)
	local style = getDamagePopupStyle(result)
	if style == nil then
		return
	end

	local adornee = self._resolvePopupParent(combatantId, snapshot)
	if adornee == nil then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ValuePopup"
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Size = UDim2.fromOffset(style.billboardSize.X, style.billboardSize.Y)
	billboard.Parent = adornee

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = billboard

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = style.text
	label.TextColor3 = style.color
	label.TextSize = style.textSize
	label.TextStrokeColor3 = Color3.fromRGB(18, 22, 30)
	label.TextStrokeTransparency = 1
	label.Parent = frame

	if style.iconImage ~= nil then
		label.Size = UDim2.new(1, -(style.iconSize + 8), 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Right

		local icon = Instance.new("ImageLabel")
		icon.AnchorPoint = Vector2.new(1, 0.5)
		icon.Position = UDim2.fromScale(1, 0.5)
		icon.Size = UDim2.fromOffset(style.iconSize, style.iconSize)
		icon.BackgroundTransparency = 1
		icon.Image = style.iconImage
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Parent = frame
	else
		label.Size = UDim2.fromScale(1, 1)
		label.TextXAlignment = Enum.TextXAlignment.Center
	end

	self:_animateValuePopup(billboard, label, style.startOffset, style.endOffset)
end

function CombatFeedbackPresenter:processSnapshot(snapshot)
	if self._lastEncounterId ~= snapshot.activeEncounterId then
		self._processedActionIds = {}
		self._processedValueResultIds = {}
		self._lastEncounterId = snapshot.activeEncounterId
	end

	if snapshot.activeEncounterId == nil then
		return
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
						snapshot,
						result.actor.combatantId,
						result.skillId,
						getSkillLabel(result.skillId, result.actionType)
					)
				end
			end

			local resultTargetId = nil
			if result.target ~= nil then
				resultTargetId = result.target.combatantId
			elseif result.actor ~= nil then
				resultTargetId = result.actor.combatantId
			end

			local resultKey = string.format(
				"%s:%s:%s",
				tostring(result.actionId),
				tostring(result.sequence),
				tostring(resultTargetId)
			)
			if self._processedValueResultIds[resultKey] ~= true then
				self._processedValueResultIds[resultKey] = true

				if result.damageDealt > 0 and resultTargetId ~= nil then
					self:_spawnValuePopup(snapshot, resultTargetId, result)
				end

				if result.healingDone > 0 and resultTargetId ~= nil then
					self:_spawnValuePopup(snapshot, resultTargetId, result)
				end
			end
		end
	end
end

function CombatFeedbackPresenter:stop()
	self._processedActionIds = {}
	self._processedValueResultIds = {}
	self._lastEncounterId = nil
	self._preloadedIcons = {}
end

return CombatFeedbackPresenter
