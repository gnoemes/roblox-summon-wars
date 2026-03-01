local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RewardConfig = require(Shared:WaitForChild("Config"):WaitForChild("Rewards"))
local RewardLedger = require(script.Parent:WaitForChild("RewardLedger"))

local RewardsService = {}

local function buildEmptyRewards()
	local rewards = {}
	for _, item in ipairs(RewardConfig.Types) do
		rewards[item.id] = 0
	end
	return rewards
end

function RewardsService.grantTestRewards(player)
	if RewardLedger.has(player.UserId) then
		return RewardLedger.get(player.UserId)
	end

	local rewards = buildEmptyRewards()
	rewards.credits = 100
	rewards.biomass = 10
	rewards.dna = 3

	RewardLedger.set(player.UserId, rewards)
	return rewards
end

function RewardsService.getRewardsForReturn(player)
	return RewardLedger.get(player.UserId)
end

function RewardsService.getRewardsByUserId(userId)
	return RewardLedger.get(userId)
end

function RewardsService.clearRewardsByUserId(userId)
	RewardLedger.clear(userId)
end

function RewardsService.buildEmptyRewards()
	return buildEmptyRewards()
end

return RewardsService
