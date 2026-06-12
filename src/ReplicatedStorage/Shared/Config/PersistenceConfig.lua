local PersistenceConfig = {
	PersistenceMode = "Mock",
	EnableRealDataStore = false,
	EnableLoadOnPlayerAdded = false,
	EnableSaveOnPlayerRemoving = false,
	EnableBindToCloseSave = false,
	EnableAutosave = false,
	UseMockInStudioByDefault = true,

	MockDataStoreName = "Mock",
	StudioPilotDataStoreName = "ANPAdventures_PlayerData_StudioPilot_v1",
	ProductionDataStoreName = "ANPAdventures_PlayerData_v1",
	DataStoreName = "Mock",
	KeyPrefix = "player_",
	SaveVersion = 1,

	MaxRetries = 3,
	BaseRetryDelaySeconds = 1,
	MaxRetryDelaySeconds = 8,
	AutosaveIntervalSeconds = 180,

	AllowDevClear = false,
	AllowStudioRealDataStore = false,
	AllowProductionDataStore = false,
	AllowDestructiveClear = false,
	AllowSaveAfterLoadFailure = false,
	RequireSuccessfulLoadBeforeSave = true,
	DebugLogs = false,
}

local VALID_MODES = {
	Mock = true,
	StudioDataStorePilot = true,
	ProductionDataStore = true,
}

local function copyConfig(config)
	local copy = {}
	for key, value in pairs(PersistenceConfig) do
		copy[key] = value
	end
	for key, value in pairs(config or {}) do
		copy[key] = value
	end
	return copy
end

function PersistenceConfig.GetDataStoreName(config)
	local effectiveConfig = copyConfig(config)
	if effectiveConfig.PersistenceMode == "StudioDataStorePilot" then
		return effectiveConfig.StudioPilotDataStoreName
	end
	if effectiveConfig.PersistenceMode == "ProductionDataStore" then
		return effectiveConfig.ProductionDataStoreName
	end
	return effectiveConfig.MockDataStoreName
end

function PersistenceConfig.Validate(config)
	local effectiveConfig = copyConfig(config)
	local errors = {}
	local warnings = {}

	if not VALID_MODES[effectiveConfig.PersistenceMode] then
		table.insert(errors, "InvalidPersistenceMode")
	end

	if effectiveConfig.PersistenceMode == "ProductionDataStore" and effectiveConfig.AllowProductionDataStore ~= true then
		table.insert(errors, "ProductionDataStoreRequiresExplicitAllow")
	end

	if effectiveConfig.PersistenceMode == "StudioDataStorePilot" and effectiveConfig.AllowStudioRealDataStore ~= true then
		table.insert(errors, "StudioDataStorePilotRequiresExplicitAllow")
	end

	if effectiveConfig.EnableRealDataStore == true and effectiveConfig.PersistenceMode == "Mock" then
		table.insert(errors, "RealDataStoreCannotUseMockMode")
	end

	if effectiveConfig.EnableRealDataStore ~= true and effectiveConfig.PersistenceMode ~= "Mock" then
		table.insert(errors, "DataStoreModeRequiresRealDataStore")
	end

	if effectiveConfig.EnableLoadOnPlayerAdded == true and effectiveConfig.EnableRealDataStore ~= true then
		table.insert(errors, "LoadOnPlayerAddedRequiresRealDataStore")
	end

	if effectiveConfig.EnableSaveOnPlayerRemoving == true and effectiveConfig.EnableRealDataStore ~= true then
		table.insert(errors, "SaveOnPlayerRemovingRequiresRealDataStore")
	end

	if effectiveConfig.EnableBindToCloseSave == true and effectiveConfig.EnableRealDataStore ~= true then
		table.insert(errors, "BindToCloseSaveRequiresRealDataStore")
	end

	if effectiveConfig.EnableAutosave == true then
		if effectiveConfig.EnableRealDataStore ~= true then
			table.insert(errors, "AutosaveRequiresRealDataStore")
		end
		if type(effectiveConfig.AutosaveIntervalSeconds) ~= "number" or effectiveConfig.AutosaveIntervalSeconds < 60 then
			table.insert(errors, "AutosaveIntervalTooLow")
		end
	end

	if effectiveConfig.AllowSaveAfterLoadFailure == true then
		table.insert(warnings, "AllowSaveAfterLoadFailureEnabled")
	end

	if effectiveConfig.AllowDestructiveClear == true or effectiveConfig.AllowDevClear == true then
		table.insert(warnings, "DestructiveClearEnabled")
	end

	return {
		Success = #errors == 0,
		Code = #errors == 0 and "PersistenceConfigValid" or "PersistenceConfigInvalid",
		Errors = errors,
		Warnings = warnings,
		Data = {
			PersistenceMode = effectiveConfig.PersistenceMode,
			DataStoreName = PersistenceConfig.GetDataStoreName(effectiveConfig),
		},
	}
end

return table.freeze(PersistenceConfig)
