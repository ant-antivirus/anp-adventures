local RunService = game:GetService("RunService")

local Phase3FBBugfixSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3FBBugfixSmokeTest] " .. message, 2)
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

local function assertInteractionState(InteractionVisibilityService, player, interactionId, expectedVisible, expectedEnabled, message)
	local stateResult = InteractionVisibilityService.GetInteractionState(player, interactionId)
	assertResultSuccess(stateResult, message)
	assertCondition(stateResult.Data.Visible == expectedVisible, message .. " Visible mismatch. Reason: " .. tostring(stateResult.Data.Reason))
	assertCondition(stateResult.Data.Enabled == expectedEnabled, message .. " Enabled mismatch. Reason: " .. tostring(stateResult.Data.Reason))
end

local function assertPromptEnabled(PromptBindingService, interactionId, expectedEnabled, message)
	local promptResult = PromptBindingService.GetPromptForInteraction(interactionId)
	assertResultSuccess(promptResult, message)
	assertCondition(promptResult.Data.Enabled == expectedEnabled, message .. " Prompt enabled mismatch.")
end

function Phase3FBBugfixSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local InteractionVisibilityService = services.InteractionVisibilityService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	assertCondition(RunService:IsStudio(), "Phase 3F-B bugfix smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 3F-B bugfix.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 3F-B bugfix.")

	local player = makeFakePlayer(936001, "Phase3FBBugfix")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3F-B bugfix player data should initialize.")
	assertResultSuccess(InteractionVisibilityService.RefreshPlayer(player), "Initial visibility refresh should succeed.")

	assertInteractionState(InteractionVisibilityService, player, "interaction_start_ep01_main_001", true, true, "Fresh player should see Quest 001 start.")
	assertPromptEnabled(PromptBindingService, "interaction_start_ep01_main_001", true, "Quest 001 start prompt should be enabled for fresh player.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_start_ep01_main_002", false, false, "Fresh player should not see Quest 002 start before Quest 001 completion.")
	assertPromptEnabled(PromptBindingService, "interaction_start_ep01_main_002", false, "Quest 002 start prompt should be disabled before Quest 001 completion.")

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_001", {}), "Quest 001 should start through prompt.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_001", {}), "Quest 001 objective 001 should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_002", {}), "Quest 001 objective 002 should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_003", {}), "Quest 001 objective 003 should progress.")
	local discoveryBridgeResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_disc_ep01_command_star_core_display", {})
	assertResultSuccess(discoveryBridgeResult, "Star Core display should record discovery and bridge objective progress.")
	assertCondition(discoveryBridgeResult.GrantedDiscovery == true, "Star Core display interaction should record discovery.")
	assertCondition(discoveryBridgeResult.GrantedQuestProgress == true, "Star Core display interaction should bridge quest objective progress.")

	local quest001State = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(quest001State, "Quest 001 state should read after discovery bridge.")
	assertCondition(
		quest001State.Data.ObjectiveStates.obj_ep01_main_001_004.Completed == true,
		"Star Core display interaction should complete obj_ep01_main_001_004."
	)

	assertResultSuccess(QuestService.CompleteQuest(player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "phase3fb_bugfix_complete_q001",
	}), "Quest 001 should complete.")

	assertInteractionState(InteractionVisibilityService, player, "interaction_start_ep01_main_002", true, true, "Quest 002 start should appear after Quest 001 completion.")
	assertPromptEnabled(PromptBindingService, "interaction_start_ep01_main_002", true, "Quest 002 start prompt should enable after Quest 001 completion.")

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_002", {}), "Quest 002 should start through prompt.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_start_ep01_main_002", false, false, "Quest 002 start should hide after Quest 002 becomes active.")
	assertPromptEnabled(PromptBindingService, "interaction_start_ep01_main_002", false, "Quest 002 start prompt should disable after Quest 002 becomes active.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3F-B bugfix player data should release.")

	print("[ANP Phase3FBBugfixSmokeTest] passed")
end

return Phase3FBBugfixSmokeTest
