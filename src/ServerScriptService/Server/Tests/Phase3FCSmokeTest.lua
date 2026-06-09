local RunService = game:GetService("RunService")

local Phase3FCSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3FCSmokeTest] " .. message, 2)
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

local function assertPrompt(PromptBindingService, interactionId, expectedActionText, expectedObjectText)
	local promptResult = PromptBindingService.GetPromptForInteraction(interactionId)
	assertResultSuccess(promptResult, "Prompt should exist for `" .. interactionId .. "`.")
	assertCondition(promptResult.Data.ActionText == expectedActionText, "Prompt ActionText mismatch for `" .. interactionId .. "`.")
	assertCondition(promptResult.Data.ObjectText == expectedObjectText, "Prompt ObjectText mismatch for `" .. interactionId .. "`.")
end

local function assertGuidanceContains(guidanceResult, expectedText, message)
	assertResultSuccess(guidanceResult, message)
	assertCondition(guidanceResult.Data.Guidance ~= nil, message .. " should return guidance data.")
	assertCondition(
		string.find(guidanceResult.Data.Guidance.HintText, expectedText, 1, true) ~= nil,
		message .. " Expected hint containing `" .. expectedText .. "`, got `" .. tostring(guidanceResult.Data.Guidance.HintText) .. "`."
	)
end

function Phase3FCSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local InteractionValidator = services.InteractionValidator
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase3FCSmokeTest] Starting Phase 3F-C smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3F-C smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 3F-C.")

	local validationResult = InteractionValidator.Validate(WorldRegistryService)
	if not validationResult.Success then
		for _, errorMessage in ipairs(validationResult.Errors) do
			warn("[ANP Phase3FCSmokeTest] " .. errorMessage)
		end
	end
	assertCondition(validationResult.Success == true, "NPCGuide interactions should validate.")

	local atomMarker = WorldRegistryService.GetNPCMarker("character_atom")
	assertResultSuccess(atomMarker, "Atom NPC guide marker should exist.")
	assertCondition(atomMarker.Data:GetAttribute("InteractionId") == "interaction_npc_atom_guide", "Atom marker should expose NPCGuide InteractionId.")

	local protonMarker = WorldRegistryService.GetNPCMarker("character_proton")
	assertResultSuccess(protonMarker, "Proton NPC guide marker should exist.")
	assertCondition(protonMarker.Data:GetAttribute("InteractionId") == "interaction_npc_proton_guide", "Proton marker should expose NPCGuide InteractionId.")

	assertResultSuccess(PromptBindingService.BindAllPrompts(), "PromptBindingService should bind NPC guide prompts.")
	assertPrompt(PromptBindingService, "interaction_npc_atom_guide", "Ask", "Atom")
	assertPrompt(PromptBindingService, "interaction_npc_neutron_guide", "Ask", "Neutron")
	assertPrompt(PromptBindingService, "interaction_npc_proton_guide", "Ask", "Proton")

	local player = makeFakePlayer(938001, "Phase3FCGuidance")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3F-C player data should initialize.")
	assertResultSuccess(PromptBindingService.RefreshPlayer(player), "Prompt visibility should refresh for Phase 3F-C player.")

	local initialProgression = PlayerDataService.GetSnapshot(player, "Progression")
	assertResultSuccess(initialProgression, "Initial progression should read.")
	local initialQuestState = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(initialQuestState, "Initial Quest 001 state should read.")

	local protonFreshGuidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_proton_guide", {})
	assertGuidanceContains(protonFreshGuidance, "green Quest Start marker", "Fresh player should get Proton Quest 001 start guidance.")

	local atomFreshGuidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_atom_guide", {})
	assertGuidanceContains(atomFreshGuidance, "Start your first ANP expedition", "Fresh player should get Atom motivational Quest 001 start guidance.")

	local afterGuidanceProgression = PlayerDataService.GetSnapshot(player, "Progression")
	assertResultSuccess(afterGuidanceProgression, "Progression should read after NPC guidance.")
	assertCondition(afterGuidanceProgression.Data.ExplorerScore == initialProgression.Data.ExplorerScore, "NPCGuide should not grant rewards.")

	local afterGuidanceQuestState = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(afterGuidanceQuestState, "Quest state should read after NPC guidance.")
	assertCondition(afterGuidanceQuestState.Data.Status == initialQuestState.Data.Status, "NPCGuide should not mutate quest state.")

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_001", {}), "Quest 001 should start.")

	local protonObjectiveGuidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_proton_guide", {})
	assertGuidanceContains(protonObjectiveGuidance, "Use the Expedition Terminal.", "Proton should guide to next incomplete objective.")
	assertCondition(
		protonObjectiveGuidance.Data.Guidance.NextObjectiveId == "obj_ep01_main_001_001",
		"Proton guidance should point at first incomplete Quest 001 objective."
	)

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_001", {}), "Quest 001 first objective should progress.")

	local protonUpdatedGuidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_proton_guide", {})
	assertGuidanceContains(protonUpdatedGuidance, "Review the mission briefing.", "Proton should update to next incomplete objective.")
	assertCondition(
		protonUpdatedGuidance.Data.Guidance.NextObjectiveId == "obj_ep01_main_001_002",
		"Proton guidance should advance after objective completion."
	)

	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_002", {}), "Quest 001 second objective should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_003", {}), "Quest 001 third objective should progress.")
	assertResultSuccess(PromptBindingService.SimulatePromptTrigger(player, "interaction_disc_ep01_command_star_core_display", {}), "Quest 001 discovery bridge objective should progress.")
	assertResultSuccess(QuestService.CompleteQuest(player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "phase3fc_complete_q001",
	}), "Quest 001 should complete.")

	local protonQuest002Guidance = PromptBindingService.SimulatePromptTrigger(player, "interaction_npc_proton_guide", {})
	assertGuidanceContains(protonQuest002Guidance, "Quest 002 is now available", "Proton should guide to Quest 002 after Quest 001 completion.")

	local finalProgression = PlayerDataService.GetSnapshot(player, "Progression")
	assertResultSuccess(finalProgression, "Final progression should read.")
	assertCondition(finalProgression.Data.ExplorerScore == 125, "Only Quest 001 reward should affect ExplorerScore in Phase 3F-C smoke test.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3F-C player data should release.")

	print("[ANP Phase3FCSmokeTest] Phase 3F-C smoke test passed.")
end

return Phase3FCSmokeTest
