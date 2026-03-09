local DeterministicRandom = {}

local MODULUS = 2147483647
local MULTIPLIER = 48271

local function normalizeSeed(seed)
	seed = math.floor(seed or 1)
	seed %= MODULUS
	if seed <= 0 then
		seed += MODULUS - 1
	end
	return seed
end

function DeterministicRandom.new(seed)
	return normalizeSeed(seed)
end

function DeterministicRandom.nextState(state)
	state = normalizeSeed(state)
	return (state * MULTIPLIER) % MODULUS
end

function DeterministicRandom.nextFloat(state)
	local nextState = DeterministicRandom.nextState(state)
	return nextState / MODULUS, nextState
end

function DeterministicRandom.nextWeightedEntry(state, weightedEntries)
	assert(
		type(weightedEntries) == "table" and #weightedEntries > 0,
		"Weighted entries are required"
	)

	local totalWeight = 0
	for _, entry in ipairs(weightedEntries) do
		totalWeight += entry.weight
	end

	assert(totalWeight > 0, "Weighted entries must total more than 0")

	local roll
	roll, state = DeterministicRandom.nextFloat(state)
	local target = roll * totalWeight
	local cumulative = 0

	for _, entry in ipairs(weightedEntries) do
		cumulative += entry.weight
		if target <= cumulative then
			return entry.value, state
		end
	end

	return weightedEntries[#weightedEntries].value, state
end

return DeterministicRandom
