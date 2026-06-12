local RunService = game:GetService("RunService")

local Phase6DEP1FinalMvpRegressionSmokeTest = {}

local FUTURE_SEGMENT_ITEM_IDS = {
	"item_star_core_segment_02",
	"item_star_core_segment_03",
	"item_star_core_segment_04",
	"item_star_core_segment_05",
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase6DEP1FinalMvpRegressionSmokeTest] " .. message, 2)
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
		SourceType = "Phase6DEP1FinalMvpRegressionSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function directInteract(InteractionService, player, interactionId)
	return InteractionService.AttemptInteraction(player, interactionId, {
		SourceType = "Phase6DEP1FinalMvpRegressionSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
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

local function assertHidden(InteractionVisibilityService, player, interactionId, message)
	local visibilityResult = InteractionVisibilityService.GetInteractionState(player, interactionId)
	assertResultSuccess(visibilityResult, message)
	assertCondition(visibilityResult.Data.Visible == false and visibilityResult.Data.Enabled == false, message .. " should be hidden and disabled.")
end

function Phase6DEP1FinalMvpRegressionSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local PlayerFeedbackService = services.PlayerFeedbackService
	local PromptBindingService = services.PromptBindingService
	local InteractionService = services.InteractionService
	local InteractionVisibilityService = services.InteractionVisibilityService
	local QuestTrackerService = services.QuestTrackerService
	local InventoryService = services.InventoryService
	local EpisodeService = services.EpisodeService
	local SaveService = services.SaveService
	local OnboardingService = services.OnboardingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase6DEP1FinalMvpRegressionSmokeTest] Starting Phase 6D EP1 final MVP regression smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 6D EP1 final MVP regression smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PlayerFeedbackService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for final MVP regression.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for final MVP regression.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompt binding should succeed for final MVP regression.")

	local player = makeFakePlayer(960701, "Phase6DFinalMvp")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Final MVP player data should initialize.")

	local noQuestTracker = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(noQuestTracker, "Fresh tracker should build.")
	assertCondition(noQuestTracker.Data.State == "NoQuest", "Fresh player should start with no active quest.")
	assertCondition(OnboardingService.ShouldShowFirstTimeOnboarding(player) == true, "Fresh player should be onboarding eligible.")

	completeQuest001(PromptBindingService, player)
	for questNumber = 2, 7 do
		completeQuest(PromptBindingService, player, questNumber, 4)
	end

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_008"), "Quest 008 should start.")
	local quest008Tracker = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(quest008Tracker, "Quest 008 tracker should build at start.")
	assertCondition(quest008Tracker.Data.TotalObjectiveCount == 5, "Quest 008 should keep five required objectives.")
	assertCondition(string.find(quest008Tracker.Data.ProgressText or "", "/ 5", 1, true) ~= nil, "Quest 008 progress text should include `/ 5`.")

	for objectiveIndex = 1, 5 do
		assertResultSuccess(
			trigger(PromptBindingService, player, "interaction_ep01_main_008_" .. string.format("%03d", objectiveIndex)),
			"Quest 008 objective " .. tostring(objectiveIndex) .. " should complete."
		)
	end

	local quest008CompleteReadyTracker = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(quest008CompleteReadyTracker, "Quest 008 complete-ready tracker should build.")
	assertCondition(quest008CompleteReadyTracker.Data.CompletedObjectiveCount == 5, "Quest 008 should report five completed objectives.")
	assertCondition(quest008CompleteReadyTracker.Data.TotalObjectiveCount == 5, "Quest 008 total should remain five before turn-in.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_008"), "Quest 008 should complete.")

	local episodeState = EpisodeService.GetPlayerEpisodeState(player, "ep01_lost_star_core")
	assertResultSuccess(episodeState, "Episode 1 state should read.")
	assertCondition(episodeState.Data.IsCompleted == true, "Episode 1 should complete.")
	local episodeTracker = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(episodeTracker, "Episode complete tracker should build.")
	assertCondition(episodeTracker.Data.State == "EpisodeCompleted", "Tracker should show EpisodeCompleted after finale.")

	assertCondition(InventoryService.HasItem(player, "item_star_core_segment_01", 1) == true, "Final MVP player should receive Star Core Segment 01.")
	for _, futureSegmentItemId in ipairs(FUTURE_SEGMENT_ITEM_IDS) do
		assertCondition(InventoryService.HasItem(player, futureSegmentItemId, 1) == false, "Final MVP player should not receive `" .. futureSegmentItemId .. "`.")
	end

	assertResultFailure(directInteract(InteractionService, player, "interaction_complete_ep01_main_008"), "QuestAlreadyCompleted", "Duplicate Quest 008 completion should be blocked.")
	assertResultFailure(directInteract(InteractionService, player, "interaction_ep01_main_003_003"), "QuestNotActive", "Completed Quest 003 collectible should not progress again.")
	assertHidden(InteractionVisibilityService, player, "interaction_ep01_main_003_003", "Quest 003 collectible after full progression")
	assertHidden(InteractionVisibilityService, player, "interaction_ep01_main_003_004", "Quest 003 recovery object after full progression")
	assertCondition(OnboardingService.ShouldShowFirstTimeOnboarding(player) == false, "Onboarding should not show after progress exists.")

	local saveResult = SaveService.BuildSave(player)
	assertResultSuccess(saveResult, "Final MVP save payload should build.")
	assertResultSuccess(SaveService.ValidateSavePayload(saveResult.Data), "Final MVP save payload should validate.")
	assertCondition(saveResult.Data.Quests.CompletedQuestIds.quest_ep01_main_008 == true, "Final MVP save should include Quest 008 completion.")
	assertCondition(saveResult.Data.Episodes.CompletedEpisodeIds.ep01_lost_star_core == true, "Final MVP save should include Episode 1 completion.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Final MVP player data should release.")

	print("[ANP Phase6DEP1FinalMvpRegressionSmokeTest] Phase 6D EP1 final MVP regression smoke test passed.")
end

return Phase6DEP1FinalMvpRegressionSmokeTest
