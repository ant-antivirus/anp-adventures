local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PersistenceConfig = require(ReplicatedStorage.Shared.Config.PersistenceConfig)
local DataStorePersistenceService = require(script.Parent.Parent.Services.DataStorePersistenceService)

local Phase5BDataStoreAdapterSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase5BDataStoreAdapterSmokeTest] " .. message, 2)
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

local function trigger(PromptBindingService, player, interactionId)
	local triggerResult = PromptBindingService.SimulatePromptTrigger(player, interactionId, {
		SourceType = "Phase5BDataStoreAdapterSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
	task.wait()
	return triggerResult
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
			error("SimulatedDataStoreLoadFailure")
		end
		return self.Storage[key]
	end

	function store:RemoveAsync(key)
		self.Storage[key] = nil
	end

	return store
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

local function assertMockRoundTrip(services)
	local PlayerDataService = services.PlayerDataService
	local PromptBindingService = services.PromptBindingService
	local SaveService = services.SaveService
	local InventoryService = services.InventoryService

	local partialPlayer = makeFakePlayer(951501, "Phase5BPartialMock")
	assertResultSuccess(PlayerDataService.InitPlayer(partialPlayer), "Phase 5B partial player should initialize.")
	assertResultSuccess(trigger(PromptBindingService, partialPlayer, "interaction_start_ep01_main_001"), "Phase 5B partial player should start Quest 001.")
	assertResultSuccess(trigger(PromptBindingService, partialPlayer, "interaction_ep01_main_001_001"), "Phase 5B partial player should complete Quest 001 objective 001.")
	assertResultSuccess(SaveService.SavePlayerToMock(partialPlayer), "Phase 5B partial player should save to mock.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(partialPlayer), "Phase 5B partial player should release.")
	assertResultSuccess(PlayerDataService.InitPlayer(partialPlayer), "Phase 5B partial player should reinitialize.")
	assertResultSuccess(SaveService.LoadPlayerFromMock(partialPlayer), "Phase 5B partial player should load from mock.")
	local questState = services.QuestService.GetQuestState(partialPlayer, "quest_ep01_main_001")
	assertResultSuccess(questState, "Phase 5B partial Quest 001 state should read.")
	assertCondition(questState.Data.ObjectiveStates.obj_ep01_main_001_001.Completed == true, "Mock load should preserve partial objective progress.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(partialPlayer), "Phase 5B partial player should release after load.")

	local fullPlayer = makeFakePlayer(951502, "Phase5BFullMock")
	assertResultSuccess(PlayerDataService.InitPlayer(fullPlayer), "Phase 5B full player should initialize.")
	completeFullEpisode(PromptBindingService, fullPlayer)
	assertResultSuccess(SaveService.SavePlayerToMock(fullPlayer), "Phase 5B full player should save to mock.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(fullPlayer), "Phase 5B full player should release.")
	assertResultSuccess(PlayerDataService.InitPlayer(fullPlayer), "Phase 5B full player should reinitialize.")
	assertResultSuccess(SaveService.LoadPlayerFromMock(fullPlayer), "Phase 5B full player should load from mock.")
	assertCondition(InventoryService.HasItem(fullPlayer, "item_star_core_segment_01", 1) == true, "Mock load should preserve Star Core Segment 01.")
	assertCondition(InventoryService.HasItem(fullPlayer, "item_star_core_segment_02", 1) == false, "Mock load should not grant future Star Core segments.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(fullPlayer), "Phase 5B full player should release after load.")
end

function Phase5BDataStoreAdapterSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local SaveService = services.SaveService
	local SaveSerializationService = services.SaveSerializationService
	local MockPersistenceService = services.MockPersistenceService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase5BDataStoreAdapterSmokeTest] Starting Phase 5B DataStore adapter smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 5B DataStore adapter smoke test must run in Studio only.")
	assertCondition(PersistenceConfig.EnableRealDataStore == false, "Real DataStore must be disabled by default.")
	assertCondition(PersistenceConfig.EnableLoadOnPlayerAdded == false, "Load on PlayerAdded must be disabled by default.")
	assertCondition(PersistenceConfig.EnableSaveOnPlayerRemoving == false, "Save on PlayerRemoving must be disabled by default.")
	assertCondition(PersistenceConfig.EnableAutosave == false, "Autosave must be disabled by default.")
	assertCondition(type(DataStorePersistenceService.SaveAsync) == "function", "DataStore adapter should expose SaveAsync.")
	assertCondition(type(DataStorePersistenceService.LoadAsync) == "function", "DataStore adapter should expose LoadAsync.")
	assertCondition(SaveService.GetActiveAdapterName() == "MockPersistenceService", "Mock adapter should be active by default.")

	PlayerDataService.ResetForTests()
	MockPersistenceService.ResetForTests()
	PromptBindingService.ResetForTests()
	SaveService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 5B smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 5B smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 5B smoke test.")

	local validationPlayer = makeFakePlayer(951500, "Phase5BValidation")
	assertResultSuccess(PlayerDataService.InitPlayer(validationPlayer), "Phase 5B validation player should initialize.")
	local validPayload = SaveService.BuildSave(validationPlayer)
	assertResultSuccess(validPayload, "Valid Phase 5B save payload should build.")
	assertResultFailure(SaveService.ValidateSavePayload({ UserId = validationPlayer.UserId }), "MissingSaveVersion", "Invalid payload should be rejected before adapter save.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(validationPlayer), "Phase 5B validation player should release.")

	local fakeDataStore = makeFakeDataStore()
	local dataStoreConfig = cloneConfig({
		PersistenceMode = "StudioDataStorePilot",
		EnableRealDataStore = true,
		AllowStudioRealDataStore = true,
		RequirePilotCanaryUserId = false,
		MaxRetries = 1,
		BaseRetryDelaySeconds = 0,
		MaxRetryDelaySeconds = 0,
	})
	services.DataStorePersistenceService.Init(dataStoreConfig, {
		DataStore = fakeDataStore,
	})
	configureSaveService(services, dataStoreConfig)
	assertCondition(SaveService.GetActiveAdapterName() == "DataStorePersistenceService", "DataStore adapter should be selected only when enabled.")

	local dataStorePlayer = makeFakePlayer(951503, "Phase5BDataStoreSelection")
	assertResultSuccess(PlayerDataService.InitPlayer(dataStorePlayer), "DataStore selection player should initialize.")
	assertResultSuccess(SaveService.SavePlayer(dataStorePlayer), "Valid payload should save through fake DataStore adapter.")
	assertCondition(fakeDataStore.SetCount == 1, "Fake DataStore should receive one SetAsync after validated save.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(dataStorePlayer), "DataStore selection player should release.")

	local failingDataStore = makeFakeDataStore()
	failingDataStore.FailLoad = true
	services.DataStorePersistenceService.Init(dataStoreConfig, {
		DataStore = failingDataStore,
	})
	configureSaveService(services, dataStoreConfig)
	local failedLoadPlayer = makeFakePlayer(951504, "Phase5BLoadFailure")
	assertResultSuccess(PlayerDataService.InitPlayer(failedLoadPlayer), "Load failure player should initialize.")
	assertResultFailure(SaveService.LoadPlayer(failedLoadPlayer), "DataStoreLoadFailed", "Simulated load failure should be surfaced.")
	assertResultFailure(SaveService.SavePlayer(failedLoadPlayer), "SaveBlockedAfterLoadFailure", "Save after load failure should be blocked by default.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(failedLoadPlayer), "Load failure player should release.")

	configureSaveService(services, PersistenceConfig)
	assertCondition(SaveService.GetActiveAdapterName() == "MockPersistenceService", "Mock adapter should be restored after DataStore adapter checks.")
	assertMockRoundTrip(services)

	print("[ANP Phase5BDataStoreAdapterSmokeTest] Phase 5B DataStore adapter smoke test passed.")
end

return Phase5BDataStoreAdapterSmokeTest
