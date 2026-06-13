local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Definitions = Shared:WaitForChild("Definitions")

local LocalizationConfig = require(Config.LocalizationConfig)
local MarkerLegendConfig = require(Config.MarkerLegendConfig)
local InteractionDefinitions = require(Definitions.InteractionDefinitions)
local QuestDefinitions = require(Definitions.QuestDefinitions)
local SaveSchema = require(Definitions.SaveSchema)

local Phase6EThaiLocalizationSmokeTest = {}

local REQUIRED_TRACKER_FIELDS = {
	"Type",
	"State",
	"QuestId",
	"QuestTitle",
	"CurrentObjectiveText",
	"ProgressText",
	"HintText",
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase6EThaiLocalizationSmokeTest] " .. message, 2)
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
		SourceType = "Phase6EThaiLocalizationSmokeTest",
		InteractionId = interactionId,
		BypassCooldownForTests = true,
	})
end

local function containsThai(text)
	if type(text) ~= "string" then
		return false
	end

	for _, codepoint in utf8.codes(text) do
		if codepoint >= 0x0E00 and codepoint <= 0x0E7F then
			return true
		end
	end

	return false
end

local function assertThaiText(text, message)
	assertCondition(containsThai(text), message .. " Expected Thai text, got `" .. tostring(text) .. "`.")
end

local function assertQuestTextIsThai()
	for questNumber = 1, 8 do
		local questId = "quest_ep01_main_" .. string.format("%03d", questNumber)
		local questDefinition = QuestDefinitions[questId]
		assertCondition(questDefinition ~= nil, "Quest `" .. questId .. "` should exist.")
		assertThaiText(questDefinition.Title, "Quest `" .. questId .. "` title should be Thai.")

		for _, objectiveId in ipairs(questDefinition.RequiredObjectiveIds) do
			local objectiveDefinition = questDefinition.ObjectiveDefinitions[objectiveId]
			assertCondition(objectiveDefinition ~= nil, "Objective `" .. objectiveId .. "` should exist.")
			assertThaiText(objectiveDefinition.ObjectiveText, "Objective `" .. objectiveId .. "` text should be Thai.")
		end
	end
end

local function assertMarkerLegendIsThai()
	local expectations = {
		QuestStart = "เริ่มภารกิจ",
		QuestObjective = "เป้าหมายปัจจุบัน",
		QuestComplete = "ส่งภารกิจ",
		Discovery = "จุดค้นพบ",
		ZoneTravel = "เดินทาง",
		NPCGuide = "ผู้ช่วยนำทาง",
	}

	for markerType, expectedMeaning in pairs(expectations) do
		local entry = MarkerLegendConfig[markerType]
		assertCondition(entry ~= nil, "Marker legend `" .. markerType .. "` should exist.")
		assertThaiText(entry.Label, "Marker legend label `" .. markerType .. "` should be Thai.")
		assertCondition(entry.Meaning == expectedMeaning, "Marker legend meaning `" .. markerType .. "` should be Thai and stable.")
	end
end

local function assertRuntimeIdsUnchanged()
	assertCondition(QuestDefinitions.quest_ep01_main_001.QuestId == "quest_ep01_main_001", "QuestId should not be translated.")
	assertCondition(QuestDefinitions.quest_ep01_main_001.RequiredObjectiveIds[1] == "obj_ep01_main_001_001", "ObjectiveId should not be translated.")
	assertCondition(InteractionDefinitions.interaction_start_ep01_main_001.InteractionId == "interaction_start_ep01_main_001", "InteractionId should not be translated.")
	assertCondition(SaveSchema.SaveVersion == 1, "SaveSchema version should remain stable.")
	assertCondition(SaveSchema.StableSections ~= nil, "SaveSchema field names should remain stable.")
end

local function assertTrackerContract(payload)
	for _, fieldName in ipairs(REQUIRED_TRACKER_FIELDS) do
		if fieldName ~= "QuestId" or payload.State ~= "EpisodeCompleted" then
			assertCondition(payload[fieldName] ~= nil, "QuestTracker payload should keep field `" .. fieldName .. "`.")
		end
	end
	assertCondition(payload.Type == "QuestTracker", "QuestTracker Type field should remain unchanged.")
	assertThaiText(payload.QuestTitle, "QuestTracker QuestTitle should be Thai.")
	assertThaiText(payload.CurrentObjectiveText, "QuestTracker CurrentObjectiveText should be Thai.")
	assertThaiText(payload.ProgressText, "QuestTracker ProgressText should be Thai.")
	assertThaiText(payload.HintText, "QuestTracker HintText should be Thai.")
end

