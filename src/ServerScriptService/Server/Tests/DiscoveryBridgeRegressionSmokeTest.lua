local RunService = game:GetService("RunService")

local DiscoveryBridgeRegressionSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP DiscoveryBridgeRegressionSmokeTest] " .. message, 2)
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

function DiscoveryBridgeRegressionSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local DiscoveryService = services.DiscoveryService
	local InteractionService = services.InteractionService
	local InteractionVisibilityService = services.InteractionVisibilityService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP DiscoveryBridgeRegressionSmokeTest] Starting discovery bridge regression smoke test.")

	assertCondition(RunService:IsStudio(), "Discovery bridge regression smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "PromptBindingService should bind prompts.")

	local player = makeFakePlayer(950001, "DiscoveryBridgeRegression")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Regression player data should initialize.")
	assertResultSuccess(PromptBindingService.RefreshPlayer(player), "Prompt visibility should refresh for regression player.")

	local preQuestDisplayResult = trigger(
		PromptBindingService,
		player,
		"interaction_disc_ep01_command_star_core_display",
		"Star Core Display discovery should record before Quest 001 starts."
	)
	assertCondition(preQuestDisplayResult.GrantedDiscovery == true, "Pre-quest Star Core Display interaction should record discovery.")
	assertCondition(preQuestDisplayResult.GrantedQuestProgress == false, "Pre-quest Star Core Display interaction should not progress inactive Quest 001.")
	assertCondition(preQuestDisplayResult.Code == "DiscoveryRecordedQuestNotActive", "Pre-quest Star Core Display should return DiscoveryRecordedQuestNotActive.")
	assertHintText(preQuestDisplayResult, "Pre-quest discovery bridge success should include HintText.")

	local discoveryState = DiscoveryService.GetDiscoveryState(player, "disc_ep01_command_star_core_display")
	assertResultSuccess(discoveryState, "Star Core Display discovery state should read.")
	assertCondition(discoveryState.Data.IsFound == true, "Star Core Display discovery should be recorded.")

	local questStateBeforeQuest = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(questStateBeforeQuest, "Quest 001 state should read before start.")
	assertCondition(
		questStateBeforeQuest.Data.ObjectiveStates.obj_ep01_main_001_004.Completed ~= true,
		"Quest 001 objective 004 should not complete before Quest 001 starts."
	)

	local hiddenBeforeQuestState = InteractionVisibilityService.GetInteractionState(player, "interaction_disc_ep01_command_star_core_display")
	assertResultSuccess(hiddenBeforeQuestState, "Star Core Display visibility should read before Quest 001.")
	assertCondition(hiddenBeforeQuestState.Data.Visible == false, "Recorded Star Core Display should hide before linked quest objective is active.")

	trigger(PromptBindingService, player, "interaction_start_ep01_main_001", "Quest 001 should start.")

	local incompleteQuestCompleteResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_complete_ep01_main_001", {})
	assertResultFailure(
		incompleteQuestCompleteResult,
		"RequiredObjectiveIncomplete",
		"Incomplete Quest 001 turn-in should be blocked with RequiredObjectiveIncomplete."
	)
	assertHintText(incompleteQuestCompleteResult, "Incomplete Quest 001 turn-in should include HintText.")

	trigger(PromptBindingService, player, "interaction_ep01_main_001_001", "Quest 001 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_001_002", "Quest 001 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_001_003", "Quest 001 objective 003 should progress.")

	local visibleForObjectiveState = InteractionVisibilityService.GetInteractionState(player, "interaction_disc_ep01_command_star_core_display")
	assertResultSuccess(visibleForObjectiveState, "Star Core Display visibility should read while objective 004 is active.")
	assertCondition(visibleForObjectiveState.Data.Visible == true, "Recorded Star Core Display should remain visible for active linked objective.")
	assertCondition(visibleForObjectiveState.Data.Enabled == true, "Recorded Star Core Display should remain enabled for active linked objective.")

	local bridgeResult = trigger(
		PromptBindingService,
		player,
		"interaction_disc_ep01_command_star_core_display",
		"Recorded Star Core Display should still progress Quest 001 objective 004."
	)
	assertCondition(bridgeResult.Code == "DiscoveryObjectiveProgressApplied", "Duplicate discovery bridge should return DiscoveryObjectiveProgressApplied.")
	assertCondition(bridgeResult.GrantedDiscovery == false, "Duplicate discovery bridge must not re-record discovery.")
	assertCondition(bridgeResult.GrantedQuestProgress == true, "Duplicate discovery bridge should progress the linked objective.")

	local questState = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(questState, "Quest 001 state should read.")
	assertCondition(
		questState.Data.ObjectiveStates.obj_ep01_main_001_004.Completed == true,
		"Quest 001 objective 004 should complete from recorded discovery bridge interaction."
	)

	local snapshot = PlayerDataService.GetSnapshot(player)
	assertResultSuccess(snapshot, "Player snapshot should read after bridge objective progress.")
	assertCondition(snapshot.Data.SessionStats.DiscoveriesFound == 1, "Star Core Display should not increment discovery count twice.")

	local hiddenAfterObjectiveState = InteractionVisibilityService.GetInteractionState(player, "interaction_disc_ep01_command_star_core_display")
	assertResultSuccess(hiddenAfterObjectiveState, "Star Core Display visibility should read after objective 004.")
	assertCondition(hiddenAfterObjectiveState.Data.Visible == false, "Star Core Display should hide again after linked objective completion.")

	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_disc_ep01_command_star_core_display", {}),
		"DiscoveryAlreadyRecorded",
		"Recorded Star Core Display should be blocked after linked objective is complete."
	)

	trigger(PromptBindingService, player, "interaction_complete_ep01_main_001", "Quest 001 should complete after bridged objective.")

	local quest003PrerequisiteResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_003", {})
	assertResultFailure(
		quest003PrerequisiteResult,
		"QuestPrerequisiteMissing",
		"Quest 003 should be blocked before Quest 002 is complete."
	)
	assertHintText(quest003PrerequisiteResult, "Quest prerequisite block should include HintText.")

	local pureDiscoveryResult = InteractionService.AttemptInteraction(player, "interaction_disc_ep01_command_expedition_terminal", {
		BypassCooldownForTests = true,
	})
	assertResultSuccess(pureDiscoveryResult, "Pure discovery interaction should record once.")

	local pureDiscoveryDuplicateResult = InteractionService.AttemptInteraction(player, "interaction_disc_ep01_command_expedition_terminal", {
		BypassCooldownForTests = true,
	})
	assertResultFailure(
		pureDiscoveryDuplicateResult,
		"DiscoveryAlreadyRecorded",
		"Pure discovery duplicate should remain blocked."
	)
	assertHintText(pureDiscoveryDuplicateResult, "Pure discovery duplicate should include HintText.")

	trigger(PromptBindingService, player, "interaction_start_ep01_main_002", "Quest 002 should start.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_001", "Quest 002 objective 001 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_002", "Quest 002 objective 002 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_003", "Quest 002 objective 003 should progress.")
	trigger(PromptBindingService, player, "interaction_ep01_main_002_004", "Quest 002 objective 004 should progress.")
	trigger(PromptBindingService, player, "interaction_complete_ep01_main_002", "Quest 002 should complete.")
	trigger(PromptBindingService, player, "interaction_start_ep01_main_003", "Quest 003 should start after Quest 002.")

	local dependencyResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_003_003", {})
	assertResultFailure(
		dependencyResult,
		"ObjectiveDependencyMissing",
		"Quest 003 dependent objective should be blocked before prerequisite."
	)
	assertHintText(dependencyResult, "Objective dependency block should include HintText.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Regression player data should release.")

	print("[ANP DiscoveryBridgeRegressionSmokeTest] Discovery bridge regression smoke test passed.")
end

return DiscoveryBridgeRegressionSmokeTest
