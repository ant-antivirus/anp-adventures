local RunService = game:GetService("RunService")

local Phase3HPlaytestPolishSmokeTest = {}

local RESERVED_SOCIAL_HUB_ZONE_ID = "zone_social_hub_anp_town"
local REQUIRED_EP01_FRAGMENTS = {
	"item_ep01_fragment_universe",
	"item_ep01_fragment_earth",
	"item_ep01_fragment_theos",
	"item_ep01_fragment_rocket",
	"item_ep01_fragment_moon",
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3HPlaytestPolishSmokeTest] " .. message, 2)
	end
end

local function assertResultSuccess(serviceResult, message)
	assertCondition(serviceResult and serviceResult.Success == true, message .. " Code: " .. tostring(serviceResult and serviceResult.Code))
end

local function assertResultFailure(serviceResult, expectedCode, message)
	assertCondition(serviceResult and serviceResult.Success == false, message)
	assertCondition(serviceResult.Code == expectedCode, message .. " Expected `" .. expectedCode .. "`, got `" .. tostring(serviceResult.Code) .. "`.")
end

local function assertHintText(serviceResult, message)
	assertCondition(serviceResult and serviceResult.Data and type(serviceResult.Data.HintText) == "string" and serviceResult.Data.HintText ~= "", message)
end

local function makeFakePlayer(userId, name)
	return {
		UserId = userId,
		Name = name,
	}
end

local function trigger(PromptBindingService, player, interactionId, message)
	local interactionResult = PromptBindingService.SimulatePromptTrigger(player, interactionId, {})
	assertResultSuccess(interactionResult, message)
	return interactionResult
end

local function triggerExpectingFailure(PromptBindingService, player, interactionId, expectedCode, message)
	local interactionResult = PromptBindingService.SimulatePromptTrigger(player, interactionId, {})
	assertResultFailure(interactionResult, expectedCode, message)
	assertHintText(interactionResult, message .. " should include HintText.")
	return interactionResult
end

local function assertInteractionState(InteractionVisibilityService, player, interactionId, expectedVisible, expectedEnabled, message)
	local stateResult = InteractionVisibilityService.GetInteractionState(player, interactionId)
	assertResultSuccess(stateResult, message)
	assertCondition(stateResult.Data.Visible == expectedVisible, message .. " Visible mismatch. Reason: " .. tostring(stateResult.Data.Reason))
	assertCondition(stateResult.Data.Enabled == expectedEnabled, message .. " Enabled mismatch. Reason: " .. tostring(stateResult.Data.Reason))
end

local function assertGuidanceContainsAll(PromptBindingService, player, expectedTokens, message)
	local guidanceResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_proton_guide", {})
	assertResultSuccess(guidanceResult, message)
	assertCondition(guidanceResult.Data.Guidance ~= nil, message .. " should return guidance data.")

	local hintText = string.lower(guidanceResult.Data.Guidance.HintText or "")
	for _, expectedToken in ipairs(expectedTokens) do
		assertCondition(
			string.find(hintText, string.lower(expectedToken), 1, true) ~= nil,
			message .. " Expected hint containing `" .. expectedToken .. "`, got `" .. tostring(guidanceResult.Data.Guidance.HintText) .. "`."
		)
	end
end

local function assertQuestCompleteLocked(PromptBindingService, player, interactionId)
	triggerExpectingFailure(PromptBindingService, player, interactionId, "RequiredObjectiveIncomplete", interactionId .. " should reject early quest completion.")
end

local function travel(ZoneService, player, zoneId, sourceId)
	assertResultSuccess(ZoneService.TravelToZone(player, zoneId, nil, "Spawn", {
		SourceType = "SmokeTest",
		SourceId = sourceId,
	}), "Zone travel should succeed for " .. zoneId .. ".")
end

