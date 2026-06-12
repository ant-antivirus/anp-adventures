local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local EpisodeDefinitions = require(Shared.Definitions.EpisodeDefinitions)

local QuestService = {}

local QuestStatus = {
	Inactive = "Inactive",
	Active = "Active",
	Completed = "Completed",
}

local playerDataService = nil
local rewardService = nil
local episodeService = nil
local interactionVisibilityService = nil
local analyticsService = nil
local playerFeedbackService = nil
local questTrackerService = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Reason = if success then nil else code,
		Message = message,
		Data = data,
	}
end

local function getQuestDefinition(questId)
	local questDefinition = QuestDefinitions[questId]
	if not questDefinition then
		return nil, result(false, "UnknownQuestId", "Unknown quest `" .. tostring(questId) .. "`.")
	end

	return questDefinition, nil
end

local function listContains(values, expectedValue)
	for _, value in ipairs(values or {}) do
		if value == expectedValue then
			return true
		end
	end

	return false
end

local function getMainRewardBundleIds(questDefinition)
	local rewardBundleIds = {}
	for _, rewardBundleId in ipairs(questDefinition.RewardBundleIds or {}) do
		if not string.find(rewardBundleId, "_teamwork_", 1, true) and not string.find(rewardBundleId, "_optional_", 1, true) then
			table.insert(rewardBundleIds, rewardBundleId)
		end
	end

	return rewardBundleIds
end

local function buildQuestCompletionSourceContext(questId, sourceContext)
	if type(sourceContext) == "table" then
		return sourceContext
	end

	return {
		SourceType = "QuestCompletion",
		SourceId = questId,
	}
end

local function buildObjectiveRewardSourceContext(questId, objectiveId)
	return {
		SourceType = "QuestObjective",
		SourceId = questId .. "_" .. objectiveId,
	}
end

local function getObjectiveRequiredAmount(questDefinition, objectiveId)
	local objectiveDefinition = questDefinition.ObjectiveDefinitions and questDefinition.ObjectiveDefinitions[objectiveId]
	if objectiveDefinition and type(objectiveDefinition.RequiredAmount) == "number" and objectiveDefinition.RequiredAmount > 0 then
		return objectiveDefinition.RequiredAmount
	end

	return 1
end

local function getObjectiveDefinition(questDefinition, objectiveId)
	return questDefinition.ObjectiveDefinitions and questDefinition.ObjectiveDefinitions[objectiveId]
end

local function objectiveDependenciesComplete(questDefinition, questState, objectiveId)
	local objectiveDefinition = getObjectiveDefinition(questDefinition, objectiveId)
	local requiresObjectiveIds = objectiveDefinition and objectiveDefinition.RequiresObjectiveIds

	for _, requiredObjectiveId in ipairs(requiresObjectiveIds or {}) do
		local requiredObjectiveState = questState.ObjectiveStates and questState.ObjectiveStates[requiredObjectiveId]
		if not requiredObjectiveState or requiredObjectiveState.Completed ~= true then
			return false, requiredObjectiveId
		end
	end

	return true, nil
end

local function buildObjectiveStates(questDefinition)
	local objectiveStates = {}

	for _, objectiveId in ipairs(questDefinition.ObjectiveIds or {}) do
		objectiveStates[objectiveId] = {
			Current = 0,
			Required = getObjectiveRequiredAmount(questDefinition, objectiveId),
			Completed = false,
			Optional = listContains(questDefinition.OptionalObjectiveIds, objectiveId),
		}
	end

	return objectiveStates
end

local function ensureQuestState(playerData, questDefinition)
	local questId = questDefinition.QuestId
	local questState = playerData.Quests.QuestStates[questId]

	if not questState then
		questState = {
			QuestId = questId,
			EpisodeId = questDefinition.EpisodeId,
			ZoneId = questDefinition.ZoneId,
			Status = QuestStatus.Inactive,
			ObjectiveStates = buildObjectiveStates(questDefinition),
			StartedAt = nil,
			CompletedAt = nil,
			LastUpdatedAt = nil,
			AssistedByCompanion = false,
			ParticipantUserIds = {},
			CoopParticipantUserIds = {},
			SourceContexts = {},
			MetadataEvents = {},
			AbandonReason = nil,
		}

		playerData.Quests.QuestStates[questId] = questState
	end

	for objectiveId, objectiveState in pairs(buildObjectiveStates(questDefinition)) do
		questState.ObjectiveStates[objectiveId] = questState.ObjectiveStates[objectiveId] or objectiveState
	end

	questState.ParticipantUserIds = questState.ParticipantUserIds or {}
	questState.CoopParticipantUserIds = questState.CoopParticipantUserIds or {}
	questState.SourceContexts = questState.SourceContexts or {}
	questState.MetadataEvents = questState.MetadataEvents or {}

	return questState
