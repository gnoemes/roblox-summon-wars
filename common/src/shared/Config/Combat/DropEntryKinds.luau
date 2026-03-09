local values = {
	"Currency",
	"Resource",
	"Card",
	"Consumable",
	"Experience",
}

local lookup = {}
for _, value in ipairs(values) do
	lookup[value] = true
end

return table.freeze({
	Values = table.freeze(values),
	Lookup = table.freeze(lookup),
})