local function completeQuest001(PromptBindingService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_001", "Quest 001 should start.")
	assertQuestCompleteLocked(PromptBindingService, player, "interaction_complete_ep01_main_001")
	trigger(PromptBindingService, player, "interaction_ep01_main_001_001", "Quest 001 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_001_002", "Quest 001 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_001_003", "Quest 001 objective 003 should progress.")
	trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display", "Quest 001 Star Core Display objective should progress.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_001", "Quest 001 should complete.")
end

local function completeQuest002(PromptBindingService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_002", "Quest 002 should start.")
	assertQuestCompleteLocked(PromptBindingService, player, "interaction_complete_ep01_main_002")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_001", "Quest 002 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_002", "Quest 002 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_003", "Quest 002 objective 003 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_004", "Quest 002 objective 004 should progress.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_002", "Quest 002 should complete.")
end

local function completeQuest003(PromptBindingService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_003", "Quest 003 should start.")
	assertQuestCompleteLocked(PromptBindingService, player, "interaction_complete_ep01_main_003")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_003_003", "ObjectiveDependencyMissing", "Quest 003 objective 003 should require objective 002.")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_003_004", "ObjectiveDependencyMissing", "Quest 003 objective 004 should require objective 003.")
	trigger(PromptBindingService, player, "interaction_ep01_main_003_001", "Quest 003 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_003_002", "Quest 003 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_003_003", "Quest 003 objective 003 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_ep01_main_003_004", "Quest 003 objective 004 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_003", "Quest 003 should complete.")
end

local function completeQuest004(PromptBindingService, ZoneService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_004", "Quest 004 should start.")
	travel(ZoneService, player, "zone_ep01_terrain_sandbox", "Phase3HQuest004Travel")
	assertQuestCompleteLocked(PromptBindingService, player, "interaction_complete_ep01_main_004")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_004_003", "ObjectiveDependencyMissing", "Quest 004 objective 003 should require objective 002.")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_004_004", "ObjectiveDependencyMissing", "Quest 004 objective 004 should require objective 003.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_001", "Quest 004 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_002", "Quest 004 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_003", "Quest 004 objective 003 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_004", "Quest 004 objective 004 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_004", "Quest 004 should complete.")
end

local function completeQuest005(PromptBindingService, ZoneService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_005", "Quest 005 should start.")
	travel(ZoneService, player, "zone_ep01_theos_satellite_center", "Phase3HQuest005Travel")
	assertQuestCompleteLocked(PromptBindingService, player, "interaction_complete_ep01_main_005")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_005_003", "ObjectiveDependencyMissing", "Quest 005 objective 003 should require objective 002.")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_005_004", "ObjectiveDependencyMissing", "Quest 005 objective 004 should require objective 003.")
	trigger(PromptBindingService, player, "interaction_ep01_main_005_001", "Quest 005 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_005_002", "Quest 005 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_005_003", "Quest 005 objective 003 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_ep01_main_005_004", "Quest 005 objective 004 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_005", "Quest 005 should complete.")
end

local function completeQuest006(PromptBindingService, ZoneService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_006", "Quest 006 should start.")
	travel(ZoneService, player, "zone_ep01_rocket_mission", "Phase3HQuest006Travel")
	assertQuestCompleteLocked(PromptBindingService, player, "interaction_complete_ep01_main_006")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_006_003", "ObjectiveDependencyMissing", "Quest 006 objective 003 should require objective 002.")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_006_004", "ObjectiveDependencyMissing", "Quest 006 objective 004 should require objective 003.")
	trigger(PromptBindingService, player, "interaction_ep01_main_006_001", "Quest 006 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_006_002", "Quest 006 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_006_003", "Quest 006 objective 003 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_ep01_main_006_004", "Quest 006 objective 004 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_006", "Quest 006 should complete.")
end

local function completeQuest007(PromptBindingService, ZoneService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_007", "Quest 007 should start.")
	travel(ZoneService, player, "zone_ep01_astronaut_training", "Phase3HQuest007Travel")
	assertQuestCompleteLocked(PromptBindingService, player, "interaction_complete_ep01_main_007")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_007_003", "ObjectiveDependencyMissing", "Quest 007 objective 003 should require objective 002.")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_007_004", "ObjectiveDependencyMissing", "Quest 007 objective 004 should require objective 003.")
	trigger(PromptBindingService, player, "interaction_ep01_main_007_001", "Quest 007 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_007_002", "Quest 007 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_007_003", "Quest 007 objective 003 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_ep01_main_007_004", "Quest 007 objective 004 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_007", "Quest 007 should complete.")
end

local function completeQuest008(PromptBindingService, ZoneService, player)
	trigger(PromptBindingService, player, "interaction_start_ep01_main_008", "Quest 008 should start.")
	travel(ZoneService, player, "zone_ep01_moon_walk", "Phase3HQuest008Travel")
	assertQuestCompleteLocked(PromptBindingService, player, "interaction_complete_ep01_main_008")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_008_003", "ObjectiveDependencyMissing", "Quest 008 objective 003 should require objective 002.")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_008_004", "ObjectiveDependencyMissing", "Quest 008 objective 004 should require objective 003.")
	triggerExpectingFailure(PromptBindingService, player, "interaction_ep01_main_008_005", "ObjectiveDependencyMissing", "Quest 008 objective 005 should require objective 004.")
	trigger(PromptBindingService, player, "interaction_ep01_main_008_001", "Quest 008 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_008_002", "Quest 008 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_008_003", "Quest 008 objective 003 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_ep01_main_008_004", "Quest 008 objective 004 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_ep01_main_008_005", "Quest 008 objective 005 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_008", "Quest 008 should complete.")
end

local function assertNoReservedZoneReferences()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)

	for interactionId, interactionDefinition in pairs(InteractionDefinitions) do
		assertCondition(interactionDefinition.ZoneId ~= RESERVED_SOCIAL_HUB_ZONE_ID, "Interaction must not target reserved social hub zone: " .. interactionId)
	end
