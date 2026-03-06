local Currencies = require(script.Parent:WaitForChild("Economy"):WaitForChild("Currencies"))

return {
	Types = Currencies.Types,
	ById = Currencies.ById,
	DisplayOrder = Currencies.DisplayOrder,
}
