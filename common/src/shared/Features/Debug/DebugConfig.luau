local DebugConfig = {}

DebugConfig.Actions = {
	set_active_pet = {
		id = "set_active_pet",
		label = "Active Pet",
	},
	grant_currency = {
		id = "grant_currency",
		label = "Grant Currency",
	},
	set_party = {
		id = "set_party",
		label = "Party",
	},
}

DebugConfig.ActionOrder = {
	"set_active_pet",
	"grant_currency",
	"set_party",
}

DebugConfig.Views = {
	raid_pet_runtime = {
		id = "raid_pet_runtime",
		label = "Raid Pet Runtime",
	},
}

DebugConfig.ViewOrder = {
	"raid_pet_runtime",
}

DebugConfig.DefaultGrantAmount = 100
DebugConfig.GrantAmountPresets = { 50, 100, 500, 1000 }

function DebugConfig.isAvailable(isStudio)
	return isStudio == true
end

return DebugConfig
