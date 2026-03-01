local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "RaidSummaryGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.fromOffset(320, 180)
frame.Position = UDim2.new(0.5, -160, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 32)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.Text = "Raid Summary"
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(230, 230, 230)
title.Parent = frame

local details = Instance.new("TextLabel")
details.Name = "Details"
details.Size = UDim2.new(1, -20, 0, 72)
details.Position = UDim2.fromOffset(10, 48)
details.BackgroundTransparency = 1
details.TextScaled = true
details.TextColor3 = Color3.fromRGB(200, 200, 200)
details.Text = ""
details.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.fromOffset(120, 36)
closeBtn.Position = UDim2.new(0.5, -60, 1, -48)
closeBtn.Text = "Close"
closeBtn.TextScaled = true
closeBtn.Parent = frame

local function clearOnServer()
	local remotesFolder = ReplicatedStorage:WaitForChild(Remotes.FolderName, 10)
	if not remotesFolder then
		return
	end
	local rf = remotesFolder:FindFirstChild(Remotes.ClearRaidSummary)
	if rf then
		pcall(function()
			rf:InvokeServer()
		end)
	end
end

local function showSummary()
	local credits = player:GetAttribute("RaidRewardsCredits")
	local biomass = player:GetAttribute("RaidRewardsBiomass")
	local dna = player:GetAttribute("RaidRewardsDNA")

	if not credits and not biomass and not dna then
		frame.Visible = false
		return
	end

	credits = credits or 0
	biomass = biomass or 0
	dna = dna or 0

	details.Text = ("Credits: %d\nBiomass: %d\nDNA: %d"):format(credits, biomass, dna)
	frame.Visible = true
end

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
	clearOnServer()
end)

player:GetAttributeChangedSignal("RaidRewardsCredits"):Connect(showSummary)
player:GetAttributeChangedSignal("RaidRewardsBiomass"):Connect(showSummary)
player:GetAttributeChangedSignal("RaidRewardsDNA"):Connect(showSummary)

task.defer(showSummary)
