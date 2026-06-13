local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local RewardDefinitions = require(Shared.Definitions.RewardDefinitions)
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)

local Phase3G3SmokeTest = {}

local RESERVED_SOCIAL_HUB_ZONE_ID = "zone_social_hub_anp_town"

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3G3SmokeTest] " .. message, 2)
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
	local normalizedHintText = string.lower(hintText)
	for _, expectedToken in ipairs(expectedTokens) do
		local normalizedExpectedToken = string.lower(expectedToken)
		assertCondition(
			string.find(normalizedHintText, normalizedExpectedToken, 1, true) ~= nil,
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
		SourceId = "Phase3G3TerrainTravel",
	}), "Quest 004 zone travel should record after terrain unlock.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_001", "Quest 004 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_002", "Quest 004 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_003", "Quest 004 objective 003 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_004_004", "Quest 004 objective 004 should progress.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_004", "Quest 004 should complete.")
end

local function assertQuestObjectivesComplete(QuestService, player, questId)
	local questStateResult = QuestService.GetQuestState(player, questId)
	assertResultSuccess(questStateResult, questId .. " state should read.")

	for _, objectiveId in ipairs(QuestDefinitions[questId].RequiredObjectiveIds or {}) do
		local objectiveState = questStateResult.Data.ObjectiveStates[objectiveId]
		assertCondition(objectiveState and objectiveState.Completed == true, questId .. " objective should be complete: " .. objectiveId)
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

