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
local SaveSchema = require(Definitions.SaveSchema)
local LocalizationConfig = require(Config.LocalizationConfig)
local PersistenceConfig = require(Config.PersistenceConfig)

local Phase6GEP1ReleaseCandidateSmokeTest = {}

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

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase6GEP1ReleaseCandidateSmokeTest] " .. message, 2)
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
		SourceType = "Phase6GEP1ReleaseCandidateSmokeTest",
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
	for questNumber = 2, 7 do
		completeQuest(PromptBindingService, player, questNumber, 4)
	end
	completeQuest(PromptBindingService, player, 8, 5)
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
	return interactionIds
end

local function assertRuntimeDefaults()
	assertCondition(LocalizationConfig.DefaultLocale == "th-TH", "Thai should remain the default player-facing locale.")
	assertCondition(PersistenceConfig.PersistenceMode == "Mock", "PersistenceMode should default to Mock.")
	assertCondition(PersistenceConfig.EnableRealDataStore == false, "Real DataStore should be disabled by default.")
	assertCondition(PersistenceConfig.EnableLoadOnPlayerAdded == false, "Load on player added should be disabled by default.")
	assertCondition(PersistenceConfig.EnableSaveOnPlayerRemoving == false, "Save on player removing should be disabled by default.")
	assertCondition(PersistenceConfig.EnableAutosave == false, "Autosave should be disabled by default.")
	assertCondition(PersistenceConfig.EnableBindToCloseSave == false, "BindToClose save should be disabled by default.")
	assertCondition(PersistenceConfig.RequirePilotCanaryUserId == true, "Studio pilot should require canary user by default.")
	assertCondition(#PersistenceConfig.PilotCanaryUserIds == 0, "Pilot canary list should be empty by default.")
	assertCondition(PersistenceConfig.ProductionDataStoreConfirm == false, "Production DataStore confirmation should be blocked by default.")
	assertResultSuccess(PersistenceConfig.Validate(PersistenceConfig), "Default persistence config should validate.")

	local productionValidation = PersistenceConfig.Validate({
		PersistenceMode = "ProductionDataStore",
		EnableRealDataStore = true,
		AllowProductionDataStore = false,
		ProductionDataStoreConfirm = false,
	})
	assertCondition(productionValidation.Success == false, "Production DataStore mode should be blocked without explicit confirmation.")
end

local function assertEP1Content()
	assertCondition(EpisodeDefinitions[EPISODE_ONE_ID] ~= nil, "Episode 1 should exist.")
	for episodeId in pairs(EpisodeDefinitions) do
		assertCondition(episodeId == EPISODE_ONE_ID, "EP1 should remain the only active episode.")
	end
	assertCondition(#EpisodeDefinitions[EPISODE_ONE_ID].QuestIds == 8, "Episode 1 should keep eight quests.")

	for questNumber, questId in ipairs(QUEST_IDS) do
		local paddedQuestNumber = string.format("%03d", questNumber)
		local questDefinition = QuestDefinitions[questId]
		assertCondition(questDefinition ~= nil, "Quest `" .. questId .. "` should exist.")
		assertCondition(InteractionDefinitions["interaction_start_ep01_main_" .. paddedQuestNumber] ~= nil, "Quest " .. paddedQuestNumber .. " start interaction should exist.")
		assertCondition(InteractionDefinitions["interaction_complete_ep01_main_" .. paddedQuestNumber] ~= nil, "Quest " .. paddedQuestNumber .. " complete interaction should exist.")
		for _, objectiveId in ipairs(questDefinition.RequiredObjectiveIds or {}) do
			assertCondition(#getObjectiveRouteInteractionIds(questId, objectiveId) > 0, "Required objective `" .. objectiveId .. "` should have a route.")
		end
	end

	assertCondition(#QuestDefinitions.quest_ep01_main_008.RequiredObjectiveIds == 5, "Quest 008 should have exactly five required objectives.")
	assertCondition(InteractionDefinitions.interaction_ep01_main_008_005 ~= nil, "Quest 008 objective 5 interaction should exist.")
	for questId in pairs(QuestDefinitions) do
		assertCondition(string.find(questId, "ep02", 1, true) == nil, "No active EP2 quest definitions should exist.")
	end
end

local function assertRewardSafety()
	local finalReward = RewardDefinitions.reward_ep01_main_008
	assertCondition(finalReward ~= nil, "Quest 008 final reward should exist.")
	assertCondition(ItemDefinitions.item_star_core_segment_01 ~= nil, "Star Core Segment 01 item should exist.")
	assertCondition(hasItemGrant(finalReward, "item_star_core_segment_01"), "Final reward should grant Star Core Segment 01.")
	assertCondition(not hasItemGrant(finalReward, "item_star_core"), "Final reward should not grant a complete Star Core.")
	for _, futureSegmentItemId in ipairs(FUTURE_SEGMENT_ITEM_IDS) do
		assertCondition(not hasItemGrant(finalReward, futureSegmentItemId), "Final reward should not grant `" .. futureSegmentItemId .. "`.")
	end
end

local function assertDisplayContracts(services)
	local PlayerDataService = services.PlayerDataService
	local PlayerFeedbackService = services.PlayerFeedbackService
	local QuestTrackerService = services.QuestTrackerService
	local OnboardingService = services.OnboardingService
	local PromptBindingService = services.PromptBindingService

	local eventResult = PlayerFeedbackService.GetFeedbackEvent()
	assertResultSuccess(eventResult, "PlayerFeedbackEvent should exist.")
	assertCondition(eventResult.Data:IsA("RemoteEvent"), "PlayerFeedbackEvent should remain a RemoteEvent.")
	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		assertCondition(not descendant:IsA("Remote" .. "Function"), "Release candidate should not create RemoteFunction.")
	end

	local player = makeFakePlayer(961001, "Phase6GDisplay")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "RC display player should initialize.")

	local welcomePayload = OnboardingService.BuildWelcomePayload(player)
	assertCondition(welcomePayload.Type == "Onboarding", "Onboarding payload Type should remain stable.")
	assertThaiText(welcomePayload.Title, "Onboarding title should be Thai-ready.")
	assertThaiText(welcomePayload.Message, "Onboarding message should be Thai-ready.")

	local freshTracker = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(freshTracker, "Fresh tracker should build.")
	assertCondition(freshTracker.Data.Type == "QuestTracker", "QuestTracker Type should remain stable.")
	assertCondition(type(freshTracker.Data.QuestTitle) == "string" and freshTracker.Data.QuestTitle ~= "", "Fresh QuestTracker should include a safe display title.")
	assertThaiText(freshTracker.Data.ProgressText, "Fresh QuestTracker progress should be Thai-ready.")
	assertThaiText(freshTracker.Data.CurrentObjectiveText, "Fresh QuestTracker objective should be Thai-ready.")
	assertThaiText(freshTracker.Data.HintText, "Fresh QuestTracker hint should be Thai-ready.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start for RC tracker.")
	local questTracker = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(questTracker, "Quest 001 tracker should build.")
	assertCondition(questTracker.Data.QuestId == "quest_ep01_main_001", "QuestTracker QuestId should remain stable.")
	assertThaiText(questTracker.Data.CurrentObjectiveText, "Quest 001 objective tracker should be Thai-ready.")

	local episodeFeedback = PlayerFeedbackService.SendEpisodeCompleted(player, EPISODE_ONE_ID)
	assertResultSuccess(episodeFeedback, "Episode complete feedback should send.")
	assertCondition(episodeFeedback.Data.Type == "EpisodeCompleted", "EpisodeCompleted payload Type should remain stable.")
	assertThaiText(episodeFeedback.Data.Title, "Episode complete title should be Thai-ready.")
	assertThaiText(episodeFeedback.Data.Message, "Episode complete message should be Thai-ready.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "RC display player should release.")
end

local function assertWorldPromptReadiness(services)
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService
	local PromptBindingService = services.PromptBindingService

	PromptBindingService.ResetForTests()
	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for RC readiness.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for RC readiness.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompt binding should succeed for RC readiness.")

	for questNumber = 1, 8 do
		local paddedQuestNumber = string.format("%03d", questNumber)
		assertResultSuccess(WorldRegistryService.GetInteractionPoint("interaction_start_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " start marker should exist.")
		assertResultSuccess(WorldRegistryService.GetInteractionPoint("interaction_complete_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " complete marker should exist.")
	end
end

local function assertSaveCompatibility(services)
	local PlayerDataService = services.PlayerDataService
	local PromptBindingService = services.PromptBindingService
	local SaveService = services.SaveService

	assertCondition(SaveSchema.SaveVersion == 1, "SaveSchema v1 should remain stable.")

	local player = makeFakePlayer(961002, "Phase6GSave")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "RC save player should initialize.")
	completeFullEpisode(PromptBindingService, player)

	local saveResult = SaveService.BuildSave(player)
	assertResultSuccess(saveResult, "Full EP1 RC save should build.")
	assertCondition(saveResult.Data.SaveVersion == 1, "Full EP1 RC save should use SaveSchema v1.")
	assertResultSuccess(SaveService.ValidateSavePayload(saveResult.Data), "Full EP1 RC save should validate.")
	assertCondition(saveResult.Data.Quests.CompletedQuestIds.quest_ep01_main_008 == true, "Full EP1 RC save should preserve Quest 008 completion.")
	assertCondition(saveResult.Data.Episodes.CompletedEpisodeIds[EPISODE_ONE_ID] == true, "Full EP1 RC save should preserve Episode 1 completion.")
	assertCondition(saveResult.Data.Inventory.Items.item_star_core_segment_01.Quantity >= 1, "Full EP1 RC save should preserve Star Core Segment 01.")
	for _, futureSegmentItemId in ipairs(FUTURE_SEGMENT_ITEM_IDS) do
		local itemState = saveResult.Data.Inventory.Items[futureSegmentItemId]
		assertCondition(itemState == nil or itemState.Quantity == 0, "Full EP1 RC save should not include `" .. futureSegmentItemId .. "`.")
	end

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "RC save player should release.")
end

function Phase6GEP1ReleaseCandidateSmokeTest.Run(services)
	print("[ANP Phase6GEP1ReleaseCandidateSmokeTest] Starting Phase 6G EP1 release candidate smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 6G EP1 release candidate smoke test must run in Studio only.")

	services.PlayerDataService.ResetForTests()
	services.PlayerFeedbackService.ResetForTests()
	services.PromptBindingService.ResetForTests()
	services.SaveService.ResetForTests()

	assertRuntimeDefaults()
	assertEP1Content()
	assertRewardSafety()
	assertWorldPromptReadiness(services)
	assertDisplayContracts(services)
	assertSaveCompatibility(services)

	print("[ANP Phase6GEP1ReleaseCandidateSmokeTest] Phase 6G EP1 release candidate smoke test passed.")
end

return Phase6GEP1ReleaseCandidateSmokeTest
