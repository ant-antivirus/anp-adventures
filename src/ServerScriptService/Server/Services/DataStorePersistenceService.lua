local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TableUtil = require(Shared.Util.TableUtil)

local DataStorePersistenceService = {}

local config = nil
local dataStore = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function cloneConfig(sourceConfig)
	local clonedConfig = TableUtil.DeepCopy(sourceConfig or {})
	clonedConfig.MaxRetries = clonedConfig.MaxRetries or 3
	clonedConfig.BaseRetryDelaySeconds = clonedConfig.BaseRetryDelaySeconds or 1
	clonedConfig.MaxRetryDelaySeconds = clonedConfig.MaxRetryDelaySeconds or 8
	clonedConfig.KeyPrefix = clonedConfig.KeyPrefix or "player_"
	if type(sourceConfig) == "table" and type(sourceConfig.GetDataStoreName) == "function" then
		clonedConfig.DataStoreName = sourceConfig.GetDataStoreName(clonedConfig)
	elseif clonedConfig.PersistenceMode == "StudioDataStorePilot" then
		clonedConfig.DataStoreName = clonedConfig.StudioPilotDataStoreName
	elseif clonedConfig.PersistenceMode == "ProductionDataStore" then
		clonedConfig.DataStoreName = clonedConfig.ProductionDataStoreName
	else
		clonedConfig.DataStoreName = clonedConfig.DataStoreName or clonedConfig.MockDataStoreName or "Mock"
	end
	return clonedConfig
end

local function validateUserId(userId)
	return type(userId) == "number"
end

local function getKey(userId)
	return tostring(config.KeyPrefix) .. tostring(userId)
end

local function waitBeforeRetry(attempt)
	local delaySeconds = math.min(
		config.MaxRetryDelaySeconds,
		config.BaseRetryDelaySeconds * (2 ^ math.max(0, attempt - 1))
	)
	task.wait(delaySeconds)
end

local function withRetries(operationName, callback)
	local lastError = nil
	for attempt = 1, config.MaxRetries do
		local ok, value = pcall(callback)
		if ok then
			return result(true, operationName .. "Succeeded", nil, value)
		end

		lastError = value
		if attempt < config.MaxRetries then
			waitBeforeRetry(attempt)
		end
	end

	return result(false, operationName .. "Failed", tostring(lastError), {
		Error = tostring(lastError),
	})
end

function DataStorePersistenceService.Init(initConfig, dependencies)
	config = cloneConfig(initConfig)

	if dependencies and dependencies.DataStore then
		dataStore = dependencies.DataStore
		return
	end

	local dataStoreService = game:GetService("DataStoreService")
	dataStore = dataStoreService:GetDataStore(config.DataStoreName)
end

function DataStorePersistenceService.GetDataStoreName()
	return config and config.DataStoreName or nil
end

function DataStorePersistenceService.GetKey(userId)
	if not config then
		return nil
	end

	if not validateUserId(userId) then
		return nil
	end

	return getKey(userId)
end

function DataStorePersistenceService.SaveAsync(userId, payload)
	if not config or not dataStore then
		return result(false, "DataStorePersistenceNotInitialized", "DataStorePersistenceService is not initialized.")
	end

	if not validateUserId(userId) then
		return result(false, "InvalidUserId", "UserId must be a number.")
	end

	if type(payload) ~= "table" then
		return result(false, "InvalidPayload", "Payload must be a table.")
	end

	local payloadCopy = TableUtil.DeepCopy(payload)
	local key = getKey(userId)
	local saveResult = withRetries("DataStoreSave", function()
		dataStore:SetAsync(key, payloadCopy)
		return {
			UserId = userId,
			Key = key,
		}
	end)

	if not saveResult.Success then
		return saveResult
	end

	return result(true, "DataStoreSaveStored", nil, saveResult.Data)
end

function DataStorePersistenceService.LoadAsync(userId)
	if not config or not dataStore then
		return result(false, "DataStorePersistenceNotInitialized", "DataStorePersistenceService is not initialized.")
	end

	if not validateUserId(userId) then
		return result(false, "InvalidUserId", "UserId must be a number.")
	end

	local key = getKey(userId)
	local loadResult = withRetries("DataStoreLoad", function()
		return dataStore:GetAsync(key)
	end)

	if not loadResult.Success then
		return loadResult
	end

	if loadResult.Data == nil then
		return result(true, "SaveNotFound", nil, nil)
	end

	return result(true, "DataStoreSaveLoaded", nil, TableUtil.DeepCopy(loadResult.Data))
end

function DataStorePersistenceService.ClearAsync(userId)
	if not config or config.AllowDestructiveClear ~= true then
		return result(false, "DataStoreClearDisabled", "DataStore clear is disabled by config.")
	end

	if not validateUserId(userId) then
		return result(false, "InvalidUserId", "UserId must be a number.")
	end

	local key = getKey(userId)
	local clearResult = withRetries("DataStoreClear", function()
		dataStore:RemoveAsync(key)
		return {
			UserId = userId,
			Key = key,
		}
	end)

	if not clearResult.Success then
		return clearResult
	end

	return result(true, "DataStoreSaveCleared", nil, clearResult.Data)
end

function DataStorePersistenceService.HasSave(userId)
	local loadResult = DataStorePersistenceService.LoadAsync(userId)
	return loadResult.Success == true and loadResult.Code ~= "SaveNotFound"
end

return DataStorePersistenceService
