local Phase3ASmokeTest = {}

local EPISODE_ID = "ep01_lost_star_core"
local ZONE_ID = "zone_ep01_theos_satellite_center"
local SPAWN_POINT_ID = "spawn_ep01_theos_default"
local DISCOVERY_ID = "disc_ep01_theos_satellite_history"

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3ASmokeTest] " .. message, 2)
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

function Phase3ASmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local EpisodeService = services.EpisodeService
	local ZoneService = services.ZoneService
	local DiscoveryService = services.DiscoveryService
	local ProgressionService = services.ProgressionService

	print("[ANP Phase3ASmokeTest] Starting Phase 3A smoke test.")

	PlayerDataService.ResetForTests()

	local player = makeFakePlayer(930001, "Phase3ASmoke")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Smoke player data should initialize.")

	assertResultSuccess(EpisodeService.UnlockEpisode(player, EPISODE_ID, {
		SourceType = "SmokeTest",
		SourceId = "phase3a_unlock_episode",
	}), "EpisodeService should unlock Episode 1.")

	assertCondition(EpisodeService.IsEpisodeUnlocked(player, EPISODE_ID) == true, "Episode 1 should be unlocked.")

	assertResultSuccess(EpisodeService.SetActiveEpisode(player, EPISODE_ID, {
		SourceType = "SmokeTest",
		SourceId = "phase3a_set_active_episode",
	}), "EpisodeService should set active episode.")

	local episodeState = EpisodeService.GetPlayerEpisodeState(player, EPISODE_ID)
	assertResultSuccess(episodeState, "Episode state should read.")
	assertCondition(episodeState.Data.IsActive == true, "Episode 1 should be active.")

	assertResultSuccess(ZoneService.UnlockZone(player, ZONE_ID, {
		SourceType = "SmokeTest",
		SourceId = "phase3a_unlock_zone",
	}), "ZoneService should unlock THEOS zone.")

	assertCondition(ZoneService.IsZoneUnlocked(player, ZONE_ID) == true, "THEOS zone should be unlocked.")
	assertCondition(ZoneService.CanTravelToZone(player, ZONE_ID, "Spawn") == true, "THEOS zone should be travel eligible.")

	assertResultSuccess(ZoneService.TravelToZone(player, ZONE_ID, SPAWN_POINT_ID, "Spawn", {
		SourceType = "SmokeTest",
		SourceId = "phase3a_travel_zone",
	}), "ZoneService should record travel to THEOS zone.")

	local beforeProgression = ProgressionService.GetProgression(player)
	assertResultSuccess(beforeProgression, "Progression before discovery should read.")

	assertCondition(DiscoveryService.CanRecordDiscovery(player, DISCOVERY_ID) == true, "Discovery should be recordable.")

	local discoveryResult = DiscoveryService.RecordDiscovery(player, DISCOVERY_ID, {
		SourceType = "Discovery",
		SourceId = DISCOVERY_ID,
	})
	assertResultSuccess(discoveryResult, "DiscoveryService should record THEOS discovery.")
	assertCondition(discoveryResult.Data.RewardGranted == true, "DiscoveryService should grant the discovery reward.")

	local duplicateDiscovery = DiscoveryService.RecordDiscovery(player, DISCOVERY_ID, {
		SourceType = "Discovery",
		SourceId = DISCOVERY_ID,
	})
	assertResultFailure(duplicateDiscovery, "DiscoveryAlreadyRecorded", "DiscoveryService should block duplicate discovery records.")

	local afterProgression = ProgressionService.GetProgression(player)
	assertResultSuccess(afterProgression, "Progression after discovery should read.")
	assertCondition(afterProgression.Data.ExplorerScore == beforeProgression.Data.ExplorerScore + 25, "Discovery reward should add 25 Explorer Score.")

	local playerSnapshot = PlayerDataService.GetSnapshot(player)
	assertResultSuccess(playerSnapshot, "Full player snapshot should read.")
	assertCondition(playerSnapshot.Data.Discoveries.FoundDiscoveryIds[DISCOVERY_ID] == true, "Discovery should be persisted in player discovery state.")
	assertCondition(playerSnapshot.Data.Discoveries.DiscoveryStates[DISCOVERY_ID].RewardPending == false, "Discovery reward should not remain pending after successful grant.")
	assertCondition(playerSnapshot.Data.Journal.UnlockedEntryIds.journal_ep01_theos_satellite_history == true, "Discovery reward should unlock journal entry.")
	assertCondition(playerSnapshot.Data.Lore.UnlockedLoreIds.lore_ep01_theos_satellite_history == true, "Discovery reward should unlock lore entry.")

	assertResultSuccess(EpisodeService.CompleteEpisode(player, EPISODE_ID, {
		SourceType = "SmokeTest",
		SourceId = "phase3a_complete_episode",
	}), "EpisodeService should complete Episode 1.")

	local duplicateComplete = EpisodeService.CompleteEpisode(player, EPISODE_ID, {
		SourceType = "SmokeTest",
		SourceId = "phase3a_complete_episode_duplicate",
	})
	assertResultSuccess(duplicateComplete, "EpisodeService duplicate completion should remain idempotent.")
	assertCondition(duplicateComplete.Data.WasAlreadyCompleted == true, "Duplicate episode completion should report idempotent state.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Smoke player data should release.")

	print("[ANP Phase3ASmokeTest] Phase 3A smoke test passed.")
end

return Phase3ASmokeTest
