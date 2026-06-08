local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)

local Phase3ESmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3ESmokeTest] " .. message, 2)
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

local function countProximityPrompts(object)
	local count = 0
	for _, child in ipairs(object:GetChildren()) do
		if child:IsA("ProximityPrompt") then
			count += 1
		end
	end

	return count
end

local function getPromptHost(WorldRegistryService, definition)
	if definition.Type == "Discovery" then
		return WorldRegistryService.GetDiscoveryPoint(definition.DiscoveryId)
	end

	return WorldRegistryService.GetInteractionPoint(definition.InteractionId)
end

function Phase3ESmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local ZoneService = services.ZoneService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase3ESmokeTest] Starting Phase 3E smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3E smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 3E.")

	local bindResult = PromptBindingService.BindAllPrompts()
	assertResultSuccess(bindResult, "PromptBindingService should bind prompts.")
	assertCondition(bindResult.Data.BoundCount >= 8, "PromptBindingService should bind all Episode 1 prompt interactions.")

	local secondBindResult = PromptBindingService.BindAllPrompts()
	assertResultSuccess(secondBindResult, "PromptBindingService should be idempotent when binding twice.")

	for _, definition in pairs(InteractionDefinitions) do
		if definition.EnabledInWorld ~= false then
			local hostResult = getPromptHost(WorldRegistryService, definition)
			assertResultSuccess(hostResult, "Prompt host should exist for interaction `" .. definition.InteractionId .. "`.")
			assertCondition(
				countProximityPrompts(hostResult.Data) == 1,
				"Prompt host should have exactly one ProximityPrompt for `" .. definition.InteractionId .. "`."
			)
		end
	end

	local player = makeFakePlayer(933001, "Phase3EPrompt")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3E player data should initialize.")

	assertResultSuccess(QuestService.StartQuest(player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "phase3e_start_quest_001",
	}), "Quest 001 should start for prompt test.")

	local questPromptResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_001", {
		CompanionAssisted = true,
		CoopParticipantUserIds = {},
	})
	assertResultSuccess(questPromptResult, "Quest prompt should progress quest objective.")
	assertCondition(questPromptResult.GrantedQuestProgress == true, "Quest prompt should report quest progress.")

	local questState = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(questState, "Quest state should read after prompt interaction.")
	assertCondition(questState.Data.ObjectiveStates.obj_ep01_main_001_001.Completed == true, "Prompt should complete first quest objective.")
	assertCondition(questState.Data.AssistedByCompanion == true, "Prompt metadata should preserve companion-assisted progress.")

	assertResultFailure(QuestService.CompleteQuest(player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "phase3e_early_complete",
	}), "RequiredObjectiveIncomplete", "Prompt interaction cannot bypass quest requirements.")

	local discoveryPromptResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_disc_ep01_command_star_core_display", {})
	assertResultSuccess(discoveryPromptResult, "Discovery prompt should record discovery.")
	assertCondition(discoveryPromptResult.GrantedDiscovery == true, "Discovery prompt should report discovery.")

	local duplicateDiscoveryResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_disc_ep01_command_star_core_display", {})
	assertResultFailure(duplicateDiscoveryResult, "DiscoveryAlreadyRecorded", "Duplicate discovery prompt should be blocked.")

	assertResultFailure(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_missing", {}),
		"PromptNotBound",
		"Invalid prompt interaction should be rejected cleanly."
	)

	local lockedTravelResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_travel_ep01_universe_explorer", {
		SpawnPointId = "spawn_ep01_universe_default",
	})
	assertResultFailure(lockedTravelResult, "ZoneLocked", "Locked zone travel prompt should be rejected.")

	assertResultSuccess(ZoneService.UnlockZone(player, "zone_ep01_universe_explorer", {
		SourceType = "SmokeTest",
		SourceId = "phase3e_unlock_universe",
	}), "Universe zone should unlock for prompt travel.")

	local travelPromptResult = PromptBindingService.SimulatePromptTrigger(player, "interaction_travel_ep01_universe_explorer", {
		SpawnPointId = "spawn_ep01_universe_default",
		TravelMode = "Spawn",
	})
	assertResultSuccess(travelPromptResult, "Zone travel prompt should update zone state.")
	assertCondition(travelPromptResult.GrantedZoneTravel == true, "Zone travel prompt should report zone travel.")

	local zoneSnapshot = PlayerDataService.GetSnapshot(player, "Zones")
	assertResultSuccess(zoneSnapshot, "Zone state should read after prompt travel.")
	assertCondition(zoneSnapshot.Data.LastZoneId == "zone_ep01_universe_explorer", "Prompt travel should update last zone.")

	local progressionSnapshot = PlayerDataService.GetSnapshot(player, "Progression")
	assertResultSuccess(progressionSnapshot, "Progression state should read after prompt interactions.")
	assertCondition(progressionSnapshot.Data.ExplorerScore == 0, "PromptBindingService should not grant rewards directly.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3E player data should release.")

	print("[ANP Phase3ESmokeTest] Phase 3E smoke test passed.")
end

return Phase3ESmokeTest
