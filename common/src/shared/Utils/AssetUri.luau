local AssetUri = {}

function AssetUri.fromAssetId(value)
	local valueType = type(value)
	if valueType == "number" then
		if value <= 0 then
			return nil
		end

		return string.format("rbxassetid://%d", value)
	end

	if valueType ~= "string" then
		return nil
	end

	local trimmed = string.gsub(value, "^%s*(.-)%s*$", "%1")
	if trimmed == "" then
		return nil
	end

	if string.find(trimmed, "://", 1, true) ~= nil then
		return trimmed
	end

	if string.match(trimmed, "^%d+$") ~= nil then
		return string.format("rbxassetid://%s", trimmed)
	end

	return trimmed
end

return AssetUri
