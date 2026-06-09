local RunService = game:GetService("RunService")

local Phase3FBSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3FBSmokeTest] " .. message, 2)
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

local function countPromptsOnHost(prompt)
	local parent = prompt.Parent
	local count = 0
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("ProximityPrompt") then
			count += 1
		end
	end

	return count
end

local function assertSinglePrompt(PromptBindingService, interactionId)
	local promptResult = PromptBindingService.GetPromptForInteraction(interactionId)
	assertResultSuccess(promptResult, "Prompt should exist for `" .. interactionId .. "`.")
	assertCondition(countPromptsOnHost(promptResult.Data) == 1, "Rebinding should not duplicate prompt for `" .. interactionId .. "`.")
end

function Phase3FBSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local InteractionVisibilityService = services.InteractionVisibilityService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase3FBSmokeTest] Starting Phase 3F-B smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3F-B smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 3F-B.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "PromptBindingService should bind prompts for Phase 3F-B.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "PromptBindingService should allow idempotent rebinding.")

	assertSinglePrompt(PromptBindingService, "interaction_start_ep01_main_001")
	assertSinglePrompt(PromptBindingService, "interaction_ep01_main_001_001")
	assertSinglePrompt(PromptBindingService, "interaction_disc_ep01_command_star_core_display")

	local interactionsResult = WorldRegistryService.GetInteractions()
	assertResultSuccess(interactionsResult, "WorldRegistryService should expose deterministic interactions.")
	for index = 2, #interactionsResult.Data do
		assertCondition(
			interactionsResult.Data[index - 1].InteractionId <= interactionsResult.Data[index].InteractionId,
			"WorldRegistryService.GetInteractions should return deterministic sorted order."
		)
	end

	local player = makeFakePlayer(935001, "Phase3FBVisibility")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3F-B player data should initialize.")
	assertResultSuccess(InteractionVisibilityService.RefreshPlayer(player), "Initial visibility refresh should succeed.")

	assertInteractionState(InteractionVisibilityService, player, "interaction_start_ep01_main_001", true, true, "Quest 001 start should be visible before start.")
	assertPromptEnabled(PromptBindingService, "interaction_start_ep01_main_001", true, "Quest 001 start prompt should be enabled before start.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_ep01_main_001_001", false, false, "Quest 001 objective should be hidden before quest active.")
	assertPromptEnabled(PromptBindingService, "interaction_ep01_main_001_001", false, "Quest 001 objective prompt should be disabled before quest active.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_disc_ep01_command_star_core_display", true, true, "Discovery should be visible before record.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_travel_ep01_universe_explorer", false, false, "Travel should be hidden while destination zone is locked.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_start_ep01_main_002", false, false, "Quest 002 start should be hidden before prerequisite and zone unlock.")

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_001", {}), "Quest 001 should start through prompt.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_start_ep01_main_001", false, false, "Quest 001 start should hide after start.")
	assertPromptEnabled(PromptBindingService, "interaction_start_ep01_main_001", false, "Quest 001 start prompt should disable after start.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_ep01_main_001_001", true, true, "Quest 001 objective should appear while active.")
	assertPromptEnabled(PromptBindingService, "interaction_ep01_main_001_001", true, "Quest 001 objective prompt should enable while active.")

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_001", {}), "Quest 001 objective 001 should progress.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_ep01_main_001_001", false, false, "Quest 001 objective should hide after completion.")
	assertPromptEnabled(PromptBindingService, "interaction_ep01_main_001_001", false, "Quest 001 objective prompt should disable after completion.")

	assertPromptEnabled(PromptBindingService, "interaction_disc_ep01_command_star_core_display", true, "Discovery prompt should be enabled before record.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_disc_ep01_command_star_core_display", {}), "Discovery should record through prompt.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_disc_ep01_command_star_core_display", false, false, "Discovery should hide after record.")
	assertPromptEnabled(PromptBindingService, "interaction_disc_ep01_command_star_core_display", false, "Discovery prompt should disable after record.")

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_002", {}), "Quest 001 objective 002 should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_003", {}), "Quest 001 objective 003 should progress.")
	assertResultSuccess(QuestService.ApplyObjectiveProgress(player, "quest_ep01_main_001", "obj_ep01_main_001_004", 1, {
		SourceType = "SmokeTest",
		SourceId = "phase3fb_complete_remaining_q001_objective",
	}, {}), "Quest 001 final required objective should progress through QuestService test hook.")
	assertResultSuccess(QuestService.CompleteQuest(player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "phase3fb_complete_q001",
	}), "Quest 001 should complete.")

	assertInteractionState(InteractionVisibilityService, player, "interaction_ep01_main_001_002", false, false, "Quest 001 objective 002 prompt should disappear after quest completion.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_ep01_main_001_003", false, false, "Quest 001 objective 003 prompt should disappear after quest completion.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_start_ep01_main_002", true, true, "Quest 002 start prompt should appear after Quest 001 completion.")
	assertPromptEnabled(PromptBindingService, "interaction_start_ep01_main_002", true, "Quest 002 start prompt should enable after Quest 001 completion.")
	assertInteractionState(InteractionVisibilityService, player, "interaction_travel_ep01_universe_explorer", true, true, "Travel prompt should appear after destination zone unlock.")
	assertPromptEnabled(PromptBindingService, "interaction_travel_ep01_universe_explorer", true, "Travel prompt should enable after destination zone unlock.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3F-B player data should release.")

	print("[ANP Phase3FBSmokeTest] Phase 3F-B smoke test passed.")
end

return Phase3FBSmokeTest