end

local function copySourceContext(sourceContext)
	if type(sourceContext) ~= "table" then
		return nil
	end

	return {
		SourceType = sourceContext.SourceType,
		SourceId = sourceContext.SourceId,
	}
end

local function recordMetadata(questState, sourceContext, metadata)
	local event = {
		SourceContext = copySourceContext(sourceContext),
		CompanionAssisted = false,
		ParticipantUserIds = {},
		CoopParticipantUserIds = {},
		RecordedAt = os.time(),
	}

	if type(metadata) == "table" then
		if metadata.CompanionAssisted == true then
			questState.AssistedByCompanion = true
			event.CompanionAssisted = true
		end

		local participantUserIds = metadata.ParticipantUserIds or metadata.CoopParticipantUserIds or metadata.CoOpParticipantUserIds or metadata.CoopParticipantIds or metadata.CoOpParticipantIds or {}
		for _, participantUserId in ipairs(participantUserIds) do
			if type(participantUserId) == "number" then
				table.insert(questState.ParticipantUserIds, participantUserId)
				table.insert(questState.CoopParticipantUserIds, participantUserId)
				table.insert(event.ParticipantUserIds, participantUserId)
				table.insert(event.CoopParticipantUserIds, participantUserId)
			end
		end
	end

	if event.SourceContext then
		table.insert(questState.SourceContexts, event.SourceContext)
	end
	table.insert(questState.MetadataEvents, event)
end

local function findPreviousQuestId(questDefinition)
	local episodeDefinition = EpisodeDefinitions[questDefinition.EpisodeId]
	if not episodeDefinition then
		return nil
	end

	local previousQuestId = nil
	for _, episodeQuestId in ipairs(episodeDefinition.QuestIds or {}) do
		if episodeQuestId == questDefinition.QuestId then
			return previousQuestId
		end

		previousQuestId = episodeQuestId
	end

	return nil
end

function QuestService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	rewardService = dependencies.RewardService
	episodeService = dependencies.EpisodeService
	interactionVisibilityService = dependencies.InteractionVisibilityService
	analyticsService = dependencies.AnalyticsService
	playerFeedbackService = dependencies.PlayerFeedbackService
	questTrackerService = dependencies.QuestTrackerService

	assert(playerDataService, "QuestService requires PlayerDataService.")
	assert(rewardService, "QuestService requires RewardService.")
	assert(episodeService, "QuestService requires EpisodeService.")
end

local function incrementSessionStat(player, statName)
	playerDataService.Mutate(player, "IncrementSessionStat", {
		SourceType = "SessionStats",
		SourceId = statName,
	}, function(playerData)
		playerData.SessionStats = playerData.SessionStats or {}
		playerData.SessionStats[statName] = (playerData.SessionStats[statName] or 0) + 1
		return true
	end)
end

local function trackAnalytics(player, eventName, metadata)
	if analyticsService then
		analyticsService.Track(player, eventName, metadata)
	end
end

function QuestService.SetInteractionVisibilityService(service)
	interactionVisibilityService = service
end

function QuestService.SetQuestTrackerService(service)
	questTrackerService = service
end

local function refreshInteractionVisibility(player)
	if interactionVisibilityService then
		interactionVisibilityService.RefreshPlayer(player)
	end
end

local function sendQuestTrackerUpdate(player)
	if questTrackerService then
		questTrackerService.SendTrackerUpdate(player)
	end
end

function QuestService.CanStartQuest(player, questId)
	local questDefinition, errorResult = getQuestDefinition(questId)
	if errorResult then
		return false, errorResult.Code
	end

	if not episodeService.IsEpisodeUnlocked(player, questDefinition.EpisodeId) then
		return false, "QuestLocked"
	end

	local readResult = playerDataService.Read(player, "CanStartQuest", function(playerData)
		local questData = playerData.Quests
		local questState = questData.QuestStates[questId]
		local previousQuestId = findPreviousQuestId(questDefinition)
		return {
			Completed = questData.CompletedQuestIds[questId] == true,
			Active = questState and questState.Status == QuestStatus.Active,
			PreviousQuestMissing = previousQuestId ~= nil and questData.CompletedQuestIds[previousQuestId] ~= true,
		}
	end)
	if not readResult.Success then
		return false, readResult.Code
	end

	if readResult.Data.Completed then
		return false, "QuestAlreadyCompleted"
	end

	if readResult.Data.Active then
		return false, "QuestAlreadyActive"
	end

	if readResult.Data.PreviousQuestMissing then
		return false, "QuestPrerequisiteMissing"
	end

	return true
