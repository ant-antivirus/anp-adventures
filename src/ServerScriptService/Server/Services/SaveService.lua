local SaveService = {}

local Logger = require(script.Parent.Parent.Utils.Logger)

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

local function getTime()
	return os.time()
end

local function getUserId(player)
	if type(player) == "table" then
		return player.UserId
	end

	return player and player.UserId
end

local function getActiveAdapter()
	if persistenceConfig and persistenceConfig.EnableRealDataStore == true and persistenceConfig.PersistenceMode ~= "Mock" then
		return dataStorePersistenceService, "DataStorePersistenceService"
	end

	return mockPersistenceService, "MockPersistenceService"
end

local function logPersistence(message)
	if persistenceConfig and persistenceConfig.DebugLogs == false then
		return
	end

	Logger.Info("Persistence", message)
end

local function setPersistenceState(userId, patch)
	local state = persistenceStateByUserId[userId] or {
		UserId = userId,
		AdapterName = SaveService.GetActiveAdapterName(),
		LoadAttempted = false,
		LoadSucceeded = false,
		LoadFailed = false,
		SaveAttempted = false,
		LastSaveSucceeded = false,
		LastSaveFailed = false,
		UsingDefaultData = true,
		SaveBlockedReason = nil,
		LastLoadCode = nil,
		LastSaveCode = nil,
		LastLoadTime = nil,
		LastSaveTime = nil,
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
		UserId = userId,
		AdapterName = SaveService.GetActiveAdapterName(),
		LoadAttempted = false,
		LoadSucceeded = false,
		LoadFailed = false,
		SaveAttempted = false,
		LastSaveSucceeded = false,
		LastSaveFailed = false,
		UsingDefaultData = true,
		SaveBlockedReason = nil,
		LastLoadCode = nil,
		LastSaveCode = nil,
		LastLoadTime = nil,
		LastSaveTime = nil,
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

	if dependencies.PersistenceConfig and type(dependencies.PersistenceConfig.Validate) == "function" then
		local validationResult = dependencies.PersistenceConfig.Validate(persistenceConfig)
		if not validationResult.Success then
			Logger.Warn("Persistence", "Invalid persistence config: " .. table.concat(validationResult.Errors, ", "))
		end
		for _, warningCode in ipairs(validationResult.Warnings or {}) do
			Logger.Warn("Persistence", "Persistence config warning: " .. warningCode)
		end
	end

	local _, adapterName = getActiveAdapter()
	logPersistence(
		"mode=" .. tostring(persistenceConfig.PersistenceMode or "Mock")
			.. " adapter=" .. adapterName
			.. " realDataStore=" .. tostring(persistenceConfig.EnableRealDataStore == true)
	)
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
	setPersistenceState(userId, {
		AdapterName = adapterName,
		SaveAttempted = true,
		LastSaveTime = getTime(),
	})
	if adapterName == "DataStorePersistenceService"
		and (state.LoadFailed == true or state.PersistenceLoadFailed == true)
		and not (persistenceConfig and persistenceConfig.AllowSaveAfterLoadFailure == true)
	then
		local blockedResult = result(false, "SaveBlockedAfterLoadFailure", "Save skipped because persistence load failed for this session.", {
			UserId = userId,
		})
		setPersistenceState(userId, {
			LastSaveSucceeded = false,
			LastSaveFailed = true,
			SaveBlockedReason = blockedResult.Code,
			LastSaveCode = blockedResult.Code,
		})
		logPersistence("Save skipped for " .. tostring(player.Name or userId) .. " reason=LoadFailedOverwriteProtection")
		return blockedResult
	end

	local validationResult = saveSerializationService.ValidateSavePayload(payloadResult.Data)
	if not validationResult.Success then
		return validationResult
	end

	local saveResult = adapter.SaveAsync(userId, payloadResult.Data)
	if not saveResult.Success then
		setPersistenceState(userId, {
			LastSaveSucceeded = false,
			LastSaveFailed = true,
			LastSaveCode = saveResult.Code,
		})
		return saveResult
	end

	setPersistenceState(userId, {
		LastSaveSucceeded = true,
		LastSaveFailed = false,
		SaveBlockedReason = nil,
		LastSaveCode = saveResult.Code,
	})
	logPersistence("Save success for " .. tostring(player.Name or userId) .. " code=" .. tostring(saveResult.Code))
	return result(true, "PlayerSaved", nil, {
		UserId = userId,
		AdapterName = adapterName,
	})
end

function SaveService.LoadPlayer(player)
	local adapter, adapterName = getActiveAdapter()
	local userId = getUserId(player)
	setPersistenceState(userId, {
		UserId = userId,
		AdapterName = adapterName,
		LoadAttempted = true,
		LoadSucceeded = false,
		LoadFailed = false,
		UsingDefaultData = true,
		LastLoadTime = getTime(),
		PersistenceLoadAttempted = true,
		PersistenceLoadSucceeded = false,
		PersistenceLoadFailed = false,
		PersistenceUsingDefaultData = true,
	})

	local loadResult = adapter.LoadAsync(userId)
	if not loadResult.Success then
		setPersistenceState(userId, {
			LoadFailed = true,
			LoadSucceeded = false,
			UsingDefaultData = true,
			SaveBlockedReason = "LoadFailedOverwriteProtection",
			LastLoadCode = loadResult.Code,
			PersistenceLoadFailed = true,
			PersistenceUsingDefaultData = true,
		})
		logPersistence("Load failed for " .. tostring(player.Name or userId) .. " code=" .. tostring(loadResult.Code) .. " saveBlocked=true")
		return loadResult
	end

	if loadResult.Code == "SaveNotFound" or loadResult.Data == nil then
		setPersistenceState(userId, {
			LoadSucceeded = true,
			LoadFailed = false,
			UsingDefaultData = true,
			LastLoadCode = loadResult.Code,
			PersistenceLoadSucceeded = true,
			PersistenceUsingDefaultData = true,
		})
		logPersistence("Load missing for " .. tostring(player.Name or userId) .. ": using default data")
		return result(true, "PlayerSaveNotFound", nil, {
			UserId = userId,
			AdapterName = adapterName,
		})
	end

	local validationResult = saveSerializationService.ValidateSavePayload(loadResult.Data)
	if not validationResult.Success then
		setPersistenceState(userId, {
			LoadFailed = true,
			LoadSucceeded = false,
			UsingDefaultData = true,
			SaveBlockedReason = "LoadValidationFailed",
			LastLoadCode = validationResult.Code,
			PersistenceLoadFailed = true,
			PersistenceUsingDefaultData = true,
		})
		return validationResult
	end

	local applyResult = saveSerializationService.ApplySavePayload(player, loadResult.Data)
	if not applyResult.Success then
		setPersistenceState(userId, {
			LoadFailed = true,
			LoadSucceeded = false,
			UsingDefaultData = true,
			SaveBlockedReason = "LoadApplyFailed",
			LastLoadCode = applyResult.Code,
			PersistenceLoadFailed = true,
			PersistenceUsingDefaultData = true,
		})
		return applyResult
	end

	setPersistenceState(userId, {
		LoadSucceeded = true,
		LoadFailed = false,
		UsingDefaultData = false,
		SaveBlockedReason = nil,
		LastLoadCode = loadResult.Code,
		PersistenceLoadSucceeded = true,
		PersistenceUsingDefaultData = false,
	})
	logPersistence("Load success for " .. tostring(player.Name or userId) .. " code=" .. tostring(loadResult.Code))
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
