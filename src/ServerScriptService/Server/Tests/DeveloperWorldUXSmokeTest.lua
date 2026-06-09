local RunService = game:GetService("RunService")

local DeveloperWorldUXSmokeTest = {}

local EXPECTED_COLORS = {
	QuestStart = Color3.fromRGB(80, 220, 120),
	QuestComplete = Color3.fromRGB(80, 230, 235),
	QuestObjective = Color3.fromRGB(90, 155, 255),
	Discovery = Color3.fromRGB(245, 210, 80),
	ZoneTravel = Color3.fromRGB(170, 110, 245),
	NPCMarker = Color3.fromRGB(245, 145, 65),
	SpawnPoint = Color3.fromRGB(245, 245, 245),
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP DeveloperWorldUXSmokeTest] " .. message, 2)
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

local function assertColor(object, expectedColor, message)
	assertCondition(object and object:IsA("BasePart"), message .. " Object should be a BasePart.")
	assertCondition(object.Color == expectedColor, message .. " Color mismatch.")
end

local function assertDeveloperLabel(object, expectedCategory, expectedFriendlyName, expectedInternalId)
	local label = object:FindFirstChild("ANP_DeveloperLabel")
	assertCondition(label and label:IsA("BillboardGui"), "Developer label should exist for `" .. object.Name .. "`.")

	local textLabel = label:FindFirstChild("Text")
	assertCondition(textLabel and textLabel:IsA("TextLabel"), "Developer label text should exist for `" .. object.Name .. "`.")
	assertCondition(string.find(textLabel.Text, expectedCategory, 1, true) ~= nil, "Developer label should include category `" .. expectedCategory .. "`.")
	assertCondition(string.find(textLabel.Text, expectedFriendlyName, 1, true) ~= nil, "Developer label should include friendly name `" .. expectedFriendlyName .. "`.")
	assertCondition(string.find(textLabel.Text, expectedInternalId, 1, true) ~= nil, "Developer label should include internal id `" .. expectedInternalId .. "`.")
end

local function assertPromptText(PromptBindingService, interactionId, expectedActionText)
	local promptResult = PromptBindingService.GetPromptForInteraction(interactionId)
	assertResultSuccess(promptResult, "Prompt should exist for `" .. interactionId .. "`.")
	assertCondition(promptResult.Data.ActionText == expectedActionText, "Prompt `" .. interactionId .. "` ActionText should be `" .. expectedActionText .. "`.")
end

function DeveloperWorldUXSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP DeveloperWorldUXSmokeTest] Starting developer world UX smoke test.")

	assertCondition(RunService:IsStudio(), "Developer world UX smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for developer world UX test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for developer world UX test.")

	local questStart = WorldRegistryService.GetInteractionPoint("interaction_start_ep01_main_001")
	assertResultSuccess(questStart, "Quest start interaction point should exist.")
	assertColor(questStart.Data, EXPECTED_COLORS.QuestStart, "QuestStart placeholder")
	assertDeveloperLabel(questStart.Data, "[QUEST START]", "Quest 001", "interaction_start_ep01_main_001")

	local questComplete = WorldRegistryService.GetInteractionPoint("interaction_complete_ep01_main_001")
	assertResultSuccess(questComplete, "Quest complete interaction point should exist.")
	assertColor(questComplete.Data, EXPECTED_COLORS.QuestComplete, "QuestComplete placeholder")
	assertDeveloperLabel(questComplete.Data, "[QUEST COMPLETE]", "Quest 001", "interaction_complete_ep01_main_001")

	local questObjective = WorldRegistryService.GetInteractionPoint("interaction_ep01_main_001_001")
	assertResultSuccess(questObjective, "Quest objective interaction point should exist.")
	assertColor(questObjective.Data, EXPECTED_COLORS.QuestObjective, "QuestObjective placeholder")
	assertDeveloperLabel(questObjective.Data, "[QUEST OBJECTIVE]", "Expedition Terminal", "interaction_ep01_main_001_001")

	local discovery = WorldRegistryService.GetDiscoveryPoint("disc_ep01_command_star_core_display")
	assertResultSuccess(discovery, "Discovery point should exist.")
	assertColor(discovery.Data, EXPECTED_COLORS.Discovery, "Discovery placeholder")
	assertDeveloperLabel(discovery.Data, "[DISCOVERY]", "Star Core Display", "disc_ep01_command_star_core_display")

	local travel = WorldRegistryService.GetInteractionPoint("interaction_travel_ep01_universe_explorer")
	assertResultSuccess(travel, "Zone travel interaction point should exist.")
	assertColor(travel.Data, EXPECTED_COLORS.ZoneTravel, "ZoneTravel placeholder")

	local spawn = WorldRegistryService.GetSpawnPoint("spawn_ep01_command_default")
	assertResultSuccess(spawn, "Spawn point should exist.")
	assertColor(spawn.Data, EXPECTED_COLORS.SpawnPoint, "SpawnPoint placeholder")
	assertDeveloperLabel(spawn.Data, "[SPAWN]", "spawn_ep01_command_default", "spawn_ep01_command_default")

	local npc = WorldRegistryService.GetNPCMarker("character_proton")
	assertResultSuccess(npc, "Proton NPC marker should exist.")
	assertColor(npc.Data, EXPECTED_COLORS.NPCMarker, "NPCMarker placeholder")
	assertDeveloperLabel(npc.Data, "[NPC GUIDE]", "Proton", "interaction_npc_proton_guide")

	assertPromptText(PromptBindingService, "interaction_start_ep01_main_001", "Start Quest")
	assertPromptText(PromptBindingService, "interaction_complete_ep01_main_001", "Complete Quest")
	assertPromptText(PromptBindingService, "interaction_ep01_main_001_001", "Interact")
	assertPromptText(PromptBindingService, "interaction_disc_ep01_command_star_core_display", "Inspect")
	assertPromptText(PromptBindingService, "interaction_travel_ep01_universe_explorer", "Travel")

	local player = makeFakePlayer(937001, "DeveloperWorldUX")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Developer UX player data should initialize.")

	local discoveryResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_disc_ep01_command_star_core_display", {})
	assertResultSuccess(discoveryResult, "Discovery should record before quest start.")
	assertCondition(discoveryResult.GrantedDiscovery == true, "Discovery interaction should record discovery before quest start.")
	assertCondition(discoveryResult.GrantedQuestProgress == false, "Discovery objective bridge should not progress inactive quest.")

	local questState = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(questState, "Quest 001 state should read after inactive discovery bridge.")
	assertCondition(questState.Data.ObjectiveStates.obj_ep01_main_001_004.Completed ~= true, "Objective bridge must require active quest.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Developer UX player data should release.")

	print("[ANP DeveloperWorldUXSmokeTest] Developer world UX smoke test passed.")
end

return DeveloperWorldUXSmokeTest
