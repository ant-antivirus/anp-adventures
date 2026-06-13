local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")

local EpisodeDefinitions = require(Definitions.EpisodeDefinitions)
local InteractionDefinitions = require(Definitions.InteractionDefinitions)
local ItemDefinitions = require(Definitions.ItemDefinitions)
local QuestDefinitions = require(Definitions.QuestDefinitions)
local RewardDefinitions = require(Definitions.RewardDefinitions)
local ZoneDefinitions = require(Definitions.ZoneDefinitions)

local Phase6DEP1ContentLockSmokeTest = {}

local EPISODE_ONE_ID = "ep01_lost_star_core"
local QUEST_IDS = {
	"quest_ep01_main_001",
	"quest_ep01_main_002",
	"quest_ep01_main_003",
	"quest_ep01_main_004",
	"quest_ep01_main_005",
	"quest_ep01_main_006",
	"quest_ep01_main_007",
	"quest_ep01_main_008",
}
local REQUIRED_OBJECTIVE_COUNTS = {
	quest_ep01_main_001 = 4,
	quest_ep01_main_002 = 4,
	quest_ep01_main_003 = 4,
	quest_ep01_main_004 = 4,
	quest_ep01_main_005 = 4,
	quest_ep01_main_006 = 4,
	quest_ep01_main_007 = 4,
	quest_ep01_main_008 = 5,
}
local ACTIVE_ZONE_IDS = {
	"zone_ep01_command_center",
	"zone_ep01_universe_explorer",
	"zone_ep01_terrain_sandbox",
	"zone_ep01_theos_satellite_center",
	"zone_ep01_rocket_mission",
	"zone_ep01_astronaut_training",
	"zone_ep01_moon_walk",
}
local FUTURE_SEGMENT_ITEM_IDS = {
	"item_star_core_segment_02",
	"item_star_core_segment_03",
	"item_star_core_segment_04",
	"item_star_core_segment_05",
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase6DEP1ContentLockSmokeTest] " .. message, 2)
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

local function trigger(PromptBindingService, player, interactionId)
	return PromptBindingService.SimulatePromptTrigger(player, interactionId, {
		SourceType = "Phase6DEP1ContentLockSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function assertNoDuplicateListValues(values, message)
	local seen = {}
	for _, value in ipairs(values or {}) do
		assertCondition(seen[value] ~= true, message .. " Duplicate `" .. tostring(value) .. "`.")
		seen[value] = true
	end
end

local function hasItemGrant(rewardDefinition, itemId)
	for _, itemGrant in ipairs(rewardDefinition.Items or {}) do
		if itemGrant.ItemId == itemId then
			return true
		end
	end

	return false
end

local function hasObjectiveInteraction(questId, objectiveId)
	for _, interactionDefinition in pairs(InteractionDefinitions) do
		if interactionDefinition.QuestId == questId and interactionDefinition.ObjectiveId == objectiveId then
			return true
		end

		for _, objectiveProgressId in ipairs(interactionDefinition.ObjectiveProgressIds or {}) do
			if objectiveProgressId == objectiveId then
				return true
			end
		end
	end

	return false
end

local function getObjectiveRouteInteractionIds(questId, objectiveId)
	local interactionIds = {}
	for interactionId, interactionDefinition in pairs(InteractionDefinitions) do
		if interactionDefinition.QuestId == questId and interactionDefinition.ObjectiveId == objectiveId then
			table.insert(interactionIds, interactionId)
		else
			for _, objectiveProgressId in ipairs(interactionDefinition.ObjectiveProgressIds or {}) do
				if objectiveProgressId == objectiveId then
					table.insert(interactionIds, interactionId)
					break
				end
			end
		end
	end
	table.sort(interactionIds)

	return interactionIds
end

local function completeQuest001(PromptBindingService, player)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_001"), "Quest 001 objective 001 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_002"), "Quest 001 objective 002 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_ep01_main_001_003"), "Quest 001 objective 003 should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_disc_ep01_command_star_core_display"), "Quest 001 Star Core bridge should complete.")
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_001"), "Quest 001 should complete.")
end

local function completeQuest(PromptBindingService, player, questNumber, objectiveCount)
	local paddedQuestNumber = string.format("%03d", questNumber)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " should start.")
	for objectiveIndex = 1, objectiveCount do
		assertResultSuccess(
			trigger(PromptBindingService, player, "interaction_ep01_main_" .. paddedQuestNumber .. "_" .. string.format("%03d", objectiveIndex)),
			"Quest " .. paddedQuestNumber .. " objective " .. tostring(objectiveIndex) .. " should complete."
		)
	end
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_complete_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " should complete.")
end

