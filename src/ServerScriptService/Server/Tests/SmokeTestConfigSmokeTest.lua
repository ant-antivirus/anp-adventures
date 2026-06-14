local SmokeTestConfigSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP SmokeTestConfigSmokeTest] " .. message, 2)
	end
end

local StudioRunService = {}

function StudioRunService:IsStudio()
	return true
end

local LiveRunService = {}

function LiveRunService:IsStudio()
	return false
end

function SmokeTestConfigSmokeTest.Run(dependencies)
	print("[ANP SmokeTestConfigSmokeTest] Starting smoke test config smoke test.")

	local SmokeTestConfig = dependencies.SmokeTestConfig

	local shouldRun, reason = SmokeTestConfig.ShouldRunStudioSmokeTests(StudioRunService, {
		EnableRealDataStore = false,
	})
	assertCondition(shouldRun == true, "Studio mock config should run smoke tests.")
	assertCondition(reason == "Enabled", "Studio mock config should return Enabled.")

	shouldRun, reason = SmokeTestConfig.ShouldRunStudioSmokeTests(StudioRunService, {
		EnableRealDataStore = true,
	})
	assertCondition(shouldRun == false, "Studio real DataStore config should skip smoke tests.")
	assertCondition(reason == "RealDataStoreEnabled", "Real DataStore skip should return RealDataStoreEnabled.")

	shouldRun, reason = SmokeTestConfig.ShouldRunStudioSmokeTests(
		StudioRunService,
		{
			EnableRealDataStore = false,
		},
		{
			RunStudioSmokeTests = false,
		}
	)
	assertCondition(shouldRun == false, "Disabled smoke config should skip smoke tests.")
	assertCondition(reason == "RunStudioSmokeTestsDisabled", "Disabled smoke config should return RunStudioSmokeTestsDisabled.")

	shouldRun, reason = SmokeTestConfig.ShouldRunStudioSmokeTests(LiveRunService, {
		EnableRealDataStore = false,
	})
	assertCondition(shouldRun == false, "Non-Studio should skip smoke tests.")
	assertCondition(reason == "NotStudio", "Non-Studio should return NotStudio.")

	assertCondition(SmokeTestConfig.RunStudioSmokeTests == true, "Default RunStudioSmokeTests should be true.")
	assertCondition(
		SmokeTestConfig.AllowSmokeTestsDuringRealDataStorePilot == false,
		"Default AllowSmokeTestsDuringRealDataStorePilot should be false."
	)

	print("[ANP SmokeTestConfigSmokeTest] Smoke test config smoke test passed.")
end

return SmokeTestConfigSmokeTest
