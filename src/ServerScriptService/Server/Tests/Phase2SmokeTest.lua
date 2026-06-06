local Phase2SmokeTest = {}

local REQUIRED_EP01_FRAGMENTS = {
	"item_ep01_fragment_universe",
	"item_ep01_fragment_earth",
	"item_ep01_fragment_theos",
	"item_ep01_fragment_rocket",
	"item_ep01_fragment_moon",
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase2SmokeTest] " .. message, 2)
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

function Phase2SmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local ProgressionService = services.ProgressionService
	local InventoryService = services.InventoryService
	local RewardService = services.RewardService

	print("[ANP Phase2SmokeTest] Starting Phase 2 smoke test.")

	PlayerDataService.ResetForTests()

	local playerA = makeFakePlayer(900001, "Phase2SmokeA")
	local playerB = makeFakePlayer(900002, "Phase2SmokeB")
	local studioTestPlayer = makeFakePlayer(-1, "StudioPlayer1")
	local studioDelayedPlayer = makeFakePlayer(nil, "StudioPlayer2")
	local studioZeroPlayerA = makeFakePlayer(0, "StudioZeroPlayerA")
	local studioZeroPlayerB = makeFakePlayer(0, "StudioZeroPlayerB")

	assertResultSuccess(PlayerDataService.InitPlayer(playerA), "Player A data should initialize.")
	assertResultSuccess(PlayerDataService.InitPlayer(playerB), "Player B data should initialize.")
	assertCondition(PlayerDataService.IsValidPlayerForSession(studioTestPlayer) == true, "Studio test player UserIds should be valid while smoke tests run in Studio.")
	assertResultSuccess(PlayerDataService.InitPlayer(studioTestPlayer), "Studio test player data should initialize with a non-production UserId.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(studioTestPlayer), "Studio test player data should release.")
	assertCondition(PlayerDataService.IsValidPlayerForSession(studioDelayedPlayer) == true, "Studio test players should be valid even when UserId is not production-shaped.")
	assertResultSuccess(PlayerDataService.InitPlayer(studioDelayedPlayer), "Studio delayed identity player data should initialize.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(studioDelayedPlayer), "Studio delayed identity player data should release.")
	assertResultSuccess(PlayerDataService.InitPlayer(studioZeroPlayerA), "First Studio zero UserId player data should initialize.")
	assertResultSuccess(PlayerDataService.InitPlayer(studioZeroPlayerB), "Second Studio zero UserId player data should initialize without colliding.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(studioZeroPlayerA), "First Studio zero UserId player data should release.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(studioZeroPlayerB), "Second Studio zero UserId player data should release.")

	local playerAInventory = PlayerDataService.GetSnapshot(playerA, "Inventory")
	local playerBInventory = PlayerDataService.GetSnapshot(playerB, "Inventory")
	assertResultSuccess(playerAInventory, "Player A inventory snapshot should read.")
	assertResultSuccess(playerBInventory, "Player B inventory snapshot should read.")
	assertCondition(playerAInventory.Data ~= playerBInventory.Data, "Players must not share inventory tables.")

	assertResultSuccess(ProgressionService.AddExplorerScore(playerA, 25, {
		SourceType = "SmokeTest",
		SourceId = "phase2_progression",
	}), "ProgressionService should add Explorer Score.")

	local progression = ProgressionService.GetProgression(playerA)
	assertResultSuccess(progression, "Progression snapshot should read.")
	assertCondition(progression.Data.ExplorerScore == 25, "Explorer Score should be 25 after direct progression smoke grant.")

	assertResultSuccess(InventoryService.AddItem(playerA, "item_ep01_fragment_universe", 1, {
		SourceType = "SmokeTest",
		SourceId = "phase2_inventory",
	}), "InventoryService should add an item.")
	assertCondition(InventoryService.HasItem(playerA, "item_ep01_fragment_universe", 1), "InventoryService should report owned item.")
	assertCondition(not InventoryService.HasItem(playerB, "item_ep01_fragment_universe", 1), "Player B must not receive Player A inventory mutation.")
	assertCondition(
		RewardService.BuildRewardClaimId("reward_ep01_teamwork_main_002") == "RewardBundle:reward_ep01_teamwork_main_002:reward_ep01_teamwork_main_002",
		"RewardService should default missing source context into a stable RewardClaimId."
	)

	local main001SourceContext = {
		SourceType = "SmokeTest",
		SourceId = "reward_ep01_main_001",
	}
	local main001 = RewardService.GrantRewardBundle(playerA, "reward_ep01_main_001", main001SourceContext)
	assertResultSuccess(main001, "RewardService should grant reward_ep01_main_001 once.")
	assertCondition(main001.Data.RewardClaimId == "SmokeTest:reward_ep01_main_001:reward_ep01_main_001", "Reward summary should include source-specific RewardClaimId.")

	local exactDuplicateMain001 = RewardService.GrantRewardBundle(playerA, "reward_ep01_main_001", main001SourceContext)
	assertResultFailure(exactDuplicateMain001, "DuplicateRewardBlocked", "RewardService should block duplicate reward_ep01_main_001 source context.")

	local duplicateMain001 = RewardService.GrantRewardBundle(playerA, "reward_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "reward_ep01_main_001_duplicate",
	})
	assertResultFailure(duplicateMain001, "DuplicateRewardBlocked", "RewardService should block alternate source reward_ep01_main_001 because its DuplicatePolicy is bundle-wide.")

	local teamworkSourceA = {
		SourceType = "TeamworkContribution",
		SourceId = "phase2_teamwork_a",
	}
	local teamworkRewardA = RewardService.GrantRewardBundle(playerA, "reward_ep01_teamwork_main_001", teamworkSourceA)
	assertResultSuccess(teamworkRewardA, "Source-specific teamwork reward should grant for first source.")
	assertCondition(teamworkRewardA.Data.RewardClaimId == "TeamworkContribution:phase2_teamwork_a:reward_ep01_teamwork_main_001", "Teamwork reward should include source-specific RewardClaimId.")

	local duplicateTeamworkRewardA = RewardService.GrantRewardBundle(playerA, "reward_ep01_teamwork_main_001", teamworkSourceA)
	assertResultFailure(duplicateTeamworkRewardA, "DuplicateRewardBlocked", "Source-specific teamwork reward should block duplicate source context.")

	local teamworkRewardB = RewardService.GrantRewardBundle(playerA, "reward_ep01_teamwork_main_001", {
		SourceType = "TeamworkContribution",
		SourceId = "phase2_teamwork_b",
	})
	assertResultSuccess(teamworkRewardB, "Source-specific teamwork reward should allow a different valid source context.")

	local discoveryReward = RewardService.GrantRewardBundle(playerA, "reward_ep01_discovery_theos_satellite_history", {
		SourceType = "SmokeTest",
		SourceId = "disc_ep01_theos_satellite_history",
	})
	assertResultSuccess(discoveryReward, "RewardService should grant a THEOS discovery reward.")

	local main008Missing = RewardService.GrantRewardBundle(playerB, "reward_ep01_main_008", {
		SourceType = "SmokeTest",
		SourceId = "reward_ep01_main_008_missing_items",
	})
	assertResultFailure(main008Missing, "MissingEpisodeOneAssemblyItem", "RewardService should require Episode 1 fragments before final reward.")

	for _, fragmentId in ipairs(REQUIRED_EP01_FRAGMENTS) do
		assertResultSuccess(InventoryService.AddItem(playerB, fragmentId, 1, {
			SourceType = "SmokeTest",
			SourceId = "phase2_fragment_setup",
		}), "Smoke setup should add " .. fragmentId)
	end

	local beforeFinalInventory = InventoryService.GetInventory(playerB)
	assertResultSuccess(beforeFinalInventory, "Inventory snapshot before final reward should read.")

	local main008 = RewardService.GrantRewardBundle(playerB, "reward_ep01_main_008", {
		SourceType = "SmokeTest",
		SourceId = "reward_ep01_main_008",
	})
	assertResultSuccess(main008, "RewardService should grant reward_ep01_main_008 when required fragments are present.")
	assertCondition(InventoryService.HasItem(playerB, "item_star_core_segment_01", 1), "Final reward should grant item_star_core_segment_01.")

	local afterFinalInventory = InventoryService.GetInventory(playerB)
	assertResultSuccess(afterFinalInventory, "Inventory snapshot after final reward should read.")

	for _, fragmentId in ipairs(REQUIRED_EP01_FRAGMENTS) do
		local beforeItem = beforeFinalInventory.Data.Items[fragmentId]
		local afterItem = afterFinalInventory.Data.Items[fragmentId]
		assertCondition(beforeItem and afterItem, "Final reward must retain " .. fragmentId)
		assertCondition(afterItem.Quantity >= beforeItem.Quantity, "Final reward must not consume " .. fragmentId)
	end

	local playerASnapshot = PlayerDataService.GetSnapshot(playerA)
	assertResultSuccess(playerASnapshot, "Player A full snapshot should read.")
	assertCondition(playerASnapshot.Data.Journal.UnlockedEntryIds.journal_ep01_expedition_started == true, "Journal unlock should be recorded.")
	assertCondition(playerASnapshot.Data.Lore.UnlockedLoreIds.lore_ep01_theos_satellite_history == true, "Lore unlock should be recorded.")

	local playerBSnapshot = PlayerDataService.GetSnapshot(playerB)
	assertResultSuccess(playerBSnapshot, "Player B full snapshot should read.")
	assertCondition(playerBSnapshot.Data.Badges.AwardedBadgeIds.badge_ep01_explorer == true, "Internal badge state should update.")
	assertCondition(#playerBSnapshot.Data.Badges.PendingRobloxBadgeAwards == 0, "Smoke test must not queue or call Roblox badge API.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(playerA), "Player A data should release.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(playerB), "Player B data should release.")

	print("[ANP Phase2SmokeTest] Phase 2 smoke test passed.")
end

return Phase2SmokeTest