end

function QuestService.StartQuest(player, questId, sourceContext)
	local questDefinition, errorResult = getQuestDefinition(questId)
	if errorResult then
		return errorResult
	end

	local canStart, blockCode = QuestService.CanStartQuest(player, questId)
	if not canStart then
		return result(false, blockCode, "Cannot start quest `" .. questId .. "`.")
	end

	local now = os.time()
	local mutationResult = playerDataService.Mutate(player, "StartQuest", sourceContext, function(playerData)
		local questState = ensureQuestState(playerData, questDefinition)
		questState.Status = QuestStatus.Active
		questState.StartedAt = questState.StartedAt or now
		questState.LastUpdatedAt = now
		questState.AbandonReason = nil
		playerData.Quests.ActiveQuestIds[questId] = true
		recordMetadata(questState, sourceContext, nil)
		return true
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	incrementSessionStat(player, "QuestsStarted")
	trackAnalytics(player, "QuestStarted", {
		QuestId = questId,
		EpisodeId = questDefinition.EpisodeId,
		ZoneId = questDefinition.ZoneId,
	})
	if playerFeedbackService then
		playerFeedbackService.SendQuestStarted(player, questId, "Quest started. Follow the next objective.")
	end
	refreshInteractionVisibility(player)
	sendQuestTrackerUpdate(player)

	return result(true, "QuestStarted", nil, {
		QuestId = questId,
	})
end

function QuestService.GetQuestState(player, questId)
	if questId ~= nil then
		local questDefinition, errorResult = getQuestDefinition(questId)
		if errorResult then
			return errorResult
		end

		local readResult = playerDataService.Read(player, "GetQuestState", function(playerData)
			return playerData.Quests.QuestStates[questId]
		end)
		if not readResult.Success then
			return readResult
		end

		local questState = readResult.Data or {
			QuestId = questId,
			EpisodeId = questDefinition.EpisodeId,
			ZoneId = questDefinition.ZoneId,
			Status = QuestStatus.Inactive,
			ObjectiveStates = buildObjectiveStates(questDefinition),
		}

		return result(true, "QuestStateRead", nil, questState)
	end

	local snapshotResult = playerDataService.GetSnapshot(player, "Quests")
	if not snapshotResult.Success then
		return snapshotResult
	end

	return result(true, "QuestStateRead", nil, snapshotResult.Data)
end

function QuestService.IsObjectiveCompleted(player, questId, objectiveId)
	local questDefinition, errorResult = getQuestDefinition(questId)
	if errorResult then
		return false, errorResult.Code
	end

	if not listContains(questDefinition.ObjectiveIds, objectiveId) then
		return false, "UnknownQuestObjectiveId"
	end

	local readResult = playerDataService.Read(player, "IsObjectiveCompleted", function(playerData)
		local questData = playerData.Quests
		local questState = questData.QuestStates[questId]
		local objectiveState = questState and questState.ObjectiveStates and questState.ObjectiveStates[objectiveId]
		if objectiveState and objectiveState.Completed == true then
			return {
				IsCompleted = true,
				Code = "ObjectiveCompleted",
			}
		end

		if questData.CompletedQuestIds[questId] == true and listContains(questDefinition.RequiredObjectiveIds, objectiveId) then
			return {
				IsCompleted = true,
				Code = "CompletedQuestRequiredObjective",
			}
		end

		return {
			IsCompleted = false,
			Code = "ObjectiveIncomplete",
		}
	end)

	if not readResult.Success then
		return false, readResult.Code
	end

	return readResult.Data.IsCompleted == true, readResult.Data.Code
end

function QuestService.ApplyObjectiveProgress(player, questId, objectiveId, amount, sourceContext, metadata)
	local questDefinition, errorResult = getQuestDefinition(questId)
	if errorResult then
		return errorResult
	end

	if not listContains(questDefinition.ObjectiveIds, objectiveId) then
		return result(false, "UnknownQuestObjectiveId", "Quest `" .. questId .. "` does not contain objective `" .. tostring(objectiveId) .. "`.")
	end

	if type(amount) ~= "number" or amount <= 0 then
		return result(false, "InvalidObjectiveProgressAmount", "Objective progress amount must be positive.")
	end

	local stateResult = QuestService.GetQuestState(player, questId)
	if not stateResult.Success then
		return stateResult
	end

	if stateResult.Data.Status ~= QuestStatus.Active then
		return result(false, "QuestNotActive", "Cannot progress inactive quest `" .. questId .. "`.")
	end

	local objectiveStateBefore = stateResult.Data.ObjectiveStates and stateResult.Data.ObjectiveStates[objectiveId]
	if not objectiveStateBefore then
		return result(false, "UnknownQuestObjectiveId", "Quest `" .. questId .. "` does not contain objective state `" .. tostring(objectiveId) .. "`.")
	end

	local dependenciesReady, missingObjectiveId = objectiveDependenciesComplete(questDefinition, stateResult.Data, objectiveId)
	if not dependenciesReady then
		return result(false, "ObjectiveDependencyMissing", "Objective `" .. objectiveId .. "` requires `" .. tostring(missingObjectiveId) .. "` first.", {
			QuestId = questId,
			ObjectiveId = objectiveId,
			MissingObjectiveId = missingObjectiveId,
		})
	end

	local objectiveDefinition = getObjectiveDefinition(questDefinition, objectiveId)
	local objectiveRewardBundleIds = objectiveDefinition and objectiveDefinition.RewardBundleIds or {}
	local willCompleteObjective = objectiveStateBefore.Completed ~= true and objectiveStateBefore.Current + amount >= objectiveStateBefore.Required
	local objectiveRewardSourceContext = buildObjectiveRewardSourceContext(questId, objectiveId)

	if willCompleteObjective then
		for _, rewardBundleId in ipairs(objectiveRewardBundleIds) do
			local preflightResult = rewardService.CanGrantRewardBundle(player, rewardBundleId, objectiveRewardSourceContext)
			if not preflightResult.Success then
				return preflightResult
			end
		end
	end

	local now = os.time()
	local mutationResult = playerDataService.Mutate(player, "ApplyObjectiveProgress", sourceContext, function(playerData)
		local questState = ensureQuestState(playerData, questDefinition)
		local objectiveState = questState.ObjectiveStates[objectiveId]
		objectiveState.Current = math.min(objectiveState.Required, objectiveState.Current + amount)
		objectiveState.Completed = objectiveState.Current >= objectiveState.Required
		questState.LastUpdatedAt = now
		recordMetadata(questState, sourceContext, metadata)
		return true
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	local updatedStateResult = QuestService.GetQuestState(player, questId)
	if not updatedStateResult.Success then
		return updatedStateResult
	end

	local grantedObjectiveRewardBundleIds = {}
	if willCompleteObjective then
		for _, rewardBundleId in ipairs(objectiveRewardBundleIds) do
			-- TODO: Include objective reward grants in the future DataStore transaction or rollback ledger.
			local rewardResult = rewardService.GrantRewardBundle(player, rewardBundleId, objectiveRewardSourceContext)
			if not rewardResult.Success then
				return result(false, "ObjectiveRewardFailed", "Objective completed but reward grant failed.", {
					QuestId = questId,
					ObjectiveId = objectiveId,
					RewardBundleId = rewardBundleId,
					FailureCode = rewardResult.Code,
				})
			end

			table.insert(grantedObjectiveRewardBundleIds, rewardBundleId)
		end
	end

	if willCompleteObjective and playerFeedbackService then
		playerFeedbackService.SendObjectiveUpdated(player, questId, objectiveId, "Objective complete. Check the next step.")
	end
	if willCompleteObjective then
		sendQuestTrackerUpdate(player)
	end

	return result(true, "ObjectiveProgressApplied", nil, {
		QuestId = questId,
		ObjectiveId = objectiveId,
		ObjectiveState = updatedStateResult.Data.ObjectiveStates[objectiveId],
		GrantedObjectiveRewardBundleIds = grantedObjectiveRewardBundleIds,
	})
end

local function requiredObjectivesComplete(questDefinition, questState)
	for _, objectiveId in ipairs(questDefinition.RequiredObjectiveIds or {}) do
		local objectiveState = questState.ObjectiveStates[objectiveId]
		if not objectiveState or objectiveState.Completed ~= true then
			return false, objectiveId
		end
	end

	return true, nil
end

function QuestService.CompleteQuest(player, questId, sourceContext)
	local questDefinition, errorResult = getQuestDefinition(questId)
	if errorResult then
		return errorResult
	end

	local stateResult = QuestService.GetQuestState(player, questId)
	if not stateResult.Success then
		return stateResult
	end

	local questState = stateResult.Data
	if questState.Status == QuestStatus.Completed then
		if questState.RewardPending == true then
			local rewardSourceContext = buildQuestCompletionSourceContext(questId, sourceContext)
			local pendingRewardBundleIds = questState.RewardBundleIds or getMainRewardBundleIds(questDefinition)
			local grantedRewardBundleIds = {}

			for _, rewardBundleId in ipairs(pendingRewardBundleIds) do
				local rewardResult = rewardService.GrantRewardBundle(player, rewardBundleId, rewardSourceContext)
				if not rewardResult.Success then
					return result(false, "QuestCompletionRewardFailed", "Pending quest reward retry failed.", {
						QuestId = questId,
						RewardBundleId = rewardBundleId,
						FailureCode = rewardResult.Code,
					})
				end
				table.insert(grantedRewardBundleIds, rewardBundleId)
			end

			local retryAppliedResult = playerDataService.Mutate(player, "MarkQuestCompletionRewardRetryApplied", rewardSourceContext, function(playerData)
				local currentQuestState = ensureQuestState(playerData, questDefinition)
				currentQuestState.RewardPending = false
				currentQuestState.CompletionRewardFailed = false
				currentQuestState.RewardFailureCode = nil
				currentQuestState.LastUpdatedAt = os.time()
				return true
			end)

			if not retryAppliedResult.Success then
				return retryAppliedResult
			end

			refreshInteractionVisibility(player)

			return result(true, "QuestCompletionRewardRetried", nil, {
				QuestId = questId,
				GrantedRewardBundleIds = grantedRewardBundleIds,
			})
		end

		return result(false, "QuestAlreadyCompleted", "Quest `" .. questId .. "` is already completed.")
	end

	if questState.Status ~= QuestStatus.Active then
		return result(false, "QuestNotActive", "Cannot complete inactive quest `" .. questId .. "`.")
	end

	local allRequiredComplete, missingObjectiveId = requiredObjectivesComplete(questDefinition, questState)
	if not allRequiredComplete then
		return result(false, "RequiredObjectiveIncomplete", "Required objective `" .. missingObjectiveId .. "` is incomplete.", {
			QuestId = questId,
			MissingObjectiveId = missingObjectiveId,
		})
	end

	local rewardSourceContext = buildQuestCompletionSourceContext(questId, sourceContext)
	local rewardBundleIds = getMainRewardBundleIds(questDefinition)
	for _, rewardBundleId in ipairs(rewardBundleIds) do
		local preflightResult = rewardService.CanGrantRewardBundle(player, rewardBundleId, rewardSourceContext)
		if not preflightResult.Success then
			return preflightResult
		end
	end

	local now = os.time()
	local mutationResult = playerDataService.Mutate(player, "CompleteQuest", rewardSourceContext, function(playerData)
		local currentQuestState = ensureQuestState(playerData, questDefinition)
		currentQuestState.Status = QuestStatus.Completed
		currentQuestState.CompletedAt = now
		currentQuestState.LastUpdatedAt = now
		currentQuestState.RewardPending = #rewardBundleIds > 0
		currentQuestState.RewardBundleIds = rewardBundleIds
		currentQuestState.CompletionRewardFailed = false
		currentQuestState.RewardFailureCode = nil
		playerData.Quests.CompletedQuestIds[questId] = true
		playerData.Quests.ActiveQuestIds[questId] = nil

		local episodeProgress = playerData.Episodes.EpisodeProgress[questDefinition.EpisodeId]
		if episodeProgress then
			local completedCount = 0
			for completedQuestId in pairs(playerData.Quests.CompletedQuestIds) do
				if QuestDefinitions[completedQuestId] and QuestDefinitions[completedQuestId].EpisodeId == questDefinition.EpisodeId then
					completedCount += 1
				end
			end
			episodeProgress.CompletedQuestCount = completedCount
		end

		recordMetadata(currentQuestState, rewardSourceContext, nil)
		return true
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	local grantedRewardBundleIds = {}
	for _, rewardBundleId in ipairs(rewardBundleIds) do
		local rewardResult = rewardService.GrantRewardBundle(player, rewardBundleId, rewardSourceContext)

		if not rewardResult.Success then
			playerDataService.Mutate(player, "MarkQuestCompletionRewardFailed", rewardSourceContext, function(playerData)
				local currentQuestState = ensureQuestState(playerData, questDefinition)
				currentQuestState.RewardPending = true
				currentQuestState.RewardBundleIds = rewardBundleIds
				currentQuestState.CompletionRewardFailed = true
				currentQuestState.RewardFailureCode = rewardResult.Code
				currentQuestState.LastUpdatedAt = os.time()
				return true
			end)

			return result(false, "QuestCompletionRewardFailed", "Quest completed but reward grant failed.", {
				QuestId = questId,
				RewardBundleId = rewardBundleId,
				FailureCode = rewardResult.Code,
			})
		end

		table.insert(grantedRewardBundleIds, rewardBundleId)
	end

	local rewardAppliedResult = playerDataService.Mutate(player, "MarkQuestCompletionRewardApplied", rewardSourceContext, function(playerData)
		local currentQuestState = ensureQuestState(playerData, questDefinition)
		currentQuestState.RewardPending = false
		currentQuestState.CompletionRewardFailed = false
		currentQuestState.RewardFailureCode = nil
		currentQuestState.LastUpdatedAt = os.time()
		return true
	end)

	if not rewardAppliedResult.Success then
		return rewardAppliedResult
	end

	local nextQuestId = nil
	local episodeDefinition = EpisodeDefinitions[questDefinition.EpisodeId]
	if episodeDefinition then
		for index, episodeQuestId in ipairs(episodeDefinition.QuestIds or {}) do
			if episodeQuestId == questId then
				nextQuestId = episodeDefinition.QuestIds[index + 1]
				break
			end
		end
	end

	local episodeCompletionResult = nil
	if nextQuestId == nil then
		episodeCompletionResult = episodeService.CompleteEpisode(player, questDefinition.EpisodeId, rewardSourceContext)
		if not episodeCompletionResult.Success then
			return episodeCompletionResult
		end
		if playerFeedbackService then
			playerFeedbackService.SendEpisodeCompleted(player, questDefinition.EpisodeId, "Episode 1 complete. Star Core Segment 01 has been restored.")
		end
	end

	incrementSessionStat(player, "QuestsCompleted")
	trackAnalytics(player, "QuestCompleted", {
		QuestId = questId,
		EpisodeId = questDefinition.EpisodeId,
		ZoneId = questDefinition.ZoneId,
		RewardBundleIds = grantedRewardBundleIds,
	})
	if playerFeedbackService then
		playerFeedbackService.SendQuestCompleted(player, questId, "Quest complete.")
	end
	refreshInteractionVisibility(player)
	sendQuestTrackerUpdate(player)

	return result(true, "QuestCompleted", nil, {
		QuestId = questId,
		GrantedRewardBundleIds = grantedRewardBundleIds,
		NextQuestId = nextQuestId,
		EpisodeCompletionResult = episodeCompletionResult,
	})
end

function QuestService.AbandonQuest(player, questId, reason)
	local questDefinition, errorResult = getQuestDefinition(questId)
	if errorResult then
		return errorResult
	end

	local stateResult = QuestService.GetQuestState(player, questId)
	if not stateResult.Success then
		return stateResult
	end

	if stateResult.Data.Status ~= QuestStatus.Active then
		return result(false, "QuestNotActive", "Cannot abandon inactive quest `" .. questId .. "`.")
	end

	local mutationResult = playerDataService.Mutate(player, "AbandonQuest", {
		SourceType = "QuestAbandon",
		SourceId = questId,
	}, function(playerData)
		local questState = ensureQuestState(playerData, questDefinition)
		questState.Status = QuestStatus.Inactive
		questState.AbandonReason = tostring(reason or "Unspecified")
		questState.LastUpdatedAt = os.time()
		playerData.Quests.ActiveQuestIds[questId] = nil
		return true
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	refreshInteractionVisibility(player)
	sendQuestTrackerUpdate(player)

	return result(true, "QuestAbandoned", nil, {
		QuestId = questId,
		Reason = tostring(reason or "Unspecified"),
	})
end

QuestService.QuestStatus = QuestStatus

return QuestService
