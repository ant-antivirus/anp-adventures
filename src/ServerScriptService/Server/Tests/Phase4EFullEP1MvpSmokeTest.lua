local RunService = game:GetService("RunService")

local Phase4EFullEP1MvpSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase4EFullEP1MvpSmokeTest] " .. message, 2)
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
		SourceType = "Phase4EFullEP1MvpSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function directInteract(InteractionService, player, interactionId)
	return InteractionService.AttemptInteraction(player, interactionId, {
		SourceType = "Phase4EFullEP1MvpSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function assertTracker(QuestTrackerService, player, expectedState, message)
	local trackerResult = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(trackerResult, message)
	assertCondition(trackerResult.Data.Type == "QuestTracker", message .. " should build QuestTracker payload.")
	assertCondition(trackerResult.Data.State == expectedState, message .. " Expected state `" .. expectedState .. "`, got `" .. tostring(trackerResult.Data.State) .. "`.")
	return trackerResult.Data
end

local function assertHidden(InteractionVisibilityService, player, interactionId, message)
	local stateResult = InteractionVisibilityService.GetInteractionState(player, interactionId)
	assertResultSuccess(stateResult, message)
	assertCondition(stateResult.Data.Visible == false and stateResult.Data.Enabled == false, message .. " should be hidden and disabled.")
	return stateResult.Data
end

local function assertItem(InventoryService, player, itemId, expected, message)
	local hasItem = InventoryService.HasItem(player, itemId, 1)
	assertCondition(hasItem == expected, message .. " Expected item `" .. itemId .. "` presence " .. tostring(expected) .. ".")
end

local function completeQuest001(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display"), "Quest 001 Star Core bridge objective should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_001"), "Quest 001 should complete.")
end

local function completeQuest002(PromptBindingService, QuestTrackerService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_002"), "Quest 002 should start after Quest 001.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_001"), "Quest 002 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_002"), "Quest 002 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_003"), "Quest 002 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_004"), "Quest 002 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_002"), "Quest 002 should complete.")
	local tracker = assertTracker(QuestTrackerService, player, "QuestCompleted", "Tracker after Quest 002 should read.")
	assertCondition(tracker.CurrentObjectiveId ~= "obj_ep01_main_001_001", "Tracker should not show stale Quest 001 objective after Quest 002.")
end

local function completeQuest003(PromptBindingService, InteractionService, InteractionVisibilityService, InventoryService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_003"), "Quest 003 should start after Quest 002.")
	local earlyDependent = directInteract(InteractionService, player, "interaction_ep01_main_003_003")
	assertResultFailure(earlyDependent, "ObjectiveDependencyMissing", "Quest 003 dependent objective should respect prerequisite.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_001"), "Quest 003 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_002"), "Quest 003 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_003"), "Quest 003 objective 003 should complete.")
	assertHidden(InteractionVisibilityService, player, "interaction_ep01_main_003_003", "Quest 003 objective 003 prompt after completion")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_004"), "Quest 003 objective 004 should complete.")
	assertHidden(InteractionVisibilityService, player, "interaction_ep01_main_003_004", "Quest 003 objective 004 prompt after completion")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_003"), "Quest 003 should complete.")
	assertItem(InventoryService, player, "item_ep01_fragment_universe", true, "Quest 003 should grant Universe Fragment.")
end

local function completeQuest004(PromptBindingService, InteractionVisibilityService, InventoryService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_004"), "Quest 004 should start after Quest 003.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_004_001"), "Quest 004 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_004_002"), "Quest 004 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_004_003"), "Quest 004 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_004_004"), "Quest 004 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_004"), "Quest 004 should complete.")
	assertHidden(InteractionVisibilityService, player, "interaction_ep01_main_003_003", "Quest 003 objective 003 prompt after Quest 004")
	assertHidden(InteractionVisibilityService, player, "interaction_ep01_main_003_004", "Quest 003 objective 004 prompt after Quest 004")
	assertItem(InventoryService, player, "item_ep01_fragment_earth", true, "Quest 004 should grant Earth Fragment.")
end

local function completeQuest005(PromptBindingService, QuestTrackerService, InventoryService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_005"), "Quest 005 should start after Quest 004.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_005_001"), "Quest 005 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_005_002"), "Quest 005 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_005_003"), "Quest 005 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_005_004"), "Quest 005 objective 004 should complete.")
	local completeReadyTracker = assertTracker(QuestTrackerService, player, "ActiveQuest", "Quest 005 complete-ready tracker should read.")
	assertCondition(completeReadyTracker.CompletedObjectiveCount == completeReadyTracker.TotalObjectiveCount, "Quest 005 optional objectives should not block main completion.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_005"), "Quest 005 should complete.")
	assertItem(InventoryService, player, "item_ep01_fragment_theos", true, "Quest 005 should grant THEOS Fragment.")
end

local function completeQuest006(PromptBindingService, InteractionService, InventoryService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_006"), "Quest 006 should start after Quest 005.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_006_001"), "Quest 006 objective 001 should complete.")
	local earlyDiagnostics = directInteract(InteractionService, player, "interaction_ep01_main_006_003")
	assertResultFailure(earlyDiagnostics, "ObjectiveDependencyMissing", "Quest 006 diagnostics should require control panel.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_006_002"), "Quest 006 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_006_003"), "Quest 006 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_006_004"), "Quest 006 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_006"), "Quest 006 should complete.")
	assertItem(InventoryService, player, "item_ep01_fragment_rocket", true, "Quest 006 should grant Rocket Fragment.")
