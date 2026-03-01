local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "RaidReturnGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "ReturnHubButton"
button.Size = UDim2.fromOffset(220, 56)
button.Position = UDim2.new(1, -240, 1, -80)
button.AnchorPoint = Vector2.new(0, 0)
button.Text = "Return Hub"
button.TextScaled = true
button.AutoButtonColor = true
button.Parent = gui

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.fromOffset(220, 24)
status.Position = UDim2.new(1, -240, 1, -108)
status.BackgroundTransparency = 1
status.TextScaled = true
status.Text = ""
status.Parent = gui

local function setBusy(isBusy, message)
	button.Active = not isBusy
	button.AutoButtonColor = not isBusy
	button.Text = if isBusy then "Returning..." else "Return Hub"
	status.Text = message or ""
end

local function requestReturn()
	setBusy(true, "")

	local remotesFolder = ReplicatedStorage:WaitForChild(Remotes.FolderName, 15)
	if not remotesFolder then
		setBusy(false, "Server not ready")
		return
	end

	local rf = remotesFolder:WaitForChild(Remotes.ReturnToHub, 15)
	if not rf then
		setBusy(false, "Server not ready")
		return
	end

	local finished = false
	local resultOk = false
	local resultErr = "UnknownError"

	task.spawn(function()
		local ok, result = pcall(function()
			return rf:InvokeServer()
		end)

		finished = true

		if not ok then
			resultOk = false
			resultErr = "TeleportFailed"
			return
		end

		if type(result) == "table" and result.ok then
			resultOk = true
		else
			resultOk = false
			resultErr = type(result) == "table" and result.error or "UnknownError"
			if resultErr == "NotPartyLeader" then
				resultErr = "Only leader can return"
			end
		end
	end)

	task.delay(8, function()
		if finished then
			if resultOk then
				setBusy(true, "Teleporting...")
			else
				setBusy(false, resultErr)
			end
			return
		end

		setBusy(false, "No response")
	end)
end

button.MouseButton1Click:Connect(requestReturn)
