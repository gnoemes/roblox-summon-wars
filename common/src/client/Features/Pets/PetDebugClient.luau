local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Net"):WaitForChild("Remotes"))

local PetDebugClient = {}

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Pet",
			Text = text,
			Duration = 3,
		})
	end)
end

local function getDebugEvent()
	local remotesFolder = ReplicatedStorage:WaitForChild(Remotes.FolderName, 10)
	if not remotesFolder then
		return nil
	end
	return remotesFolder:WaitForChild(Remotes.PetDebug, 10)
end

local function sendPetDefinition(definitionId)
	local event = getDebugEvent()
	if not event then
		notify("Pet debug not ready")
		return
	end

	event:FireServer({
		action = "set_active_definition",
		definitionId = definitionId,
	})
end

function PetDebugClient.init(player)
	TextChatService.MessageReceived:Connect(function(message)
		if not message.TextSource or message.TextSource.UserId ~= player.UserId then
			return
		end

		local text = message.Text
		local lower = string.lower(text)
		if string.sub(lower, 1, 4) ~= "/pet" then
			return
		end

		local definitionId = string.lower(string.sub(text, 6))
		if definitionId == "" then
			notify("Use /pet guardian | crusher | shooter")
			return
		end

		sendPetDefinition(definitionId)
	end)

	local event = getDebugEvent()
	if event then
		event.OnClientEvent:Connect(function(payload)
			if type(payload) == "table" and payload.action == "ack" then
				notify(payload.message or "OK")
			end
		end)
	end
end

return PetDebugClient
