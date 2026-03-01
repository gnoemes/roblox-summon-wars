local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))

local player = Players.LocalPlayer

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Party",
			Text = text,
			Duration = 3,
		})
	end)
end

local function sendParty(value)
	local remotesFolder = ReplicatedStorage:WaitForChild(Remotes.FolderName, 10)
	if not remotesFolder then
		notify("Server not ready")
		return
	end
	local event = remotesFolder:WaitForChild(Remotes.PartyDebug, 10)
	if not event then
		notify("Server not ready")
		return
	end
	event:FireServer({
		action = "set_party",
		value = value,
	})
end

local function handleMessage(text)
	local lower = string.lower(text)
	if string.sub(lower, 1, 6) ~= "/party" then
		return
	end
	local arg = string.sub(text, 8)
	sendParty(arg)
end

TextChatService.MessageReceived:Connect(function(message)
	if not message.TextSource then
		return
	end
	if message.TextSource.UserId ~= player.UserId then
		return
	end
	handleMessage(message.Text)
end)

local remotesFolder = ReplicatedStorage:WaitForChild(Remotes.FolderName, 10)
if remotesFolder then
	local event = remotesFolder:FindFirstChild(Remotes.PartyDebug)
	if event then
		event.OnClientEvent:Connect(function(payload)
			if type(payload) == "table" and payload.action == "ack" then
				notify(payload.message or "OK")
			end
		end)
	end
end
