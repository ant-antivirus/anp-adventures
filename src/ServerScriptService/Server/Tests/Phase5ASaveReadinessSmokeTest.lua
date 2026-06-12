local RunService = game:GetService("RunService")

local Phase5ASaveReadinessSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase5ASaveReadinessSmokeTest] " .. message, 2)
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
	return PromptBindingService.SimulatePromptTrigger(player, interactionId, {
		SourceType = "Phase5ASaveReadinessSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
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

local function completeQuest001(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display"), "Quest 001 Star Core bridge should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_001"), "Quest 001 should complete.")
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

local function assertItem(InventoryService, player, itemId, expected, message)
	assertCondition(InventoryService.HasItem(player, itemId, 1) == expected, message)
end

local function assertNoRuntimeFields(payload)
	assertCondition(payload.SessionStats == nil, "Save payload should not include SessionStats.")
	assertCondition(payload.FeedbackPayloads == nil, "Save payload should not include feedback payloads.")
	assertCondition(payload.PromptState == nil, "Save payload should not include prompt state.")
	assertCondition(payload.QuestTrackerPayload == nil, "Save payload should not include tracker payload state.")
end

local function assertFullEpisodeLoadedState(services, player)
	local PlayerDataService = services.PlayerDataService
	local InventoryService = services.InventoryService
	local EpisodeService = services.EpisodeService

	local questSnapshot = PlayerDataService.GetSnapshot(player, "Quests")
	assertResultSuccess(questSnapshot, "Loaded quest snapshot should read.")
	for questNumber = 1, 8 do
		local questId = "quest_ep01_main_" .. string.format("%03d", questNumber)
		assertCondition(questSnapshot.Data.CompletedQuestIds[questId] == true, "Loaded save should include completed `" .. questId .. "`.")
	end

	local episodeState = EpisodeService.GetPlayerEpisodeState(player, "ep01_lost_star_core")
	assertResultSuccess(episodeState, "Loaded episode state should read.")
	assertCondition(episodeState.Data.IsCompleted == true, "Loaded save should preserve Episode 1 completion.")
	assertCondition(PlayerDataService.HasRewardBundleClaim(player, "reward_ep01_objective_008_moon_fragment") == true, "Loaded save should preserve Moon Fragment objective reward claim.")
	assertCondition(PlayerDataService.HasRewardBundleClaim(player, "reward_ep01_main_008") == true, "Loaded save should preserve final reward claim.")

	for _, itemId in ipairs({
		"item_ep01_fragment_universe",
		"item_ep01_fragment_earth",
		"item_ep01_fragment_theos",
		"item_ep01_fragment_rocket",
		"item_ep01_fragment_moon",
		"item_star_core_segment_01",
	}) do
		assertItem(InventoryService, player, itemId, true, "Loaded save should include `" .. itemId .. "`.")
	end

	for _, futureSegmentItemId in ipairs({
		"item_star_core_segment_02",
		"item_star_core_segment_03",
		"item_star_core_segment_04",
		"item_star_core_segment_05",
	}) do
		assertItem(InventoryService, player, futureSegmentItemId, false, "Loaded save should not include future segment `" .. futureSegmentItemId .. "`.")
	end

	local discoverySnapshot = PlayerDataService.GetSnapshot(player, "Discoveries")
	assertResultSuccess(discoverySnapshot, "Loaded discovery snapshot should read.")
	assertCondition(discoverySnapshot.Data.FoundDiscoveryIds.disc_ep01_command_star_core_display == true, "Loaded save should preserve Star Core Display discovery.")

	local journalSnapshot = PlayerDataService.GetSnapshot(player, "Journal")
	assertResultSuccess(journalSnapshot, "Loaded journal snapshot should read.")
	assertCondition(journalSnapshot.Data.UnlockedEntryIds.journal_ep01_episode_complete == true, "Loaded save should preserve episode complete journal entry.")
end

function Phase5ASaveReadinessSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local SaveService = services.SaveService
	local MockPersistenceService = services.MockPersistenceService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase5ASaveReadinessSmokeTest] Starting Phase 5A save readiness smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 5A save readiness smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	MockPersistenceService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 5A smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 5A smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 5A smoke test.")

	local freshPlayer = makeFakePlayer(950501, "Phase5AFresh")
	assertResultSuccess(PlayerDataService.InitPlayer(freshPlayer), "Fresh save player should initialize.")
	local freshPayload = SaveService.BuildSave(freshPlayer)
	assertResultSuccess(freshPayload, "Fresh save payload should build.")
	assertCondition(freshPayload.Data.SaveVersion == 1, "Fresh payload should use SaveVersion 1.")
	assertNoRuntimeFields(freshPayload.Data)
	assertResultSuccess(SaveService.ValidateSavePayload(freshPayload.Data), "Fresh save payload should validate.")

	assertResultFailure(SaveService.ValidateSavePayload({ UserId = freshPlayer.UserId }), "MissingSaveVersion", "Missing SaveVersion should fail validation.")
	local unsupportedPayload = table.clone(freshPayload.Data)
	unsupportedPayload.SaveVersion = 99
	assertResultFailure(SaveService.ValidateSavePayload(unsupportedPayload), "MigrationRequired", "Future SaveVersion should require migration.")
	local malformedQuestPayload = table.clone(freshPayload.Data)
	malformedQuestPayload.Quests = {}
	assertResultFailure(SaveService.ValidateSavePayload(malformedQuestPayload), "MalformedQuestData", "Malformed quest data should fail validation.")
	local runtimeFieldPayload = table.clone(freshPayload.Data)
	runtimeFieldPayload.SessionStats = {}
	assertResultFailure(SaveService.ValidateSavePayload(runtimeFieldPayload), "ForbiddenRuntimeField", "Runtime fields should fail validation.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(freshPlayer), "Fresh save player should release.")

	local progressPlayer = makeFakePlayer(950502, "Phase5AQuestProgress")
	assertResultSuccess(PlayerDataService.InitPlayer(progressPlayer), "Progress save player should initialize.")
	assertResultSuccess(trigger(PromptBindingService, progressPlayer, "interaction_start_ep01_main_001"), "Quest progress player should start Quest 001.")
	assertResultSuccess(trigger(PromptBindingService, progressPlayer, "interaction_ep01_main_001_001"), "Quest progress player should complete objective 001.")
	assertResultSuccess(SaveService.SavePlayerToMock(progressPlayer), "Quest progress should save to mock.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(progressPlayer), "Progress save player should release before load.")
	assertResultSuccess(PlayerDataService.InitPlayer(progressPlayer), "Progress save player should reinitialize before load.")
	assertResultSuccess(SaveService.LoadPlayerFromMock(progressPlayer), "Quest progress should load from mock.")
	local restoredQuestState = services.QuestService.GetQuestState(progressPlayer, "quest_ep01_main_001")
	assertResultSuccess(restoredQuestState, "Restored Quest 001 state should read.")
	assertCondition(restoredQuestState.Data.Status == services.QuestService.QuestStatus.Active, "Restored Quest 001 should remain active.")
	assertCondition(restoredQuestState.Data.ObjectiveStates.obj_ep01_main_001_001.Completed == true, "Restored Quest 001 objective 001 should stay complete.")
	local restoredSessionStats = PlayerDataService.GetSnapshot(progressPlayer, "SessionStats")
	assertResultSuccess(restoredSessionStats, "Restored session stats should read.")
	assertCondition(restoredSessionStats.Data.QuestsStarted == 0, "Session stats should reset after save load.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(progressPlayer), "Progress save player should release after load.")

	local fullPlayer = makeFakePlayer(950503, "Phase5AFullEP1")
	assertResultSuccess(PlayerDataService.InitPlayer(fullPlayer), "Full EP1 save player should initialize.")
	completeFullEpisode(PromptBindingService, fullPlayer)
	assertResultSuccess(SaveService.SavePlayerToMock(fullPlayer), "Full EP1 player should save to mock.")
	local firstLoad = MockPersistenceService.LoadAsync(fullPlayer.UserId)
	assertResultSuccess(firstLoad, "Full EP1 mock save should load.")
	firstLoad.Data.Profile.DisplayName = "Mutated Load Copy"
	local secondLoad = MockPersistenceService.LoadAsync(fullPlayer.UserId)
	assertResultSuccess(secondLoad, "Full EP1 mock save should load again.")
	assertCondition(secondLoad.Data.Profile.DisplayName ~= "Mutated Load Copy", "Mock persistence load should return cloned payloads.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(fullPlayer), "Full EP1 player should release before load.")
	assertResultSuccess(PlayerDataService.InitPlayer(fullPlayer), "Full EP1 player should reinitialize before load.")
	assertResultSuccess(SaveService.LoadPlayerFromMock(fullPlayer), "Full EP1 player should load from mock.")
	assertFullEpisodeLoadedState(services, fullPlayer)
	assertResultSuccess(MockPersistenceService.ClearAsync(fullPlayer.UserId), "Full EP1 mock save should clear.")
	assertCondition(MockPersistenceService.HasSave(fullPlayer.UserId) == false, "Mock persistence should report cleared save missing.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(fullPlayer), "Full EP1 player should release after load.")

	print("[ANP Phase5ASaveReadinessSmokeTest] Phase 5A save readiness smoke test passed.")
end

return Phase5ASaveReadinessSmokeTest
