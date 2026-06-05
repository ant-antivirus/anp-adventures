local TableUtil = {}

function TableUtil.ShallowCopy(source)
	local copy = {}

	for key, value in pairs(source) do
		copy[key] = value
	end

	return copy
end

function TableUtil.DeepCopy(source)
	if type(source) ~= "table" then
		return source
	end

	local copy = {}

	for key, value in pairs(source) do
		copy[TableUtil.DeepCopy(key)] = TableUtil.DeepCopy(value)
	end

	return copy
end

function TableUtil.Count(source)
	local count = 0

	for _ in pairs(source) do
		count += 1
	end

	return count
end

function TableUtil.Contains(list, value)
	for _, item in ipairs(list) do
		if item == value then
			return true
		end
	end

	return false
end

return TableUtil
