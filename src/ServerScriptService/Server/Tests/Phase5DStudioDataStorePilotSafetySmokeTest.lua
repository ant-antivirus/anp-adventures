local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PersistenceConfig = require(ReplicatedStorage.Shared.Config.PersistenceConfig)

local Phase5DStudioDataStorePilotSafetySmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase5DStudioDataStorePilotSafetySmokeTest] " .. message, 2)
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
			error("SimulatedPhase5DLoadFailure")
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
		SourceType = "Phase5DStudioDataStorePilotSafetySmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
	task.wait()
	return triggerResult
end

local function completeQuest001Partial(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start for Phase 5D partial round trip.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete for Phase 5D partial round trip.")
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
	completeQuest(PromptBindingService, player, 2, 4)
	completeQuest(PromptBindingService, player, 3, 4)
	completeQuest(PromptBindingService, player, 4, 4)
	completeQuest(PromptBindingService, player, 5, 4)
	completeQuest(PromptBindingService, player, 6, 4)
	completeQuest(PromptBindingService, player, 7, 4)
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

local function assertValidationFails(config, expectedCode)
	local validationResult = PersistenceConfig.Validate(config)
	assertCondition(validationResult.Success == false, "Persistence config should fail validation.")
	assertCondition(table.find(validationResult.Errors, expectedCode) ~= nil, "Persistence config should include `" .. expectedCode .. "`.")
end

local function assertMockRoundTrip(services)
	local PlayerDataService = services.PlayerDataService
	local PromptBindingService = services.PromptBindingService
	local SaveService = services.SaveService
	local InventoryService = services.InventoryService

	local partialPlayer = makeFakePlayer(953501, "Phase5DPartialMock")
	assertResultSuccess(PlayerDataService.InitPlayer(partialPlayer), "Phase 5D partial mock player should initialize.")
	completeQuest001Partial(PromptBindingService, partialPlayer)
	assertResultSuccess(SaveService.SavePlayerToMock(partialPlayer), "Phase 5D partial mock player should save.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(partialPlayer), "Phase 5D partial mock player should release.")
	assertResultSuccess(PlayerDataService.InitPlayer(partialPlayer), "Phase 5D partial mock player should reinitialize.")
	assertResultSuccess(SaveService.LoadPlayerFromMock(partialPlayer), "Phase 5D partial mock player should load.")
	local questState = services.QuestService.GetQuestState(partialPlayer, "quest_ep01_main_001")
	assertResultSuccess(questState, "Phase 5D partial Quest 001 state should read.")
	assertCondition(questState.Data.ObjectiveStates.obj_ep01_main_001_001.Completed == true, "Phase 5D partial mock load should preserve Quest 001 objective progress.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(partialPlayer), "Phase 5D partial mock player should release after load.")

	local fullPlayer = makeFakePlayer(953502, "Phase5DFullMock")
	assertResultSuccess(PlayerDataService.InitPlayer(fullPlayer), "Phase 5D full mock player should initialize.")
	completeFullEpisode(PromptBindingService, fullPlayer)
	assertResultSuccess(SaveService.SavePlayerToMock(fullPlayer), "Phase 5D full mock player should save.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(fullPlayer), "Phase 5D full mock player should release.")
	assertResultSuccess(PlayerDataService.InitPlayer(fullPlayer), "Phase 5D full mock player should reinitialize.")
	assertResultSuccess(SaveService.LoadPlayerFromMock(fullPlayer), "Phase 5D full mock player should load.")
	assertCondition(InventoryService.HasItem(fullPlayer, "item_star_core_segment_01", 1) == true, "Phase 5D mock load should preserve Star Core Segment 01.")
	assertCondition(InventoryService.HasItem(fullPlayer, "item_star_core_segment_02", 1) == false, "Phase 5D mock load should not grant future Star Core segments.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(fullPlayer), "Phase 5D full mock player should release after load.")
end

function Phase5DStudioDataStorePilotSafetySmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local SaveService = services.SaveService
	local MockPersistenceService = services.MockPersistenceService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService
	local PersistencePilotService = services.PersistencePilotService

	print("[ANP Phase5DStudioDataStorePilotSafetySmokeTest] Starting Phase 5D Studio DataStore pilot safety smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 5D Studio DataStore pilot safety smoke test must run in Studio only.")
	assertCondition(PersistenceConfig.PersistenceMode == "Mock", "PersistenceMode must default to Mock.")
	assertCondition(PersistenceConfig.EnableRealDataStore == false, "Real DataStore must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableLoadOnPlayerAdded == false, "Load on PlayerAdded must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableSaveOnPlayerRemoving == false, "Save on PlayerRemoving must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableAutosave == false, "Autosave must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableBindToCloseSave == false, "BindToClose save must remain disabled by default.")
	assertCondition(PersistenceConfig.RequirePilotCanaryUserId == true, "Pilot canary must be required by default.")
	assertCondition(#PersistenceConfig.PilotCanaryUserIds == 0, "Pilot canary list must be empty by default.")
	assertCondition(SaveService.GetActiveAdapterName() == "MockPersistenceService", "Mock adapter should remain active by default.")

	local defaultStatus = PersistencePilotService.GetPilotStatus()
	assertCondition(defaultStatus.Mode == "Mock", "Default pilot status should report Mock mode.")
	assertCondition(defaultStatus.RealDataStoreEnabled == false, "Default pilot status should report real DataStore disabled.")
	assertCondition(defaultStatus.CanaryRequired == true, "Default pilot status should report canary required.")
	assertCondition(defaultStatus.CanaryCount == 0, "Default pilot status should report zero canaries.")

	assertCondition(PersistenceConfig.Validate(PersistenceConfig).Success == true, "Default persistence config should validate.")
	assertValidationFails(cloneConfig({
		PersistenceMode = "StudioDataStorePilot",
		EnableRealDataStore = true,
	}), "StudioDataStorePilotRequiresExplicitAllow")
	assertCondition(PersistenceConfig.GetDataStoreName(cloneConfig({
		PersistenceMode = "StudioDataStorePilot",
		EnableRealDataStore = true,
		AllowStudioRealDataStore = true,
	})) == PersistenceConfig.StudioPilotDataStoreName, "Studio pilot should resolve the Studio pilot DataStore name.")
	assertValidationFails(cloneConfig({
		PersistenceMode = "ProductionDataStore",
		EnableRealDataStore = true,
	}), "ProductionDataStoreRequiresExplicitAllow")
	assertValidationFails(cloneConfig({
		PersistenceMode = "ProductionDataStore",
		EnableRealDataStore = true,
		AllowProductionDataStore = true,
	}), "ProductionDataStoreRequiresConfirmation")
	assertValidationFails(cloneConfig({
		PersistenceMode = "StudioDataStorePilot",
		EnableRealDataStore = true,
		AllowStudioRealDataStore = true,
		EnableAutosave = true,
		AutosaveIntervalSeconds = 60,
	}), "AutosaveIntervalTooLow")

	local destructiveValidation = PersistenceConfig.Validate(cloneConfig({
		AllowDestructiveClear = true,
	}))
	assertCondition(table.find(destructiveValidation.Warnings, "DestructiveClearEnabled") ~= nil, "Destructive clear should produce a warning.")

	PlayerDataService.ResetForTests()
	MockPersistenceService.ResetForTests()
	PromptBindingService.ResetForTests()
	SaveService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 5D smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 5D smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 5D smoke test.")

	local nonCanaryPlayer = makeFakePlayer(953503, "Phase5DNonCanary")
	local canaryPlayer = makeFakePlayer(953504, "Phase5DCanary")
	local fakeDataStore = makeFakeDataStore()
	local studioPilotConfig = cloneConfig({
		PersistenceMode = "StudioDataStorePilot",
		EnableRealDataStore = true,
		AllowStudioRealDataStore = true,
		RequirePilotCanaryUserId = true,
		PilotCanaryUserIds = { canaryPlayer.UserId },
		MaxRetries = 1,
		BaseRetryDelaySeconds = 0,
		MaxRetryDelaySeconds = 0,
	})

	services.DataStorePersistenceService.Init(studioPilotConfig, {
		DataStore = fakeDataStore,
	})
	configurePersistence(services, studioPilotConfig)

	local nonCanaryEligible = PersistencePilotService.IsPlayerEligibleForRealPersistence(nonCanaryPlayer)
	local canaryEligible = PersistencePilotService.IsPlayerEligibleForRealPersistence(canaryPlayer)
	assertCondition(nonCanaryEligible == false, "Non-allowlisted player should not be eligible for Studio pilot persistence.")
	assertCondition(canaryEligible == true, "Allowlisted player should be eligible for Studio pilot persistence.")

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
	local canaryLoad = SaveService.LoadPlayer(canaryPlayer)
	assertResultSuccess(canaryLoad, "Canary missing save should load safely.")
	assertCondition(canaryLoad.Code == "PlayerSaveNotFound", "Canary missing save should return PlayerSaveNotFound.")
	assertCondition(SaveService.GetPersistenceState(canaryPlayer).UsingDefaultData == true, "Canary missing save should mark default data.")
	assertResultSuccess(SaveService.SavePlayer(canaryPlayer), "Canary save should proceed after safe missing-save load.")
	assertCondition(SaveService.GetPersistenceState(canaryPlayer).LastSaveSucceeded == true, "Canary save should mark session save success.")
	assertCondition(fakeDataStore.GetCount == 1 and fakeDataStore.SetCount == 1, "Canary load/save should touch fake DataStore once each.")
	local report = PersistencePilotService.BuildSessionReport(canaryPlayer)
	assertCondition(report.UserId == canaryPlayer.UserId, "Session report should include UserId.")
	assertCondition(report.PlayerName == canaryPlayer.Name, "Session report should include PlayerName.")
	assertCondition(report.LastSaveSucceeded == true, "Session report should include save success.")
	assertCondition(report.SavePayload == nil, "Session report should not include save payload.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(canaryPlayer), "Canary player should release.")

	local failedLoadStore = makeFakeDataStore()
	failedLoadStore.FailLoad = true
	services.DataStorePersistenceService.Init(studioPilotConfig, {
		DataStore = failedLoadStore,
	})
	configurePersistence(services, studioPilotConfig)
	local failedLoadPlayer = makeFakePlayer(canaryPlayer.UserId, "Phase5DLoadFailure")
	assertResultSuccess(PlayerDataService.InitPlayer(failedLoadPlayer), "Load failure canary should initialize.")
	assertResultFailure(SaveService.LoadPlayer(failedLoadPlayer), "DataStoreLoadFailed", "Fake load failure should surface.")
	assertCondition(SaveService.GetPersistenceState(failedLoadPlayer).LoadFailed == true, "Load failure should mark session LoadFailed.")
	assertResultFailure(SaveService.SavePlayer(failedLoadPlayer), "SaveBlockedAfterLoadFailure", "Save should be blocked after failed load.")
	assertCondition(SaveService.GetPersistenceState(failedLoadPlayer).SaveBlockedReason == "SaveBlockedAfterLoadFailure", "Load failure should record save block reason.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(failedLoadPlayer), "Load failure canary should release.")

	configurePersistence(services, PersistenceConfig)
	assertCondition(SaveService.GetActiveAdapterName() == "MockPersistenceService", "Mock adapter should be restored after Phase 5D pilot checks.")
	assertMockRoundTrip(services)

	print("[ANP Phase5DStudioDataStorePilotSafetySmokeTest] Phase 5D Studio DataStore pilot safety smoke test passed.")
end

return Phase5DStudioDataStorePilotSafetySmokeTest
