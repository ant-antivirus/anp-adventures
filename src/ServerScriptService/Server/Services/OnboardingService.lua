local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MarkerLegendConfig = require(Shared.Config.MarkerLegendConfig)

local OnboardingService = {}

local playerDataService = nil
local playerFeedbackService = nil

local EPISODE_ONE_ID = "ep01_lost_star_core"
local FIRST_QUEST_ID = "quest_ep01_main_001"

local LEGEND_ORDER = {
	"QuestStart",
	"QuestObjective",
	"QuestComplete",
	"Discovery",
	"ZoneTravel",
	"NPCGuide",
}

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

function OnboardingService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	playerFeedbackService = dependencies.PlayerFeedbackService

	assert(playerDataService, "OnboardingService requires PlayerDataService.")
	assert(playerFeedbackService, "OnboardingService requires PlayerFeedbackService.")

	return result(true, "OnboardingServiceInitialized")
end

function OnboardingService.ShouldShowFirstTimeOnboarding(player)
	if not playerDataService.IsLoaded(player) then
		return result(false, "PlayerDataNotLoaded", "Player data is not loaded.")
	end

	local readResult = playerDataService.Read(player, "ShouldShowFirstTimeOnboarding", function(playerData)
		local quests = playerData.Quests
		local episodes = playerData.Episodes
		if episodes.CompletedEpisodeIds[EPISODE_ONE_ID] == true then
			return false
		end

		for _, isActive in pairs(quests.ActiveQuestIds or {}) do
			if isActive == true then
				return false
			end
		end

		for _, questState in pairs(quests.QuestStates or {}) do
			if questState.Status == "Active" then
				return false
			end
		end

		for _, isCompleted in pairs(quests.CompletedQuestIds or {}) do
			if isCompleted == true then
				return false
			end
		end

		return true
	end)
	if not readResult.Success then
		return readResult
	end

	return result(true, "OnboardingEligibilityRead", nil, {
		ShouldShow = readResult.Data == true,
	})
end

function OnboardingService.BuildWelcomePayload()
	return {
		Type = "Onboarding",
		State = "Welcome",
		Title = "ยินดีต้อนรับสู่ ANP Adventures",
		Message = "ร่วมผจญภัยวิทยาศาสตร์กับ Atom, Neutron และ Proton",
		Duration = 7,
	}
end

function OnboardingService.BuildEpisodeGoalPayload()
	return {
		Type = "Onboarding",
		State = "EpisodeGoal",
		Title = "ตอนที่ 1",
		Message = "เริ่มการสำรวจครั้งแรกและฟื้นฟูสตาร์คอร์ส่วนที่ 1",
		Duration = 7,
	}
end

function OnboardingService.BuildMarkerLegendPayload()
	local lines = {}
	for _, markerType in ipairs(LEGEND_ORDER) do
		local entry = MarkerLegendConfig[markerType]
		if entry then
			table.insert(lines, entry.Label .. " = " .. entry.Meaning)
		end
	end

	return {
		Type = "Onboarding",
		State = "MarkerLegend",
		Title = "คู่มือสัญลักษณ์",
		Message = "ดูสีของสัญลักษณ์เพื่อหาขั้นตอนถัดไป",
		Lines = lines,
		Duration = 9,
	}
end

function OnboardingService.BuildFirstQuestHintPayload()
	return {
		Type = "Onboarding",
		State = "FirstQuestHint",
		Title = "ขั้นตอนแรก",
		Message = "มองหาสัญลักษณ์สีเขียวเพื่อเริ่มภารกิจในศูนย์บัญชาการ",
		QuestId = FIRST_QUEST_ID,
		Duration = 7,
	}
end

function OnboardingService.SendInitialOnboarding(player)
	local eligibilityResult = OnboardingService.ShouldShowFirstTimeOnboarding(player)
	if not eligibilityResult.Success then
		return eligibilityResult
	end

	if eligibilityResult.Data.ShouldShow ~= true then
		return result(true, "OnboardingSkipped", "Player already has Episode 1 progress.", {
			SentCount = 0,
		})
	end

	local payloads = {
		OnboardingService.BuildWelcomePayload(player),
		OnboardingService.BuildEpisodeGoalPayload(player),
		OnboardingService.BuildMarkerLegendPayload(player),
		OnboardingService.BuildFirstQuestHintPayload(player),
	}

	for _, payload in ipairs(payloads) do
		local sendResult = playerFeedbackService.SendOnboarding(player, payload)
		if not sendResult.Success then
			return sendResult
		end
	end

	return result(true, "OnboardingSent", nil, {
		SentCount = #payloads,
	})
end

return OnboardingService
