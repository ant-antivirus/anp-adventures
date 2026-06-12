local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteractionDefinitions = require(ReplicatedStorage.Shared.Definitions.InteractionDefinitions)

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

local function assertDeveloperLabel(object, expectedCompactText, expectedInternalId)
	local label = object:FindFirstChild("ANP_DeveloperLabel")
	assertCondition(label and label:IsA("BillboardGui"), "Developer label should exist for `" .. object.Name .. "`.")
	assertCondition(label.MaxDistance <= 55, "Developer label should use compact max distance for `" .. object.Name .. "`.")

	local textLabel = label:FindFirstChild("Text")
	assertCondition(textLabel and textLabel:IsA("TextLabel"), "Developer label text should exist for `" .. object.Name .. "`.")
	assertCondition(textLabel.TextSize <= 12, "Developer label should use compact text size for `" .. object.Name .. "`.")
	assertCondition(textLabel.Text == expectedCompactText, "Developer label should use compact text `" .. expectedCompactText .. "`.")
	assertCondition(string.find(textLabel.Text, expectedInternalId, 1, true) == nil, "Developer label should hide long internal id `" .. expectedInternalId .. "` by default.")
end

local function assertPromptText(PromptBindingService, interactionId, expectedActionText)
	local promptResult = PromptBindingService.GetPromptForInteraction(interactionId)
	assertResultSuccess(promptResult, "Prompt should exist for `" .. interactionId .. "`.")
	assertCondition(promptResult.Data.ActionText == expectedActionText, "Prompt `" .. interactionId .. "` ActionText should be `" .. expectedActionText .. "`.")
end

local function assertPromptMatchesDefinition(PromptBindingService, interactionId)
	local interactionDefinition = InteractionDefinitions[interactionId]
	assertCondition(interactionDefinition ~= nil, "Interaction definition should exist for `" .. interactionId .. "`.")
	assertPromptText(PromptBindingService, interactionId, interactionDefinition.PromptActionText)
end

local function assertLeftToRight(previousObject, nextObject, message)
	assertCondition(previousObject and previousObject:IsA("BasePart"), message .. " Previous object should be a BasePart.")
	assertCondition(nextObject and nextObject:IsA("BasePart"), message .. " Next object should be a BasePart.")
	assertCondition(nextObject.Position.X > previousObject.Position.X, message .. " Next object should be farther along the test track.")
	assertCondition(math.abs(nextObject.Position.Z - previousObject.Position.Z) <= 2, message .. " Objects should stay on the same compact quest row.")
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
	assertDeveloperLabel(questStart.Data, "Q1 Start", "interaction_start_ep01_main_001")

	local questComplete = WorldRegistryService.GetInteractionPoint("interaction_complete_ep01_main_001")
	assertResultSuccess(questComplete, "Quest complete interaction point should exist.")
	assertColor(questComplete.Data, EXPECTED_COLORS.QuestComplete, "QuestComplete placeholder")
	assertDeveloperLabel(questComplete.Data, "Q1 Complete", "interaction_complete_ep01_main_001")

	local questObjective = WorldRegistryService.GetInteractionPoint("interaction_ep01_main_001_001")
	assertResultSuccess(questObjective, "Quest objective interaction point should exist.")
	assertColor(questObjective.Data, EXPECTED_COLORS.QuestObjective, "QuestObjective placeholder")
	assertDeveloperLabel(questObjective.Data, "Q1 Obj1", "interaction_ep01_main_001_001")
	assertLeftToRight(questStart.Data, questObjective.Data, "Q1 start to Q1 Obj1 layout")

	local discovery = WorldRegistryService.GetDiscoveryPoint("disc_ep01_command_star_core_display")
	assertResultSuccess(discovery, "Discovery point should exist.")
	assertColor(discovery.Data, EXPECTED_COLORS.Discovery, "Discovery placeholder")
	assertDeveloperLabel(discovery.Data, "Star Core Display", "disc_ep01_command_star_core_display")
	assertLeftToRight(questObjective.Data, discovery.Data, "Q1 Obj1 to Q1 Star Core Display layout")

	local travel = WorldRegistryService.GetInteractionPoint("interaction_travel_ep01_universe_explorer")
	assertResultSuccess(travel, "Zone travel interaction point should exist.")
	assertColor(travel.Data, EXPECTED_COLORS.ZoneTravel, "ZoneTravel placeholder")

	local spawn = WorldRegistryService.GetSpawnPoint("spawn_ep01_command_default")
	assertResultSuccess(spawn, "Spawn point should exist.")
	assertColor(spawn.Data, EXPECTED_COLORS.SpawnPoint, "SpawnPoint placeholder")
	assertDeveloperLabel(spawn.Data, "Spawn Command", "spawn_ep01_command_default")

	local npc = WorldRegistryService.GetNPCMarker("character_proton")
	assertResultSuccess(npc, "Proton NPC marker should exist.")
	assertColor(npc.Data, EXPECTED_COLORS.NPCMarker, "NPCMarker placeholder")
	assertDeveloperLabel(npc.Data, "NPC Proton", "interaction_npc_proton_guide")

	local quest008Objective5 = WorldRegistryService.GetInteractionPoint("interaction_ep01_main_008_005")
	assertResultSuccess(quest008Objective5, "Quest 008 objective 005 interaction point should exist.")
	local quest008Complete = WorldRegistryService.GetInteractionPoint("interaction_complete_ep01_main_008")
	assertResultSuccess(quest008Complete, "Quest 008 complete interaction point should exist.")
	assertLeftToRight(quest008Objective5.Data, quest008Complete.Data, "Q8 Obj5 to Q8 Complete layout")

	assertPromptMatchesDefinition(PromptBindingService, "interaction_start_ep01_main_001")
	assertPromptMatchesDefinition(PromptBindingService, "interaction_complete_ep01_main_001")
	assertPromptMatchesDefinition(PromptBindingService, "interaction_ep01_main_001_001")
	assertPromptMatchesDefinition(PromptBindingService, "interaction_disc_ep01_command_star_core_display")
	assertPromptMatchesDefinition(PromptBindingService, "interaction_travel_ep01_universe_explorer")

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
