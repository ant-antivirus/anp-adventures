local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestDefinitions = require(ReplicatedStorage.Shared.Definitions.QuestDefinitions)

local Phase6BVisualWorldPresentationSmokeTest = {}

local WORLD_ROOT_NAME = "ANP_World"

local EPISODE_ONE_ZONE_IDS = {
	"zone_ep01_command_center",
	"zone_ep01_universe_explorer",
	"zone_ep01_terrain_sandbox",
	"zone_ep01_theos_satellite_center",
	"zone_ep01_rocket_mission",
	"zone_ep01_astronaut_training",
	"zone_ep01_moon_walk",
}

local QUEST_START_INTERACTIONS = {
	"interaction_start_ep01_main_001",
	"interaction_start_ep01_main_002",
	"interaction_start_ep01_main_003",
	"interaction_start_ep01_main_004",
	"interaction_start_ep01_main_005",
	"interaction_start_ep01_main_006",
	"interaction_start_ep01_main_007",
	"interaction_start_ep01_main_008",
}

local QUEST_COMPLETE_INTERACTIONS = {
	"interaction_complete_ep01_main_001",
	"interaction_complete_ep01_main_002",
	"interaction_complete_ep01_main_003",
	"interaction_complete_ep01_main_004",
	"interaction_complete_ep01_main_005",
	"interaction_complete_ep01_main_006",
	"interaction_complete_ep01_main_007",
	"interaction_complete_ep01_main_008",
}

local QUEST_008_OBJECTIVES = {
	"interaction_ep01_main_008_001",
	"interaction_ep01_main_008_002",
	"interaction_ep01_main_008_003",
	"interaction_ep01_main_008_004",
	"interaction_ep01_main_008_005",
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase6BVisualWorldPresentationSmokeTest] " .. message, 2)
	end
end

local function assertResultSuccess(serviceResult, message)
	assertCondition(serviceResult and serviceResult.Success == true, message .. " Code: " .. tostring(serviceResult and serviceResult.Code))
end

local function getWorldFolder(folderName)
	local worldRoot = Workspace:FindFirstChild(WORLD_ROOT_NAME)
	assertCondition(worldRoot ~= nil, "Skeleton world root should exist.")

	local folder = worldRoot:FindFirstChild(folderName)
	assertCondition(folder ~= nil, "World folder `" .. folderName .. "` should exist.")
	return folder
end

local function assertPromptExists(PromptBindingService, interactionId)
	local promptResult = PromptBindingService.GetPromptForInteraction(interactionId)
	assertResultSuccess(promptResult, "Prompt should bind for `" .. interactionId .. "`.")
	assertCondition(promptResult.Data.ObjectText ~= nil, "Prompt `" .. interactionId .. "` should keep display object text.")
end

local function assertInteractionMarker(WorldRegistryService, interactionId, expectedType)
	local interactionResult = WorldRegistryService.GetInteractionPoint(interactionId)
	assertResultSuccess(interactionResult, "Interaction marker should exist for `" .. interactionId .. "`.")
	assertCondition(interactionResult.Data:GetAttribute("InteractionId") == interactionId, "Interaction marker should keep InteractionId `" .. interactionId .. "`.")
	assertCondition(interactionResult.Data:GetAttribute("InteractionType") == expectedType, "Interaction marker should keep InteractionType `" .. expectedType .. "`.")
	return interactionResult.Data
end

local function assertPresentationPart(container, partName)
	local part = container:FindFirstChild(partName)
	assertCondition(part and part:IsA("BasePart"), "Presentation part `" .. partName .. "` should exist under `" .. container.Name .. "`.")
	assertCondition(part.CanCollide == false, "Presentation part `" .. partName .. "` should not block player testing.")
end

function Phase6BVisualWorldPresentationSmokeTest.Run(services)
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService
	local PromptBindingService = services.PromptBindingService

	print("[ANP Phase6BVisualWorldPresentationSmokeTest] Starting Phase 6B visual world presentation smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 6B visual world presentation smoke test must run in Studio only.")

	PromptBindingService.ResetForTests()
	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 6B smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize after Phase 6B world build.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompt binding should still succeed after Phase 6B visual presentation.")

	local presentationFolder = getWorldFolder("WorldPresentation")
	local zonesFolder = getWorldFolder("Zones")

	for _, zoneId in ipairs(EPISODE_ONE_ZONE_IDS) do
		local zoneMarker = zonesFolder:FindFirstChild("Zone_" .. zoneId)
		assertCondition(zoneMarker and zoneMarker:IsA("BasePart"), "Zone marker should still exist for `" .. zoneId .. "`.")

		local zonePresentation = presentationFolder:FindFirstChild(zoneId)
		assertCondition(zonePresentation and zonePresentation:IsA("Folder"), "Zone presentation folder should exist for `" .. zoneId .. "`.")
		assertPresentationPart(zonePresentation, "PresentationPlatform")
		assertPresentationPart(zonePresentation, "RouteStripe")
		assertPresentationPart(zonePresentation, "ZoneSign")
	end

	local questPath = presentationFolder:FindFirstChild("QuestPath")
	assertCondition(questPath and questPath:IsA("Folder"), "Quest path presentation folder should exist.")
	for questIndex = 1, 8 do
		local questId = string.format("quest_ep01_main_%03d", questIndex)
		local requiredObjectives = (QuestDefinitions[questId] and QuestDefinitions[questId].RequiredObjectiveIds) or {}
		assertPresentationPart(questPath, "Q" .. questIndex .. "_RouteSign")
		for stepIndex = 0, #requiredObjectives do
			assertPresentationPart(questPath, "Q" .. questIndex .. "_Arrow_" .. stepIndex)
		end
	end

	for _, interactionId in ipairs(QUEST_START_INTERACTIONS) do
		local marker = assertInteractionMarker(WorldRegistryService, interactionId, "QuestStart")
		assertCondition(marker:FindFirstChild("Presentation") ~= nil, "Quest start marker should have decorative presentation for `" .. interactionId .. "`.")
		assertPromptExists(PromptBindingService, interactionId)
	end

	for _, interactionId in ipairs(QUEST_COMPLETE_INTERACTIONS) do
		local marker = assertInteractionMarker(WorldRegistryService, interactionId, "QuestComplete")
		assertCondition(marker:FindFirstChild("Presentation") ~= nil, "Quest complete marker should have decorative presentation for `" .. interactionId .. "`.")
		assertPromptExists(PromptBindingService, interactionId)
	end

	for _, interactionId in ipairs(QUEST_008_OBJECTIVES) do
		local marker = assertInteractionMarker(WorldRegistryService, interactionId, "QuestObjective")
		assertCondition(marker:FindFirstChild("Presentation") ~= nil, "Quest 008 objective marker should have decorative presentation for `" .. interactionId .. "`.")
		assertPromptExists(PromptBindingService, interactionId)
	end

	local quest008Definition = QuestDefinitions.quest_ep01_main_008
	assertCondition(#quest008Definition.RequiredObjectiveIds == 5, "Quest 008 should still have five required objectives.")

	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		assertCondition(not descendant:IsA("Remote" .. "Function"), "Phase 6B should not create request/response remotes.")
	end

	print("[ANP Phase6BVisualWorldPresentationSmokeTest] Phase 6B visual world presentation smoke test passed.")
end

return Phase6BVisualWorldPresentationSmokeTest
