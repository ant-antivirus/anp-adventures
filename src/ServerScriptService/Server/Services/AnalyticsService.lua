local AnalyticsService = {}

local function formatValue(value)
	if type(value) == "string" then
		return "\"" .. value .. "\""
	elseif type(value) == "table" then
		local parts = {}
		for key, childValue in pairs(value) do
			table.insert(parts, tostring(key) .. " = " .. formatValue(childValue))
		end
		table.sort(parts)
		return "{ " .. table.concat(parts, ", ") .. " }"
	end

	return tostring(value)
end

function AnalyticsService.Track(player, eventName, metadata)
	local safeEventName = tostring(eventName or "UnknownEvent")
	local safeMetadata = if type(metadata) == "table" then metadata else {}
	local playerName = player and player.Name or "UnknownPlayer"

	print("[ANP Analytics] " .. safeEventName .. " " .. formatValue(safeMetadata) .. " Player = " .. playerName)

	return {
		Success = true,
		Code = "AnalyticsTracked",
		EventName = safeEventName,
		Metadata = safeMetadata,
	}
end

return AnalyticsService
