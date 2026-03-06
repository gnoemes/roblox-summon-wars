local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "RaidPetSkillDebugGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.AnchorPoint = Vector2.new(0, 0)
frame.Position = UDim2.fromOffset(16, 16)
frame.Size = UDim2.fromOffset(280, 120)
frame.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(10, 8)
title.Size = UDim2.new(1, -20, 0, 20)
title.Text = "Raid Pet Debug"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local body = Instance.new("TextLabel")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(10, 32)
body.Size = UDim2.new(1, -20, 1, -42)
body.TextColor3 = Color3.fromRGB(220, 220, 220)
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = false
body.TextScaled = false
body.TextSize = 16
body.Font = Enum.Font.Code
body.Text = "Waiting for pet debug state..."
body.Parent = frame

local function refresh()
	local summary = player:GetAttribute("RaidPetDebugSummary")
	local pipelineStatus = player:GetAttribute("RaidPetPipelineStatus")
	if type(summary) == "string" and summary ~= "" then
		body.Text = summary
	elseif type(pipelineStatus) == "string" and pipelineStatus ~= "" then
		body.Text = pipelineStatus
	else
		body.Text = "Waiting for pet debug state..."
	end
end

player:GetAttributeChangedSignal("RaidPetDebugSummary"):Connect(refresh)
player:GetAttributeChangedSignal("RaidPetPipelineStatus"):Connect(refresh)
refresh()
