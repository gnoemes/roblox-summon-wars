local RewardLedger = {}

local ledger = {}

local function cloneRewards(rewards)
	local out = {}
	for key, value in pairs(rewards) do
		out[key] = value
	end
	return out
end

function RewardLedger.get(userId)
	local entry = ledger[userId]
	if not entry then
		return nil
	end
	return cloneRewards(entry.rewards)
end

function RewardLedger.set(userId, rewards)
	ledger[userId] = {
		rewards = cloneRewards(rewards),
	}
end

function RewardLedger.clear(userId)
	ledger[userId] = nil
end

function RewardLedger.has(userId)
	return ledger[userId] ~= nil
end

return RewardLedger
