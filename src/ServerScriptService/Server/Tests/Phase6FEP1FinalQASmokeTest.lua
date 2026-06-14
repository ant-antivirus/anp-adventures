local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local Config = Shared:WaitForChild("Config")

local EpisodeDefinitions = require(Definitions.EpisodeDefinitions)
local InteractionDefinitions = require(Definitions.InteractionDefinitions)
local ItemDefinitions = require(Definitions.ItemDefinitions)
local QuestDefinitions = require(Definitions.QuestDefinitions)
local RewardDefinitions = require(Definitions.RewardDefinitions)
local PersistenceConfig = require(Config.PersistenceConfig)

local Phase6FEP1FinalQASmokeTest = {}

local EPISODE_ONE_ID = "ep01_lost_star_core"
local QUEST_IDS = {
	"quest_ep01_main_001",
	"quest_ep01_main_002",
	"quest_ep01_main_003",
	"quest_ep01_main_004",
	"quest_ep01_main_005",
	"quest_ep01_main_006",
	"quest_ep01_main_007",
	"quest_ep01_main_008",
}
local FUTURE_SEGMENT_ITEM_IDS = {
	"item_star_core_segment_02",
	"item_star_core_segment_03",
	"item_star_core_segment_04",
	"item_star_core_segment_05",
}
local TRACKER_FIELDS = {
	"Type",
	"State",
	"QuestTitle",
	"CurrentObjectiveText",
	"ProgressText",
	"HintText",
}
local ONBOARDING_FIELDS = {
	"Type",
	"State",
	"Title",
	"Message",
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase6FEP1FinalQASmokeTest] " .. message, 2)
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
		SourceType = "Phase6FEP1FinalQASmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function containsThai(text)
	if type(text) ~= "string" then
		return false
	end

	for _, codepoint in utf8.codes(text) do
		if codepoint >= 0x0E00 and codepoint <= 0x0E7F then
			return true
		end
	end

	return false
end

local function assertThaiText(text, message)
	assertCondition(containsThai(text), message .. " Expected Thai text, got `" .. tostring(text) .. "`.")
end

local function hasItemGrant(rewardDefinition, itemId)
	for _, itemGrant in ipairs(rewardDefinition.Items or {}) do
		if itemGrant.ItemId == itemId then
			return true
		end
	end

	return false
end

local function getObjectiveRouteInteractionIds(questId, objectiveId)
	local interactionIds = {}
	for interactionId, interactionDefinition in pairs(InteractionDefinitions) do
		if interactionDefinition.QuestId == questId and interactionDefinition.ObjectiveId == objectiveId then
			table.insert(interactionIds, interactionId)
		else
			for _, objectiveProgressId in ipairs(interactionDefinition.ObjectiveProgressIds or {}) do
				if objectiveProgressId == objectiveId then
					table.insert(interactionIds, interactionId)
					break
				end
			end
		end
	end
	table.sort(interactionIds)

	return interactionIds
end

local function assertOnlyEP1ActiveContent()
	assertCondition(EpisodeDefinitions[EPISODE_ONE_ID] ~= nil, "Episode 1 definition should exist.")
	for episodeId in pairs(EpisodeDefinitions) do
		assertCondition(episodeId == EPISODE_ONE_ID, "EP1 should remain the only active episode definition.")
	end
	for questId in pairs(QuestDefinitions) do
		assertCondition(string.find(questId, "ep02", 1, true) == nil, "No active EP2 quest definitions should exist.")
	end
end

