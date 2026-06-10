local RunService = game:GetService("RunService")

local Phase3G1SmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3G1SmokeTest] " .. message, 2)
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

local function assertGuidanceContains(guidanceResult, expectedText, message)
	assertResultSuccess(guidanceResult, message)
	assertCondition(guidanceResult.Data.Guidance ~= nil, message .. " should return guidance data.")
	assertCondition(
		string.find(guidanceResult.Data.Guidance.HintText, expectedText, 1, true) ~= nil,
		message .. " Expected hint containing `" .. expectedText .. "`, got `" .. tostring(guidanceResult.Data.Guidance.HintText) .. "`."
	)
end

local function assertGuidanceContainsAll(guidanceResult, expectedTexts, message)
	assertResultSuccess(guidanceResult, message)
	assertCondition(guidanceResult.Data.Guidance ~= nil, message .. " should return guidance data.")

	local hintText = tostring(guidanceResult.Data.Guidance.HintText)
	for _, expectedText in ipairs(expectedTexts) do
		assertCondition(
			string.find(hintText, expectedText, 1, true) ~= nil,
			message .. " Expected hint containing `" .. expectedText .. "`, got `" .. hintText .. "`."
		)
	end
end

local function completeQuest001(PromptBindingService, player)
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_001", {}), "Quest 001 should start.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_001", {}), "Quest 001 objective 001 should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_002", {}), "Quest 001 objective 002 should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_003", {}), "Quest 001 objective 003 should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_disc_ep01_command_star_core_display", {}), "Quest 001 discovery bridge objective should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_complete_ep01_main_001", {}), "Quest 001 should complete through QuestComplete interaction.")
end

function Phase3G1SmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local InteractionValidator = services.InteractionValidator
	local InteractionVisibilityService = services.InteractionVisibilityService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase3G1SmokeTest] Starting Phase 3G-1 smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3G-1 smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 3G-1.")

	local validationResult = InteractionValidator.Validate(WorldRegistryService)
	if not validationResult.Success then
		for _, errorMessage in ipairs(validationResult.Errors) do
			warn("[ANP Phase3G1SmokeTest] " .. errorMessage)
		end
	end
	assertCondition(validationResult.Success == true, "Quest 002 interactions should validate.")

	assertResultSuccess(PromptBindingService.BindAllPrompts(), "PromptBindingService should bind Quest 002 prompts.")

	local player = makeFakePlayer(940001, "Phase3G1Quest002")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3G-1 player data should initialize.")
	assertResultSuccess(PromptBindingService.RefreshPlayer(player), "Prompt visibility should refresh for Phase 3G-1 player.")

	completeQuest001(PromptBindingService, player)

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_start_ep01_main_002",
		true,
		true,
		"Quest 002 start should be visible after Quest 001 completion."
	)

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_002", {}), "Quest 002 should start.")

	local quest002State = QuestService.GetQuestState(player, "quest_ep01_main_002")
	assertResultSuccess(quest002State, "Quest 002 state should read after start.")
	assertCondition(quest002State.Data.Status == QuestService.QuestStatus.Active, "Quest 002 should be active.")

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_ep01_main_002_001",
		true,
		true,
		"Quest 002 objective 001 should be visible when Quest 002 is active."
	)

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_002_001", {}), "Quest 002 objective 001 should progress through interaction.")

	local protonGuidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_proton_guide", {})
	assertGuidanceContains(protonGuidance, "Find the first signal marker", "Proton should guide to Quest 002 objective 002.")

	local neutronGuidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_neutron_guide", {})
	assertGuidanceContains(neutronGuidance, "Locate the first signal marker", "Neutron should guide to Quest 002 objective 002.")

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_002_002", {}), "Quest 002 objective 002 should progress through interaction.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_002_003", {}), "Quest 002 objective 003 should progress through interaction.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_002_004", {}), "Quest 002 objective 004 should progress through interaction.")

	local completedObjectivesState = QuestService.GetQuestState(player, "quest_ep01_main_002")
	assertResultSuccess(completedObjectivesState, "Quest 002 state should read after all objective interactions.")
	for _, objectiveId in ipairs({
		"obj_ep01_main_002_001",
		"obj_ep01_main_002_002",
		"obj_ep01_main_002_003",
		"obj_ep01_main_002_004",
	}) do
		assertCondition(
			completedObjectivesState.Data.ObjectiveStates[objectiveId].Completed == true,
			"Quest 002 required objective should be complete: " .. objectiveId
		)
	end

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_complete_ep01_main_002",
		true,
		true,
		"Quest 002 complete marker should be visible after all required objectives."
	)

	local completeResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_complete_ep01_main_002", {})
	assertResultSuccess(completeResult, "Quest 002 should complete through QuestComplete interaction.")
	assertCondition(completeResult.GrantedQuestComplete == true, "Quest 002 complete interaction should report quest completion.")

	local progressionSnapshot = PlayerDataService.GetSnapshot(player, "Progression")
	assertResultSuccess(progressionSnapshot, "Progression should read after Quest 002 completion.")
	assertCondition(progressionSnapshot.Data.ExplorerScore == 275, "Quest 001 and Quest 002 rewards should be granted through quest completion.")
	assertCondition(
		PlayerDataService.HasRewardClaim(player, "Interaction:interaction_complete_ep01_main_002:reward_ep01_main_002") == true,
		"reward_ep01_main_002 should be claimed through the Quest 002 completion interaction source."
	)

	local finalQuest002State = QuestService.GetQuestState(player, "quest_ep01_main_002")
	assertResultSuccess(finalQuest002State, "Quest 002 final state should read.")
	assertCondition(finalQuest002State.Data.Status == QuestService.QuestStatus.Completed, "Quest 002 should be completed.")

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_complete_ep01_main_002",
		false,
		false,
		"Quest 002 complete marker should hide after completion."
	)

	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_complete_ep01_main_002", {}),
		"QuestAlreadyCompleted",
		"Duplicate Quest 002 completion should be blocked."
	)

	local postQuest002Guidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_proton_guide", {})
	assertGuidanceContainsAll(
		postQuest002Guidance,
		{ "Quest 003", "available" },
		"Guidance after Quest 002 should point to Quest 003."
	)

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3G-1 player data should release.")

	print("[ANP Phase3G1SmokeTest] Phase 3G-1 smoke test passed.")
end

return Phase3G1SmokeTest
