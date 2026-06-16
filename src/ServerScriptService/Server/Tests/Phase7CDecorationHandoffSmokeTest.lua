local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Definitions = Shared:WaitForChild("Definitions")

local EpisodeDefinitions = require(Definitions.EpisodeDefinitions)
local ItemDefinitions = require(Definitions.ItemDefinitions)
local QuestDefinitions = require(Definitions.QuestDefinitions)
local RewardDefinitions = require(Definitions.RewardDefinitions)
local SaveSchema = require(Definitions.SaveSchema)
local PersistenceConfig = require(Config.PersistenceConfig)
local WorldBuildConfig = require(Config.WorldBuildConfig)
local SmokeTestConfig = require(script.Parent.Parent.Config.SmokeTestConfig)

local Phase7CDecorationHandoffSmokeTest = {}

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

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase7CDecorationHandoffSmokeTest] " .. message, 2)
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
		SourceType = "Phase7CDecorationHandoffSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function completeQuest001(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display"), "Quest 001 bridge should complete.")
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

local function hasItemGrant(rewardDefinition, itemId)
	for _, itemGrant in ipairs(rewardDefinition.Items or {}) do
		if itemGrant.ItemId == itemId then
			return true
		end
	end

	return false
end

local function assertEP1Only()
	assertCondition(EpisodeDefinitions[EPISODE_ONE_ID] ~= nil, "EP1 should exist.")
	for episodeId in pairs(EpisodeDefinitions) do
		assertCondition(episodeId == EPISODE_ONE_ID, "EP1 should remain the only active episode.")
	end
	for _, questId in ipairs(QUEST_IDS) do
		assertCondition(QuestDefinitions[questId] ~= nil, "Quest should exist: " .. questId)
	end
	assertCondition(#QuestDefinitions.quest_ep01_main_008.RequiredObjectiveIds == 5, "Quest 008 should keep five required objectives.")
	for questId in pairs(QuestDefinitions) do
		assertCondition(string.find(questId, "ep02", 1, true) == nil, "No active EP2 quest should exist.")
	end
end

local function assertDefaultConfigs()
	assertCondition(PersistenceConfig.PersistenceMode == "Mock", "PersistenceMode should remain Mock.")
	assertCondition(PersistenceConfig.EnableRealDataStore == false, "Real DataStore should remain disabled.")
	assertCondition(#PersistenceConfig.PilotCanaryUserIds == 0, "Pilot canary list should remain empty.")
	assertCondition(PersistenceConfig.AllowProductionDataStore == false, "Production DataStore should remain blocked.")
	assertCondition(PersistenceConfig.ProductionDataStoreConfirm == false, "Production DataStore confirmation should remain false.")
	assertResultSuccess(PersistenceConfig.Validate(PersistenceConfig), "Default persistence config should validate.")

	assertCondition(SmokeTestConfig.RunStudioSmokeTests == true, "Smoke tests should run by default.")
	assertCondition(SmokeTestConfig.SkipWhenRealDataStoreEnabled == true, "Smoke tests should skip when real DataStore is enabled.")
	assertCondition(SmokeTestConfig.AllowSmokeTestsDuringRealDataStorePilot == false, "Smoke tests should not run during pilot by default.")

	assertCondition(WorldBuildConfig.BuildMode == "Skeleton", "WorldBuildConfig should default to Skeleton.")
	assertCondition(WorldBuildConfig.AllowSkeletonBuildInManualMode == false, "Manual mode should not overwrite existing maps.")
	assertCondition(WorldBuildConfig.ValidateManualMapInStudio == true, "Manual map validation should stay enabled.")
end

local function assertManualMapTooling(services)
	assertCondition(type(WorldBuildConfig.BuildMode) == "string", "WorldBuildConfig should exist.")
	assertCondition(type(services.MapAuthoringValidator.Validate) == "function", "MapAuthoringValidator should exist.")
	assertCondition(type(services.MapAuthoringValidator.FormatSummary) == "function", "MapAuthoringValidator should format summaries.")
	assertCondition(type(services.MapAuthoringValidator.FormatIssueReport) == "function", "MapAuthoringValidator should format issue reports.")
	assertCondition(type(services.PromptBindingService.BindAllPrompts) == "function", "PromptBindingService should bind prompts.")
	assertCondition(type(services.PromptBindingService.GetPromptForInteraction) == "function", "PromptBindingService should expose prompt lookup.")
end

local function assertRewardAndSaveReadiness(services)
	local finalReward = RewardDefinitions.reward_ep01_main_008
	assertCondition(finalReward ~= nil, "Final EP1 reward should exist.")
	assertCondition(ItemDefinitions.item_star_core_segment_01 ~= nil, "Star Core Segment 01 item should exist.")
	assertCondition(hasItemGrant(finalReward, "item_star_core_segment_01"), "Final reward should grant Star Core Segment 01.")
	assertCondition(not hasItemGrant(finalReward, "item_star_core_segment_02"), "Final reward should not grant future Star Core segments.")
	assertCondition(SaveSchema.SaveVersion == 1, "SaveSchema v1 should remain stable.")

	assertResultSuccess(services.SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for handoff smoke test.")
	assertResultSuccess(services.WorldRegistryService.Init(), "World registry should initialize for handoff smoke test.")
	assertResultSuccess(services.PromptBindingService.BindAllPrompts(), "Prompt binding should succeed for handoff smoke test.")

	local player = makeFakePlayer(971001, "Phase7CHandoff")
	assertResultSuccess(services.PlayerDataService.InitPlayer(player), "Handoff save player should initialize.")
	completeFullEpisode(services.PromptBindingService, player)

	local saveResult = services.SaveService.BuildSave(player)
	assertResultSuccess(saveResult, "Full EP1 handoff save should build.")
	assertResultSuccess(services.SaveService.ValidateSavePayload(saveResult.Data), "Full EP1 handoff save should validate.")
	assertCondition(saveResult.Data.Quests.CompletedQuestIds.quest_ep01_main_008 == true, "Full EP1 handoff save should preserve Quest 008 completion.")
	assertCondition(saveResult.Data.Episodes.CompletedEpisodeIds[EPISODE_ONE_ID] == true, "Full EP1 handoff save should preserve Episode 1 completion.")
	assertCondition(saveResult.Data.Inventory.Items.item_star_core_segment_01.Quantity >= 1, "Full EP1 handoff save should preserve Star Core Segment 01.")

	assertResultSuccess(services.PlayerDataService.ReleasePlayer(player), "Handoff save player should release.")
end

local function assertForbiddenSystems()
	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		assertCondition(not descendant:IsA("Remote" .. "Function"), "No RemoteFunction should exist.")
	end
end

function Phase7CDecorationHandoffSmokeTest.Run(services)
	print("[ANP Phase7CDecorationHandoffSmokeTest] Starting Phase 7C decoration handoff smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 7C decoration handoff smoke test must run in Studio only.")

	services.PlayerDataService.ResetForTests()
	services.PromptBindingService.ResetForTests()
	services.SaveService.ResetForTests()

	assertEP1Only()
	assertDefaultConfigs()
	assertManualMapTooling(services)
	assertRewardAndSaveReadiness(services)
	assertForbiddenSystems()

	print("[ANP Phase7CDecorationHandoffSmokeTest] Phase 7C decoration handoff smoke test passed.")
end

return Phase7CDecorationHandoffSmokeTest
