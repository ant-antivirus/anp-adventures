local PersistencePilotService = {}

local persistenceConfig = nil
local saveService = nil
local dataStorePersistenceService = nil

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

function PersistencePilotService.Init(dependencies)
	persistenceConfig = dependencies.PersistenceConfig
	saveService = dependencies.SaveService
	dataStorePersistenceService = dependencies.DataStorePersistenceService

	assert(persistenceConfig, "PersistencePilotService requires PersistenceConfig.")
	assert(saveService, "PersistencePilotService requires SaveService.")
	assert(dataStorePersistenceService, "PersistencePilotService requires DataStorePersistenceService.")
end

function PersistencePilotService.GetPilotStatus()
	local config = cloneConfig(persistenceConfig)
	local adapterName = saveService.GetActiveAdapterName()
	local dataStoreName = nil
	if type(persistenceConfig.GetDataStoreName) == "function" then
		dataStoreName = persistenceConfig.GetDataStoreName(config)
	elseif dataStorePersistenceService.GetDataStoreName then
		dataStoreName = dataStorePersistenceService.GetDataStoreName()
	end

	return {
		Mode = config.PersistenceMode or "Mock",
		RealDataStoreEnabled = config.EnableRealDataStore == true,
		ActiveAdapterName = adapterName,
		DataStoreName = dataStoreName,
		LoadOnPlayerAdded = config.EnableLoadOnPlayerAdded == true,
		SaveOnPlayerRemoving = config.EnableSaveOnPlayerRemoving == true,
		AutosaveEnabled = config.EnableAutosave == true,
		BindToCloseEnabled = config.EnableBindToCloseSave == true,
		CanaryRequired = config.RequirePilotCanaryUserId == true,
		CanaryCount = type(config.PilotCanaryUserIds) == "table" and #config.PilotCanaryUserIds or 0,
		ProductionAllowed = config.AllowProductionDataStore == true and config.ProductionDataStoreConfirm == true,
	}
end

function PersistencePilotService.IsPlayerEligibleForRealPersistence(player)
	if saveService.IsPlayerEligibleForRealPersistence then
		return saveService.IsPlayerEligibleForRealPersistence(player)
	end

	local userId = getUserId(player)
	if persistenceConfig.EnableRealDataStore ~= true then
		return true, "RealDataStoreDisabled"
	end
	if persistenceConfig.PersistenceMode == "StudioDataStorePilot"
		and persistenceConfig.RequirePilotCanaryUserId == true
		and not persistenceConfig.IsUserAllowedForPilot(userId, persistenceConfig)
	then
		return false, "PilotCanaryNotAllowed"
	end
	return true, "Eligible"
end

function PersistencePilotService.BuildSessionReport(player)
	local state = saveService.GetPersistenceState(player)
	return {
		UserId = getUserId(player),
		PlayerName = player and player.Name or nil,
		Mode = persistenceConfig.PersistenceMode or "Mock",
		AdapterName = saveService.GetActiveAdapterName(),
		LoadAttempted = state.LoadAttempted == true,
		LoadSucceeded = state.LoadSucceeded == true,
		LoadFailed = state.LoadFailed == true,
		SaveAttempted = state.SaveAttempted == true,
		LastSaveSucceeded = state.LastSaveSucceeded == true,
		LastSaveFailed = state.LastSaveFailed == true,
		SaveBlockedReason = state.SaveBlockedReason,
		LastLoadCode = state.LastLoadCode,
		LastSaveCode = state.LastSaveCode,
		UsingDefaultData = state.UsingDefaultData == true,
	}
end

return PersistencePilotService
