local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Definitions = Shared:WaitForChild("Definitions")

local EpisodeDefinitions = require(Definitions.EpisodeDefinitions)
local InteractionDefinitions = require(Definitions.InteractionDefinitions)
local ItemDefinitions = require(Definitions.ItemDefinitions)
local QuestDefinitions = require(Definitions.QuestDefinitions)
local RewardDefinitions = require(Definitions.RewardDefinitions)
local SaveSchema = require(Definitions.SaveSchema)
local LocalizationConfig = require(Config.LocalizationConfig)
local PersistenceConfig = require(Config.PersistenceConfig)
local SmokeTestConfig = require(script.Parent.Parent.Config.SmokeTestConfig)
local WorldBuildConfig = require(Config.WorldBuildConfig)

local Phase6HEP1RCSignOffSmokeTest = {}

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
local REPLACEMENT_CHARACTER = utf8.char(0xFFFD)

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase6HEP1RCSignOffSmokeTest] " .. message, 2)
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
	assertCondition(string.find(text, REPLACEMENT_CHARACTER, 1, true) == nil, message .. " should not contain replacement characters.")
end

local function hasItemGrant(rewardDefinition, itemId)
	for _, itemGrant in ipairs(rewardDefinition.Items or {}) do
		if itemGrant.ItemId == itemId then
			return true
		end
	end

	return false
end