end

local function completeQuest007(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_007"), "Quest 007 should start after Quest 006.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_007_001"), "Quest 007 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_007_002"), "Quest 007 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_007_003"), "Quest 007 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_007_004"), "Quest 007 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_007"), "Quest 007 should complete.")
end

local function assertQuest008Tracker(QuestTrackerService, player, expectedCompleted, message)
	local tracker = assertTracker(QuestTrackerService, player, "ActiveQuest", message)
	assertCondition(tracker.QuestId == "quest_ep01_main_008", message .. " should track Quest 008.")
	assertCondition(tracker.TotalObjectiveCount == 5, message .. " should keep total objective count at 5.")
	assertCondition(tracker.CompletedObjectiveCount == expectedCompleted, message .. " expected completed count " .. tostring(expectedCompleted) .. ", got " .. tostring(tracker.CompletedObjectiveCount) .. ".")
	assertCondition(string.find(tracker.ProgressText or "", "/ 5", 1, true) ~= nil, message .. " should show `/ 5` progress.")
	return tracker
end

local function completeQuest008(PromptBindingService, QuestTrackerService, InventoryService, PlayerDataService, EpisodeService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_008"), "Quest 008 should start after Quest 007.")
	assertQuest008Tracker(QuestTrackerService, player, 0, "Quest 008 tracker at start")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_008_001"), "Quest 008 objective 001 should complete.")
	assertQuest008Tracker(QuestTrackerService, player, 1, "Quest 008 tracker after objective 001")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_008_002"), "Quest 008 objective 002 should complete.")
	assertQuest008Tracker(QuestTrackerService, player, 2, "Quest 008 tracker after objective 002")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_008_003"), "Quest 008 objective 003 should complete.")
	assertQuest008Tracker(QuestTrackerService, player, 3, "Quest 008 tracker after objective 003")
	assertCondition(PlayerDataService.HasRewardBundleClaim(player, "reward_ep01_objective_008_moon_fragment") == true, "Moon Fragment objective reward should be claimed.")
	assertItem(InventoryService, player, "item_ep01_fragment_moon", true, "Quest 008 objective should grant Moon Fragment before finale.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_008_004"), "Quest 008 objective 004 should complete.")
	assertQuest008Tracker(QuestTrackerService, player, 4, "Quest 008 tracker after objective 004")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_008_005"), "Quest 008 objective 005 should complete.")
	assertQuest008Tracker(QuestTrackerService, player, 5, "Quest 008 tracker after objective 005")

	for _, fragmentItemId in ipairs({
		"item_ep01_fragment_universe",
		"item_ep01_fragment_earth",
		"item_ep01_fragment_theos",
		"item_ep01_fragment_rocket",
		"item_ep01_fragment_moon",
	}) do
		assertItem(InventoryService, player, fragmentItemId, true, "All Episode 1 fragments should exist before final completion.")
	end

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_008"), "Quest 008 should complete.")
	assertCondition(PlayerDataService.HasRewardBundleClaim(player, "reward_ep01_main_008") == true, "Final Quest 008 reward should be claimed.")
	assertItem(InventoryService, player, "item_star_core_segment_01", true, "Final reward should grant Star Core Segment 01.")
	for _, futureSegmentItemId in ipairs({
		"item_star_core_segment_02",
		"item_star_core_segment_03",
		"item_star_core_segment_04",
		"item_star_core_segment_05",
	}) do
		assertItem(InventoryService, player, futureSegmentItemId, false, "Final reward should not grant future Star Core segments.")
	end

	local episodeState = EpisodeService.GetPlayerEpisodeState(player, "ep01_lost_star_core")
	assertResultSuccess(episodeState, "Episode 1 state should read after finale.")
	assertCondition(episodeState.Data.IsCompleted == true, "Episode 1 should be marked complete.")
	local tracker = assertTracker(QuestTrackerService, player, "EpisodeCompleted", "Episode complete tracker should read.")
	assertCondition(string.find(tracker.HintText or "", "Star Core Segment 01", 1, true) ~= nil, "Episode complete tracker should mention Star Core Segment 01.")
end

local function assertEarlyStarCoreBridge(services)
	local PlayerDataService = services.PlayerDataService
	local DiscoveryService = services.DiscoveryService
	local PromptBindingService = services.PromptBindingService
	local QuestService = services.QuestService

	local player = makeFakePlayer(948702, "Phase4EEarlyBridge")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Early bridge player data should initialize.")
	local earlyDiscovery = trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display")
	assertResultSuccess(earlyDiscovery, "Star Core Display should record before Quest 001.")
	local discoveryState = DiscoveryService.GetDiscoveryState(player, "disc_ep01_command_star_core_display")
	assertResultSuccess(discoveryState, "Star Core Display discovery state should read.")
	assertCondition(discoveryState.Data.IsFound == true, "Star Core Display discovery should be recorded.")
	local inactiveObjective = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(inactiveObjective, "Quest 001 state should read after early discovery.")
	assertCondition(inactiveObjective.Data.ObjectiveStates.obj_ep01_main_001_004.Completed ~= true, "Early discovery should not complete inactive Quest 001 objective.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start after early discovery.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	local bridgeRetry = trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display")
	assertResultSuccess(bridgeRetry, "Already-recorded Star Core Display should still apply active objective progress.")
	assertCondition(bridgeRetry.Code == "DiscoveryObjectiveProgressApplied", "Star Core bridge retry should use objective-progress success code.")
	local completedObjective = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(completedObjective, "Quest 001 state should read after bridge retry.")
	assertCondition(completedObjective.Data.ObjectiveStates.obj_ep01_main_001_004.Completed == true, "Bridge retry should complete Quest 001 objective 004.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Early bridge player data should release.")
end

function Phase4EFullEP1MvpSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local PlayerFeedbackService = services.PlayerFeedbackService
	local QuestTrackerService = services.QuestTrackerService
	local PromptBindingService = services.PromptBindingService
	local InteractionService = services.InteractionService
	local InteractionVisibilityService = services.InteractionVisibilityService
	local InventoryService = services.InventoryService
	local EpisodeService = services.EpisodeService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase4EFullEP1MvpSmokeTest] Starting Phase 4E full EP1 MVP smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 4E full EP1 MVP smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PlayerFeedbackService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 4E smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 4E smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 4E smoke test.")

	local quest008Definition = require(game:GetService("ReplicatedStorage").Shared.Definitions.QuestDefinitions).quest_ep01_main_008
	assertCondition(#quest008Definition.RequiredObjectiveIds == 5, "Quest 008 must keep exactly five required objectives.")

	assertEarlyStarCoreBridge(services)

	local player = makeFakePlayer(948701, "Phase4EFullEP1Mvp")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 4E player data should initialize.")
	local noQuestTracker = assertTracker(QuestTrackerService, player, "NoQuest", "Fresh player tracker should read.")
	assertCondition(string.find(noQuestTracker.HintText or "", "green", 1, true) ~= nil, "Fresh player tracker should point to green Quest Start marker.")

	local q2CanStart, q2BlockCode = services.QuestService.CanStartQuest(player, "quest_ep01_main_002")
	assertCondition(q2CanStart == false and q2BlockCode == "QuestPrerequisiteMissing", "Quest 002 should require Quest 001 completion.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	local quest001Tracker = assertTracker(QuestTrackerService, player, "ActiveQuest", "Quest 001 tracker should read.")
	assertCondition(quest001Tracker.QuestId == "quest_ep01_main_001", "Tracker should show Quest 001 after start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete.")
	local quest001ProgressTracker = assertTracker(QuestTrackerService, player, "ActiveQuest", "Quest 001 progress tracker should read.")
	assertCondition(quest001ProgressTracker.CompletedObjectiveCount == 1, "Quest 001 tracker should count completed objective.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display"), "Quest 001 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_001"), "Quest 001 should complete.")
	assertCondition(PlayerDataService.HasRewardBundleClaim(player, "reward_ep01_main_001") == true, "Quest 001 reward should be claimed.")

	completeQuest002(PromptBindingService, QuestTrackerService, player)
	completeQuest003(PromptBindingService, InteractionService, InteractionVisibilityService, InventoryService, player)
	local universeBeforeDuplicate = InventoryService.GetItemQuantity(player, "item_ep01_fragment_universe")
	assertResultSuccess(universeBeforeDuplicate, "Universe Fragment quantity before duplicate should read.")
	local duplicateQuest003 = directInteract(InteractionService, player, "interaction_ep01_main_003_003")
	assertResultFailure(duplicateQuest003, "ObjectiveAlreadyCompleted", "Direct Quest 003 duplicate should safely block.")
	local universeAfterDuplicate = InventoryService.GetItemQuantity(player, "item_ep01_fragment_universe")
	assertResultSuccess(universeAfterDuplicate, "Universe Fragment quantity after duplicate should read.")
	assertCondition(universeAfterDuplicate.Data.Quantity == universeBeforeDuplicate.Data.Quantity, "Quest 003 duplicate should not grant duplicate reward.")

	completeQuest004(PromptBindingService, InteractionVisibilityService, InventoryService, player)
	completeQuest005(PromptBindingService, QuestTrackerService, InventoryService, player)
	completeQuest006(PromptBindingService, InteractionService, InventoryService, player)
	completeQuest007(PromptBindingService, player)

	local q8CanStart = services.QuestService.CanStartQuest(player, "quest_ep01_main_008")
	assertCondition(q8CanStart == true, "Quest 008 should become available after Quest 007.")
	completeQuest008(PromptBindingService, QuestTrackerService, InventoryService, PlayerDataService, EpisodeService, player)

	assertResultFailure(directInteract(InteractionService, player, "interaction_complete_ep01_main_008"), "QuestAlreadyCompleted", "Duplicate finale direct processing should be blocked.")
	local sentPayloads = PlayerFeedbackService.GetSentFeedbackForTests(player)
	local sawTrackerPayload = false
	local sawQuestCompletePayload = false
	for _, payload in ipairs(sentPayloads) do
		if payload.Type == "QuestTracker" then
			sawTrackerPayload = true
		elseif payload.Type == "QuestCompleted" then
			sawQuestCompletePayload = true
		end
	end
	assertCondition(sawTrackerPayload == true, "PlayerFeedbackService should emit QuestTracker payloads.")
	assertCondition(sawQuestCompletePayload == true, "PlayerFeedbackService should emit quest completion feedback.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 4E player data should release.")

	print("[ANP Phase4EFullEP1MvpSmokeTest] Phase 4E full EP1 MVP smoke test passed.")
end

return Phase4EFullEP1MvpSmokeTest
