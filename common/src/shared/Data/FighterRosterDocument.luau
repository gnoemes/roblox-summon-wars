local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Contract =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Contract"))
local FighterDocument = require(script.Parent:WaitForChild("FighterDocument"))

local DEFAULT_ROSTER_CAPACITY = 20

local FighterRosterDocument = {}

function FighterRosterDocument.createNew()
	return {
		starterSeedVersion = 0,
		rosterCapacity = DEFAULT_ROSTER_CAPACITY,
		byId = {},
		rosterOrder = {},
		activeTrioFighterIds = {},
	}
end

function FighterRosterDocument.assert(value, fieldName)
	fieldName = fieldName or "FighterRosterDocument"

	Contract.assertTable(value, fieldName)
	Contract.assertNonNegativeNumber(
		value.starterSeedVersion,
		string.format("%s.starterSeedVersion", fieldName)
	)
	Contract.assertPositiveInteger(
		value.rosterCapacity,
		string.format("%s.rosterCapacity", fieldName)
	)
	Contract.assertDictionary(value.byId, string.format("%s.byId", fieldName))
	for fighterId, fighterDocument in pairs(value.byId) do
		FighterDocument.assert(fighterDocument, string.format("%s.byId.%s", fieldName, fighterId))
	end
	Contract.assertStringArray(value.rosterOrder, string.format("%s.rosterOrder", fieldName))
	Contract.assertStringArray(
		value.activeTrioFighterIds,
		string.format("%s.activeTrioFighterIds", fieldName)
	)

	return value
end

function FighterRosterDocument.reconcile(rawRoster)
	local roster = FighterRosterDocument.createNew()

	if type(rawRoster) == "table" then
		roster.starterSeedVersion = if type(rawRoster.starterSeedVersion) == "number"
				and rawRoster.starterSeedVersion >= 0
			then rawRoster.starterSeedVersion
			else roster.starterSeedVersion
		roster.rosterCapacity = if type(rawRoster.rosterCapacity) == "number"
				and rawRoster.rosterCapacity >= 1
			then math.floor(rawRoster.rosterCapacity)
			else roster.rosterCapacity

		if type(rawRoster.byId) == "table" then
			for fighterId, fighterDocument in pairs(rawRoster.byId) do
				if type(fighterId) == "string" and type(fighterDocument) == "table" then
					roster.byId[fighterId] = FighterDocument.reconcile(fighterDocument, fighterId)
				end
			end
		end

		if type(rawRoster.rosterOrder) == "table" then
			for _, fighterId in ipairs(rawRoster.rosterOrder) do
				if type(fighterId) == "string" and roster.byId[fighterId] ~= nil then
					table.insert(roster.rosterOrder, fighterId)
				end
			end
		end

		if type(rawRoster.activeTrioFighterIds) == "table" then
			for _, fighterId in ipairs(rawRoster.activeTrioFighterIds) do
				if type(fighterId) == "string" and roster.byId[fighterId] ~= nil then
					table.insert(roster.activeTrioFighterIds, fighterId)
				end
			end
		end
	end

	for fighterId in pairs(roster.byId) do
		local exists = false
		for _, orderedFighterId in ipairs(roster.rosterOrder) do
			if orderedFighterId == fighterId then
				exists = true
				break
			end
		end

		if not exists then
			table.insert(roster.rosterOrder, fighterId)
		end
	end

	FighterRosterDocument.assert(roster)

	return roster
end

return FighterRosterDocument
