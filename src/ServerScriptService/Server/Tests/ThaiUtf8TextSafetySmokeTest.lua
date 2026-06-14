local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TextUtils = require(Shared.Util.TextUtils)
local MarkerLegendConfig = require(Shared.Config.MarkerLegendConfig)

local ThaiUtf8TextSafetySmokeTest = {}

local REPLACEMENT_CHARACTER = utf8.char(0xFFFD)

local THAI_TEST_STRINGS = {
	"ภารกิจที่ 3: กู้คืนชิ้นส่วนแห่งจักรวาล",
	"มองหาสัญลักษณ์สีฟ้าเพื่อส่งภารกิจ",
	"เริ่มภารกิจถัดไปที่สัญลักษณ์สีเขียว",
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP ThaiUtf8TextSafetySmokeTest] " .. message, 2)
	end
end

local function assertValidPlayerText(value, context)
	if type(value) ~= "string" or value == "" then
		return
	end

	assertCondition(TextUtils.IsValidUtf8(value), context .. " should be valid UTF-8.")
	assertCondition(not string.find(value, REPLACEMENT_CHARACTER, 1, true), context .. " should not contain replacement characters.")
end

local function assertPayloadText(payload, context)
	for key, value in pairs(payload) do
		if type(value) == "string" then
			assertValidPlayerText(value, context .. "." .. key)
		elseif type(value) == "table" then
			for index, nestedValue in ipairs(value) do
				assertValidPlayerText(nestedValue, context .. "." .. key .. "[" .. tostring(index) .. "]")
			end
		end
	end
end

local function makeFakePlayer(userId, name)
	return {
		UserId = userId,
		Name = name,
	}
end

local function assertTruncateUtf8()
	for _, text in ipairs(THAI_TEST_STRINGS) do
		local truncated = TextUtils.TruncateUtf8(text, 18, "...")
		assertCondition(TextUtils.IsValidUtf8(truncated), "Truncated Thai text should remain valid UTF-8.")
		assertCondition(string.sub(truncated, -3) == "...", "Truncated Thai text should end with ellipsis.")
		assertCondition(not string.find(truncated, REPLACEMENT_CHARACTER, 1, true), "Truncated Thai text should not contain replacement characters.")
	end

	local invalidText = string.char(0xE0) .. "broken"
	assertCondition(TextUtils.TruncateUtf8(invalidText, 3, "...") == invalidText, "Invalid UTF-8 should not be cut further.")
end

local function assertTrackerPayloads(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local QuestTrackerService = services.QuestTrackerService

	local player = makeFakePlayer(970001, "ThaiUtf8Tracker")
	assertCondition(PlayerDataService.InitPlayer(player).Success == true, "Tracker test player should initialize.")

	local freshTracker = QuestTrackerService.BuildTrackerState(player)
	assertCondition(freshTracker.Success == true, "Fresh tracker payload should build.")
	assertPayloadText(freshTracker.Data, "FreshQuestTracker")

	local startResult = QuestService.StartQuest(player, "quest_ep01_main_001", {
		SourceType = "ThaiUtf8TextSafetySmokeTest",
		SourceId = "quest_ep01_main_001",
	})
	assertCondition(startResult.Success == true, "Quest 001 should start for tracker UTF-8 check.")

	local activeTracker = QuestTrackerService.BuildTrackerState(player)
	assertCondition(activeTracker.Success == true, "Active tracker payload should build.")
	assertPayloadText(activeTracker.Data, "ActiveQuestTracker")

	assertCondition(PlayerDataService.ReleasePlayer(player).Success == true, "Tracker test player should release.")
end

local function assertOnboardingPayloads(services)
	local payloads = {
		services.OnboardingService.BuildWelcomePayload(),
		services.OnboardingService.BuildEpisodeGoalPayload(),
		services.OnboardingService.BuildMarkerLegendPayload(),
		services.OnboardingService.BuildFirstQuestHintPayload(),
	}

	for index, payload in ipairs(payloads) do
		assertCondition(payload.Type == "Onboarding", "Onboarding payload should keep Type field.")
		assertPayloadText(payload, "OnboardingPayload" .. tostring(index))
	end
end

local function assertMarkerLegend()
	local requiredLegendKeys = {
		"QuestStart",
		"QuestObjective",
		"QuestComplete",
		"Discovery",
		"ZoneTravel",
		"NPCGuide",
	}

	for _, legendKey in ipairs(requiredLegendKeys) do
		local entry = MarkerLegendConfig[legendKey]
		assertCondition(entry ~= nil, "Marker legend entry should exist for `" .. legendKey .. "`.")
		assertValidPlayerText(entry.Label, "MarkerLegend." .. legendKey .. ".Label")
		assertValidPlayerText(entry.Meaning, "MarkerLegend." .. legendKey .. ".Meaning")
	end
end

function ThaiUtf8TextSafetySmokeTest.Run(services)
	print("[ANP ThaiUtf8TextSafetySmokeTest] Starting Thai UTF-8 text safety smoke test.")

	services.PlayerDataService.ResetForTests()

	assertTruncateUtf8()
	assertTrackerPayloads(services)
	assertOnboardingPayloads(services)
	assertMarkerLegend()

	print("[ANP ThaiUtf8TextSafetySmokeTest] Thai UTF-8 text safety smoke test passed.")
end

return ThaiUtf8TextSafetySmokeTest
