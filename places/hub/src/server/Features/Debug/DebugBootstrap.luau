local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local PetProfile = require(Shared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetProfile"))
local PetDefinitions = require(
	Shared:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("Definitions"):WaitForChild("PetDefinitions")
)
local DebugService = require(
	ServerScriptService:WaitForChild("ServerShared"):WaitForChild("Features"):WaitForChild("Debug"):WaitForChild("DebugService")
)
local PetService = require(
	ServerScriptService:WaitForChild("ServerShared"):WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetService")
)
local HubPetPresenceService = require(script.Parent.Parent:WaitForChild("Pets"):WaitForChild("HubPetPresenceService"))

local DebugBootstrap = {}

local initialized = false

local function clonePetDefinitions()
	local definitions = {}
	for _, definitionId in ipairs(PetDefinitions.OrderedIds) do
		local definition = PetDefinitions.ById[definitionId]
		table.insert(definitions, {
			id = definition.id,
			displayName = definition.displayName,
		})
	end
	return definitions
end

local function buildPetProfile(player, definitionId)
	return PetProfile.create({
		id = ("starter_%d_%s"):format(player.UserId, definitionId),
		definitionId = definitionId,
	})
end

function DebugBootstrap.init()
	if initialized then
		return
	end

	initialized = true

	DebugService.init({
		place = "hub",
	})

	DebugService.registerAction("set_active_pet", function(player, payload)
		local definitionId = payload.definitionId
		if type(definitionId) ~= "string" or PetDefinitions.ById[definitionId] == nil then
			return false, "Unknown pet"
		end

		local ok, errors = PetService.setActivePetProfile(player, buildPetProfile(player, definitionId))
		if not ok then
			return false, if type(errors) == "table" then table.concat(errors, "; ") else "Failed to set pet"
		end

		HubPetPresenceService.refreshPlayer(player)
		return true, ("Active pet: %s"):format(definitionId)
	end)

	DebugService.registerAction("set_party", function(player, payload)
		local value = payload.value
		if value == nil or value == "" then
			player:SetAttribute("PartyId", nil)
			return true, "PartyId cleared"
		end

		if type(value) ~= "string" then
			return false, "PartyId must be a string"
		end

		player:SetAttribute("PartyId", value)
		return true, ("PartyId set to %s"):format(value)
	end)

	DebugService.registerStateBuilder(function(player, state)
		local profile = PetService.ensureActivePetProfile(player)
		state.petDefinitions = clonePetDefinitions()
		state.currentPetDefinitionId = profile.definitionId
		state.partyId = player:GetAttribute("PartyId")
	end)
end

return DebugBootstrap