local function completeFullEpisode(PromptBindingService, player)
	completeQuest001(PromptBindingService, player)
	completeQuest(PromptBindingService, player, 2, 4)
	completeQuest(PromptBindingService, player, 3, 4)
	completeQuest(PromptBindingService, player, 4, 4)
	completeQuest(PromptBindingService, player, 5, 4)
	completeQuest(PromptBindingService, player, 6, 4)
	completeQuest(PromptBindingService, player, 7, 4)
	completeQuest(PromptBindingService, player, 8, 5)
end

local function assertEpisodeAndQuestDefinitions()
	local episodeDefinition = EpisodeDefinitions[EPISODE_ONE_ID]
	assertCondition(episodeDefinition ~= nil, "Episode 1 definition should exist.")
	assertCondition(#episodeDefinition.QuestIds == #QUEST_IDS, "Episode 1 should include exactly the locked Q1-Q8 quest list.")
	for index, questId in ipairs(QUEST_IDS) do
		assertCondition(episodeDefinition.QuestIds[index] == questId, "Episode 1 quest order should keep `" .. questId .. "` at index " .. tostring(index) .. ".")
		local questDefinition = QuestDefinitions[questId]
		assertCondition(questDefinition ~= nil, "Quest definition `" .. questId .. "` should exist.")
		assertCondition(#(questDefinition.RequiredObjectiveIds or {}) == REQUIRED_OBJECTIVE_COUNTS[questId], "Quest `" .. questId .. "` should keep required objective count " .. tostring(REQUIRED_OBJECTIVE_COUNTS[questId]) .. ".")
		assertNoDuplicateListValues(questDefinition.RequiredObjectiveIds, "Quest `" .. questId .. "` required objectives should be unique.")
		assertCondition(#(questDefinition.RequiredObjectiveIds or {}) <= #(questDefinition.ObjectiveIds or questDefinition.RequiredObjectiveIds or {}), "Optional objectives should not reduce required objective count for `" .. questId .. "`.")
	end

	for questId in pairs(QuestDefinitions) do
		assertCondition(string.find(questId, "ep02", 1, true) == nil, "No active EP2 quest definition should be present in MVP lock.")
	end
end

local function assertInteractions()
	local seenInteractionIds = {}
	for interactionId, interactionDefinition in pairs(InteractionDefinitions) do
		assertCondition(seenInteractionIds[interactionId] ~= true, "Interaction ID `" .. tostring(interactionId) .. "` should be unique.")
		seenInteractionIds[interactionId] = true
		assertCondition(interactionDefinition.InteractionId == nil or interactionDefinition.InteractionId == interactionId, "Interaction key should match InteractionId field for `" .. tostring(interactionId) .. "`.")
	end

	for questNumber, questId in ipairs(QUEST_IDS) do
		local paddedQuestNumber = string.format("%03d", questNumber)
		assertCondition(InteractionDefinitions["interaction_start_ep01_main_" .. paddedQuestNumber] ~= nil, "Quest `" .. questId .. "` should have a start interaction.")
		assertCondition(InteractionDefinitions["interaction_complete_ep01_main_" .. paddedQuestNumber] ~= nil, "Quest `" .. questId .. "` should have a complete interaction.")

		for _, objectiveId in ipairs(QuestDefinitions[questId].RequiredObjectiveIds) do
			assertCondition(hasObjectiveInteraction(questId, objectiveId), "Required objective `" .. objectiveId .. "` should have an interaction route.")
		end
	end

	assertCondition(InteractionDefinitions.interaction_ep01_main_008_005 ~= nil, "Quest 008 objective 5 interaction should exist.")
end

local function assertRewardsAndItems()
	local finalReward = RewardDefinitions.reward_ep01_main_008
	assertCondition(finalReward ~= nil, "Quest 008 final reward should exist.")
	assertCondition(ItemDefinitions.item_star_core_segment_01 ~= nil, "Star Core Segment 01 item should exist.")
	assertCondition(hasItemGrant(finalReward, "item_star_core_segment_01"), "Quest 008 final reward should grant Star Core Segment 01.")
	assertCondition(not hasItemGrant(finalReward, "item_star_core"), "Quest 008 final reward should not grant complete Star Core.")

	for _, futureSegmentItemId in ipairs(FUTURE_SEGMENT_ITEM_IDS) do
		assertCondition(not hasItemGrant(finalReward, futureSegmentItemId), "Quest 008 final reward should not grant `" .. futureSegmentItemId .. "`.")
	end

	assertCondition(RewardDefinitions.reward_ep01_objective_008_moon_fragment ~= nil, "Moon Fragment objective reward should exist.")
end

local function assertZones()
	for _, zoneId in ipairs(ACTIVE_ZONE_IDS) do
		assertCondition(ZoneDefinitions[zoneId] ~= nil, "Active EP1 zone `" .. zoneId .. "` should exist.")
	end
end

local function assertWorldBindings(services)
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService
	local PromptBindingService = services.PromptBindingService

	PromptBindingService.ResetForTests()
	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 6D content lock.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 6D content lock.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompt binding should succeed for Phase 6D content lock.")

	for questNumber = 1, 8 do
		local paddedQuestNumber = string.format("%03d", questNumber)
		local questId = "quest_ep01_main_" .. paddedQuestNumber
		assertResultSuccess(WorldRegistryService.GetInteractionPoint("interaction_start_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " start marker should exist.")
		assertResultSuccess(WorldRegistryService.GetInteractionPoint("interaction_complete_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " complete marker should exist.")
		for _, objectiveId in ipairs(QuestDefinitions[questId].RequiredObjectiveIds) do
			local routeInteractionIds = getObjectiveRouteInteractionIds(questId, objectiveId)
			assertCondition(#routeInteractionIds > 0, "Required objective `" .. objectiveId .. "` should have a world route.")
			local hasWorldHost = false
			for _, interactionId in ipairs(routeInteractionIds) do
				local definition = InteractionDefinitions[interactionId]
				local hostResult
				if definition.Type == "Discovery" then
					hostResult = WorldRegistryService.GetDiscoveryPoint(definition.DiscoveryId)
					if not hostResult.Success then
						hostResult = WorldRegistryService.GetInteractionPoint(interactionId)
					end
				else
					hostResult = WorldRegistryService.GetInteractionPoint(interactionId)
				end
				if hostResult.Success then
					hasWorldHost = true
					break
				end
			end
			assertCondition(hasWorldHost, "Required objective `" .. objectiveId .. "` should have a registered prompt host.")
		end
	end
end

local function assertTrackerAndOnboardingCompatibility(services)
	local PlayerDataService = services.PlayerDataService
	local QuestTrackerService = services.QuestTrackerService
	local OnboardingService = services.OnboardingService
	local PromptBindingService = services.PromptBindingService

	local player = makeFakePlayer(960601, "Phase6DContentLock")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Content lock player data should initialize.")
	local freshEligibility = OnboardingService.ShouldShowFirstTimeOnboarding(player)
	assertResultSuccess(freshEligibility, "Fresh player onboarding eligibility should read.")
	assertCondition(freshEligibility.Data.ShouldShow == true, "Fresh player should be onboarding eligible.")

	completeQuest001(PromptBindingService, player)
	completeQuest(PromptBindingService, player, 2, 4)
	completeQuest(PromptBindingService, player, 3, 4)
	completeQuest(PromptBindingService, player, 4, 4)
	completeQuest(PromptBindingService, player, 5, 4)
	completeQuest(PromptBindingService, player, 6, 4)
	completeQuest(PromptBindingService, player, 7, 4)
	assertResultSuccess(trigger(PromptBindingService, player, "interaction_start_ep01_main_008"), "Quest 008 should start for tracker contract check.")

	local trackerResult = QuestTrackerService.BuildTrackerState(player)
	assertResultSuccess(trackerResult, "Quest 008 tracker should build.")
	assertCondition(trackerResult.Data.QuestId == "quest_ep01_main_008", "Tracker should target Quest 008.")
	assertCondition(trackerResult.Data.TotalObjectiveCount == 5, "Quest 008 tracker should keep total objective count at 5.")
	assertCondition(string.find(trackerResult.Data.ProgressText or "", "/ 5", 1, true) ~= nil, "Quest 008 tracker progress should include `/ 5`.")
	assertCondition(trackerResult.Data.QuestTitle ~= nil, "Tracker should include safe quest title text.")
	assertCondition(trackerResult.Data.CurrentObjectiveText ~= nil, "Tracker should include safe objective text.")
	assertCondition(trackerResult.Data.HintText ~= nil, "Tracker should include safe hint text.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Content lock tracker player should release.")

	local completedPlayer = makeFakePlayer(960602, "Phase6DOnboardingComplete")
	assertResultSuccess(PlayerDataService.InitPlayer(completedPlayer), "Completed onboarding player data should initialize.")
	completeFullEpisode(PromptBindingService, completedPlayer)
	local beforePayload = services.SaveService.BuildSave(completedPlayer)
	assertResultSuccess(beforePayload, "Completed onboarding save payload should build.")
	local completedEligibility = OnboardingService.ShouldShowFirstTimeOnboarding(completedPlayer)
	assertResultSuccess(completedEligibility, "Completed Episode 1 onboarding eligibility should read.")
	assertCondition(completedEligibility.Data.ShouldShow == false, "Completed Episode 1 player should not receive first-time onboarding.")
	local sendResult = OnboardingService.SendInitialOnboarding(completedPlayer)
	assertCondition(sendResult.Success == true and sendResult.Code == "OnboardingSkipped", "Completed player onboarding should skip safely.")
	local afterPayload = services.SaveService.BuildSave(completedPlayer)
	assertResultSuccess(afterPayload, "Completed onboarding save payload should build after skip.")
	assertCondition(afterPayload.Data.UpdatedAt >= beforePayload.Data.UpdatedAt, "Onboarding skip should not invalidate save payload.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(completedPlayer), "Completed onboarding player should release.")
end

local function assertSaveCompatibility(services)
	local PlayerDataService = services.PlayerDataService
	local PromptBindingService = services.PromptBindingService
	local SaveService = services.SaveService
	local InventoryService = services.InventoryService
	local EpisodeService = services.EpisodeService
	local MockPersistenceService = services.MockPersistenceService

	MockPersistenceService.ResetForTests()
	local player = makeFakePlayer(960603, "Phase6DSaveCompatibility")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Save compatibility player should initialize.")
	completeFullEpisode(PromptBindingService, player)
	local saveResult = SaveService.BuildSave(player)
	assertResultSuccess(saveResult, "Full EP1 content lock save should build.")
	assertResultSuccess(SaveService.ValidateSavePayload(saveResult.Data), "Full EP1 content lock save should validate.")
	assertResultSuccess(SaveService.SavePlayerToMock(player), "Full EP1 content lock save should store to mock.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Save compatibility player should release before load.")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Save compatibility player should reinitialize before load.")
	assertResultSuccess(SaveService.LoadPlayerFromMock(player), "Full EP1 content lock save should load from mock.")

	local questSnapshot = PlayerDataService.GetSnapshot(player, "Quests")
	assertResultSuccess(questSnapshot, "Loaded quest snapshot should read.")
	for _, questId in ipairs(QUEST_IDS) do
		assertCondition(questSnapshot.Data.CompletedQuestIds[questId] == true, "Loaded save should preserve completed `" .. questId .. "`.")
	end

	local episodeState = EpisodeService.GetPlayerEpisodeState(player, EPISODE_ONE_ID)
	assertResultSuccess(episodeState, "Loaded EP1 episode state should read.")
	assertCondition(episodeState.Data.IsCompleted == true, "Loaded save should preserve Episode 1 completion.")
	assertCondition(InventoryService.HasItem(player, "item_star_core_segment_01", 1) == true, "Loaded save should preserve Star Core Segment 01.")
	assertCondition(PlayerDataService.HasRewardBundleClaim(player, "reward_ep01_main_008") == true, "Loaded save should preserve final reward claim.")

	for _, futureSegmentItemId in ipairs(FUTURE_SEGMENT_ITEM_IDS) do
		assertCondition(InventoryService.HasItem(player, futureSegmentItemId, 1) == false, "Loaded save should not include `" .. futureSegmentItemId .. "`.")
	end

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Save compatibility player should release after load.")
end

function Phase6DEP1ContentLockSmokeTest.Run(services)
	print("[ANP Phase6DEP1ContentLockSmokeTest] Starting Phase 6D EP1 content lock smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 6D EP1 content lock smoke test must run in Studio only.")

	services.PlayerDataService.ResetForTests()
	services.PlayerFeedbackService.ResetForTests()
	services.MockPersistenceService.ResetForTests()
	services.PromptBindingService.ResetForTests()

	assertEpisodeAndQuestDefinitions()
	assertInteractions()
	assertRewardsAndItems()
	assertZones()
	assertWorldBindings(services)
	assertTrackerAndOnboardingCompatibility(services)
	assertSaveCompatibility(services)

	print("[ANP Phase6DEP1ContentLockSmokeTest] Phase 6D EP1 content lock smoke test passed.")
end

return Phase6DEP1ContentLockSmokeTest
