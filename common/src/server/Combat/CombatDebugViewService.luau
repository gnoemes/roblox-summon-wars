local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BASE_Y = 8
local ENCOUNTER_SPACING_X = 34
local OWNER_SPACING_Z = 42
local SIDE_OFFSET_X = 12
local SLOT_SPACING_Z = 9

local CombatDebugViewService = {}
CombatDebugViewService.__index = CombatDebugViewService

local function countEntries(map)
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function getEncounterBase(encounter)
	local encounterOffsetX = (math.max(encounter.encounterIndex, 1) - 1) * ENCOUNTER_SPACING_X
	local ownerBucket = math.abs(encounter.ownerUserId) % 5
	local ownerOffsetZ = (ownerBucket - 2) * OWNER_SPACING_Z

	return encounterOffsetX, ownerOffsetZ
end

local function getCombatantPosition(encounter, combatant)
	local baseX, baseZ = getEncounterBase(encounter)
	local orderOffset = (math.max(combatant.order, 1) - 1) * SLOT_SPACING_Z

	if combatant.kind == "Enemy" then
		return Vector3.new(baseX + SIDE_OFFSET_X, BASE_Y, baseZ + orderOffset)
	end

	return Vector3.new(baseX - SIDE_OFFSET_X, BASE_Y, baseZ + orderOffset)
end

local function createViewPart(folder, key)
	local part = Instance.new("Part")
	part.Name = key
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = false
	part.Parent = folder

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Billboard"
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Size = UDim2.fromOffset(180, 60)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	billboard.MaxDistance = 250
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Code
	label.TextColor3 = Color3.fromRGB(240, 244, 255)
	label.TextStrokeTransparency = 0.8
	label.TextSize = 14
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = billboard

	return {
		part = part,
		label = label,
	}
end

local function getPartColor(combatant, runtimeState)
	if runtimeState.currentHp <= 0 then
		return Color3.fromRGB(95, 95, 95)
	end

	if combatant.kind == "Enemy" then
		return Color3.fromRGB(204, 78, 78)
	end

	return Color3.fromRGB(88, 165, 255)
end

local function buildLabelText(combatant, runtimeState)
	local currentHp = math.max(0, math.floor(runtimeState.currentHp + 0.5))
	local maxHp = math.max(0, math.floor(runtimeState.maxHp + 0.5))
	local statusCount = countEntries(runtimeState.statusesById)
	local cooldownCount = countEntries(runtimeState.remainingCooldownsBySkillId)

	return string.format(
		"%s\n%s\nHP %d / %d\nStatuses %d | CDs %d",
		combatant.displayName,
		combatant.kind,
		currentHp,
		maxHp,
		statusCount,
		cooldownCount
	)
end

function CombatDebugViewService.new()
	local enabled = RunService:IsStudio()
	local folder = nil

	if enabled then
		folder = Instance.new("Folder")
		folder.Name = "CombatDebugViews"
		folder.Parent = Workspace
	end

	return setmetatable({
		enabled = enabled,
		_folder = folder,
		_viewsByKey = {},
		_seenKeys = {},
	}, CombatDebugViewService)
end

function CombatDebugViewService:beginFrame()
	if not self.enabled then
		return
	end

	self._seenKeys = {}
end

function CombatDebugViewService:presentEncounter(encounter, records)
	if not self.enabled then
		return
	end

	for _, record in ipairs(records) do
		local combatant = record.combatant
		local runtimeState = record.runtimeState
		local key = string.format("%s/%s", encounter.encounterId, combatant.combatantId)
		local view = self._viewsByKey[key]

		if view == nil then
			view = createViewPart(self._folder, key)
			self._viewsByKey[key] = view
		end

		self._seenKeys[key] = true

		local hpRatio = 0
		if runtimeState.maxHp > 0 then
			hpRatio = math.clamp(runtimeState.currentHp / runtimeState.maxHp, 0, 1)
		end
		local height = 2 + hpRatio * 5
		local position = getCombatantPosition(encounter, combatant)
			+ Vector3.new(0, height * 0.5, 0)

		view.part.Size = Vector3.new(5, height, 5)
		view.part.CFrame = CFrame.new(position)
		view.part.Color = getPartColor(combatant, runtimeState)
		view.part.Transparency = if runtimeState.currentHp > 0 then 0 else 0.45
		view.label.Text = buildLabelText(combatant, runtimeState)
	end
end

function CombatDebugViewService:endFrame()
	if not self.enabled then
		return
	end

	for key, view in pairs(self._viewsByKey) do
		if self._seenKeys[key] ~= true then
			view.part:Destroy()
			self._viewsByKey[key] = nil
		end
	end
end

function CombatDebugViewService:stop()
	for key, view in pairs(self._viewsByKey) do
		view.part:Destroy()
		self._viewsByKey[key] = nil
	end

	if self._folder ~= nil then
		self._folder:Destroy()
		self._folder = nil
	end
end

return CombatDebugViewService
