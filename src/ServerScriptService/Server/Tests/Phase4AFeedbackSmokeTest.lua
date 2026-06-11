local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Phase4AFeedbackSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase4AFeedbackSmokeTest] " .. message, 2)
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

local function getFeedbackTypes(PlayerFeedbackService, player)
	local feedbackTypes = {}
	for _, payload in ipairs(PlayerFeedbackService.GetSentFeedbackForTests(player)) do
		feedbackTypes[payload.Type] = true
	end

	return feedbackTypes
end

local function assertFeedbackType(PlayerFeedbackService, player, feedbackType, message)
	local feedbackTypes = getFeedbackTypes(PlayerFeedbackService, player)
	assertCondition(feedbackTypes[feedbackType] == true, message .. " Missing feedback type `" .. feedbackType .. "`.")
end

local function trigger(PromptBindingService, player, interactionId)
	return PromptBindingService.SimulatePromptTrigger(player, interactionId, {
		SourceType = "Phase4AFeedbackSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function completeQuest001(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should progress.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should progress.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should progress.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display"), "Quest 001 discovery bridge should progress.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_001"), "Quest 001 should complete.")
end

function Phase4AFeedbackSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local PlayerFeedbackService = services.PlayerFeedbackService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase4AFeedbackSmokeTest] Starting Phase 4A feedback smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 4A feedback smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PlayerFeedbackService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(PlayerFeedbackService.Init(), "PlayerFeedbackService should initialize.")
	local eventResult = PlayerFeedbackService.GetFeedbackEvent()
	assertResultSuccess(eventResult, "Feedback RemoteEvent should exist.")
	assertCondition(eventResult.Data:IsA("RemoteEvent"), "Feedback event should be a RemoteEvent.")
	assertCondition(eventResult.Data.Parent == ReplicatedStorage:WaitForChild("ANP_Remotes"), "Feedback event should live under ANP_Remotes.")

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 4A smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 4A smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 4A smoke test.")

	local directPlayer = makeFakePlayer(948401, "Phase4AFeedbackDirect")
	assertResultSuccess(PlayerDataService.InitPlayer(directPlayer), "Direct feedback player should initialize.")
	local beforeSnapshot = PlayerDataService.GetSnapshot(directPlayer)
	assertResultSuccess(beforeSnapshot, "Direct feedback snapshot should read before feedback sends.")

	assertResultSuccess(PlayerFeedbackService.SendHint(directPlayer, "Hint message.", { Title = "Guide" }), "Hint feedback should send.")
	assertResultSuccess(PlayerFeedbackService.SendBlocked(directPlayer, "Blocked message."), "Blocked feedback should send.")
	assertResultSuccess(PlayerFeedbackService.SendQuestStarted(directPlayer, "quest_test"), "QuestStarted feedback should send.")
	assertResultSuccess(PlayerFeedbackService.SendObjectiveUpdated(directPlayer, "quest_test", "objective_test"), "ObjectiveUpdated feedback should send.")
	assertResultSuccess(PlayerFeedbackService.SendQuestCompleted(directPlayer, "quest_test"), "QuestCompleted feedback should send.")
	assertResultSuccess(PlayerFeedbackService.SendRewardReceived(directPlayer, "reward_test"), "RewardReceived feedback should send.")
	assertResultSuccess(PlayerFeedbackService.SendEpisodeCompleted(directPlayer, "episode_test"), "EpisodeCompleted feedback should send.")

	assertFeedbackType(PlayerFeedbackService, directPlayer, "Hint", "Direct send should record Hint.")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "Blocked", "Direct send should record Blocked.")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "QuestStarted", "Direct send should record QuestStarted.")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "ObjectiveUpdated", "Direct send should record ObjectiveUpdated.")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "QuestCompleted", "Direct send should record QuestCompleted.")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "RewardReceived", "Direct send should record RewardReceived.")
	assertFeedbackType(PlayerFeedbackService, directPlayer, "EpisodeCompleted", "Direct send should record EpisodeCompleted.")

	local afterSnapshot = PlayerDataService.GetSnapshot(directPlayer)
	assertResultSuccess(afterSnapshot, "Direct feedback snapshot should read after feedback sends.")
	assertCondition(next(beforeSnapshot.Data.Quests.ActiveQuestIds) == nil and next(afterSnapshot.Data.Quests.ActiveQuestIds) == nil, "Feedback service itself should not mutate active quest state.")
	assertCondition(next(beforeSnapshot.Data.Quests.CompletedQuestIds) == nil and next(afterSnapshot.Data.Quests.CompletedQuestIds) == nil, "Feedback service itself should not mutate completed quest state.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(directPlayer), "Direct feedback player should release.")

	local interactionPlayer = makeFakePlayer(948402, "Phase4AFeedbackInteraction")
	assertResultSuccess(PlayerDataService.InitPlayer(interactionPlayer), "Interaction feedback player should initialize.")

	local blockedResult = trigger(PromptBindingService, interactionPlayer, "interaction_start_ep01_main_003")
	assertCondition(blockedResult.Success == false and blockedResult.Data and blockedResult.Data.HintText ~= nil, "Blocked interaction should return HintText.")
	assertFeedbackType(PlayerFeedbackService, interactionPlayer, "Blocked", "Blocked interaction should send Blocked feedback.")

	local guideResult = trigger(PromptBindingService, interactionPlayer, "interaction_npc_proton_guide")
	assertResultSuccess(guideResult, "NPCGuide interaction should succeed.")
	assertFeedbackType(PlayerFeedbackService, interactionPlayer, "Hint", "NPCGuide should send Hint feedback.")

	completeQuest001(PromptBindingService, interactionPlayer)
	assertFeedbackType(PlayerFeedbackService, interactionPlayer, "QuestStarted", "Quest start should send QuestStarted feedback.")
	assertFeedbackType(PlayerFeedbackService, interactionPlayer, "ObjectiveUpdated", "Objective completion should send ObjectiveUpdated feedback.")
	assertFeedbackType(PlayerFeedbackService, interactionPlayer, "QuestCompleted", "Quest completion should send QuestCompleted feedback.")
	assertFeedbackType(PlayerFeedbackService, interactionPlayer, "RewardReceived", "Reward grant should send RewardReceived feedback.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(interactionPlayer), "Interaction feedback player should release.")

	print("[ANP Phase4AFeedbackSmokeTest] Phase 4A feedback smoke test passed.")
end

return Phase4AFeedbackSmokeTest