end

function Phase3HPlaytestPolishSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local InventoryService = services.InventoryService
	local EpisodeService = services.EpisodeService
	local ZoneService = services.ZoneService
	local InteractionVisibilityService = services.InteractionVisibilityService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase3HPlaytestPolishSmokeTest] Starting Phase 3H playtest polish smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3H playtest polish smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "PromptBindingService should bind prompts.")

	local player = makeFakePlayer(960001, "Phase3HPlaytestPolish")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3H player data should initialize.")
	assertResultSuccess(PromptBindingService.RefreshPlayer(player), "Prompt visibility should refresh for Phase 3H player.")

	assertInteractionState(InteractionVisibilityService, player, "interaction_start_ep01_main_001", true, true, "Quest 001 start should be available at the beginning.")
	triggerExpectingFailure(PromptBindingService, player, "interaction_start_ep01_main_002", "QuestPrerequisiteMissing", "Quest 002 should be blocked before Quest 001 completes.")
	triggerExpectingFailure(PromptBindingService, player, "interaction_start_ep01_main_003", "QuestPrerequisiteMissing", "Quest 003 should be blocked before Quest 002 completes.")

	local earlyDisplayResult = trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display", "Star Core Display should allow early discovery.")
	assertCondition(earlyDisplayResult.Code == "DiscoveryRecordedQuestNotActive", "Early Star Core Display should return a quest-not-active discovery code.")
	assertHintText(earlyDisplayResult, "Early Star Core Display should include HintText.")

	completeQuest001(PromptBindingService, player)
	assertGuidanceContainsAll(PromptBindingService, player, { "Quest 002" }, "Guidance after Quest 001 should point to Quest 002.")

	completeQuest002(PromptBindingService, player)
	assertGuidanceContainsAll(PromptBindingService, player, { "Quest 003" }, "Guidance after Quest 002 should point to Quest 003.")

	completeQuest003(PromptBindingService, player)
	assertGuidanceContainsAll(PromptBindingService, player, { "Quest 004" }, "Guidance after Quest 003 should point to Quest 004.")

	completeQuest004(PromptBindingService, ZoneService, player)
	assertGuidanceContainsAll(PromptBindingService, player, { "Quest 005", "THEOS" }, "Guidance after Quest 004 should point to Quest 005 / THEOS.")

	completeQuest005(PromptBindingService, ZoneService, player)
	assertGuidanceContainsAll(PromptBindingService, player, { "Quest 006", "Rocket" }, "Guidance after Quest 005 should point to Quest 006 / Rocket.")

	completeQuest006(PromptBindingService, ZoneService, player)
	assertGuidanceContainsAll(PromptBindingService, player, { "Quest 007", "Astronaut" }, "Guidance after Quest 006 should point to Quest 007 / Astronaut Training.")

	completeQuest007(PromptBindingService, ZoneService, player)
	assertGuidanceContainsAll(PromptBindingService, player, { "Quest 008", "Moon" }, "Guidance after Quest 007 should point to Quest 008 / Moon Walk.")

	completeQuest008(PromptBindingService, ZoneService, player)
	assertGuidanceContainsAll(PromptBindingService, player, { "Episode 1", "complete", "Star Core Segment 01" }, "Guidance after Quest 008 should confirm Episode 1 completion.")

	for _, itemId in ipairs(REQUIRED_EP01_FRAGMENTS) do
		assertCondition(InventoryService.HasItem(player, itemId, 1), "Final inventory should include " .. itemId .. ".")
	end

	assertCondition(InventoryService.HasItem(player, "item_star_core_segment_01", 1), "Final inventory should include item_star_core_segment_01.")
	assertCondition(not InventoryService.HasItem(player, "item_star_core_complete", 1), "Final inventory must not include a complete Star Core item.")

	local episodeState = EpisodeService.GetPlayerEpisodeState(player, "ep01_lost_star_core")
	assertResultSuccess(episodeState, "Episode 1 state should read after finale.")
	assertCondition(episodeState.Data.IsCompleted == true, "Episode 1 should be marked complete after Quest 008.")

	assertNoReservedZoneReferences()

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3H player data should release.")

	print("[ANP Phase3HPlaytestPolishSmokeTest] Phase 3H playtest polish smoke test passed.")
end

return Phase3HPlaytestPolishSmokeTest