local function assertQuestRouteDefinitions()
	for questNumber, questId in ipairs(QUEST_IDS) do
		local paddedQuestNumber = string.format("%03d", questNumber)
		local questDefinition = QuestDefinitions[questId]
		assertCondition(questDefinition ~= nil, "Quest `" .. questId .. "` should exist.")
		assertCondition(InteractionDefinitions["interaction_start_ep01_main_" .. paddedQuestNumber] ~= nil, "Quest " .. paddedQuestNumber .. " start interaction should exist.")
		assertCondition(InteractionDefinitions["interaction_complete_ep01_main_" .. paddedQuestNumber] ~= nil, "Quest " .. paddedQuestNumber .. " complete interaction should exist.")

		for _, objectiveId in ipairs(questDefinition.RequiredObjectiveIds or {}) do
			assertCondition(#getObjectiveRouteInteractionIds(questId, objectiveId) > 0, "Objective `" .. objectiveId .. "` should have a supported interaction route.")
		end
	end

	assertCondition(#QuestDefinitions.quest_ep01_main_008.RequiredObjectiveIds == 5, "Quest 008 should keep five required objectives.")
	assertCondition(InteractionDefinitions.interaction_ep01_main_008_005 ~= nil, "Quest 008 objective 5 interaction should exist.")
end

local function assertRewardSafety()
	local finalReward = RewardDefinitions.reward_ep01_main_008
	assertCondition(finalReward ~= nil, "Quest 008 final reward should exist.")
	assertCondition(ItemDefinitions.item_star_core_segment_01 ~= nil, "Star Core Segment 01 item should exist.")
	assertCondition(hasItemGrant(finalReward, "item_star_core_segment_01"), "Final reward should grant Star Core Segment 01.")
	assertCondition(not hasItemGrant(finalReward, "item_star_core"), "Final reward should not grant complete Star Core.")

	for _, futureSegmentItemId in ipairs(FUTURE_SEGMENT_ITEM_IDS) do
		assertCondition(not hasItemGrant(finalReward, futureSegmentItemId), "Final reward should not grant `" .. futureSegmentItemId .. "`.")
	end
end

local function assertPersistenceDefaultSafety()
	assertCondition(PersistenceConfig.PersistenceMode == "Mock", "PersistenceMode should default to Mock.")
	assertCondition(PersistenceConfig.EnableRealDataStore == false, "Real DataStore should be disabled by default.")
	assertCondition(PersistenceConfig.EnableLoadOnPlayerAdded == false, "Load on player added should be disabled by default.")
	assertCondition(PersistenceConfig.EnableSaveOnPlayerRemoving == false, "Save on player removing should be disabled by default.")
	assertCondition(PersistenceConfig.EnableAutosave == false, "Autosave should be disabled by default.")
	assertCondition(PersistenceConfig.EnableBindToCloseSave == false, "BindToClose save should be disabled by default.")
	assertCondition(PersistenceConfig.ProductionDataStoreConfirm == false, "Production DataStore confirmation should be false by default.")
	assertResultSuccess(PersistenceConfig.Validate(PersistenceConfig), "Default persistence config should validate.")
end

local function assertUIContracts(services)
	local PlayerFeedbackService = services.PlayerFeedbackService
	local QuestTrackerService = services.QuestTrackerService
	local OnboardingService = services.OnboardingService
	local PlayerDataService = services.PlayerDataService
	local PromptBindingService = services.PromptBindingService

	assertResultSuccess(PlayerFeedbackService.Init(), "PlayerFeedbackService should initialize.")
	local feedbackEventResult = PlayerFeedbackService.GetFeedbackEvent()
	assertResultSuccess(feedbackEventResult, "PlayerFeedbackEvent should exist.")
	assertCondition(feedbackEventResult.Data:IsA("RemoteEvent"), "PlayerFeedbackEvent should remain a RemoteEvent.")
	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		assertCondition(not descendant:IsA("Remote" .. "Function"), "No RemoteFunction should exist for final QA.")
	end

	local player = makeFakePlayer(960901, "Phase6FUIContract")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 6F UI contract player should initialize.")

	local onboardingPayload = OnboardingService.BuildWelcomePayload(player)
	for _, fieldName in ipairs(ONBOARDING_FIELDS) do
		assertCondition(onboardingPayload[fieldName] ~= nil, "Onboarding payload should include `" .. fieldName .. "`.")
	end
	assertCondition(onboardingPayload.Type == "Onboarding", "Onboarding Type field should remain stable.")
	assertThaiText(onboardingPayload.Title, "Onboarding title should be Thai.")
	assertThaiText(onboardingPayload.Message, "Onboarding message should be Thai.")

	local freshTracker = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(freshTracker, "Fresh tracker should build.")
	for _, fieldName in ipairs(TRACKER_FIELDS) do
		assertCondition(freshTracker.Data[fieldName] ~= nil, "QuestTracker payload should include `" .. fieldName .. "`.")
	end
	assertCondition(freshTracker.Data.Type == "QuestTracker", "QuestTracker Type field should remain stable.")
	assertCondition(type(freshTracker.Data.QuestTitle) == "string" and freshTracker.Data.QuestTitle ~= "", "Fresh tracker title should include a safe display title.")
	assertThaiText(freshTracker.Data.ProgressText, "Fresh tracker progress should be Thai.")
	assertThaiText(freshTracker.Data.CurrentObjectiveText, "Fresh tracker objective should be Thai.")
	assertThaiText(freshTracker.Data.HintText, "Fresh tracker hint should be Thai.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start for final QA tracker check.")
	local questTracker = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(questTracker, "Quest 001 tracker should build.")
	assertCondition(questTracker.Data.QuestId == "quest_ep01_main_001", "QuestTracker QuestId should remain stable.")
	assertThaiText(questTracker.Data.QuestTitle, "Quest 001 tracker title should be Thai.")
	assertThaiText(questTracker.Data.CurrentObjectiveText, "Quest 001 tracker objective should be Thai.")

	local episodeFeedback = PlayerFeedbackService.SendEpisodeCompleted(player, "ep01_lost_star_core")
	assertResultSuccess(episodeFeedback, "EpisodeCompleted feedback should send.")
	assertCondition(episodeFeedback.Data.Type == "EpisodeCompleted", "EpisodeCompleted Type should remain stable.")
	assertThaiText(episodeFeedback.Data.Title, "EpisodeCompleted title should be Thai.")
	assertThaiText(episodeFeedback.Data.Message, "EpisodeCompleted message should be Thai.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 6F UI contract player should release.")
end

local function assertWorldPromptReadiness(services)
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService
	local PromptBindingService = services.PromptBindingService

	PromptBindingService.ResetForTests()
	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for final QA.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for final QA.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompt binding should succeed for final QA.")

	for questNumber, questId in ipairs(QUEST_IDS) do
		local paddedQuestNumber = string.format("%03d", questNumber)
		assertResultSuccess(WorldRegistryService.GetInteractionPoint("interaction_start_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " start marker should exist.")
		assertResultSuccess(WorldRegistryService.GetInteractionPoint("interaction_complete_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " complete marker should exist.")
		for _, objectiveId in ipairs(QuestDefinitions[questId].RequiredObjectiveIds or {}) do
			local routeInteractionIds = getObjectiveRouteInteractionIds(questId, objectiveId)
			local hasWorldHost = false
			for _, interactionId in ipairs(routeInteractionIds) do
				local definition = InteractionDefinitions[interactionId]
				local hostResult
				if definition.Type == "Discovery" then
					hostResult = WorldRegistryService.GetDiscoveryPoint(definition.DiscoveryId)
					if not hostResult.Success then
						hostResult = WorldRegistryService.GetInteractionPoint(interactionId)
					end
				else
					hostResult = WorldRegistryService.GetInteractionPoint(interactionId)
				end
				if hostResult.Success then
					hasWorldHost = true
					break
				end
			end
			assertCondition(hasWorldHost, "Objective `" .. objectiveId .. "` should have a registered world prompt host.")
		end
	end
end

function Phase6FEP1FinalQASmokeTest.Run(services)
	print("[ANP Phase6FEP1FinalQASmokeTest] Starting Phase 6F EP1 final QA smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 6F EP1 final QA smoke test must run in Studio only.")

	services.PlayerDataService.ResetForTests()
	services.PlayerFeedbackService.ResetForTests()
	services.PromptBindingService.ResetForTests()

	assertOnlyEP1ActiveContent()
	assertQuestRouteDefinitions()
	assertRewardSafety()
	assertPersistenceDefaultSafety()
	assertWorldPromptReadiness(services)
	assertUIContracts(services)

	print("[ANP Phase6FEP1FinalQASmokeTest] Phase 6F EP1 final QA smoke test passed.")
end

return Phase6FEP1FinalQASmokeTest
