local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local RewardDefinitions = require(Shared.Definitions.RewardDefinitions)
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)

local Phase3G4SmokeTest = {}

local RESERVED_SOCIAL_HUB_ZONE_ID = "zone_social_hub_anp_town"
local EP01_ID = "ep01_lost_star_core"
local REQUIRED_EP01_FRAGMENTS = {
	"item_ep01_fragment_universe",
	"item_ep01_fragment_earth",
	"item_ep01_fragment_theos",
	"item_ep01_fragment_rocket",
	"item_ep01_fragment_moon",
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3G4SmokeTest] " .. message, 2)
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

local function assertInteractionState(InteractionVisibilityService, player, interactionId, expectedVisible, expectedEnabled, message)
	local stateResult = InteractionVisibilityService.GetInteractionState(player, interactionId)
	assertResultSuccess(stateResult, message)
	assertCondition(stateResult.Data.Visible == expectedVisible, message .. " Visible mismatch. Reason: " .. tostring(stateResult.Data.Reason))
	assertCondition(stateResult.Data.Enabled == expectedEnabled, message .. " Enabled mismatch. Reason: " .. tostring(stateResult.Data.Reason))
end

local function assertGuidanceContainsAll(guidanceResult, expectedTokens, message)
	assertResultSuccess(guidanceResult, message)
	assertCondition(guidanceResult.Data.Guidance ~= nil, message .. " should return guidance data.")

	local hintText = guidanceResult.Data.Guidance.HintText or ""
	for _, expectedToken in ipairs(expectedTokens) do
		assertCondition(
			string.find(hintText, expectedToken, 1, true) ~= nil,
			message .. " Expected hint containing `" .. expectedToken .. "`, got `" .. hintText .. "`."
		)
	end
end

local function trigger(PromptBindingService, player, interactionId, message)
	local interactionResult = PromptBindingService.SimulatePromptTrigger(player, interactionId, {})
	assertResultSuccess(interactionResult, message)
	return interactionResult
end

