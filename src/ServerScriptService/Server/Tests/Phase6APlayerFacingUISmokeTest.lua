local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Phase6APlayerFacingUISmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase6APlayerFacingUISmokeTest] " .. message, 2)
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
	local triggerResult = PromptBindingService.SimulatePromptTrigger(player, interactionId, {
		SourceType = "Phase6APlayerFacingUISmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
	task.wait()
	return triggerResult
end

local function assertFeedbackType(PlayerFeedbackService, player, feedbackType)
	for _, payload in ipairs(PlayerFeedbackService.GetSentFeedbackForTests(player)) do
		if payload.Type == feedbackType then
			return payload
		end
	end

	error("[ANP Phase6APlayerFacingUISmokeTest] Missing feedback type `" .. feedbackType .. "`.", 2)
end

local function assertTrackerPayload(payload, message)
	assertCondition(type(payload) == "table", message .. " Tracker payload should be a table.")
	assertCondition(payload.Type == "QuestTracker", message .. " Tracker payload should have Type QuestTracker.")
	assertCondition(type(payload.State) == "string", message .. " Tracker payload should include State.")
	assertCondition(type(payload.ProgressText) == "string", message .. " Tracker payload should include ProgressText.")
	assertCondition(type(payload.QuestTitle) == "string" or type(payload.QuestId) == "string", message .. " Tracker payload should include QuestTitle or QuestId.")
	assertCondition(type(payload.CurrentObjectiveText) == "string", message .. " Tracker payload should include CurrentObjectiveText.")
	assertCondition(type(payload.HintText) == "string", message .. " Tracker payload should include HintText.")
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

local function completeThroughQuest007(PromptBindingService, player)
	completeQuest001(PromptBindingService, player)
	completeQuest(PromptBindingService, player, 2, 4)
	completeQuest(PromptBindingService, player, 3, 4)
	completeQuest(PromptBindingService, player, 4, 4)
	completeQuest(PromptBindingService, player, 5, 4)
	completeQuest(PromptBindingService, player, 6, 4)
	completeQuest(PromptBindingService, player, 7, 4)
end

function Phase6APlayerFacingUISmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local PlayerFeedbackService = services.PlayerFeedbackService
	local QuestTrackerService = services.QuestTrackerService
	local PromptBindingService = services.PromptBindingService
	local InventoryService = services.InventoryService
	local EpisodeService = services.EpisodeService
	local SaveService = services.SaveService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase6APlayerFacingUISmokeTest] Starting Phase 6A player-facing UI smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 6A player-facing UI smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PlayerFeedbackService.ResetForTests()
	PromptBindingService.ResetForTests()
	SaveService.ResetForTests()

	assertResultSuccess(PlayerFeedbackService.Init(), "PlayerFeedbackService should initialize.")
	local eventResult = PlayerFeedbackService.GetFeedbackEvent()
	assertResultSuccess(eventResult, "PlayerFeedbackEvent should exist.")
	assertCondition(eventResult.Data:IsA("RemoteEvent"), "PlayerFeedbackEvent should be a RemoteEvent.")
	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		assertCondition(not descendant:IsA("Remote" .. "Function"), "Phase 6A should not create request/response remotes.")
	end

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 6A smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 6A smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 6A smoke test.")

	local directPlayer = makeFakePlayer(956101, "Phase6AUIDirect")
	assertResultSuccess(PlayerDataService.InitPlayer(directPlayer), "Direct UI player should initialize.")
	local beforeSnapshot = PlayerDataService.GetSnapshot(directPlayer)
	assertResultSuccess(beforeSnapshot, "Direct UI player snapshot should read before payload sends.")
	assertResultSuccess(PlayerFeedbackService.SendHint(directPlayer, "Hint message.", { Title = "Guide" }), "Hint payload should send.")
	assertResultSuccess(PlayerFeedbackService.SendBlocked(directPlayer, "Blocked message."), "Blocked payload should send.")
	assertResultSuccess(PlayerFeedbackService.SendQuestStarted(directPlayer, "quest_test"), "QuestStarted payload should send.")
	assertResultSuccess(PlayerFeedbackService.SendObjectiveUpdated(directPlayer, "quest_test", "objective_test"), "ObjectiveUpdated payload should send.")
	assertResultSuccess(PlayerFeedbackService.SendQuestCompleted(directPlayer, "quest_test"), "QuestCompleted payload should send.")
	assertResultSuccess(PlayerFeedbackService.SendRewardReceived(directPlayer, "reward_test"), "RewardReceived payload should send.")
	assertResultSuccess(PlayerFeedbackService.SendEpisodeCompleted(directPlayer, "episode_test"), "EpisodeCompleted payload should send.")
	local trackerResult = QuestTrackerService.BuildTrackerState(directPlayer)
	assertResultSuccess(trackerResult, "Direct UI player tracker should build.")
	assertTrackerPayload(trackerResult.Data, "Direct UI player")
	assertResultSuccess(PlayerFeedbackService.SendQuestTracker(directPlayer, trackerResult.Data), "QuestTracker payload should send.")

	assertFeedbackType(PlayerFeedbackService, directPlayer, "Hint")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "Blocked")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "QuestStarted")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "ObjectiveUpdated")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "QuestCompleted")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "RewardReceived")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "EpisodeCompleted")
	assertTrackerPayload(assertFeedbackType(PlayerFeedbackService, directPlayer, "QuestTracker"), "Recorded direct UI")

	local afterSnapshot = PlayerDataService.GetSnapshot(directPlayer)
	assertResultSuccess(afterSnapshot, "Direct UI player snapshot should read after payload sends.")
	assertCondition(next(beforeSnapshot.Data.Quests.ActiveQuestIds) == nil and next(afterSnapshot.Data.Quests.ActiveQuestIds) == nil, "Display payloads should not mutate active quest state.")
	assertCondition(next(beforeSnapshot.Data.Quests.CompletedQuestIds) == nil and next(afterSnapshot.Data.Quests.CompletedQuestIds) == nil, "Display payloads should not mutate completed quest state.")
	assertCondition(InventoryService.HasItem(directPlayer, "item_star_core_segment_01", 1) == false, "Display payloads should not grant Star Core items.")
	local episodeState = EpisodeService.GetPlayerEpisodeState(directPlayer, "ep01_lost_star_core")
	assertResultSuccess(episodeState, "Episode state should read after display payloads.")
	assertCondition(episodeState.Data.IsCompleted ~= true, "Display payloads should not complete episodes.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(directPlayer), "Direct UI player should release.")

	local q8Player = makeFakePlayer(956102, "Phase6AQuest008Tracker")
	assertResultSuccess(PlayerDataService.InitPlayer(q8Player), "Quest 008 tracker player should initialize.")
	completeThroughQuest007(PromptBindingService, q8Player)
	assertResultSuccess(trigger(PromptBindingService, q8Player, "interaction_start_ep01_main_008"), "Quest 008 should start.")
	local q8TrackerResult = QuestTrackerService.BuildTrackerState(q8Player)
	assertResultSuccess(q8TrackerResult, "Quest 008 tracker should build.")
	assertTrackerPayload(q8TrackerResult.Data, "Quest 008")
	assertCondition(q8TrackerResult.Data.QuestId == "quest_ep01_main_008", "Quest 008 tracker should reference Quest 008.")
	assertCondition(q8TrackerResult.Data.TotalObjectiveCount == 5, "Quest 008 tracker should use five total objectives.")
	assertCondition(string.find(q8TrackerResult.Data.ProgressText, "/ 5", 1, true) ~= nil, "Quest 008 ProgressText should contain `/ 5`.")
	assertResultSuccess(PlayerFeedbackService.SendQuestTracker(q8Player, q8TrackerResult.Data), "Quest 008 tracker payload should send.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(q8Player), "Quest 008 tracker player should release.")

	print("[ANP Phase6APlayerFacingUISmokeTest] Phase 6A player-facing UI smoke test passed.")
end

return Phase6APlayerFacingUISmokeTest
