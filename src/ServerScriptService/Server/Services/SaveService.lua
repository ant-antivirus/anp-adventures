local SaveService = {}

local saveSerializationService = nil
local mockPersistenceService = nil
local dataStorePersistenceService = nil
local persistenceConfig = nil
local persistenceStateByUserId = {}

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function cloneConfig(config)
	local clonedConfig = {}
	for key, value in pairs(config or {}) do
		clonedConfig[key] = value
	end
	return clonedConfig
end

local function getUserId(player)
	if type(player) == "table" then
		return player.UserId
	end

	return player and player.UserId
end

local function getActiveAdapter()
	if persistenceConfig and persistenceConfig.EnableRealDataStore == true then
		return dataStorePersistenceService, "DataStorePersistenceService"
	end

	return mockPersistenceService, "MockPersistenceService"
end

local function setPersistenceState(userId, patch)
	local state = persistenceStateByUserId[userId] or {
		PersistenceLoadAttempted = false,
		PersistenceLoadSucceeded = false,
		PersistenceLoadFailed = false,
		PersistenceUsingDefaultData = true,
	}

	for key, value in pairs(patch) do
		state[key] = value
	end

	persistenceStateByUserId[userId] = state
	return state
end

local function getPersistenceState(userId)
	return persistenceStateByUserId[userId] or {
		PersistenceLoadAttempted = false,
		PersistenceLoadSucceeded = false,
		PersistenceLoadFailed = false,
		PersistenceUsingDefaultData = true,
	}
end

function SaveService.Init(dependencies)
	saveSerializationService = dependencies.SaveSerializationService
	mockPersistenceService = dependencies.MockPersistenceService
	dataStorePersistenceService = dependencies.DataStorePersistenceService
	persistenceConfig = cloneConfig(dependencies.PersistenceConfig)

	assert(saveSerializationService, "SaveService requires SaveSerializationService.")
	assert(mockPersistenceService, "SaveService requires MockPersistenceService.")
	assert(dataStorePersistenceService, "SaveService requires DataStorePersistenceService.")
end

function SaveService.BuildSave(player)
	return saveSerializationService.BuildSavePayload(player)
end

function SaveService.ValidateSavePayload(payload)
	return saveSerializationService.ValidateSavePayload(payload)
end

function SaveService.GetActiveAdapterName()
	local _, adapterName = getActiveAdapter()
	return adapterName
end

function SaveService.GetPersistenceState(player)
	return getPersistenceState(getUserId(player))
end

function SaveService.SavePlayer(player)
	local payloadResult = saveSerializationService.BuildSavePayload(player)
	if not payloadResult.Success then
		return payloadResult
	end

	local adapter, adapterName = getActiveAdapter()
	local userId = getUserId(player)
	local state = getPersistenceState(userId)
	if adapterName == "DataStorePersistenceService"
		and state.PersistenceLoadFailed == true
		and not (persistenceConfig and persistenceConfig.AllowSaveAfterLoadFailure == true)
	then
		return result(false, "PersistenceLoadFailedSaveBlocked", "Save skipped because persistence load failed for this session.", {
			UserId = userId,
		})
	end

	local validationResult = saveSerializationService.ValidateSavePayload(payloadResult.Data)
	if not validationResult.Success then
		return validationResult
	end

	local saveResult = adapter.SaveAsync(userId, payloadResult.Data)
	if not saveResult.Success then
		return saveResult
	end

	return result(true, "PlayerSaved", nil, {
		UserId = userId,
		AdapterName = adapterName,
	})
end

function SaveService.LoadPlayer(player)
	local adapter, adapterName = getActiveAdapter()
	local userId = getUserId(player)
	setPersistenceState(userId, {
		PersistenceLoadAttempted = true,
		PersistenceLoadSucceeded = false,
		PersistenceLoadFailed = false,
		PersistenceUsingDefaultData = true,
	})

	local loadResult = adapter.LoadAsync(userId)
	if not loadResult.Success then
		setPersistenceState(userId, {
			PersistenceLoadFailed = true,
			PersistenceUsingDefaultData = true,
		})
		return loadResult
	end

	if loadResult.Code == "SaveNotFound" or loadResult.Data == nil then
		setPersistenceState(userId, {
			PersistenceLoadSucceeded = true,
			PersistenceUsingDefaultData = true,
		})
		return result(true, "PlayerSaveNotFound", nil, {
			UserId = userId,
			AdapterName = adapterName,
		})
	end

	local validationResult = saveSerializationService.ValidateSavePayload(loadResult.Data)
	if not validationResult.Success then
		setPersistenceState(userId, {
			PersistenceLoadFailed = true,
			PersistenceUsingDefaultData = true,
		})
		return validationResult
	end

	local applyResult = saveSerializationService.ApplySavePayload(player, loadResult.Data)
	if not applyResult.Success then
		setPersistenceState(userId, {
			PersistenceLoadFailed = true,
			PersistenceUsingDefaultData = true,
		})
		return applyResult
	end

	setPersistenceState(userId, {
		PersistenceLoadSucceeded = true,
		PersistenceUsingDefaultData = false,
	})
	return result(true, "PlayerLoaded", nil, {
		UserId = userId,
		AdapterName = adapterName,
	})
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

function SaveService.ResetForTests()
	table.clear(persistenceStateByUserId)
end

return SaveService
