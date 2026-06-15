local WorldBuildConfig = {
	BuildMode = "Skeleton",

	BuildSkeletonWhenMissingInStudio = true,
	AllowSkeletonBuildInManualMode = false,
	ValidateManualMapInStudio = true,
	LogWorldBuildMode = true,
}

return table.freeze(WorldBuildConfig)
