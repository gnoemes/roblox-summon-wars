local ProfileReadModel = {}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local clone = {}

	for key, childValue in pairs(value) do
		clone[key] = deepCopy(childValue)
	end

	return clone
end

function ProfileReadModel.fromDocument(document)
	local fighterRoster = document.fighters or {}

	return {
		userId = document.player.userId,
		schemaVersion = document.schemaVersion,
		revision = document.meta.profileRevision,
		updatedAt = document.meta.updatedAt,
		wallets = deepCopy(document.wallets),
		resources = deepCopy(document.resources),
		fighters = {
			rosterCount = #(fighterRoster.rosterOrder or {}),
			rosterCapacity = fighterRoster.rosterCapacity or 0,
			activeTrioFighterIds = deepCopy(fighterRoster.activeTrioFighterIds or {}),
		},
		flags = deepCopy(document.flags),
		progression = deepCopy(document.progression),
	}
end

return ProfileReadModel
