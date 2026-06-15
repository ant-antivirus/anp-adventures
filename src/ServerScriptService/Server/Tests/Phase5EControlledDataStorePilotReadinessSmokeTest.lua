local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PersistenceConfig = require(ReplicatedStorage.Shared.Config.PersistenceConfig)
local WorldBuildConfig = require(ReplicatedStorage.Shared.Config.WorldBuildConfig)

local Phase5EControlledDataStorePilotReadinessSmokeTest = {}

local FUTURE_SEGMENT_ITEM_IDS = {
	"item_star_core_segment_02",
	"item_star_core_segment_03",
	"item_star_core_segment_04",
	"item_star_core_segment_05",
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase5EControlledDataStorePilotReadinessSmokeTest] " .. message, 2)
	end
end

local function assertResultSuccess(serviceResult, message)
	assertCondition(serviceResult and serviceResult.Success == true, message .. " Code: " .. tostring(serviceResult and serviceResult.Code))
end

local function assertResultFailure(serviceResult, expectedCode, message)
	assertCondition(serviceResult and serviceResult.Success == false, message)
	assertCondition(serviceResult.Code == expectedCode, message .. " Expected `" .. expectedCode .. "`, got `" .. tostring(serviceResult.Code) .. "`.")
end

local function makeFakePlayer(userId, name)
	return {
		UserId = userId,
		Name = name,
	}
end

local function cloneConfig(overrides)
	local clonedConfig = {}
	for key, value in pairs(PersistenceConfig) do
		clonedConfig[key] = value
	end
	for key, value in pairs(overrides or {}) do
		clonedConfig[key] = value
	end
	return clonedConfig
end

local function makeFakeDataStore()
	local store = {
		Storage = {},
		SetCount = 0,
		GetCount = 0,
		FailLoad = false,
	}

	function store:SetAsync(key, value)
		self.SetCount += 1
		self.Storage[key] = value
	end

	function store:GetAsync(key)
		self.GetCount += 1
		if self.FailLoad then
			error("SimulatedPhase5ELoadFailure")
		end
		return self.Storage[key]
	end

	function store:RemoveAsync(key)
		self.Storage[key] = nil
	end

	return store
end

