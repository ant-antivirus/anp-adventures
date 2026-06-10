local RunService = game:GetService("RunService")

local Phase3DSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3DSmokeTest] " .. message, 2)
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

function Phase3DSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local ZoneService = services.ZoneService
	local InteractionService = services.InteractionService
	local InteractionValidator = services.InteractionValidator
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase3DSmokeTest] Starting Phase 3D smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3D smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 3D.")

	local validationResult = InteractionValidator.Validate(WorldRegistryService)
	if not validationResult.Success then
		for _, errorMessage in ipairs(validationResult.Errors) do
			warn("[ANP Phase3DSmokeTest] " .. errorMessage)
		end
	end
	assertCondition(validationResult.Success == true, "Interaction definitions should validate.")

	local player = makeFakePlayer(932001, "Phase3DInteraction")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3D player data should initialize.")

	assertResultSuccess(QuestService.StartQuest(player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "phase3d_start_quest_001",
	}), "Quest 001 should start for interaction test.")

	local questProgressResult = InteractionService.AttemptInteraction(player, "interaction_ep01_main_001_001", {
		CompanionAssisted = false,
		CoopParticipantUserIds = {},
		BypassCooldownForTests = true,
	})
	assertResultSuccess(questProgressResult, "Quest objective interaction should progress objective.")
	assertCondition(questProgressResult.GrantedQuestProgress == true, "Quest objective interaction should report quest progress.")

	local questState = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(questState, "Quest state should read after interaction progress.")
	assertCondition(questState.Data.ObjectiveStates.obj_ep01_main_001_001.Completed == true, "Interaction should complete first quest objective.")

	assertResultFailure(QuestService.CompleteQuest(player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "phase3d_early_complete",
	}), "RequiredObjectiveIncomplete", "Interaction cannot bypass remaining quest requirements.")

	local discoveryResult = InteractionService.AttemptInteraction(player, "interaction_disc_ep01_command_star_core_display", {
		BypassCooldownForTests = true,
	})
	assertResultSuccess(discoveryResult, "Discovery interaction should record discovery.")
	assertCondition(discoveryResult.GrantedDiscovery == true, "Discovery interaction should report discovery grant.")

	local duplicateDiscoveryResult = InteractionService.AttemptInteraction(player, "interaction_disc_ep01_command_star_core_display", {
		BypassCooldownForTests = true,
	})
	assertResultFailure(duplicateDiscoveryResult, "DiscoveryAlreadyRecorded", "Duplicate discovery interaction should be blocked.")

	assertResultFailure(InteractionService.AttemptInteraction(player, "interaction_missing", {
		BypassCooldownForTests = true,
	}), "UnknownInteractionId", "Invalid interaction should be rejected.")

	local lockedZoneResult = InteractionService.AttemptInteraction(player, "interaction_ep01_main_002_002", {
		BypassCooldownForTests = true,
	})
	assertResultFailure(lockedZoneResult, "ZoneLocked", "Locked zone interaction should be rejected before quest progress.")

	assertResultSuccess(ZoneService.UnlockZone(player, "zone_ep01_universe_explorer", {
		SourceType = "SmokeTest",
		SourceId = "phase3d_unlock_universe",
	}), "Universe zone should unlock for travel interaction.")

	local travelResult = InteractionService.AttemptInteraction(player, "interaction_travel_ep01_universe_explorer", {
		SpawnPointId = "spawn_ep01_universe_default",
		TravelMode = "Spawn",
		BypassCooldownForTests = true,
	})
	assertResultSuccess(travelResult, "Zone travel interaction should record travel.")
	assertCondition(travelResult.GrantedZoneTravel == true, "Zone travel interaction should report zone travel.")

	local zoneSnapshot = PlayerDataService.GetSnapshot(player, "Zones")
	assertResultSuccess(zoneSnapshot, "Zone state should read after travel interaction.")
	assertCondition(zoneSnapshot.Data.LastZoneId == "zone_ep01_universe_explorer", "Travel interaction should update last zone state.")
	assertCondition(zoneSnapshot.Data.LastSpawnPointId == "spawn_ep01_universe_default", "Travel interaction should update last spawn point state.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3D player data should release.")

	print("[ANP Phase3DSmokeTest] Phase 3D smoke test passed.")
end

return Phase3DSmokeTest
