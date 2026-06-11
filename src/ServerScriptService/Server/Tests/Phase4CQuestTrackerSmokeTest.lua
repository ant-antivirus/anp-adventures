local RunService = game:GetService("RunService")

local Phase4CQuestTrackerSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase4CQuestTrackerSmokeTest] " .. message, 2)
	end
end

local function assertResultSuccess(serviceResult, message)
	assertCondition(serviceResult and serviceResult.Success == true, message .. " Code: " .. tostring(serviceResult and serviceResult.Code))
end

local function makeFakePlayer(userId, name)
	return {
		UserId = userId,
		Name = name,
	}
end

local function trigger(PromptBindingService, player, interactionId)
	return PromptBindingService.SimulatePromptTrigger(player, interactionId, {
		SourceType = "Phase4CQuestTrackerSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function getLastTrackerPayload(PlayerFeedbackService, player)
	local lastTrackerPayload = nil
	for _, payload in ipairs(PlayerFeedbackService.GetSentFeedbackForTests(player)) do
		if payload.Type == "QuestTracker" then
			lastTrackerPayload = payload
		end
	end

	return lastTrackerPayload
end

local function assertTrackerState(QuestTrackerService, player, expectedState, message)
	local trackerResult = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(trackerResult, message)
	assertCondition(trackerResult.Data.Type == "QuestTracker", message .. " should build a QuestTracker payload.")
	assertCondition(trackerResult.Data.State == expectedState, message .. " Expected `" .. expectedState .. "`, got `" .. tostring(trackerResult.Data.State) .. "`.")
	return trackerResult.Data
end

local function completeQuest001(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display"), "Quest 001 bridge objective should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_001"), "Quest 001 should complete.")
end

local function completeQuest002(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_002"), "Quest 002 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_001"), "Quest 002 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_002"), "Quest 002 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_003"), "Quest 002 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_004"), "Quest 002 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_002"), "Quest 002 should complete.")
end

local function completeQuest003(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_003"), "Quest 003 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_001"), "Quest 003 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_002"), "Quest 003 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_003"), "Quest 003 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_004"), "Quest 003 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_003"), "Quest 003 should complete.")
end

local function completeQuest004(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_004"), "Quest 004 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_004_001"), "Quest 004 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_004_002"), "Quest 004 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_004_003"), "Quest 004 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_004_004"), "Quest 004 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_004"), "Quest 004 should complete.")
end

local function completeQuest005(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_005"), "Quest 005 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_005_001"), "Quest 005 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_005_002"), "Quest 005 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_005_003"), "Quest 005 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_005_004"), "Quest 005 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_005"), "Quest 005 should complete.")
end

local function completeQuest006(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_006"), "Quest 006 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_006_001"), "Quest 006 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_006_002"), "Quest 006 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_006_003"), "Quest 006 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_006_004"), "Quest 006 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_006"), "Quest 006 should complete.")
end

local function completeQuest007(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_007"), "Quest 007 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_007_001"), "Quest 007 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_007_002"), "Quest 007 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_007_003"), "Quest 007 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_007_004"), "Quest 007 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_007"), "Quest 007 should complete.")
end

local function assertQuest008TrackerCount(QuestTrackerService, player, expectedCompletedCount, message)
	local tracker = assertTrackerState(QuestTrackerService, player, "ActiveQuest", message)
	assertCondition(tracker.QuestId == "quest_ep01_main_008", message .. " should track Quest 008.")
	assertCondition(tracker.TotalObjectiveCount == 5, message .. " should keep Quest 008 total at 5.")
	assertCondition(tracker.CompletedObjectiveCount == expectedCompletedCount, message .. " expected completed count " .. tostring(expectedCompletedCount) .. ", got " .. tostring(tracker.CompletedObjectiveCount) .. ".")
	assertCondition(string.find(tracker.ProgressText or "", "/ 5", 1, true) ~= nil, message .. " should display `/ 5` in ProgressText.")
	return tracker
end

local function completeQuest008(PromptBindingService, QuestTrackerService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_008"), "Quest 008 should start.")
	assertQuest008TrackerCount(QuestTrackerService, player, 0, "Quest 008 tracker should start at 0 / 5.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_008_001"), "Quest 008 objective 001 should complete.")
	assertQuest008TrackerCount(QuestTrackerService, player, 1, "Quest 008 tracker should stay at total 5 after objective 001.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_008_002"), "Quest 008 objective 002 should complete.")
	assertQuest008TrackerCount(QuestTrackerService, player, 2, "Quest 008 tracker should stay at total 5 after objective 002.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_008_003"), "Quest 008 objective 003 should complete.")
	assertQuest008TrackerCount(QuestTrackerService, player, 3, "Quest 008 tracker should stay at total 5 after objective 003.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_008_004"), "Quest 008 objective 004 should complete.")
	assertQuest008TrackerCount(QuestTrackerService, player, 4, "Quest 008 tracker should stay at total 5 after objective 004.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_008_005"), "Quest 008 objective 005 should complete.")
	assertQuest008TrackerCount(QuestTrackerService, player, 5, "Quest 008 tracker should end at 5 / 5 before turn-in.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_008"), "Quest 008 should complete.")
end

function Phase4CQuestTrackerSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local PlayerFeedbackService = services.PlayerFeedbackService
	local QuestTrackerService = services.QuestTrackerService
	local PromptBindingService = services.PromptBindingService
	local InteractionVisibilityService = services.InteractionVisibilityService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase4CQuestTrackerSmokeTest] Starting Phase 4C quest tracker smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 4C quest tracker smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PlayerFeedbackService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 4C smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 4C smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 4C smoke test.")

	local player = makeFakePlayer(948601, "Phase4CQuestTracker")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 4C player data should initialize.")

	local noQuestTracker = assertTrackerState(QuestTrackerService, player, "NoQuest", "Fresh player tracker should read.")
	assertCondition(string.find(noQuestTracker.HintText or "", "green", 1, true) ~= nil, "NoQuest tracker should suggest a green Quest Start marker.")
	local beforeTrackerSendSnapshot = PlayerDataService.GetSnapshot(player)
	assertResultSuccess(beforeTrackerSendSnapshot, "Snapshot before tracker send should read.")
	assertResultSuccess(QuestTrackerService.SendTrackerUpdate(player), "Quest tracker payload should send.")
	local sentTracker = getLastTrackerPayload(PlayerFeedbackService, player)
	assertCondition(sentTracker and sentTracker.Type == "QuestTracker", "Quest tracker feedback payload should be recorded.")
	local afterTrackerSendSnapshot = PlayerDataService.GetSnapshot(player)
	assertResultSuccess(afterTrackerSendSnapshot, "Snapshot after tracker send should read.")
	assertCondition(next(beforeTrackerSendSnapshot.Data.Quests.ActiveQuestIds) == nil and next(afterTrackerSendSnapshot.Data.Quests.ActiveQuestIds) == nil, "Quest tracker send should not mutate active quests.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	local quest001Tracker = assertTrackerState(QuestTrackerService, player, "ActiveQuest", "Quest 001 active tracker should read.")
	assertCondition(quest001Tracker.QuestTitle ~= nil and quest001Tracker.QuestTitle ~= "", "Quest 001 tracker should include title.")
	assertCondition(quest001Tracker.CurrentObjectiveId == "obj_ep01_main_001_001", "Quest 001 tracker should show first objective.")
	assertCondition(quest001Tracker.CompletedObjectiveCount == 0, "Quest 001 tracker should begin at 0 completed objectives.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 first objective should complete.")
	local updatedQuest001Tracker = assertTrackerState(QuestTrackerService, player, "ActiveQuest", "Quest 001 updated tracker should read.")
	assertCondition(updatedQuest001Tracker.CompletedObjectiveCount == 1, "Quest 001 tracker should count one completed objective.")
	assertCondition(updatedQuest001Tracker.CurrentObjectiveId == "obj_ep01_main_001_002", "Quest 001 tracker should advance to objective 002.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display"), "Quest 001 Star Core objective should complete.")
	local completeReadyTracker = assertTrackerState(QuestTrackerService, player, "ActiveQuest", "Quest 001 complete-ready tracker should read.")
	assertCondition(string.find(completeReadyTracker.HintText or "", "cyan", 1, true) ~= nil, "Quest complete-ready tracker should point to cyan marker.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_001"), "Quest 001 should complete.")
	local afterQuest001Tracker = assertTrackerState(QuestTrackerService, player, "QuestCompleted", "After Quest 001 tracker should read.")
	assertCondition(afterQuest001Tracker.CurrentObjectiveId == nil, "Completed tracker should not show stale objective id.")
	assertCondition(string.find(afterQuest001Tracker.HintText or "", "green", 1, true) ~= nil, "Completed tracker should guide to next green marker.")

	completeQuest002(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_003"), "Quest 003 should start.")
	local quest003Tracker = assertTrackerState(QuestTrackerService, player, "ActiveQuest", "Quest 003 tracker should read.")
	assertCondition(quest003Tracker.CurrentObjectiveId == "obj_ep01_main_003_001", "Quest 003 tracker should not skip to dependency-gated objective.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_001"), "Quest 003 objective 001 should complete.")
	local quest003FlexibleTracker = assertTrackerState(QuestTrackerService, player, "ActiveQuest", "Quest 003 flexible tracker should read.")
	assertCondition(quest003FlexibleTracker.CurrentObjectiveId == "obj_ep01_main_003_002", "Quest 003 tracker should show available prerequisite before dependent objective.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_002"), "Quest 003 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_003"), "Quest 003 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_004"), "Quest 003 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_003"), "Quest 003 should complete.")

	local hiddenQuest003State = InteractionVisibilityService.GetInteractionState(player, "interaction_ep01_main_003_003")
	assertResultSuccess(hiddenQuest003State, "Quest 003 completed object state should read.")
	assertCondition(hiddenQuest003State.Data.Visible == false and hiddenQuest003State.Data.Enabled == false, "Quest 003 completed collectible prompt should remain hidden.")

	completeQuest004(PromptBindingService, player)
	completeQuest005(PromptBindingService, player)
	completeQuest006(PromptBindingService, player)
	completeQuest007(PromptBindingService, player)
	completeQuest008(PromptBindingService, QuestTrackerService, player)
	local episodeCompleteTracker = assertTrackerState(QuestTrackerService, player, "EpisodeCompleted", "Episode completed tracker should read.")
	assertCondition(string.find(episodeCompleteTracker.HintText or "", "Star Core Segment 01", 1, true) ~= nil, "Episode complete tracker should mention Star Core Segment 01.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 4C player data should release.")

	print("[ANP Phase4CQuestTrackerSmokeTest] Phase 4C quest tracker smoke test passed.")
end

return Phase4CQuestTrackerSmokeTest
