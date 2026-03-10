local FighterReadModel = require(script.Parent:WaitForChild("FighterReadModel"))

local FighterRosterReadModel = {}

local function cloneArray(values)
	return table.clone(values or {})
end

function FighterRosterReadModel.fromProfileDocument(document)
	local fighters = document.fighters
	local roster = {}
	local trioLookup = {}
	local trio = {}

	for _, fighterId in ipairs(fighters.activeTrioFighterIds or {}) do
		trioLookup[fighterId] = true
	end

	for _, fighterId in ipairs(fighters.rosterOrder or {}) do
		local fighterDocument = fighters.byId[fighterId]
		if fighterDocument ~= nil then
			local fighterReadModel = FighterReadModel.fromDocument(fighterDocument)
			local entry = {
				fighterId = fighterReadModel.fighterId,
				displayName = fighterReadModel.displayName,
				classId = fighterReadModel.classId,
				grade = fighterReadModel.grade,
				level = fighterReadModel.level,
				experience = fighterReadModel.experience,
				ascensionExperience = fighterReadModel.ascensionExperience,
				progression = fighterReadModel.progression,
				traitId = fighterReadModel.traitId,
				subclassId = fighterReadModel.subclassId,
				sourceTag = fighterReadModel.sourceTag,
				specialSkill = fighterReadModel.specialSkill,
				equippedActiveSkillIds = fighterReadModel.equippedActiveSkillIds,
				usableActiveSkillIds = fighterReadModel.usableActiveSkillIds,
				milestones = fighterReadModel.milestones,
				stats = fighterReadModel.stats,
				computedStats = fighterReadModel.computedStats,
				isInActiveTrio = trioLookup[fighterId] == true,
			}
			table.insert(roster, entry)

			if entry.isInActiveTrio then
				trio[fighterId] = entry
			end
		end
	end

	local orderedTrio = {}
	for _, fighterId in ipairs(fighters.activeTrioFighterIds or {}) do
		local entry = trio[fighterId]
		if entry ~= nil then
			table.insert(orderedTrio, entry)
		end
	end

	return {
		revision = document.meta.profileRevision,
		rosterCapacity = fighters.rosterCapacity,
		rosterCount = #roster,
		activeTrioFighterIds = cloneArray(fighters.activeTrioFighterIds),
		roster = roster,
		trio = orderedTrio,
	}
end

return FighterRosterReadModel
