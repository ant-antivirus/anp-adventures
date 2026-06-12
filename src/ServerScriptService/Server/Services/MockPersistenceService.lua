local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TableUtil = require(Shared.Util.TableUtil)

local MockPersistenceService = {}

local savesByUserId = {}

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function validateUserId(userId)
	if type(userId) ~= "number" then
		return false
	end

	return true
end

function MockPersistenceService.SaveAsync(userId, payload)
	if not validateUserId(userId) then
		return result(false, "InvalidUserId", "UserId must be a number.")
	end

	if type(payload) ~= "table" then
		return result(false, "InvalidPayload", "Payload must be a table.")
	end

	savesByUserId[userId] = TableUtil.DeepCopy(payload)

	return result(true, "MockSaveStored", nil, {
		UserId = userId,
	})
end

function MockPersistenceService.LoadAsync(userId)
	if not validateUserId(userId) then
		return result(false, "InvalidUserId", "UserId must be a number.")
	end

	local payload = savesByUserId[userId]
	if payload == nil then
		return result(false, "MockSaveMissing", "No mock save exists for user.")
	end

	return result(true, "MockSaveLoaded", nil, TableUtil.DeepCopy(payload))
end

function MockPersistenceService.ClearAsync(userId)
	if not validateUserId(userId) then
		return result(false, "InvalidUserId", "UserId must be a number.")
	end

	savesByUserId[userId] = nil

	return result(true, "MockSaveCleared", nil, {
		UserId = userId,
	})
end

function MockPersistenceService.HasSave(userId)
	if not validateUserId(userId) then
		return false
	end

	return savesByUserId[userId] ~= nil
end

function MockPersistenceService.ResetForTests()
	table.clear(savesByUserId)
end

return MockPersistenceService
