local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ReplicationTopics = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("Topics")
)
local Cleaner =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Cleaner"))
local SandboxPresentersFolder = script.Parent:WaitForChild("Presenters")
local SandboxHudPresenter = require(SandboxPresentersFolder:WaitForChild("SandboxHudPresenter"))
local ClientCombat =
	require(script.Parent.Parent.Parent:WaitForChild("ClientShared"):WaitForChild("Combat"))
local CombatPresentation = ClientCombat.Presentation
local CombatPresenters = ClientCombat.Presenters
local CombatPalette = CombatPresentation.Palette
local CombatText = CombatPresentation.Text
local CombatWidgets = CombatPresentation.Widgets
local EnemyHeaderPresenter = CombatPresenters.EnemyHeaderPresenter
local ResultSummaryPresenter = CombatPresenters.ResultSummaryPresenter
local FighterWorldPresenter = CombatPresenters.FighterWorldPresenter
local CombatFeedbackPresenter = CombatPresenters.CombatFeedbackPresenter

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
local FIGHTER_VIEW_SIZE = Vector3.new(1.85, 2.62, 1.85)
local ENEMY_VIEW_SIZE = Vector3.new(5.4, 6.1, 5.4)

local SandboxController = {}
SandboxController.__index = SandboxController

function SandboxController.new(config)
	assert(type(config) == "table", "SandboxController config must be a table")
	assert(config.snapshotClient ~= nil, "SandboxController requires SnapshotClient")
	assert(config.debugClient ~= nil, "SandboxController requires DebugClient")

	return setmetatable({
		_snapshotClient = config.snapshotClient,
		_debugClient = config.debugClient,
		_cleaner = Cleaner.new(),
		_snapshot = nil,
		_hudPresenter = nil,
		_enemyHeaderPresenter = nil,
		_resultSummaryPresenter = nil,
		_worldPresenter = nil,
		_feedbackPresenter = nil,
		_screenGui = nil,
		_worldFolder = nil,
	}, SandboxController)
end

function SandboxController:_renderPanel(snapshot)
	if self._hudPresenter ~= nil then
		self._hudPresenter:render(snapshot)
	end

	self:_renderResultSummary(snapshot)
end

function SandboxController:_renderEnemyHeader(snapshot)
	if self._enemyHeaderPresenter == nil then
		return
	end

	self._enemyHeaderPresenter:render(snapshot)
end

function SandboxController:_renderResultSummary(snapshot)
	if self._resultSummaryPresenter == nil then
		return
	end

	self._resultSummaryPresenter:render(snapshot)
end

function SandboxController:_updateWorld(snapshot)
	if self._worldPresenter == nil then
		return
	end

	self._worldPresenter:render(snapshot)
end

function SandboxController:_processJournalEntries(snapshot)
	if self._feedbackPresenter == nil then
		return
	end

	self._feedbackPresenter:processSnapshot(snapshot)
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

	self._worldPresenter = FighterWorldPresenter.new({
		folder = self._worldFolder,
		createHealthBar = CombatWidgets.createHealthBar,
		createStatusStrip = CombatWidgets.createStatusStrip,
		syncStatusStrip = CombatWidgets.syncStatusStrip,
		getBarColor = CombatPalette.getBarColor,
		getGradeColor = CombatPalette.getGradeColor,
		getEnemyColor = CombatPalette.getEnemyColor,
		followOffsets = FOLLOW_OFFSETS,
		combatOffsets = COMBAT_OFFSETS,
		previewDistance = PREVIEW_DISTANCE,
		worldBaseYOffset = WORLD_BASE_Y_OFFSET,
		fighterViewSize = FIGHTER_VIEW_SIZE,
		enemyViewSize = ENEMY_VIEW_SIZE,
	})

	self._feedbackPresenter = CombatFeedbackPresenter.new({
		resolvePopupParent = function(combatantId, snapshot)
			if self._worldPresenter == nil then
				return nil
			end

			return self._worldPresenter:getPopupParent(combatantId, snapshot)
		end,
	})
	self._feedbackPresenter:preload()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CombatSandboxGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 950
	screenGui.Parent = playerGui
	self._screenGui = screenGui
	self._cleaner:add(screenGui)

	self._enemyHeaderPresenter = EnemyHeaderPresenter.new(screenGui, {
		createHealthBar = CombatWidgets.createHealthBar,
		createStatusStrip = CombatWidgets.createStatusStrip,
		syncStatusStrip = CombatWidgets.syncStatusStrip,
		getBarColor = CombatPalette.getBarColor,
	})

	self._hudPresenter = SandboxHudPresenter.new(screenGui, {
		debugClient = self._debugClient,
		getSkillLabel = CombatText.getSkillLabel,
		getOutcomeLabel = CombatText.getOutcomeLabel,
	})

	local panel = self._hudPresenter:getPanel()
	self._resultSummaryPresenter = ResultSummaryPresenter.new(panel)

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
	if self._hudPresenter ~= nil then
		self._hudPresenter:stop()
	end
	if self._feedbackPresenter ~= nil then
		self._feedbackPresenter:stop()
	end
	if self._worldPresenter ~= nil then
		self._worldPresenter:stop()
	end
	self._hudPresenter = nil
	self._enemyHeaderPresenter = nil
	self._resultSummaryPresenter = nil
	self._worldPresenter = nil
	self._feedbackPresenter = nil
	self._screenGui = nil
	self._worldFolder = nil
end

return SandboxController
