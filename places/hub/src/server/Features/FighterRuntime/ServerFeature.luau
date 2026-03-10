local ServerFighters =
	require(script.Parent.Parent.Parent:WaitForChild("ServerShared"):WaitForChild("Fighters"))

local FighterRosterService = ServerFighters.FighterRosterService
local FighterProgressionService = ServerFighters.FighterProgressionService

return {
	id = "FighterRuntime",

	registerServices = function(context)
		context.services:register(
			"FighterRosterService",
			FighterRosterService.new({
				playerSessionService = context.services:get("PlayerSessionService"),
				snapshotService = context.services:get("SnapshotService"),
				debugService = context.services:get("DebugService"),
				network = context.services:get("Network"),
			})
		)
		context.services:register(
			"FighterProgressionService",
			FighterProgressionService.new({
				playerSessionService = context.services:get("PlayerSessionService"),
				fighterRosterService = context.services:get("FighterRosterService"),
				snapshotService = context.services:get("SnapshotService"),
				debugService = context.services:get("DebugService"),
			})
		)
	end,

	start = function(context)
		local rosterService = context.services:get("FighterRosterService")
		rosterService:start()
		context.cleaner:add(rosterService)

		local progressionService = context.services:get("FighterProgressionService")
		progressionService:start()
		context.cleaner:add(progressionService)

		local encounterService = context.services:getOptional("CombatEncounterService")
		if encounterService ~= nil then
			encounterService:setFighterRunSeedProvider(function(player)
				return rosterService:getActiveTrioCombatSnapshots(player)
			end)
			context.cleaner:add(
				encounterService:registerEncounterCompletedListener(
					"FighterProgression",
					function(payload)
						return progressionService:applyEncounterResult(payload.player, payload)
					end
				)
			)
		end
	end,
}
