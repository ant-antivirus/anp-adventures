local SmokeTestConfig = {
	RunStudioSmokeTests = true,

	-- Safety: when real DataStore is enabled, normal smoke tests should be skipped
	-- because several tests intentionally assert that real DataStore is disabled by default.
	SkipWhenRealDataStoreEnabled = true,

	-- Used only for explicit debugging. Keep false by default.
	AllowSmokeTestsDuringRealDataStorePilot = false,

	LogSkippedSmokeTests = true,
}

local function getSetting(settingName, overrideConfig)
	if overrideConfig and overrideConfig[settingName] ~= nil then
		return overrideConfig[settingName]
	end

	return SmokeTestConfig[settingName]
end

function SmokeTestConfig.ShouldRunStudioSmokeTests(runService, persistenceConfig, overrideConfig)
	if not runService:IsStudio() then
		return false, "NotStudio"
	end

	if getSetting("RunStudioSmokeTests", overrideConfig) ~= true then
		return false, "RunStudioSmokeTestsDisabled"
	end

	local realDataStoreEnabled = persistenceConfig and persistenceConfig.EnableRealDataStore == true
	if realDataStoreEnabled and getSetting("SkipWhenRealDataStoreEnabled", overrideConfig) == true then
		if getSetting("AllowSmokeTestsDuringRealDataStorePilot", overrideConfig) ~= true then
			return false, "RealDataStoreEnabled"
		end
	end

	return true, "Enabled"
end

return table.freeze(SmokeTestConfig)
