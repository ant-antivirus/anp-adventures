local PersistenceConfig = {
	EnableRealDataStore = false,
	EnableLoadOnPlayerAdded = false,
	EnableSaveOnPlayerRemoving = false,
	EnableBindToCloseSave = false,
	EnableAutosave = false,
	UseMockInStudioByDefault = true,

	DataStoreName = "ANPAdventures_PlayerData_v1",
	KeyPrefix = "player_",
	SaveVersion = 1,

	MaxRetries = 3,
	BaseRetryDelaySeconds = 1,
	MaxRetryDelaySeconds = 8,
	AutosaveIntervalSeconds = 180,

	AllowDevClear = false,
	AllowSaveAfterLoadFailure = false,
	DebugLogs = false,
}

return table.freeze(PersistenceConfig)