function Phase3G3SmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local InventoryService = services.InventoryService
	local ZoneService = services.ZoneService
	local AnalyticsService = services.AnalyticsService
	local InteractionValidator = services.InteractionValidator
	local InteractionVisibilityService = services.InteractionVisibilityService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase3G3SmokeTest] Starting Phase 3G-3 smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3G-3 smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 3G-3.")

	local validationResult = InteractionValidator.Validate(WorldRegistryService)
	if not validationResult.Success then
		for _, errorMessage in ipairs(validationResult.Errors) do
			warn("[ANP Phase3G3SmokeTest] " .. errorMessage)
		end
	end
	assertCondition(validationResult.Success == true, "Quest 005 and Quest 006 interactions should validate.")

	assertResultSuccess(PromptBindingService.BindAllPrompts(), "PromptBindingService should bind Quest 005 and Quest 006 prompts.")

	local player = makeFakePlayer(940003, "Phase3G3Quest005006")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3G-3 player data should initialize.")
	assertResultSuccess(PromptBindingService.RefreshPlayer(player), "Prompt visibility should refresh for Phase 3G-3 player.")

	completeQuest001(PromptBindingService, player)
	completeQuest002(PromptBindingService, player)
	completeQuest003(PromptBindingService, player)
	completeQuest004(PromptBindingService, ZoneService, player)

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_start_ep01_main_005",
		true,
		true,
		"Quest 005 start should be visible after Quest 004 completion."
	)

	trigger(PromptBindingService, player, "interaction_start_ep01_main_005", "Quest 005 should start.")
	local quest005State = QuestService.GetQuestState(player, "quest_ep01_main_005")
	assertResultSuccess(quest005State, "Quest 005 state should read after start.")
	assertCondition(quest005State.Data.Status == QuestService.QuestStatus.Active, "Quest 005 should be active.")

	assertResultSuccess(ZoneService.TravelToZone(player, "zone_ep01_theos_satellite_center", nil, "Spawn", {
		SourceType = "SmokeTest",
		SourceId = "Phase3G3THEOSTravel",
	}), "Quest 005 zone travel should record after THEOS unlock.")

	trigger(PromptBindingService, player, "interaction_ep01_main_005_001", "Quest 005 objective 001 should progress.")
	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_005_003", {}),
		"ObjectiveDependencyMissing",
		"Quest 005 dependent objective should fail before prerequisite."
	)
	trigger(PromptBindingService, player, "interaction_ep01_main_005_002", "Quest 005 prerequisite objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_005_003", "Quest 005 objective 003 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_ep01_main_005_004", "Quest 005 objective 004 should progress after dependency.")

	assertQuestObjectivesComplete(QuestService, player, "quest_ep01_main_005")
	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_complete_ep01_main_005",
		true,
		true,
		"Quest 005 complete marker should be visible after all objectives."
	)
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_005", "Quest 005 should complete through QuestComplete interaction.")
	assertCondition(
		PlayerDataService.HasRewardClaim(player, "Interaction:interaction_complete_ep01_main_005:reward_ep01_main_005") == true,
		"reward_ep01_main_005 should be claimed through Quest 005 completion."
	)
	assertCondition(InventoryService.HasItem(player, "item_ep01_fragment_theos", 1), "Quest 005 reward should grant item_ep01_fragment_theos.")

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_start_ep01_main_006",
		true,
		true,
		"Quest 006 start should be visible after Quest 005 completion."
	)
	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_complete_ep01_main_005", {}),
		"QuestAlreadyCompleted",
		"Duplicate Quest 005 completion should be blocked."
	)

	trigger(PromptBindingService, player, "interaction_start_ep01_main_006", "Quest 006 should start.")

	assertResultSuccess(ZoneService.TravelToZone(player, "zone_ep01_rocket_mission", nil, "Spawn", {
		SourceType = "SmokeTest",
		SourceId = "Phase3G3RocketTravel",
	}), "Quest 006 zone travel should record after rocket unlock.")

	trigger(PromptBindingService, player, "interaction_ep01_main_006_001", "Quest 006 objective 001 should progress.")
	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_006_003", {}),
		"ObjectiveDependencyMissing",
		"Quest 006 dependent objective should fail before prerequisite."
	)
	trigger(PromptBindingService, player, "interaction_ep01_main_006_002", "Quest 006 prerequisite objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_006_003", "Quest 006 objective 003 should progress after dependency.")
	trigger(PromptBindingService, player, "interaction_ep01_main_006_004", "Quest 006 objective 004 should progress after dependency.")

	assertQuestObjectivesComplete(QuestService, player, "quest_ep01_main_006")
	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_complete_ep01_main_006",
		true,
		true,
		"Quest 006 complete marker should be visible after all objectives."
	)
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_006", "Quest 006 should complete through QuestComplete interaction.")
	assertCondition(
		PlayerDataService.HasRewardClaim(player, "Interaction:interaction_complete_ep01_main_006:reward_ep01_main_006") == true,
		"reward_ep01_main_006 should be claimed through Quest 006 completion."
	)
	assertCondition(InventoryService.HasItem(player, "item_ep01_fragment_rocket", 1), "Quest 006 reward should grant item_ep01_fragment_rocket.")
	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_complete_ep01_main_006", {}),
		"QuestAlreadyCompleted",
		"Duplicate Quest 006 completion should be blocked."
	)

	local postQuest006Guidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_proton_guide", {})
	assertGuidanceContainsAll(postQuest006Guidance, { "ชิ้นส่วนจรวด", "นักบินอวกาศ" }, "Guidance after Quest 006 should point to astronaut training.")

	assertResultSuccess(
		AnalyticsService.Track(player, "QuestCompleted", {
			QuestId = "quest_ep01_main_006",
			Source = "Phase3G3SmokeTest",
		}),
		"Analytics tracking should not error."
	)

	local snapshotResult = PlayerDataService.GetSnapshot(player)
	assertResultSuccess(snapshotResult, "Player snapshot should read after Quest 006.")
	assertCondition(snapshotResult.Data.SessionStats.QuestsStarted >= 6, "SessionStats.QuestsStarted should include Quests 001-006.")
	assertCondition(snapshotResult.Data.SessionStats.QuestsCompleted >= 6, "SessionStats.QuestsCompleted should include Quests 001-006.")
	assertCondition(snapshotResult.Data.SessionStats.ZoneTravels >= 3, "SessionStats.ZoneTravels should increment when travel is used.")
	assertCondition(snapshotResult.Data.SessionStats.DiscoveriesFound >= 1, "SessionStats.DiscoveriesFound should include the Quest 001 discovery.")

	assertNoReservedZoneReferences()

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3G-3 player data should release.")

	print("[ANP Phase3G3SmokeTest] Phase 3G-3 smoke test passed.")
end

return Phase3G3SmokeTest