local function trigger(PromptBindingService, player, interactionId)
	local triggerResult = PromptBindingService.SimulatePromptTrigger(player, interactionId, {
		SourceType = "Phase5EControlledDataStorePilotReadinessSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
	task.wait()
	return triggerResult
end

local function completeQuest001(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display"), "Quest 001 Star Core bridge should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_001"), "Quest 001 should complete.")
end

local function completeQuest(PromptBindingService, player, questNumber, objectiveCount)
	local paddedQuestNumber = string.format("%03d", questNumber)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " should start.")
	for objectiveIndex = 1, objectiveCount do
		assertResultSuccess(
			trigger(PromptBindingService, player, "interaction_ep01_main_" .. paddedQuestNumber .. "_" .. string.format("%03d", objectiveIndex)),
			"Quest " .. paddedQuestNumber .. " objective " .. tostring(objectiveIndex) .. " should complete."
		)
	end
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " should complete.")
end

local function completeFullEpisode(PromptBindingService, player)
	completeQuest001(PromptBindingService, player)
	for questNumber = 2, 7 do
		completeQuest(PromptBindingService, player, questNumber, 4)
	end
	completeQuest(PromptBindingService, player, 8, 5)
end

local function configurePersistence(services, config)
	services.SaveService.Init({
		SaveSerializationService = services.SaveSerializationService,
		MockPersistenceService = services.MockPersistenceService,
		DataStorePersistenceService = services.DataStorePersistenceService,
		PersistenceConfig = config,
	})
	services.SaveService.ResetForTests()
	services.PersistencePilotService.Init({
		PersistenceConfig = config,
		SaveService = services.SaveService,
		DataStorePersistenceService = services.DataStorePersistenceService,
	})
end

local function assertDefaultConfig()
	assertCondition(PersistenceConfig.PersistenceMode == "Mock", "PersistenceMode must default to Mock.")
	assertCondition(PersistenceConfig.EnableRealDataStore == false, "Real DataStore must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableLoadOnPlayerAdded == false, "Load on PlayerAdded must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableSaveOnPlayerRemoving == false, "Save on PlayerRemoving must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableAutosave == false, "Autosave must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableBindToCloseSave == false, "BindToClose save must remain disabled by default.")
	assertCondition(#PersistenceConfig.PilotCanaryUserIds == 0, "Pilot canary list must be empty by default.")
	assertCondition(PersistenceConfig.ProductionDataStoreConfirm == false, "Production DataStore confirmation must be false by default.")
	assertCondition(PersistenceConfig.Validate(PersistenceConfig).Success == true, "Default persistence config should validate.")
end

local function assertPilotConfigValidation(canaryUserId)
	local studioPilotConfig = cloneConfig({
		PersistenceMode = "StudioDataStorePilot",
		EnableRealDataStore = true,
		AllowStudioRealDataStore = true,
		RequirePilotCanaryUserId = true,
		PilotCanaryUserIds = { canaryUserId },
		MaxRetries = 1,
		BaseRetryDelaySeconds = 0,
		MaxRetryDelaySeconds = 0,
	})
	local validationResult = PersistenceConfig.Validate(studioPilotConfig)
	assertCondition(validationResult.Success == true, "Studio pilot override should validate when explicitly allowed with a canary.")
	assertCondition(PersistenceConfig.GetDataStoreName(studioPilotConfig) == PersistenceConfig.StudioPilotDataStoreName, "Studio pilot should resolve the Studio pilot DataStore name.")

	local productionValidation = PersistenceConfig.Validate(cloneConfig({
		PersistenceMode = "ProductionDataStore",
		EnableRealDataStore = true,
		AllowProductionDataStore = false,
		ProductionDataStoreConfirm = false,
	}))
	assertCondition(productionValidation.Success == false, "Production mode should remain blocked without explicit confirmation.")

	return studioPilotConfig
end

local function assertPilotWorldBootstrapConfig(services, studioPilotConfig)
	local SmokeTestConfig = services.SmokeTestConfig
	local WorldBootstrapConfig = services.WorldBootstrapConfig

	assertCondition(WorldBuildConfig.BuildMode == "Skeleton", "WorldBuildConfig should default to Skeleton for current dev flow.")
	assertCondition(WorldBuildConfig.AllowSkeletonBuildInManualMode == false, "Manual mode should not allow skeleton overwrite by default.")
	assertCondition(WorldBuildConfig.BuildSkeletonWhenMissingInStudio == true, "Skeleton mode should allow Studio world bootstrap when missing.")

	local StudioRunService = {}
	function StudioRunService:IsStudio()
		return true
	end

	local LiveRunService = {}
	function LiveRunService:IsStudio()
		return false
	end

	local missingWorldResult = {
		Success = false,
		Code = "WorldRootMissing",
	}
	local existingWorldResult = {
		Success = true,
		Code = "WorldRegistered",
	}

	local shouldRunSmokeTests, smokeGateReason = SmokeTestConfig.ShouldRunStudioSmokeTests(StudioRunService, studioPilotConfig)
	assertCondition(shouldRunSmokeTests == false, "Studio pilot with real DataStore should skip normal smoke tests.")
	assertCondition(smokeGateReason == "RealDataStoreEnabled", "Studio pilot smoke gate should explain real DataStore skip.")

	local shouldBuildWorld, worldGateReason = WorldBootstrapConfig.ShouldBuildSkeletonWorld(
		StudioRunService,
		studioPilotConfig,
		missingWorldResult
	)
	assertCondition(shouldBuildWorld == true, "Studio pilot should allow skeleton bootstrap when the world root is missing.")
	assertCondition(worldGateReason == "BuildAllowed", "Missing Studio pilot world should return BuildAllowed.")

	shouldBuildWorld, worldGateReason = WorldBootstrapConfig.ShouldBuildSkeletonWorld(
		StudioRunService,
		studioPilotConfig,
		existingWorldResult
	)
	assertCondition(shouldBuildWorld == false, "Existing world root should not be rebuilt.")
	assertCondition(worldGateReason == "WorldRootExists", "Existing world root should return WorldRootExists.")

	shouldBuildWorld, worldGateReason = WorldBootstrapConfig.ShouldBuildSkeletonWorld(
		LiveRunService,
		studioPilotConfig,
		missingWorldResult
	)
	assertCondition(shouldBuildWorld == false, "Non-Studio should not auto-build the skeleton world.")
	assertCondition(worldGateReason == "NotStudio", "Non-Studio world bootstrap should return NotStudio.")

	local shouldRunDefaultSmokeTests = SmokeTestConfig.ShouldRunStudioSmokeTests(StudioRunService, PersistenceConfig)
	assertCondition(shouldRunDefaultSmokeTests == true, "Default Mock config should still run smoke tests.")
end

local function assertPilotEligibilityAndSaveFlow(services, studioPilotConfig)
	local PlayerDataService = services.PlayerDataService
	local SaveService = services.SaveService
	local PersistencePilotService = services.PersistencePilotService

	local fakeDataStore = makeFakeDataStore()
	services.DataStorePersistenceService.Init(studioPilotConfig, {
		DataStore = fakeDataStore,
	})
	configurePersistence(services, studioPilotConfig)

	local nonCanaryPlayer = makeFakePlayer(965001, "Phase5ENonCanary")
	local canaryPlayer = makeFakePlayer(studioPilotConfig.PilotCanaryUserIds[1], "Phase5ECanary")
	local nonCanaryEligible = PersistencePilotService.IsPlayerEligibleForRealPersistence(nonCanaryPlayer)
	local canaryEligible = PersistencePilotService.IsPlayerEligibleForRealPersistence(canaryPlayer)
	assertCondition(nonCanaryEligible == false, "Non-canary player should not be eligible for Studio pilot persistence.")
	assertCondition(canaryEligible == true, "Canary player should be eligible for Studio pilot persistence.")

	assertResultSuccess(PlayerDataService.InitPlayer(nonCanaryPlayer), "Non-canary player should initialize.")
	local skippedLoad = SaveService.LoadPlayer(nonCanaryPlayer)
	assertResultSuccess(skippedLoad, "Non-canary load should skip safely.")
	assertCondition(skippedLoad.Code == "PersistenceLoadSkippedPilotCanaryNotAllowed", "Non-canary load should report canary skip.")
	local skippedSave = SaveService.SavePlayer(nonCanaryPlayer)
	assertResultSuccess(skippedSave, "Non-canary save should skip safely.")
	assertCondition(skippedSave.Code == "PersistenceSaveSkippedPilotCanaryNotAllowed", "Non-canary save should report canary skip.")
	assertCondition(fakeDataStore.GetCount == 0 and fakeDataStore.SetCount == 0, "Non-canary load/save should not touch fake DataStore.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(nonCanaryPlayer), "Non-canary player should release.")

	assertResultSuccess(PlayerDataService.InitPlayer(canaryPlayer), "Canary player should initialize.")
	local loadResult = SaveService.LoadPlayer(canaryPlayer)
	assertResultSuccess(loadResult, "Canary SaveNotFound load should succeed safely.")
	assertCondition(loadResult.Code == "PlayerSaveNotFound", "Canary missing save should return PlayerSaveNotFound.")
	assertCondition(SaveService.GetPersistenceState(canaryPlayer).UsingDefaultData == true, "Canary missing save should mark default data.")
	assertResultSuccess(SaveService.SavePlayer(canaryPlayer), "Canary save should proceed after safe missing-save load.")
	local report = PersistencePilotService.BuildSessionReport(canaryPlayer)
	assertCondition(report.LastSaveSucceeded == true, "Session report should record save success.")
	assertCondition(report.LastSaveFailed == false, "Session report should not record save failure.")
	assertCondition(report.SavePayload == nil, "Session report should not include full save payload.")
	assertCondition(fakeDataStore.GetCount == 1 and fakeDataStore.SetCount == 1, "Canary load/save should touch fake DataStore once each.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(canaryPlayer), "Canary player should release.")
end

local function assertLoadFailureProtection(services, studioPilotConfig)
	local PlayerDataService = services.PlayerDataService
	local SaveService = services.SaveService

	local failedLoadStore = makeFakeDataStore()
	failedLoadStore.FailLoad = true
	services.DataStorePersistenceService.Init(studioPilotConfig, {
		DataStore = failedLoadStore,
	})
	configurePersistence(services, studioPilotConfig)

	local failedLoadPlayer = makeFakePlayer(studioPilotConfig.PilotCanaryUserIds[1], "Phase5ELoadFailure")
	assertResultSuccess(PlayerDataService.InitPlayer(failedLoadPlayer), "Load failure canary should initialize.")
	assertResultFailure(SaveService.LoadPlayer(failedLoadPlayer), "DataStoreLoadFailed", "Fake load failure should surface.")
	assertCondition(SaveService.GetPersistenceState(failedLoadPlayer).LoadFailed == true, "Load failure should mark session LoadFailed.")
	assertResultFailure(SaveService.SavePlayer(failedLoadPlayer), "SaveBlockedAfterLoadFailure", "Save should be blocked after failed load.")
	assertCondition(SaveService.GetPersistenceState(failedLoadPlayer).SaveBlockedReason == "SaveBlockedAfterLoadFailure", "Load failure should record save block reason.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(failedLoadPlayer), "Load failure canary should release.")
end

local function assertEP1SaveReadiness(services)
	local PlayerDataService = services.PlayerDataService
	local PromptBindingService = services.PromptBindingService
	local SaveService = services.SaveService

	configurePersistence(services, PersistenceConfig)
	assertCondition(SaveService.GetActiveAdapterName() == "MockPersistenceService", "Mock adapter should be restored before EP1 save readiness check.")

	local player = makeFakePlayer(965003, "Phase5EEP1Save")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "EP1 save readiness player should initialize.")
	completeFullEpisode(PromptBindingService, player)
	local saveResult = SaveService.BuildSave(player)
	assertResultSuccess(saveResult, "Full EP1 pilot-readiness save payload should build.")
	assertResultSuccess(SaveService.ValidateSavePayload(saveResult.Data), "Full EP1 pilot-readiness save payload should validate.")
	assertCondition(saveResult.Data.Inventory.Items.item_star_core_segment_01.Quantity >= 1, "Star Core Segment 01 should be preserved in save payload.")
	for _, futureSegmentItemId in ipairs(FUTURE_SEGMENT_ITEM_IDS) do
		local itemState = saveResult.Data.Inventory.Items[futureSegmentItemId]
		assertCondition(itemState == nil or itemState.Quantity == 0, "Future Star Core segment `" .. futureSegmentItemId .. "` should not be present.")
	end
	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "EP1 save readiness player should release.")
end

function Phase5EControlledDataStorePilotReadinessSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local MockPersistenceService = services.MockPersistenceService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase5EControlledDataStorePilotReadinessSmokeTest] Starting Phase 5E controlled DataStore pilot readiness smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 5E controlled DataStore pilot readiness smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	MockPersistenceService.ResetForTests()
	PromptBindingService.ResetForTests()
	services.SaveService.ResetForTests()

	assertDefaultConfig()
	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 5E smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 5E smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 5E smoke test.")

	local studioPilotConfig = assertPilotConfigValidation(965002)
	assertPilotWorldBootstrapConfig(services, studioPilotConfig)
	assertPilotEligibilityAndSaveFlow(services, studioPilotConfig)
	assertLoadFailureProtection(services, studioPilotConfig)
	assertEP1SaveReadiness(services)

	configurePersistence(services, PersistenceConfig)
	assertCondition(services.SaveService.GetActiveAdapterName() == "MockPersistenceService", "Mock adapter should be restored after Phase 5E checks.")

	print("[ANP Phase5EControlledDataStorePilotReadinessSmokeTest] Phase 5E controlled DataStore pilot readiness smoke test passed.")
end

return Phase5EControlledDataStorePilotReadinessSmokeTest
