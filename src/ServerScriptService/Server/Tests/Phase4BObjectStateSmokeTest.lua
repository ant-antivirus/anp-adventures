local RunService = game:GetService("RunService")

local Phase4BObjectStateSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase4BObjectStateSmokeTest] " .. message, 2)
	end
end

local function assertResultSuccess(serviceResult, message)
	assertCondition(serviceResult and serviceResult.Success == true, message .. " Code: " .. tostring(serviceResult and serviceResult.Code))
end

local function assertResultFailure(serviceResult, expectedCode, message)
	assertCondition(serviceResult and serviceResult.Success == false, message)
	assertCondition(serviceResult.Code == expectedCode, message .. " Expected `" .. expectedCode .. "`, got `" .. tostring(serviceResult.Code) .. "`.")
	assertCondition(serviceResult.Data and type(serviceResult.Data.HintText) == "string" and serviceResult.Data.HintText ~= "", message .. " should include HintText.")
end

local function makeFakePlayer(userId, name)
	return {
		UserId = userId,
		Name = name,
	}
end

local function trigger(PromptBindingService, player, interactionId)
	return PromptBindingService.SimulatePromptTrigger(player, interactionId, {
		SourceType = "Phase4BObjectStateSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function directInteract(InteractionService, player, interactionId)
	return InteractionService.AttemptInteraction(player, interactionId, {
		SourceType = "Phase4BObjectStateSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function feedbackCount(PlayerFeedbackService, player, feedbackType)
	local count = 0
	for _, payload in ipairs(PlayerFeedbackService.GetSentFeedbackForTests(player)) do
		if payload.Type == feedbackType then
			count += 1
		end
	end

	return count
end

local function completeQuest001(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display"), "Quest 001 Star Core bridge should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_001"), "Quest 001 should complete.")
end

local function completeQuest002(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_002"), "Quest 002 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_001"), "Quest 002 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_002"), "Quest 002 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_003"), "Quest 002 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_002_004"), "Quest 002 objective 004 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_002"), "Quest 002 should complete.")
end

function Phase4BObjectStateSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local PlayerFeedbackService = services.PlayerFeedbackService
	local InteractionService = services.InteractionService
	local InteractionVisibilityService = services.InteractionVisibilityService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase4BObjectStateSmokeTest] Starting Phase 4B object state smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 4B object state smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PlayerFeedbackService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 4B smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 4B smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 4B smoke test.")

	local player = makeFakePlayer(948501, "Phase4BObjectState")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 4B player data should initialize.")

	local earlyDiscoveryResult = trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display")
	assertResultSuccess(earlyDiscoveryResult, "Star Core Display should be discoverable before Quest 001.")
	assertCondition(earlyDiscoveryResult.Code == "DiscoveryRecordedQuestNotActive", "Early Star Core Display should return quest-not-active discovery code.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Expedition Terminal should complete once.")
	local stationDuplicateResult = trigger(PromptBindingService, player, "interaction_ep01_main_001_001")
	assertResultFailure(stationDuplicateResult, "ObjectiveAlreadyCompleted", "Station duplicate should return already-used feedback.")
	assertCondition(feedbackCount(PlayerFeedbackService, player, "Blocked") >= 1, "Station duplicate should emit blocked feedback.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	local starCoreBridgeRetry = trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display")
	assertResultSuccess(starCoreBridgeRetry, "Recorded Star Core Display should still complete active objective 004.")
	assertCondition(starCoreBridgeRetry.Code == "DiscoveryObjectiveProgressApplied", "Star Core Display retry should apply objective bridge.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_001"), "Quest 001 should complete.")

	local pureDiscoveryPlayer = makeFakePlayer(948502, "Phase4BPureDiscovery")
	assertResultSuccess(PlayerDataService.InitPlayer(pureDiscoveryPlayer), "Pure discovery player data should initialize.")
	local pureDiscoveryFirst = directInteract(InteractionService, pureDiscoveryPlayer, "interaction_disc_ep01_command_expedition_terminal")
	assertResultSuccess(pureDiscoveryFirst, "Pure discovery should record once.")
	local pureDiscoveryDuplicate = directInteract(InteractionService, pureDiscoveryPlayer, "interaction_disc_ep01_command_expedition_terminal")
	assertResultFailure(pureDiscoveryDuplicate, "DiscoveryAlreadyRecorded", "Pure discovery duplicate should be blocked with already-discovered hint.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(pureDiscoveryPlayer), "Pure discovery player data should release.")

	completeQuest002(PromptBindingService, player)

	local inspectableState = InteractionVisibilityService.GetInteractionState(player, "interaction_ep01_main_003_003")
	assertResultSuccess(inspectableState, "Inspectable locked fragment state should read before Quest 003 starts.")
	assertCondition(inspectableState.Data.Visible == true and inspectableState.Data.Enabled == true, "Inspectable locked fragment should remain visible and enabled before quest activation.")
	local lockedInactiveResult = trigger(PromptBindingService, player, "interaction_ep01_main_003_003")
	assertResultFailure(lockedInactiveResult, "QuestNotActive", "Locked inspectable fragment should return quest-not-active hint before Quest 003 starts.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_003"), "Quest 003 should start.")

	local dependentState = InteractionVisibilityService.GetInteractionState(player, "interaction_ep01_main_003_003")
	assertResultSuccess(dependentState, "Dependent fragment state should read after Quest 003 starts.")
	assertCondition(dependentState.Data.Visible == false and dependentState.Data.Enabled == false, "Dependency-gated fragment should hide before prerequisite.")
	local lockedDependencyResult = directInteract(InteractionService, player, "interaction_ep01_main_003_003")
	assertResultFailure(lockedDependencyResult, "ObjectiveDependencyMissing", "Locked fragment should still return dependency hint if processed directly.")

	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_002"), "Quest 003 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_003"), "Quest 003 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_003_004"), "Universe Fragment collectible should complete once.")
	local collectibleDuplicateResult = trigger(PromptBindingService, player, "interaction_ep01_main_003_004")
	assertResultFailure(collectibleDuplicateResult, "ObjectiveAlreadyCompleted", "Collectible duplicate should return already-collected feedback.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 4B player data should release.")

	print("[ANP Phase4BObjectStateSmokeTest] Phase 4B object state smoke test passed.")
end

return Phase4BObjectStateSmokeTest
