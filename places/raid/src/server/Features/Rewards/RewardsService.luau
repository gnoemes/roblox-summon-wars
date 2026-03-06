local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RewardConfig = require(Shared:WaitForChild("Config"):WaitForChild("Rewards"))
local RewardProfiles = require(
	Shared:WaitForChild("Config"):WaitForChild("Economy"):WaitForChild("RewardProfiles")
)
local RewardLedger = require(script.Parent:WaitForChild("RewardLedger"))

local RewardsService = {}

local function buildEmptyRewards()
	local rewards = {}
	for _, item in ipairs(RewardConfig.Types) do
		rewards[item.id] = 0
	end
	return rewards
end

local function buildRewardsFromProfile(profileId)
	local profile = RewardProfiles.Profiles[profileId]
	local rewards = buildEmptyRewards()

	if not profile then
		warn("Missing reward profile:", profileId)
		return rewards
	end

	for rewardId, amount in pairs(profile.rewards) do
		if rewards[rewardId] ~= nil then
			rewards[rewardId] = amount
		end
	end

	return rewards
end

function RewardsService.grantTestRewards(player)
	if RewardLedger.has(player.UserId) then
		return RewardLedger.get(player.UserId)
	end

	local rewards = buildRewardsFromProfile(RewardProfiles.DefaultRaidProfileId)

	RewardLedger.set(player.UserId, rewards)
	return rewards
end

function RewardsService.grantRewards(player, grantedRewards)
	local nextRewards = RewardLedger.get(player.UserId) or buildEmptyRewards()

	for rewardId, amount in pairs(grantedRewards or {}) do
		if nextRewards[rewardId] ~= nil and type(amount) == "number" then
			nextRewards[rewardId] += amount
		end
	end

	RewardLedger.set(player.UserId, nextRewards)
	return nextRewards
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
