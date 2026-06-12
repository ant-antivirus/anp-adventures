local SaveService = {}

local saveSerializationService = nil
local mockPersistenceService = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function getUserId(player)
	if type(player) == "table" then
		return player.UserId
	end

	return player and player.UserId
end

function SaveService.Init(dependencies)
	saveSerializationService = dependencies.SaveSerializationService
	mockPersistenceService = dependencies.MockPersistenceService

	assert(saveSerializationService, "SaveService requires SaveSerializationService.")
	assert(mockPersistenceService, "SaveService requires MockPersistenceService.")
end

function SaveService.BuildSave(player)
	return saveSerializationService.BuildSavePayload(player)
end

function SaveService.ValidateSavePayload(payload)
	return saveSerializationService.ValidateSavePayload(payload)
end

function SaveService.SavePlayerToMock(player)
	local payloadResult = saveSerializationService.BuildSavePayload(player)
	if not payloadResult.Success then
		return payloadResult
	end

	local userId = getUserId(player)
	local saveResult = mockPersistenceService.SaveAsync(userId, payloadResult.Data)
	if not saveResult.Success then
		return saveResult
	end

	return result(true, "PlayerSavedToMock", nil, {
		UserId = userId,
		Payload = payloadResult.Data,
	})
end

function SaveService.LoadPlayerFromMock(player)
	local userId = getUserId(player)
	local loadResult = mockPersistenceService.LoadAsync(userId)
	if not loadResult.Success then
		return loadResult
	end

	local applyResult = saveSerializationService.ApplySavePayload(player, loadResult.Data)
	if not applyResult.Success then
		return applyResult
	end

	return result(true, "PlayerLoadedFromMock", nil, {
		UserId = userId,
	})
end

return SaveService
