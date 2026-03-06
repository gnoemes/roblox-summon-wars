local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local RewardConfig = require(Shared:WaitForChild("Config"):WaitForChild("Rewards"))
local DebugService = require(
	ServerScriptService:WaitForChild("ServerShared"):WaitForChild("Features"):WaitForChild("Debug"):WaitForChild("DebugService")
)
local PetService = require(
	ServerScriptService:WaitForChild("ServerShared"):WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("PetService")
)
local RewardsService = require(script.Parent.Parent:WaitForChild("Rewards"):WaitForChild("RewardsService"))

local DebugBootstrap = {}

local initialized = false

local function cloneDictionary(map)
	local out = {}
	for key, value in pairs(map or {}) do
		out[key] = value
	end
	return out
end

local function cloneCurrencyTypes()
	local currencies = {}
	for _, currency in ipairs(RewardConfig.Types) do
		table.insert(currencies, {
			id = currency.id,
			label = currency.label,
			category = currency.category,
		})
	end
	return currencies
end

function DebugBootstrap.init()
	if initialized then
		return
	end

	initialized = true

	DebugService.init({
		place = "raid",
	})

	DebugService.registerAction("grant_currency", function(player, payload)
		local currencyId = payload.currencyId
		local amount = payload.amount
		if type(currencyId) ~= "string" or RewardConfig.ById[currencyId] == nil then
			return false, "Unknown currency"
		end
		if type(amount) ~= "number" or amount <= 0 then
			return false, "Amount must be positive"
		end

		local normalizedAmount = math.floor(amount)
		if normalizedAmount <= 0 then
			return false, "Amount must be positive"
		end

		RewardsService.grantRewards(player, {
			[currencyId] = normalizedAmount,
		})

		return true, ("%s +%d"):format(RewardConfig.ById[currencyId].label, normalizedAmount)
	end)

	DebugService.registerView("raid_pet_runtime")

	DebugService.registerStateBuilder(function(player, state)
		PetService.ensureActivePetProfile(player)
		state.currencyTypes = cloneCurrencyTypes()
		state.rewardBalances = cloneDictionary(
			RewardsService.getRewardsByUserId(player.UserId) or RewardsService.buildEmptyRewards()
		)
	end)
end

return DebugBootstrap