function Phase6EThaiLocalizationSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestTrackerService = services.QuestTrackerService
	local OnboardingService = services.OnboardingService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase6EThaiLocalizationSmokeTest] Starting Phase 6E Thai localization smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 6E Thai localization smoke test must run in Studio only.")
	assertCondition(LocalizationConfig.DefaultLocale == "th-TH", "Default locale should be Thai.")
	assertCondition(LocalizationConfig.FallbackLocale == "en-US", "Fallback locale should remain English.")

	PlayerDataService.ResetForTests()
	services.PlayerFeedbackService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build for Thai localization smoke test.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Thai localization smoke test.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompts should bind for Thai localization smoke test.")

	assertQuestTextIsThai()
	assertMarkerLegendIsThai()
	assertRuntimeIdsUnchanged()

	local freshPlayer = makeFakePlayer(960801, "Phase6EThaiFresh")
	assertResultSuccess(PlayerDataService.InitPlayer(freshPlayer), "Fresh Thai player data should initialize.")
	local freshTracker = QuestTrackerService.BuildTrackerState(freshPlayer)
	assertResultSuccess(freshTracker, "Fresh Thai tracker should build.")
	assertCondition(freshTracker.Data.State == "NoQuest", "Fresh tracker state should remain NoQuest.")
	assertThaiText(freshTracker.Data.ProgressText, "Fresh tracker progress should be Thai.")
	assertThaiText(freshTracker.Data.HintText, "Fresh tracker hint should be Thai.")

	local onboardingPayloads = {
		OnboardingService.BuildWelcomePayload(freshPlayer),
		OnboardingService.BuildEpisodeGoalPayload(freshPlayer),
		OnboardingService.BuildMarkerLegendPayload(freshPlayer),
		OnboardingService.BuildFirstQuestHintPayload(freshPlayer),
	}
	for _, payload in ipairs(onboardingPayloads) do
		assertCondition(payload.Type == "Onboarding", "Onboarding Type field should remain unchanged.")
		assertThaiText(payload.Title, "Onboarding title should be Thai.")
		assertThaiText(payload.Message, "Onboarding message should be Thai.")
	end
	assertResultSuccess(PlayerDataService.ReleasePlayer(freshPlayer), "Fresh Thai player should release.")

	local questPlayer = makeFakePlayer(960802, "Phase6EThaiQuest")
	assertResultSuccess(PlayerDataService.InitPlayer(questPlayer), "Quest Thai player data should initialize.")
	assertResultSuccess(trigger(PromptBindingService, questPlayer, "interaction_start_ep01_main_001"), "Quest 001 should start.")
	local questTracker = QuestTrackerService.BuildTrackerState(questPlayer)
	assertResultSuccess(questTracker, "Quest 001 Thai tracker should build.")
	assertTrackerContract(questTracker.Data)
	assertCondition(questTracker.Data.QuestId == "quest_ep01_main_001", "QuestTracker QuestId should remain untranslated.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(questPlayer), "Quest Thai player should release.")

	local q8Player = makeFakePlayer(960803, "Phase6EThaiQ8")
	assertResultSuccess(PlayerDataService.InitPlayer(q8Player), "Q8 Thai player data should initialize.")
	local questCounts = { 4, 4, 4, 4, 4, 4, 4 }
	for questNumber, objectiveCount in ipairs(questCounts) do
		local paddedQuestNumber = string.format("%03d", questNumber)
		assertResultSuccess(trigger(PromptBindingService, q8Player, "interaction_start_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " should start.")
		for objectiveIndex = 1, objectiveCount do
			local objectiveInteractionId = if questNumber == 1 and objectiveIndex == 4
				then "interaction_disc_ep01_command_star_core_display"
				else "interaction_ep01_main_" .. paddedQuestNumber .. "_" .. string.format("%03d", objectiveIndex)
			assertResultSuccess(trigger(PromptBindingService, q8Player, objectiveInteractionId), "Quest " .. paddedQuestNumber .. " objective should complete.")
		end
		assertResultSuccess(trigger(PromptBindingService, q8Player, "interaction_complete_ep01_main_" .. paddedQuestNumber), "Quest " .. paddedQuestNumber .. " should complete.")
	end
	assertResultSuccess(trigger(PromptBindingService, q8Player, "interaction_start_ep01_main_008"), "Quest 008 should start.")
	local q8Tracker = QuestTrackerService.BuildTrackerState(q8Player)
	assertResultSuccess(q8Tracker, "Quest 008 Thai tracker should build.")
	assertCondition(q8Tracker.Data.TotalObjectiveCount == 5, "Quest 008 total should remain 5.")
	assertCondition(string.find(q8Tracker.Data.ProgressText or "", "/ 5", 1, true) ~= nil, "Quest 008 progress should keep `/ 5`.")
	assertThaiText(q8Tracker.Data.ProgressText, "Quest 008 progress should be Thai.")

	for objectiveIndex = 1, 5 do
		assertResultSuccess(trigger(PromptBindingService, q8Player, "interaction_ep01_main_008_" .. string.format("%03d", objectiveIndex)), "Quest 008 objective should complete.")
	end
	assertResultSuccess(trigger(PromptBindingService, q8Player, "interaction_complete_ep01_main_008"), "Quest 008 should complete.")
	local episodeTracker = QuestTrackerService.BuildTrackerState(q8Player)
	assertResultSuccess(episodeTracker, "Episode complete Thai tracker should build.")
	assertCondition(episodeTracker.Data.State == "EpisodeCompleted", "Episode tracker state should remain EpisodeCompleted.")
	assertThaiText(episodeTracker.Data.QuestTitle, "Episode complete title should be Thai.")
	assertThaiText(episodeTracker.Data.HintText, "Episode complete hint should be Thai.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(q8Player), "Q8 Thai player should release.")

	print("[ANP Phase6EThaiLocalizationSmokeTest] Phase 6E Thai localization smoke test passed.")
end

return Phase6EThaiLocalizationSmokeTest
