local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local clientShared = playerScripts:WaitForChild("ClientShared")

local DebugClient = require(
	clientShared:WaitForChild("Features"):WaitForChild("Debug"):WaitForChild("DebugClient")
)
local DebugOverlayHost = require(
	clientShared:WaitForChild("Features"):WaitForChild("Debug"):WaitForChild("DebugOverlayHost")
)

local panel = DebugOverlayHost.mountTextPanel({
	id = "raid_pet_runtime",
	title = "Raid Pet Runtime",
	side = "left",
	order = 10,
	width = 300,
	height = 128,
	initialText = "Waiting for pet debug state...",
})

local function refresh()
	local summary = player:GetAttribute("RaidPetDebugSummary")
	local pipelineStatus = player:GetAttribute("RaidPetPipelineStatus")
	local enabled = DebugClient.isViewEnabled("raid_pet_runtime")
	panel.setVisible(enabled)
	if not enabled then
		return
	end

	if type(summary) == "string" and summary ~= "" then
		panel.setBodyText(summary)
	elseif type(pipelineStatus) == "string" and pipelineStatus ~= "" then
		panel.setBodyText(pipelineStatus)
	else
		panel.setBodyText("Waiting for pet debug state...")
	end
end

DebugClient.init()
DebugClient.subscribe(refresh)
player:GetAttributeChangedSignal("RaidPetDebugSummary"):Connect(refresh)
player:GetAttributeChangedSignal("RaidPetPipelineStatus"):Connect(refresh)
refresh()
