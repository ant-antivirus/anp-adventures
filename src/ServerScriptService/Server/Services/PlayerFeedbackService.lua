local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerFeedbackService = {}

local REMOTES_FOLDER_NAME = "ANP_Remotes"
local FEEDBACK_EVENT_NAME = "PlayerFeedbackEvent"

local feedbackEvent = nil
local sentFeedbackByPlayerKey = {}

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function getPlayerKey(player)
	if type(player) == "table" then
		return tostring(player.UserId or player.Name or player)
	end

	return tostring(player and player.UserId or player)
end

local function isRobloxPlayer(player)
	return typeof(player) == "Instance" and player:IsA("Player")
end

local function getOrCreateFeedbackEvent()
	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end

	local remoteEvent = remotesFolder:FindFirstChild(FEEDBACK_EVENT_NAME)
	if not remoteEvent then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = FEEDBACK_EVENT_NAME
		remoteEvent.Parent = remotesFolder
	end

	return remoteEvent
end

local function buildPayload(feedbackType, title, message, data)
	local payload = {}

	if type(data) == "table" then
		for key, value in pairs(data) do
			payload[key] = value
		end
	end

	payload.Type = feedbackType
	payload.Title = title
	payload.Message = message
	payload.Duration = payload.Duration or 4

	return payload
end

local function recordPayload(player, payload)
	local playerKey = getPlayerKey(player)
	sentFeedbackByPlayerKey[playerKey] = sentFeedbackByPlayerKey[playerKey] or {}
	table.insert(sentFeedbackByPlayerKey[playerKey], payload)
end

local function sendPayload(player, payload)
	if not feedbackEvent then
		feedbackEvent = getOrCreateFeedbackEvent()
	end

	recordPayload(player, payload)

	if isRobloxPlayer(player) then
		feedbackEvent:FireClient(player, payload)
	end

	return result(true, "FeedbackSent", nil, payload)
end

function PlayerFeedbackService.Init()
	feedbackEvent = getOrCreateFeedbackEvent()
	return result(true, "PlayerFeedbackServiceInitialized", nil, {
		RemoteEvent = feedbackEvent,
	})
end

function PlayerFeedbackService.GetFeedbackEvent()
	if not feedbackEvent then
		feedbackEvent = getOrCreateFeedbackEvent()
	end

	return result(true, "FeedbackEventRead", nil, feedbackEvent)
end

function PlayerFeedbackService.SendHint(player, message, data)
	local title = data and data.Title or "Guide"
	return sendPayload(player, buildPayload("Hint", title, message, data))
end

function PlayerFeedbackService.SendBlocked(player, message, data)
	local title = data and data.Title or "Not Yet"
	return sendPayload(player, buildPayload("Blocked", title, message, data))
end

function PlayerFeedbackService.SendQuestStarted(player, questId, message)
	return sendPayload(player, buildPayload("QuestStarted", "Quest Started", message or "Quest started. Follow the next objective.", {
		QuestId = questId,
	}))
end

function PlayerFeedbackService.SendQuestCompleted(player, questId, message)
	return sendPayload(player, buildPayload("QuestCompleted", "Quest Complete", message or "Quest complete.", {
		QuestId = questId,
	}))
end

function PlayerFeedbackService.SendObjectiveUpdated(player, questId, objectiveId, message)
	return sendPayload(player, buildPayload("ObjectiveUpdated", "Objective Complete", message or "Objective complete. Check the next step.", {
		QuestId = questId,
		ObjectiveId = objectiveId,
	}))
end

function PlayerFeedbackService.SendRewardReceived(player, rewardBundleId, message)
	return sendPayload(player, buildPayload("RewardReceived", "Reward Received", message or "Reward received.", {
		RewardBundleId = rewardBundleId,
	}))
end

function PlayerFeedbackService.SendEpisodeCompleted(player, episodeId, message)
	return sendPayload(player, buildPayload("EpisodeCompleted", "Episode Complete", message or "Episode 1 complete. Star Core Segment 01 has been restored.", {
		EpisodeId = episodeId,
		Duration = 6,
	}))
end

function PlayerFeedbackService.SendQuestTracker(player, trackerPayload)
	local payload = {}
	for key, value in pairs(trackerPayload or {}) do
		payload[key] = value
	end

	payload.Type = "QuestTracker"
	payload.Duration = nil

	return sendPayload(player, payload)
end

function PlayerFeedbackService.SendOnboarding(player, onboardingPayload)
	local payload = {}
	for key, value in pairs(onboardingPayload or {}) do
		payload[key] = value
	end

	payload.Type = "Onboarding"
	payload.Duration = payload.Duration or 7

	return sendPayload(player, payload)
end

function PlayerFeedbackService.GetSentFeedbackForTests(player)
	local playerKey = getPlayerKey(player)
	return sentFeedbackByPlayerKey[playerKey] or {}
end

function PlayerFeedbackService.ResetForTests()
	table.clear(sentFeedbackByPlayerKey)
end

return PlayerFeedbackService
