local RunService = game:GetService("RunService")

local Phase3FDSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3FDSmokeTest] " .. message, 2)
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

local function assertPrompt(PromptBindingService, interactionId, expectedActionText, expectedObjectText)
	local promptResult = PromptBindingService.GetPromptForInteraction(interactionId)
	assertResultSuccess(promptResult, "Prompt should exist for `" .. interactionId .. "`.")
	assertCondition(promptResult.Data.ActionText == expectedActionText, "Prompt ActionText mismatch for `" .. interactionId .. "`.")
	assertCondition(promptResult.Data.ObjectText == expectedObjectText, "Prompt ObjectText mismatch for `" .. interactionId .. "`.")
	return promptResult.Data
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

function Phase3FDSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local InteractionValidator = services.InteractionValidator
	local InteractionVisibilityService = services.InteractionVisibilityService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase3FDSmokeTest] Starting Phase 3F-D smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3F-D smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 3F-D.")

	local validationResult = InteractionValidator.Validate(WorldRegistryService)
	if not validationResult.Success then
		for _, errorMessage in ipairs(validationResult.Errors) do
			warn("[ANP Phase3FDSmokeTest] " .. errorMessage)
		end
	end
	assertCondition(validationResult.Success == true, "QuestComplete interaction should validate.")

	local completePart = WorldRegistryService.GetInteractionPoint("interaction_complete_ep01_main_001")
	assertResultSuccess(completePart, "CompleteQuest_001 part should exist.")
	assertCondition(completePart.Data.Name == "CompleteQuest_001", "QuestComplete part should use readable placeholder name.")
	assertCondition(completePart.Data:GetAttribute("InteractionType") == "QuestComplete", "QuestComplete part should expose InteractionType.")

	assertResultSuccess(PromptBindingService.BindAllPrompts(), "PromptBindingService should bind QuestComplete prompt.")
	local completePrompt = assertPrompt(PromptBindingService, "interaction_complete_ep01_main_001", "ส่งภารกิจ", "ส่งภารกิจที่ 1")

	local player = makeFakePlayer(939001, "Phase3FDTurnIn")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3F-D player data should initialize.")
	assertResultSuccess(PromptBindingService.RefreshPlayer(player), "Prompt visibility should refresh for Phase 3F-D player.")

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_complete_ep01_main_001",
		false,
		false,
		"QuestComplete should be hidden before quest active."
	)
	assertCondition(completePrompt.Enabled == false, "QuestComplete prompt should be disabled before quest active.")

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_001", {}), "Quest 001 should start through interaction.")

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_complete_ep01_main_001",
		false,
		false,
		"QuestComplete should be hidden while required objectives are incomplete."
	)

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_001", {}), "Quest 001 objective 001 should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_002", {}), "Quest 001 objective 002 should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_003", {}), "Quest 001 objective 003 should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_disc_ep01_command_star_core_display", {}), "Quest 001 discovery bridge objective should progress.")

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_complete_ep01_main_001",
		true,
		true,
		"QuestComplete should become visible after all required objectives complete."
	)
	assertCondition(completePrompt.Enabled == true, "QuestComplete prompt should enable after all objectives complete.")

	local protonTurnInGuidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_proton_guide", {})
	assertGuidanceContains(protonTurnInGuidance, "สัญลักษณ์สีฟ้า", "Proton should guide to Quest Complete marker.")

	local completeResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_complete_ep01_main_001", {})
	assertResultSuccess(completeResult, "QuestComplete interaction should complete Quest 001.")
	assertCondition(completeResult.GrantedQuestComplete == true, "QuestComplete interaction should report quest completion.")

	local questState = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(questState, "Quest 001 state should read after turn-in.")
	assertCondition(questState.Data.Status == QuestService.QuestStatus.Completed, "Quest 001 should be completed after turn-in.")

	local progressionSnapshot = PlayerDataService.GetSnapshot(player, "Progression")
	assertResultSuccess(progressionSnapshot, "Progression should read after turn-in.")
	assertCondition(progressionSnapshot.Data.ExplorerScore == 125, "Quest 001 reward should be granted through QuestComplete interaction.")

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_start_ep01_main_002",
		true,
		true,
		"Quest 002 start should become visible after Quest 001 completion."
	)

	assertInteractionState(
		InteractionVisibilityService,
		player,
		"interaction_complete_ep01_main_001",
		false,
		false,
		"QuestComplete should hide after quest completion."
	)
	assertCondition(completePrompt.Enabled == false, "QuestComplete prompt should disable after quest completion.")

	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_complete_ep01_main_001", {}),
		"QuestAlreadyCompleted",
		"Duplicate QuestComplete interaction should be blocked."
	)

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3F-D player data should release.")

	print("[ANP Phase3FDSmokeTest] Phase 3F-D smoke test passed.")
end

return Phase3FDSmokeTest