local function trigger(PromptBindingService, player, interactionId)
	return PromptBindingService.SimulatePromptTrigger(player, interactionId, {
		SourceType = "Phase6HEP1RCSignOffSmokeTest",
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

local function completeFullEpisode(PromptBindingService, player)
	completeQuest001(PromptBindingService, player)
	for questNumber = 2, 7 do
		completeQuest(PromptBindingService, player, questNumber, 4)
	end
	completeQuest(PromptBindingService, player, 8, 5)
end

local function assertEP1ActiveContent()
	assertCondition(EpisodeDefinitions[EPISODE_ONE_ID] ~= nil, "Episode 1 should exist.")
	for episodeId in pairs(EpisodeDefinitions) do
		assertCondition(episodeId == EPISODE_ONE_ID, "EP1 should remain the only active episode.")
	end
	for _, questId in ipairs(QUEST_IDS) do
		assertCondition(QuestDefinitions[questId] ~= nil, "Quest should exist: " .. questId)
	end
	assertCondition(#QuestDefinitions.quest_ep01_main_008.RequiredObjectiveIds == 5, "Quest 008 should keep exactly five required objectives.")
	for questId in pairs(QuestDefinitions) do
		assertCondition(string.find(questId, "ep02", 1, true) == nil, "No active EP2 quest definitions should exist.")
	end
end

local function assertDefaultConfigs()
	assertCondition(LocalizationConfig.DefaultLocale == "th-TH", "Thai locale should remain default.")

	assertCondition(PersistenceConfig.PersistenceMode == "Mock", "PersistenceMode should default to Mock.")
	assertCondition(PersistenceConfig.EnableRealDataStore == false, "Real DataStore should be disabled by default.")
	assertCondition(PersistenceConfig.EnableLoadOnPlayerAdded == false, "Load-on-join should be disabled by default.")
	assertCondition(PersistenceConfig.EnableSaveOnPlayerRemoving == false, "Save-on-leave should be disabled by default.")
	assertCondition(PersistenceConfig.EnableBindToCloseSave == false, "BindToClose save should be disabled by default.")
	assertCondition(PersistenceConfig.EnableAutosave == false, "Autosave should be disabled by default.")
	assertCondition(PersistenceConfig.UseMockInStudioByDefault == true, "Mock should remain the Studio default.")
	assertCondition(PersistenceConfig.AllowStudioRealDataStore == false, "Studio real DataStore should require local opt-in.")
	assertCondition(PersistenceConfig.AllowProductionDataStore == false, "Production DataStore should be blocked by default.")
	assertCondition(PersistenceConfig.ProductionDataStoreConfirm == false, "Production DataStore confirmation should be false.")
	assertCondition(#PersistenceConfig.PilotCanaryUserIds == 0, "Pilot canary list should remain empty by default.")
	assertCondition(PersistenceConfig.DebugLogs == false, "Persistence debug logs should be off by default.")
	assertResultSuccess(PersistenceConfig.Validate(PersistenceConfig), "Default persistence config should validate.")

	local productionValidation = PersistenceConfig.Validate({
		PersistenceMode = "ProductionDataStore",
		EnableRealDataStore = true,
		AllowProductionDataStore = false,
		ProductionDataStoreConfirm = false,
	})
	assertCondition(productionValidation.Success == false, "Production DataStore should remain blocked without explicit confirmation.")

	assertCondition(SmokeTestConfig.RunStudioSmokeTests == true, "Studio smoke tests should run by default.")
	assertCondition(SmokeTestConfig.SkipWhenRealDataStoreEnabled == true, "Smoke tests should skip when real DataStore is enabled.")
	assertCondition(SmokeTestConfig.AllowSmokeTestsDuringRealDataStorePilot == false, "Smoke tests should not run during real DataStore pilot by default.")

	local mockShouldRun, mockReason = SmokeTestConfig.ShouldRunStudioSmokeTests(RunService, PersistenceConfig, WorldBuildConfig)
	assertCondition(mockShouldRun == true and mockReason == "Enabled", "Smoke tests should run in Mock/Skeleton mode.")
	local pilotShouldRun, pilotReason = SmokeTestConfig.ShouldRunStudioSmokeTests(RunService, {
		EnableRealDataStore = true,
	}, WorldBuildConfig)
	assertCondition(pilotShouldRun == false and pilotReason == "RealDataStoreEnabled", "Smoke tests should skip when real DataStore is enabled.")

	assertCondition(WorldBuildConfig.BuildMode == "Skeleton", "WorldBuildConfig should default to Skeleton.")
	assertCondition(WorldBuildConfig.AllowSkeletonBuildInManualMode == false, "Manual mode should not overwrite handcrafted maps.")
	assertCondition(WorldBuildConfig.ValidateManualMapInStudio == true, "Manual map validation should stay enabled in Studio.")
end

local function assertThaiPayloads(services)
	local PlayerDataService = services.PlayerDataService
	local OnboardingService = services.OnboardingService
	local QuestTrackerService = services.QuestTrackerService
	local PlayerFeedbackService = services.PlayerFeedbackService

	local player = makeFakePlayer(968001, "Phase6HThai")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Thai payload test player should initialize.")

	local welcomePayload = OnboardingService.BuildWelcomePayload(player)
	assertCondition(welcomePayload.Type == "Onboarding", "Onboarding Type should remain stable.")
	assertThaiText(welcomePayload.Title, "Onboarding title should be Thai.")
	assertThaiText(welcomePayload.Message, "Onboarding message should be Thai.")

	local trackerResult = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(trackerResult, "Fresh tracker should build.")
	assertCondition(trackerResult.Data.Type == "QuestTracker", "QuestTracker Type should remain stable.")
	assertThaiText(trackerResult.Data.ProgressText, "Fresh tracker progress should be Thai.")
	assertThaiText(trackerResult.Data.CurrentObjectiveText, "Fresh tracker objective should be Thai.")
	assertThaiText(trackerResult.Data.HintText, "Fresh tracker hint should be Thai.")

	local episodeFeedback = PlayerFeedbackService.SendEpisodeCompleted(player, EPISODE_ONE_ID)
	assertResultSuccess(episodeFeedback, "Episode completed payload should send.")
	assertThaiText(episodeFeedback.Data.Title, "Episode complete title should be Thai.")
	assertThaiText(episodeFeedback.Data.Message, "Episode complete message should be Thai.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Thai payload test player should release.")
end

local function assertRewardSafety()
	local finalReward = RewardDefinitions.reward_ep01_main_008
	assertCondition(finalReward ~= nil, "Quest 008 final reward should exist.")
	assertCondition(ItemDefinitions.item_star_core_segment_01 ~= nil, "Star Core Segment 01 item should exist.")
	assertCondition(hasItemGrant(finalReward, "item_star_core_segment_01"), "Final reward should grant Star Core Segment 01.")
	assertCondition(not hasItemGrant(finalReward, "item_star_core"), "Final reward should not grant a complete Star Core.")
	for _, itemId in ipairs(FUTURE_SEGMENT_ITEM_IDS) do
		assertCondition(not hasItemGrant(finalReward, itemId), "Final reward should not grant future segment `" .. itemId .. "`.")
	end
end

local function assertManualMapSystems(services)
	assertCondition(type(WorldBuildConfig.BuildMode) == "string", "WorldBuildConfig should exist.")
	assertCondition(type(services.MapAuthoringValidator.Validate) == "function", "MapAuthoringValidator should expose Validate.")
	assertCondition(type(services.MapAuthoringValidator.FormatIssueReport) == "function", "MapAuthoringValidator should expose FormatIssueReport.")
	assertCondition(type(services.PromptBindingService.BindAllPrompts) == "function", "PromptBindingService should support prompt binding.")
end

local function assertWorldPromptReadiness(services)
	assertResultSuccess(services.SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 6H sign-off.")
	assertResultSuccess(services.WorldRegistryService.Init(), "World registry should initialize for Phase 6H sign-off.")
	assertResultSuccess(services.PromptBindingService.BindAllPrompts(), "Prompt binding should succeed for Phase 6H sign-off.")
end

local function assertSaveSchemaReadiness(services)
	local PlayerDataService = services.PlayerDataService
	local PromptBindingService = services.PromptBindingService
	local SaveService = services.SaveService

	assertCondition(SaveSchema.SaveVersion == 1, "SaveSchema v1 should remain stable.")

	local player = makeFakePlayer(968002, "Phase6HSave")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Save readiness player should initialize.")
	completeFullEpisode(PromptBindingService, player)

	local saveResult = SaveService.BuildSave(player)
	assertResultSuccess(saveResult, "Full EP1 sign-off save should build.")
	assertResultSuccess(SaveService.ValidateSavePayload(saveResult.Data), "Full EP1 sign-off save should validate.")
	assertCondition(saveResult.Data.SaveVersion == 1, "Full EP1 sign-off save should use SaveSchema v1.")
	assertCondition(saveResult.Data.Quests.CompletedQuestIds.quest_ep01_main_008 == true, "Full EP1 sign-off save should preserve Quest 008.")
	assertCondition(saveResult.Data.Episodes.CompletedEpisodeIds[EPISODE_ONE_ID] == true, "Full EP1 sign-off save should preserve Episode 1.")
	assertCondition(saveResult.Data.Inventory.Items.item_star_core_segment_01.Quantity >= 1, "Full EP1 sign-off save should preserve Star Core Segment 01.")
	for _, itemId in ipairs(FUTURE_SEGMENT_ITEM_IDS) do
		local itemState = saveResult.Data.Inventory.Items[itemId]
		assertCondition(itemState == nil or itemState.Quantity == 0, "Full EP1 sign-off save should not include `" .. itemId .. "`.")
	end

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Save readiness player should release.")
end

local function assertForbiddenSystems()
	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		assertCondition(not descendant:IsA("Remote" .. "Function"), "No RemoteFunction should exist.")
	end
end

function Phase6HEP1RCSignOffSmokeTest.Run(services)
	print("[ANP Phase6HEP1RCSignOffSmokeTest] Starting Phase 6H EP1 RC sign-off smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 6H EP1 RC sign-off smoke test must run in Studio only.")

	services.PlayerDataService.ResetForTests()
	services.PlayerFeedbackService.ResetForTests()
	services.PromptBindingService.ResetForTests()
	services.SaveService.ResetForTests()

	assertEP1ActiveContent()
	assertDefaultConfigs()
	assertThaiPayloads(services)
	assertRewardSafety()
	assertManualMapSystems(services)
	assertWorldPromptReadiness(services)
	assertSaveSchemaReadiness(services)
	assertForbiddenSystems()

	print("[ANP Phase6HEP1RCSignOffSmokeTest] Phase 6H EP1 RC sign-off smoke test passed.")
end

return Phase6HEP1RCSignOffSmokeTest

