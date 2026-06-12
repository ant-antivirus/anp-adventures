local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MarkerLegendConfig = require(ReplicatedStorage.Shared.Config.MarkerLegendConfig)

local Phase6COnboardingFlowSmokeTest = {}

local EPISODE_ONE_ID = "ep01_lost_star_core"
local QUEST_ONE_ID = "quest_ep01_main_001"

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase6COnboardingFlowSmokeTest] " .. message, 2)
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

local function assertPayloadShape(payload, expectedState)
	assertCondition(payload.Type == "Onboarding", "Onboarding payload should use Type Onboarding.")
	assertCondition(payload.State == expectedState, "Onboarding payload should use state `" .. expectedState .. "`.")
	assertCondition(type(payload.Title) == "string" and payload.Title ~= "", "Onboarding payload should include a Title.")
	assertCondition(
		(type(payload.Message) == "string" and payload.Message ~= "") or (type(payload.Lines) == "table" and #payload.Lines > 0),
		"Onboarding payload should include Message or Lines."
	)
	if payload.Duration ~= nil then
		assertCondition(type(payload.Duration) == "number", "Onboarding payload Duration should be numeric when present.")
	end
end

local function assertFeedbackType(feedbackList, feedbackType, state)
	for _, payload in ipairs(feedbackList) do
		if payload.Type == feedbackType and payload.State == state then
			return payload
		end
	end

	error("[ANP Phase6COnboardingFlowSmokeTest] Expected feedback `" .. feedbackType .. "` state `" .. tostring(state) .. "`.", 2)
end

local function assertMarkerLegend()
	local expected = {
		QuestStart = { Label = "Green", Meaning = "Start Quest" },
		QuestObjective = { Label = "Blue", Meaning = "Current Objective" },
		QuestComplete = { Label = "Cyan", Meaning = "Complete Quest" },
		Discovery = { Label = "Yellow", Meaning = "Discovery" },
		ZoneTravel = { Label = "Purple", Meaning = "Travel" },
		NPCGuide = { Label = "Orange", Meaning = "Guide" },
	}

	for markerType, markerData in pairs(expected) do
		local legendEntry = MarkerLegendConfig[markerType]
		assertCondition(legendEntry ~= nil, "Marker legend should include `" .. markerType .. "`.")
		assertCondition(legendEntry.Label == markerData.Label, "Marker legend `" .. markerType .. "` should use label `" .. markerData.Label .. "`.")
		assertCondition(legendEntry.Meaning == markerData.Meaning, "Marker legend `" .. markerType .. "` should use meaning `" .. markerData.Meaning .. "`.")
	end
end

local function assertOnboardingDoesNotMutate(services, player)
	local PlayerDataService = services.PlayerDataService
	local OnboardingService = services.OnboardingService
	local SaveService = services.SaveService

	local questBefore = PlayerDataService.GetSnapshot(player, "Quests")
	local inventoryBefore = PlayerDataService.GetSnapshot(player, "Inventory")
	local episodesBefore = PlayerDataService.GetSnapshot(player, "Episodes")
	local saveBefore = SaveService.BuildSave(player)
	assertResultSuccess(questBefore, "Quest snapshot before onboarding should read.")
	assertResultSuccess(inventoryBefore, "Inventory snapshot before onboarding should read.")
	assertResultSuccess(episodesBefore, "Episode snapshot before onboarding should read.")
	assertResultSuccess(saveBefore, "Save payload before onboarding should build.")

	assertResultSuccess(OnboardingService.SendInitialOnboarding(player), "Fresh onboarding should send.")

	local questAfter = PlayerDataService.GetSnapshot(player, "Quests")
	local inventoryAfter = PlayerDataService.GetSnapshot(player, "Inventory")
	local episodesAfter = PlayerDataService.GetSnapshot(player, "Episodes")
	local saveAfter = SaveService.BuildSave(player)
	assertResultSuccess(questAfter, "Quest snapshot after onboarding should read.")
	assertResultSuccess(inventoryAfter, "Inventory snapshot after onboarding should read.")
	assertResultSuccess(episodesAfter, "Episode snapshot after onboarding should read.")
	assertResultSuccess(saveAfter, "Save payload after onboarding should build.")

	assertCondition(next(questAfter.Data.CompletedQuestIds) == next(questBefore.Data.CompletedQuestIds), "Onboarding should not complete quests.")
	assertCondition(next(questAfter.Data.ActiveQuestIds) == next(questBefore.Data.ActiveQuestIds), "Onboarding should not activate quests.")
	assertCondition(inventoryAfter.Data.Items.item_star_core_segment_01 == inventoryBefore.Data.Items.item_star_core_segment_01, "Onboarding should not grant Star Core rewards.")
	assertCondition(episodesAfter.Data.CompletedEpisodeIds[EPISODE_ONE_ID] == episodesBefore.Data.CompletedEpisodeIds[EPISODE_ONE_ID], "Onboarding should not complete episodes.")
	assertCondition(saveAfter.Data.Quests.CompletedQuestIds[QUEST_ONE_ID] == saveBefore.Data.Quests.CompletedQuestIds[QUEST_ONE_ID], "Onboarding should not mutate save quest data.")
end

local function markQuestOneCompleted(PlayerDataService, player)
	return PlayerDataService.Mutate(player, "Phase6CMarkQuestComplete", {
		SourceType = "SmokeTest",
		SourceId = "Phase6C",
	}, function(playerData)
		playerData.Quests.CompletedQuestIds[QUEST_ONE_ID] = true
		playerData.Quests.ActiveQuestIds[QUEST_ONE_ID] = nil
		playerData.Quests.QuestStates[QUEST_ONE_ID] = playerData.Quests.QuestStates[QUEST_ONE_ID] or {
			QuestId = QUEST_ONE_ID,
			Status = "Completed",
			ObjectiveStates = {},
		}
		playerData.Quests.QuestStates[QUEST_ONE_ID].Status = "Completed"
		return true
	end)
end

local function markEpisodeCompleted(PlayerDataService, player)
	return PlayerDataService.Mutate(player, "Phase6CMarkEpisodeComplete", {
		SourceType = "SmokeTest",
		SourceId = "Phase6C",
	}, function(playerData)
		playerData.Episodes.CompletedEpisodeIds[EPISODE_ONE_ID] = true
		return true
	end)
end

function Phase6COnboardingFlowSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local PlayerFeedbackService = services.PlayerFeedbackService
	local QuestService = services.QuestService
	local OnboardingService = services.OnboardingService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase6COnboardingFlowSmokeTest] Starting Phase 6C onboarding flow smoke test.")

	PlayerDataService.ResetForTests()
	PlayerFeedbackService.ResetForTests()
	PromptBindingService.ResetForTests()
	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Phase 6C smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 6C smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Phase 6C smoke test.")

	assertMarkerLegend()

	assertPayloadShape(OnboardingService.BuildWelcomePayload(), "Welcome")
	assertPayloadShape(OnboardingService.BuildEpisodeGoalPayload(), "EpisodeGoal")
	assertPayloadShape(OnboardingService.BuildMarkerLegendPayload(), "MarkerLegend")
	assertPayloadShape(OnboardingService.BuildFirstQuestHintPayload(), "FirstQuestHint")

	local freshPlayer = makeFakePlayer(960601, "Phase6CFresh")
	assertResultSuccess(PlayerDataService.InitPlayer(freshPlayer), "Fresh onboarding player should initialize.")
	local freshEligibility = OnboardingService.ShouldShowFirstTimeOnboarding(freshPlayer)
	assertResultSuccess(freshEligibility, "Fresh player onboarding eligibility should read.")
	assertCondition(freshEligibility.Data.ShouldShow == true, "Fresh player should be eligible for onboarding.")
	assertOnboardingDoesNotMutate(services, freshPlayer)

	local freshFeedback = PlayerFeedbackService.GetSentFeedbackForTests(freshPlayer)
	assertPayloadShape(assertFeedbackType(freshFeedback, "Onboarding", "Welcome"), "Welcome")
	assertPayloadShape(assertFeedbackType(freshFeedback, "Onboarding", "EpisodeGoal"), "EpisodeGoal")
	local legendPayload = assertFeedbackType(freshFeedback, "Onboarding", "MarkerLegend")
	assertPayloadShape(legendPayload, "MarkerLegend")
	assertCondition(#legendPayload.Lines >= 6, "Marker legend onboarding payload should include all marker lines.")
	assertPayloadShape(assertFeedbackType(freshFeedback, "Onboarding", "FirstQuestHint"), "FirstQuestHint")

	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		assertCondition(not descendant:IsA("Remote" .. "Function"), "Phase 6C should not create request/response remotes.")
	end

	local activePlayer = makeFakePlayer(960602, "Phase6CActive")
	assertResultSuccess(PlayerDataService.InitPlayer(activePlayer), "Active onboarding player should initialize.")
	assertResultSuccess(QuestService.StartQuest(activePlayer, QUEST_ONE_ID, {
		SourceType = "SmokeTest",
		SourceId = "Phase6C",
	}), "Quest 001 should start for active onboarding skip test.")
	local activeEligibility = OnboardingService.ShouldShowFirstTimeOnboarding(activePlayer)
	assertResultSuccess(activeEligibility, "Active player onboarding eligibility should read.")
	assertCondition(activeEligibility.Data.ShouldShow == false, "Active quest player should not receive full onboarding.")

	local completedPlayer = makeFakePlayer(960603, "Phase6CCompletedQuest")
	assertResultSuccess(PlayerDataService.InitPlayer(completedPlayer), "Completed quest onboarding player should initialize.")
	assertResultSuccess(markQuestOneCompleted(PlayerDataService, completedPlayer), "Quest completion setup should apply.")
	local completedEligibility = OnboardingService.ShouldShowFirstTimeOnboarding(completedPlayer)
	assertResultSuccess(completedEligibility, "Completed quest player onboarding eligibility should read.")
	assertCondition(completedEligibility.Data.ShouldShow == false, "Completed quest player should not receive full onboarding.")

	local episodePlayer = makeFakePlayer(960604, "Phase6CCompletedEpisode")
	assertResultSuccess(PlayerDataService.InitPlayer(episodePlayer), "Completed episode onboarding player should initialize.")
	assertResultSuccess(markEpisodeCompleted(PlayerDataService, episodePlayer), "Episode completion setup should apply.")
	local episodeEligibility = OnboardingService.ShouldShowFirstTimeOnboarding(episodePlayer)
	assertResultSuccess(episodeEligibility, "Completed episode player onboarding eligibility should read.")
	assertCondition(episodeEligibility.Data.ShouldShow == false, "Completed episode player should not receive full onboarding.")

	print("[ANP Phase6COnboardingFlowSmokeTest] Phase 6C onboarding flow smoke test passed.")
end

return Phase6COnboardingFlowSmokeTest