local function completeQuest001(PromptBindingService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_001", "Quest 001 should start.")
	trigger(PromptBindingService, player, "interaction_ep01_main_001_001", "Quest 001 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_001_002", "Quest 001 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_001_003", "Quest 001 objective 003 should progress.")
	trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display", "Quest 001 discovery bridge objective should progress.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_001", "Quest 001 should complete.")
end

local function completeQuest002(PromptBindingService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_002", "Quest 002 should start.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_001", "Quest 002 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_002", "Quest 002 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_003", "Quest 002 objective 003 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_004", "Quest 002 objective 004 should progress.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_002", "Quest 002 should complete.")
end

local function completeQuest003(PromptBindingService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_003", "Quest 003 should start.")
	trigger(PromptBindingService, player, "interaction_ep01_main_003_001", "Quest 003 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_003_002", "Quest 003 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_003_003", "Quest 003 objective 003 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_003_004", "Quest 003 objective 004 should progress.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_003", "Quest 003 should complete.")
end

local function completeQuest004(PromptBindingService, ZoneService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_004", "Quest 004 should start.")
	assertResultSuccess(ZoneService.TravelToZone(player, "zone_ep01_terrain_sandbox", nil, "Spawn", {
		SourceType = "SmokeTest",
		SourceId = "Phase3G4TerrainTravel",
	}), "Quest 004 zone travel should record.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_001", "Quest 004 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_002", "Quest 004 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_003", "Quest 004 objective 003 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_004", "Quest 004 objective 004 should progress.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_004", "Quest 004 should complete.")
end

local function completeQuest005(PromptBindingService, ZoneService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_005", "Quest 005 should start.")
	assertResultSuccess(ZoneService.TravelToZone(player, "zone_ep01_theos_satellite_center", nil, "Spawn", {
		SourceType = "SmokeTest",
		SourceId = "Phase3G4THEOSTravel",
	}), "Quest 005 zone travel should record.")
	trigger(PromptBindingService, player, "interaction_ep01_main_005_001", "Quest 005 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_005_002", "Quest 005 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_005_003", "Quest 005 objective 003 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_005_004", "Quest 005 objective 004 should progress.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_005", "Quest 005 should complete.")
end

local function completeQuest006(PromptBindingService, ZoneService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_006", "Quest 006 should start.")
	assertResultSuccess(ZoneService.TravelToZone(player, "zone_ep01_rocket_mission", nil, "Spawn", {
		SourceType = "SmokeTest",
		SourceId = "Phase3G4RocketTravel",
	}), "Quest 006 zone travel should record.")
	trigger(PromptBindingService, player, "interaction_ep01_main_006_001", "Quest 006 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_006_002", "Quest 006 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_006_003", "Quest 006 objective 003 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_006_004", "Quest 006 objective 004 should progress.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_006", "Quest 006 should complete.")
end

local function assertQuestObjectivesComplete(QuestService, player, questId)
	local questStateResult = QuestService.GetQuestState(player, questId)
	assertResultSuccess(questStateResult, questId .. " state should read.")

	for _, objectiveId in ipairs(QuestDefinitions[questId].RequiredObjectiveIds or {}) do
		local objectiveState = questStateResult.Data.ObjectiveStates[objectiveId]
		assertCondition(objectiveState and objectiveState.Completed == true, questId .. " objective should be complete: " .. objectiveId)
	end
end

local function assertAllRequiredFragments(InventoryService, player)
	for _, itemId in ipairs(REQUIRED_EP01_FRAGMENTS) do
		assertCondition(InventoryService.HasItem(player, itemId, 1), "Player should own required Episode 1 fragment: " .. itemId)
	end
end

local function assertNoReservedZoneReferences()
	for questId, questDefinition in pairs(QuestDefinitions) do
		assertCondition(questDefinition.ZoneId ~= RESERVED_SOCIAL_HUB_ZONE_ID, "Quest must not reference reserved social hub zone: " .. questId)
	end

	for rewardId, rewardDefinition in pairs(RewardDefinitions) do
		for _, zoneId in ipairs(rewardDefinition.UnlockZones or {}) do
			assertCondition(zoneId ~= RESERVED_SOCIAL_HUB_ZONE_ID, "Reward must not unlock reserved social hub zone: " .. rewardId)
		end
	end

	for interactionId, interactionDefinition in pairs(InteractionDefinitions) do
		assertCondition(interactionDefinition.ZoneId ~= RESERVED_SOCIAL_HUB_ZONE_ID, "Interaction must not target reserved social hub zone: " .. interactionId)
	end
end

function Phase3G4SmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local InventoryService = services.InventoryService
	local ZoneService = services.ZoneService
	local EpisodeService = services.EpisodeService
	local AnalyticsService = services.AnalyticsService
	local InteractionValidator = services.InteractionValidator
	local InteractionVisibilityService = services.InteractionVisibilityService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase3G4SmokeTest] Starting Phase 3G-4 smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3G-4 smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 3G-4.")

	local validationResult = InteractionValidator.Validate(WorldRegistryService)
	if not validationResult.Success then
		for _, errorMessage in ipairs(validationResult.Errors) do
			warn("[ANP Phase3G4SmokeTest] " .. errorMessage)
		end
	end
	assertCondition(validationResult.Success == true, "Quest 007 and Quest 008 interactions should validate.")

	assertResultSuccess(PromptBindingService.BindAllPrompts(), "PromptBindingService should bind Quest 007 and Quest 008 prompts.")

	local player = makeFakePlayer(940004, "Phase3G4Quest007008")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3G-4 player data should initialize.")
	assertResultSuccess(PromptBindingService.RefreshPlayer(player), "Prompt visibility should refresh for Phase 3G-4 player.")

	completeQuest001(PromptBindingService, player)
	completeQuest002(PromptBindingService, player)
	completeQuest003(PromptBindingService, player)
	completeQuest004(PromptBindingService, ZoneService, player)
	completeQuest005(PromptBindingService, ZoneService, player)
	completeQuest006(PromptBindingService, ZoneService, player)

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_start_ep01_main_007",
		true,
		true,
		"Quest 007 start should be visible after Quest 006 completion."
	)

	trigger(PromptBindingService, player, "interaction_start_ep01_main_007", "Quest 007 should start.")
	assertResultSuccess(ZoneService.TravelToZone(player, "zone_ep01_astronaut_training", nil, "Spawn", {
		SourceType = "SmokeTest",
		SourceId = "Phase3G4AstronautTravel",
	}), "Quest 007 zone travel should record.")
	trigger(PromptBindingService, player, "interaction_ep01_main_007_001", "Quest 007 objective 001 should progress.")
	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_007_003", {}),
		"ObjectiveDependencyMissing",
		"Quest 007 dependent objective should fail before prerequisite."
	)
	trigger(PromptBindingService, player, "interaction_ep01_main_007_002", "Quest 007 prerequisite objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_007_003", "Quest 007 objective 003 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_ep01_main_007_004", "Quest 007 objective 004 should progress after dependency.")

	assertQuestObjectivesComplete(QuestService, player, "quest_ep01_main_007")
	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_complete_ep01_main_007",
		true,
		true,
		"Quest 007 complete marker should be visible after all objectives."
	)
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_007", "Quest 007 should complete through QuestComplete interaction.")
	assertCondition(PlayerDataService.HasRewardClaim(player, "Interaction:interaction_complete_ep01_main_007:reward_ep01_main_007") == true, "reward_ep01_main_007 should be claimed.")

	local afterQuest007Snapshot = PlayerDataService.GetSnapshot(player)
	assertResultSuccess(afterQuest007Snapshot, "Player snapshot should read after Quest 007.")
	assertCondition(afterQuest007Snapshot.Data.Badges.AwardedBadgeIds.badge_ep01_astronaut == true, "Quest 007 should award internal astronaut badge state.")

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_start_ep01_main_008",
		true,
		true,
		"Quest 008 start should be visible after Quest 007 completion."
	)
	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_complete_ep01_main_007", {}),
		"QuestAlreadyCompleted",
		"Duplicate Quest 007 completion should be blocked."
	)

	trigger(PromptBindingService, player, "interaction_start_ep01_main_008", "Quest 008 should start.")
	assertResultSuccess(ZoneService.TravelToZone(player, "zone_ep01_moon_walk", nil, "Spawn", {
		SourceType = "SmokeTest",
		SourceId = "Phase3G4MoonTravel",
	}), "Quest 008 zone travel should record.")
	trigger(PromptBindingService, player, "interaction_ep01_main_008_001", "Quest 008 objective 001 should progress.")
	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_008_003", {}),
		"ObjectiveDependencyMissing",
		"Quest 008 dependent objective should fail before prerequisite."
	)
	trigger(PromptBindingService, player, "interaction_ep01_main_008_002", "Quest 008 prerequisite objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_008_003", "Quest 008 objective 003 should progress and grant Moon Fragment.")

	assertCondition(
		PlayerDataService.HasRewardClaim(player, "QuestObjective:quest_ep01_main_008_obj_ep01_main_008_003:reward_ep01_objective_008_moon_fragment") == true,
		"Moon Fragment objective reward should be claimed before final completion."
	)
	assertCondition(InventoryService.HasItem(player, "item_ep01_fragment_moon", 1), "Quest 008 objective 003 should grant item_ep01_fragment_moon before final completion.")
	assertCondition(not InventoryService.HasItem(player, "item_star_core_segment_01", 1), "Star Core Segment 01 should not exist before final completion.")
	assertAllRequiredFragments(InventoryService, player)

	trigger(PromptBindingService, player, "interaction_ep01_main_008_004", "Quest 008 objective 004 should verify fragment set.")
	trigger(PromptBindingService, player, "interaction_ep01_main_008_005", "Quest 008 objective 005 should restore Star Core Segment 01 objective.")

	assertQuestObjectivesComplete(QuestService, player, "quest_ep01_main_008")
	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_complete_ep01_main_008",
		true,
		true,
		"Quest 008 finale marker should be visible after all objectives."
	)
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_008", "Quest 008 should complete Episode 1.")

	assertCondition(PlayerDataService.HasRewardClaim(player, "Interaction:interaction_complete_ep01_main_008:reward_ep01_main_008") == true, "reward_ep01_main_008 should be claimed.")
	assertCondition(InventoryService.HasItem(player, "item_star_core_segment_01", 1), "Final reward should grant item_star_core_segment_01.")
	assertCondition(not InventoryService.HasItem(player, "item_star_core_segment_02", 1), "Final reward must not grant future Star Core Segment 02.")
	assertCondition(not InventoryService.HasItem(player, "item_star_core_segment_03", 1), "Final reward must not grant future Star Core Segment 03.")
	assertCondition(not InventoryService.HasItem(player, "item_star_core_segment_04", 1), "Final reward must not grant future Star Core Segment 04.")
	assertCondition(not InventoryService.HasItem(player, "item_star_core_segment_05", 1), "Final reward must not grant future Star Core Segment 05.")

	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_complete_ep01_main_008", {}),
		"QuestAlreadyCompleted",
		"Duplicate Quest 008 completion should be blocked."
	)

	local episodeState = EpisodeService.GetPlayerEpisodeState(player, EP01_ID)
	assertResultSuccess(episodeState, "Episode 1 state should read after finale.")
	assertCondition(episodeState.Data.IsCompleted == true, "Episode 1 should be completed after Quest 008 finale.")

	local postQuest008Guidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_proton_guide", {})
	assertGuidanceContainsAll(postQuest008Guidance, { "Episode 1", "complete", "Star Core Segment 01" }, "Guidance after Quest 008 should confirm Episode 1 completion.")

	assertResultSuccess(
		AnalyticsService.Track(player, "QuestCompleted", {
			QuestId = "quest_ep01_main_008",
			Source = "Phase3G4SmokeTest",
		}),
		"Analytics tracking should not error."
	)

	local finalSnapshot = PlayerDataService.GetSnapshot(player)
	assertResultSuccess(finalSnapshot, "Player snapshot should read after Episode 1 finale.")
	assertCondition(finalSnapshot.Data.SessionStats.QuestsStarted >= 8, "SessionStats.QuestsStarted should include Quests 001-008.")
	assertCondition(finalSnapshot.Data.SessionStats.QuestsCompleted >= 8, "SessionStats.QuestsCompleted should include Quests 001-008.")
	assertCondition(finalSnapshot.Data.SessionStats.ZoneTravels >= 5, "SessionStats.ZoneTravels should increment when travel is used.")
	assertCondition(finalSnapshot.Data.SessionStats.DiscoveriesFound >= 1, "SessionStats.DiscoveriesFound should include the Quest 001 discovery.")

	assertNoReservedZoneReferences()

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3G-4 player data should release.")

	print("[ANP Phase3G4SmokeTest] Phase 3G-4 smoke test passed.")
end

return Phase3G4SmokeTest
