local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TableUtil = require(Shared.Util.TableUtil)
local EpisodeDefinitions = require(Shared.Definitions.EpisodeDefinitions)
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local RewardDefinitions = require(Shared.Definitions.RewardDefinitions)
local ItemDefinitions = require(Shared.Definitions.ItemDefinitions)
local DiscoveryDefinitions = require(Shared.Definitions.DiscoveryDefinitions)
local LoreDefinitions = require(Shared.Definitions.LoreDefinitions)
local JournalDefinitions = require(Shared.Definitions.JournalDefinitions)

local FutureProofSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP FutureProofSmokeTest] " .. message, 2)
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

local function baseCatalog()
	return {
		Episodes = EpisodeDefinitions,
		Zones = ZoneDefinitions,
		Quests = QuestDefinitions,
		Rewards = RewardDefinitions,
		Items = ItemDefinitions,
		Discoveries = DiscoveryDefinitions,
		Lore = LoreDefinitions,
		Journal = JournalDefinitions,
	}
end

function FutureProofSmokeTest.Run(services)
	local AnalyticsService = services.AnalyticsService
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local DiscoveryService = services.DiscoveryService
	local ZoneService = services.ZoneService
	local GuidanceService = services.GuidanceService
	local InteractionService = services.InteractionService
	local DefinitionValidator = services.DefinitionValidator
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService
	local BadgeConfig = services.BadgeConfig
	local CompanionConfig = services.CompanionConfig

	print("[ANP FutureProofSmokeTest] Starting future-proof foundation smoke test.")

	assertCondition(RunService:IsStudio(), "Future-proof smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	InteractionService.ResetCooldownsForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for future-proof smoke test.")

	assertResultSuccess(
		AnalyticsService.Track(makeFakePlayer(941999, "AnalyticsSmoke"), "QuestStarted", {
			QuestId = "quest_ep01_main_001",
		}),
		"AnalyticsService.Track should log without error."
	)

	local validationResult = DefinitionValidator.Validate(baseCatalog(), {
		BadgeConfig = BadgeConfig,
		CompanionConfig = CompanionConfig,
	})
	assertCondition(validationResult.Success == true, "Valid ContentStatus values should pass definition validation.")

	local invalidCatalog = TableUtil.DeepCopy(baseCatalog())
	invalidCatalog.Zones.zone_ep01_command_center.ContentStatus = "InvalidStatus"
	local invalidValidationResult = DefinitionValidator.Validate(invalidCatalog, {
		BadgeConfig = BadgeConfig,
		CompanionConfig = CompanionConfig,
	})
	assertCondition(invalidValidationResult.Success == false, "Invalid ContentStatus should fail definition validation.")

	local player = makeFakePlayer(941001, "FutureProofStats")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Future-proof player data should initialize.")

	local initialSnapshot = PlayerDataService.GetSnapshot(player)
	assertResultSuccess(initialSnapshot, "Future-proof player snapshot should read.")
	assertCondition(initialSnapshot.Data.SessionStats.SessionStartTime > 0, "SessionStartTime should initialize.")
	assertCondition(initialSnapshot.Data.Journal.UnlockedLore ~= nil, "Journal.UnlockedLore default should exist.")
	assertCondition(initialSnapshot.Data.Journal.UnlockedCharacters ~= nil, "Journal.UnlockedCharacters default should exist.")
	assertCondition(initialSnapshot.Data.Journal.UnlockedZones ~= nil, "Journal.UnlockedZones default should exist.")

	assertResultSuccess(QuestService.StartQuest(player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "futureproof_start_q001",
	}), "Quest start should increment session stats.")

	local afterStartStats = PlayerDataService.GetSnapshot(player, "SessionStats")
	assertResultSuccess(afterStartStats, "SessionStats should read after quest start.")
	assertCondition(afterStartStats.Data.QuestsStarted == 1, "QuestsStarted should increment.")

	assertResultSuccess(QuestService.ApplyObjectiveProgress(player, "quest_ep01_main_001", "obj_ep01_main_001_001", 1, {
		SourceType = "SmokeTest",
		SourceId = "futureproof_obj_001",
	}), "Quest 001 objective 001 should progress.")
	assertResultSuccess(QuestService.ApplyObjectiveProgress(player, "quest_ep01_main_001", "obj_ep01_main_001_002", 1, {
		SourceType = "SmokeTest",
		SourceId = "futureproof_obj_002",
	}), "Quest 001 objective 002 should progress.")
	assertResultSuccess(QuestService.ApplyObjectiveProgress(player, "quest_ep01_main_001", "obj_ep01_main_001_003", 1, {
		SourceType = "SmokeTest",
		SourceId = "futureproof_obj_003",
	}), "Quest 001 objective 003 should progress.")
	assertResultSuccess(QuestService.ApplyObjectiveProgress(player, "quest_ep01_main_001", "obj_ep01_main_001_004", 1, {
		SourceType = "SmokeTest",
		SourceId = "futureproof_obj_004",
	}), "Quest 001 objective 004 should progress.")
	assertResultSuccess(QuestService.CompleteQuest(player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "futureproof_complete_q001",
	}), "Quest completion should increment session stats.")

	local afterCompleteStats = PlayerDataService.GetSnapshot(player, "SessionStats")
	assertResultSuccess(afterCompleteStats, "SessionStats should read after quest completion.")
	assertCondition(afterCompleteStats.Data.QuestsCompleted == 1, "QuestsCompleted should increment.")

	assertResultSuccess(DiscoveryService.RecordDiscovery(player, "disc_ep01_command_expedition_terminal", {
		SourceType = "SmokeTest",
		SourceId = "futureproof_discovery",
	}), "Discovery should increment session stats.")

	local afterDiscoveryStats = PlayerDataService.GetSnapshot(player, "SessionStats")
	assertResultSuccess(afterDiscoveryStats, "SessionStats should read after discovery.")
	assertCondition(afterDiscoveryStats.Data.DiscoveriesFound == 1, "DiscoveriesFound should increment.")

	assertResultSuccess(GuidanceService.GetPlayerGuidance(player, "character_proton"), "NPC guidance should increment session stats.")

	local afterGuidanceStats = PlayerDataService.GetSnapshot(player, "SessionStats")
	assertResultSuccess(afterGuidanceStats, "SessionStats should read after guidance.")
	assertCondition(afterGuidanceStats.Data.NPCInteractions == 1, "NPCInteractions should increment.")

	assertResultSuccess(ZoneService.TravelToZone(player, "zone_ep01_universe_explorer", "spawn_ep01_universe_default", "Spawn", {
		SourceType = "SmokeTest",
		SourceId = "futureproof_zone_travel",
	}), "Zone travel should increment session stats.")

	local afterTravelStats = PlayerDataService.GetSnapshot(player, "SessionStats")
	assertResultSuccess(afterTravelStats, "SessionStats should read after zone travel.")
	assertCondition(afterTravelStats.Data.ZoneTravels == 1, "ZoneTravels should increment.")

	InteractionService.SetCooldownDurationForTests(0.05)
	local cooldownPlayer = makeFakePlayer(941002, "FutureProofCooldown")
	assertResultSuccess(PlayerDataService.InitPlayer(cooldownPlayer), "Cooldown player data should initialize.")
	local firstGuidance = InteractionService.AttemptInteraction(cooldownPlayer, "interaction_npc_proton_guide", {})
	assertResultSuccess(firstGuidance, "First NPCGuide interaction should succeed.")
	local cooldownResult = InteractionService.AttemptInteraction(cooldownPlayer, "interaction_npc_proton_guide", {})
	assertResultFailure(
		cooldownResult,
		"InteractionCooldown",
		"Immediate repeated interaction should be blocked by cooldown."
	)
	assertCondition(cooldownResult.Reason == "InteractionCooldown", "Cooldown result should expose Reason = InteractionCooldown.")
	task.wait(0.06)
	assertResultSuccess(
		InteractionService.AttemptInteraction(cooldownPlayer, "interaction_npc_proton_guide", {}),
		"Interaction should succeed again after cooldown expires."
	)
	InteractionService.ResetCooldownsForTests()

	assertResultSuccess(PlayerDataService.ReleasePlayer(cooldownPlayer), "Cooldown player data should release.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Future-proof player data should release.")

	print("[ANP FutureProofSmokeTest] Future-proof foundation smoke test passed.")
end

return FutureProofSmokeTest
