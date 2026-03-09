local values = {
	"BasicAttack",
	"Active",
	"Passive",
	"Trigger",
}

local lookup = {}
for _, value in ipairs(values) do
	lookup[value] = true
end

return table.freeze({
	Values = table.freeze(values),
	Lookup = table.freeze(lookup),
})
