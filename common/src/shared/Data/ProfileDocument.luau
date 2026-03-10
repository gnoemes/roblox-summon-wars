local ProfileSchema = require(script.Parent.ProfileSchema)
local FighterRosterDocument = require(script.Parent.FighterRosterDocument)

local ProfileDocument = {}

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

local function reconcileTable(target, source)
	if type(source) ~= "table" then
		return
	end

	for key, value in pairs(source) do
		if type(value) == "table" and type(target[key]) == "table" then
			reconcileTable(target[key], value)
		else
			target[key] = deepCopy(value)
		end
	end
end

function ProfileDocument.createNew(userId, nowUnix)
	return {
		schemaVersion = ProfileSchema.CurrentVersion,
		player = {
			userId = userId,
		},
		meta = {
			createdAt = nowUnix,
			updatedAt = nowUnix,
			profileRevision = 0,
		},
		wallets = {},
		resources = {},
		inventories = {},
		fighters = FighterRosterDocument.createNew(),
		flags = {},
		progression = {},
		journals = {
			economy = {},
		},
	}
end

function ProfileDocument.clone(document)
	return deepCopy(document)
end

function ProfileDocument.reconcile(rawDocument, userId, nowUnix)
	local document = ProfileDocument.createNew(userId, nowUnix)

	if type(rawDocument) == "table" then
		reconcileTable(document, rawDocument)
	end

	document.schemaVersion = ProfileSchema.CurrentVersion
	document.player.userId = userId
	document.meta.createdAt = document.meta.createdAt or nowUnix
	document.meta.updatedAt = document.meta.updatedAt or nowUnix
	document.meta.profileRevision = document.meta.profileRevision or 0
	document.wallets = document.wallets or {}
	document.resources = document.resources or {}
	document.inventories = document.inventories or {}
	document.fighters = FighterRosterDocument.reconcile(document.fighters)
	document.flags = document.flags or {}
	document.progression = document.progression or {}
	document.journals = document.journals or {}
	document.journals.economy = document.journals.economy or {}

	return document
end

function ProfileDocument.touch(document, nowUnix)
	document.meta.updatedAt = nowUnix
	document.meta.profileRevision += 1

	return document.meta.profileRevision
end

function ProfileDocument.appendEconomyEntry(document, entry)
	local journal = document.journals.economy
	table.insert(journal, entry)

	while #journal > ProfileSchema.EconomyJournalLimit do
		table.remove(journal, 1)
	end
end

function ProfileDocument.adjustCounter(document, bucketName, key, delta, reason, nowUnix)
	assert(bucketName == "wallets" or bucketName == "resources", "Unsupported profile bucket")
	assert(type(key) == "string" and key ~= "", "Counter key must be a non-empty string")
	assert(type(delta) == "number", "Counter delta must be a number")

	local bucket = document[bucketName]
	local currentBalance = bucket[key] or 0
	local nextBalance = currentBalance + delta
	assert(nextBalance >= 0, `{bucketName}.{key} cannot become negative`)

	bucket[key] = nextBalance

	local revision = ProfileDocument.touch(document, nowUnix)
	ProfileDocument.appendEconomyEntry(document, {
		at = nowUnix,
		revision = revision,
		bucket = bucketName,
		key = key,
		delta = delta,
		balance = nextBalance,
		reason = reason or "unspecified",
	})

	return nextBalance, revision
end

return ProfileDocument
