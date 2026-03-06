local types = {
	{
		id = "credits",
		label = "Cosmocredits",
		category = "soft",
	},
	{
		id = "biomass",
		label = "Biomass",
		category = "combat",
	},
	{
		id = "genome",
		label = "Genome",
		category = "progression",
	},
	{
		id = "chroma",
		label = "Chroma",
		category = "cosmetic",
	},
}

local byId = {}
for _, currency in ipairs(types) do
	byId[currency.id] = currency
end

return {
	Types = types,
	ById = byId,
	DisplayOrder = {
		"credits",
		"biomass",
		"genome",
		"chroma",
	},
}
