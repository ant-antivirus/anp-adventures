local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PersistenceConfig = require(ReplicatedStorage.Shared.Config.PersistenceConfig)

local Phase5CControlledPersistencePilotSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase5CControlledPersistencePilotSmokeTest] " .. message, 2)
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
			error("SimulatedPilotLoadFailure")
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
		SourceType = "Phase5CControlledPersistencePilotSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
	task.wait()
	return triggerResult
end

local function completeQuest001Partial(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start for Phase 5C partial round trip.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete for Phase 5C partial round trip.")
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

local function configureSaveService(services, config)
	services.SaveService.Init({
		SaveSerializationService = services.SaveSerializationService,
		MockPersistenceService = services.MockPersistenceService,
		DataStorePersistenceService = services.DataStorePersistenceService,
		PersistenceConfig = config,
	})
	services.SaveService.ResetForTests()
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

	local partialPlayer = makeFakePlayer(952501, "Phase5CPartialMock")
	assertResultSuccess(PlayerDataService.InitPlayer(partialPlayer), "Phase 5C partial mock player should initialize.")
	completeQuest001Partial(PromptBindingService, partialPlayer)
	assertResultSuccess(SaveService.SavePlayerToMock(partialPlayer), "Phase 5C partial mock player should save.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(partialPlayer), "Phase 5C partial mock player should release.")
	assertResultSuccess(PlayerDataService.InitPlayer(partialPlayer), "Phase 5C partial mock player should reinitialize.")
	assertResultSuccess(SaveService.LoadPlayerFromMock(partialPlayer), "Phase 5C partial mock player should load.")
	local questState = services.QuestService.GetQuestState(partialPlayer, "quest_ep01_main_001")
	assertResultSuccess(questState, "Phase 5C partial Quest 001 state should read.")
	assertCondition(questState.Data.ObjectiveStates.obj_ep01_main_001_001.Completed == true, "Phase 5C partial mock load should preserve Quest 001 objective progress.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(partialPlayer), "Phase 5C partial mock player should release after load.")

	local fullPlayer = makeFakePlayer(952502, "Phase5CFullMock")
	assertResultSuccess(PlayerDataService.InitPlayer(fullPlayer), "Phase 5C full mock player should initialize.")
	completeFullEpisode(PromptBindingService, fullPlayer)
	assertResultSuccess(SaveService.SavePlayerToMock(fullPlayer), "Phase 5C full mock player should save.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(fullPlayer), "Phase 5C full mock player should release.")
	assertResultSuccess(PlayerDataService.InitPlayer(fullPlayer), "Phase 5C full mock player should reinitialize.")
	assertResultSuccess(SaveService.LoadPlayerFromMock(fullPlayer), "Phase 5C full mock player should load.")
	assertCondition(InventoryService.HasItem(fullPlayer, "item_star_core_segment_01", 1) == true, "Phase 5C mock load should preserve Star Core Segment 01.")
	assertCondition(InventoryService.HasItem(fullPlayer, "item_star_core_segment_02", 1) == false, "Phase 5C mock load should not grant future Star Core segments.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(fullPlayer), "Phase 5C full mock player should release after load.")
end

function Phase5CControlledPersistencePilotSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local SaveService = services.SaveService
	local MockPersistenceService = services.MockPersistenceService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase5CControlledPersistencePilotSmokeTest] Starting Phase 5C controlled persistence pilot smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 5C controlled persistence pilot smoke test must run in Studio only.")
	assertCondition(PersistenceConfig.PersistenceMode == "Mock", "PersistenceMode must default to Mock.")
	assertCondition(PersistenceConfig.EnableRealDataStore == false, "Real DataStore must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableLoadOnPlayerAdded == false, "Load on PlayerAdded must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableSaveOnPlayerRemoving == false, "Save on PlayerRemoving must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableAutosave == false, "Autosave must remain disabled by default.")
	assertCondition(PersistenceConfig.EnableBindToCloseSave == false, "BindToClose save must remain disabled by default.")
	assertCondition(SaveService.GetActiveAdapterName() == "MockPersistenceService", "Mock adapter should remain active by default.")

	local defaultValidation = PersistenceConfig.Validate(PersistenceConfig)
	assertCondition(defaultValidation.Success == true, "Default persistence config should validate.")
	assertValidationFails(cloneConfig({
		PersistenceMode = "ProductionDataStore",
		EnableRealDataStore = true,
	}), "ProductionDataStoreRequiresExplicitAllow")
	assertValidationFails(cloneConfig({
		PersistenceMode = "Mock",
		EnableRealDataStore = true,
	}), "RealDataStoreCannotUseMockMode")
	assertValidationFails(cloneConfig({
		PersistenceMode = "StudioDataStorePilot",
		EnableRealDataStore = true,
		AllowStudioRealDataStore = true,
		EnableAutosave = true,
		AutosaveIntervalSeconds = 15,
	}), "AutosaveIntervalTooLow")

	local destructiveValidation = PersistenceConfig.Validate(cloneConfig({
		AllowDestructiveClear = true,
	}))
	assertCondition(table.find(destructiveValidation.Warnings, "DestructiveClearEnabled") ~= nil, "Destructive clear should produce an explicit warning.")

	PlayerDataService.ResetForTests()
	MockPersistenceService.ResetForTests()
	PromptBindingService.ResetForTests()
	SaveService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 5C smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 5C smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 5C smoke test.")

	local fakeDataStore = makeFakeDataStore()
	local studioPilotConfig = cloneConfig({
		PersistenceMode = "StudioDataStorePilot",
		EnableRealDataStore = true,
		AllowStudioRealDataStore = true,
		MaxRetries = 1,
		BaseRetryDelaySeconds = 0,
		MaxRetryDelaySeconds = 0,
	})
	assertCondition(PersistenceConfig.GetDataStoreName(studioPilotConfig) == PersistenceConfig.StudioPilotDataStoreName, "Studio pilot should use the Studio pilot DataStore name.")
	assertCondition(PersistenceConfig.GetDataStoreName(studioPilotConfig) ~= PersistenceConfig.ProductionDataStoreName, "Studio pilot should not use the production DataStore name.")

	services.DataStorePersistenceService.Init(studioPilotConfig, {
		DataStore = fakeDataStore,
	})
	configureSaveService(services, studioPilotConfig)
	assertCondition(SaveService.GetActiveAdapterName() == "DataStorePersistenceService", "Studio pilot config should select DataStore adapter.")
	assertCondition(services.DataStorePersistenceService.GetDataStoreName() == PersistenceConfig.StudioPilotDataStoreName, "DataStore adapter should receive the Studio pilot DataStore name.")

	local failedLoadStore = makeFakeDataStore()
	failedLoadStore.FailLoad = true
	services.DataStorePersistenceService.Init(studioPilotConfig, {
		DataStore = failedLoadStore,
	})
	configureSaveService(services, studioPilotConfig)
	local failedLoadPlayer = makeFakePlayer(952503, "Phase5CLoadFailure")
	assertResultSuccess(PlayerDataService.InitPlayer(failedLoadPlayer), "Phase 5C load failure player should initialize.")
	assertResultFailure(SaveService.LoadPlayer(failedLoadPlayer), "DataStoreLoadFailed", "Simulated pilot load failure should surface.")
	local failedState = SaveService.GetPersistenceState(failedLoadPlayer)
	assertCondition(failedState.LoadFailed == true, "Session state should mark LoadFailed after pilot load failure.")
	assertResultFailure(SaveService.SavePlayer(failedLoadPlayer), "SaveBlockedAfterLoadFailure", "Save should be blocked after pilot load failure.")
	assertCondition(SaveService.GetPersistenceState(failedLoadPlayer).SaveBlockedReason == "SaveBlockedAfterLoadFailure", "Session state should record save block reason.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(failedLoadPlayer), "Phase 5C load failure player should release.")

	local successfulStore = makeFakeDataStore()
	services.DataStorePersistenceService.Init(studioPilotConfig, {
		DataStore = successfulStore,
	})
	configureSaveService(services, studioPilotConfig)
	local missingSavePlayer = makeFakePlayer(952504, "Phase5CMissingSave")
	assertResultSuccess(PlayerDataService.InitPlayer(missingSavePlayer), "Phase 5C missing-save player should initialize.")
	local loadMissingResult = SaveService.LoadPlayer(missingSavePlayer)
	assertResultSuccess(loadMissingResult, "Missing pilot save should load safely as default data.")
	assertCondition(loadMissingResult.Code == "PlayerSaveNotFound", "Missing pilot save should return PlayerSaveNotFound.")
	assertResultSuccess(SaveService.SavePlayer(missingSavePlayer), "Save should proceed after successful missing-save load.")
	local saveState = SaveService.GetPersistenceState(missingSavePlayer)
	assertCondition(saveState.LastSaveSucceeded == true, "Session state should record save success.")
	assertCondition(successfulStore.SetCount == 1, "Fake pilot DataStore should receive one SetAsync.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(missingSavePlayer), "Phase 5C missing-save player should release.")

	configureSaveService(services, PersistenceConfig)
	assertCondition(SaveService.GetActiveAdapterName() == "MockPersistenceService", "Mock adapter should be restored after Phase 5C pilot checks.")
	assertMockRoundTrip(services)

	print("[ANP Phase5CControlledPersistencePilotSmokeTest] Phase 5C controlled persistence pilot smoke test passed.")
end

return Phase5CControlledPersistencePilotSmokeTest
