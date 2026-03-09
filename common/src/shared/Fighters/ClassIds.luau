local values = {
	"Guardian",
	"Warrior",
	"Berserker",
	"Rogue",
	"Jester",
	"Archer",
	"Priest",
	"Mage",
	"Occultist",
}

local lookup = {}
for _, value in ipairs(values) do
	lookup[value] = true
end

return table.freeze({
	Values = table.freeze(values),
	Lookup = table.freeze(lookup),
})
