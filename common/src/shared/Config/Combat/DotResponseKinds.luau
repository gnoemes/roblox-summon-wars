local values = {
	"Normal",
	"Immune",
	"Vulnerable",
}

local lookup = {}
for _, value in ipairs(values) do
	lookup[value] = true
end

return table.freeze({
	Values = table.freeze(values),
	Lookup = table.freeze(lookup),
})
