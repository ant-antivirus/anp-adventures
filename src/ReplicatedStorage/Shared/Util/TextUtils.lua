local TextUtils = {}

function TextUtils.IsValidUtf8(text)
	if type(text) ~= "string" then
		return false
	end

	return utf8.len(text) ~= nil
end

function TextUtils.TruncateUtf8(text, maxCharacters, suffix)
	if type(text) ~= "string" then
		return ""
	end

	if type(maxCharacters) ~= "number" or maxCharacters <= 0 then
		return text
	end

	suffix = suffix or "..."

	local length = utf8.len(text)
	if not length then
		return text
	end

	if length <= maxCharacters then
		return text
	end

	local suffixLength = utf8.len(suffix) or 0
	local contentLength = math.max(1, maxCharacters - suffixLength)
	local byteOffset = utf8.offset(text, contentLength + 1)
	if not byteOffset then
		return text
	end

	return string.sub(text, 1, byteOffset - 1) .. suffix
end

return table.freeze(TextUtils)
