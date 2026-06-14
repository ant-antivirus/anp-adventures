local WorldBootstrapConfig = {
	BuildSkeletonWorldInStudioWhenMissing = true,
	BuildSkeletonWorldDuringDataStorePilot = true,
	AllowSkeletonWorldBuildOutsideStudio = false,
	LogWorldBootstrap = true,
}

function WorldBootstrapConfig.ShouldBuildSkeletonWorld(runService, persistenceConfig, worldRegistryResult, overrideConfig)
	local effectiveConfig = {}
	for key, value in pairs(WorldBootstrapConfig) do
		effectiveConfig[key] = value
	end
	for key, value in pairs(overrideConfig or {}) do
		effectiveConfig[key] = value
	end

	if worldRegistryResult == nil or worldRegistryResult.Code ~= "WorldRootMissing" then
		return false, "WorldRootExists"
	end

	local isStudio = runService:IsStudio()
	if not isStudio and effectiveConfig.AllowSkeletonWorldBuildOutsideStudio ~= true then
		return false, "NotStudio"
	end

	if isStudio and effectiveConfig.BuildSkeletonWorldInStudioWhenMissing ~= true then
		return false, "StudioBuildDisabled"
	end

	local realDataStoreEnabled = persistenceConfig and persistenceConfig.EnableRealDataStore == true
	if realDataStoreEnabled and effectiveConfig.BuildSkeletonWorldDuringDataStorePilot ~= true then
		return false, "DataStorePilotBuildDisabled"
	end

	return true, "BuildAllowed"
end

return table.freeze(WorldBootstrapConfig)
