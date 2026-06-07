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

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
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

local function getObjectiveRequiredAmount(questDefinition, objectiveId)
	local objectiveDefinition = questDefinition.ObjectiveDefinitions and questDefinition.ObjectiveDefinitions[objectiveId]
	if objectiveDefinition and type(objectiveDefinition.RequiredAmount) == "number" and objectiveDefinition.RequiredAmount > 0 then
		return objectiveDefinition.RequiredAmount
	end

	return 1
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
		CoopParticipantUserIds = {},
		RecordedAt = os.time(),
	}

	if type(metadata) == "table" then
		if metadata.CompanionAssisted == true then
			questState.AssistedByCompanion = true
			event.CompanionAssisted = true
		end

		for _, participantUserId in ipairs(metadata.CoopParticipantUserIds or {}) do
			if type(participantUserId) == "number" then
				table.insert(questState.CoopParticipantUserIds, participantUserId)
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

	assert(playerDataService, "QuestService requires PlayerDataService.")
	assert(rewardService, "QuestService requires RewardService.")
	assert(episodeService, "QuestService requires EpisodeService.")
end

function QuestService.CanStartQuest(player, questId)
	local questDefinition, errorResult = getQuestDefinition(questId)
	if errorResult then
		return false, errorResult.Code
	end

	if not episodeService.IsEpisodeUnlocked(player, questDefinition.EpisodeId) then
		return false, "EpisodeLocked"
	end

	local snapshotResult = playerDataService.GetSnapshot(player, "Quests")
	if not snapshotResult.Success then
		return false, snapshotResult.Code
	end

	if snapshotResult.Data.CompletedQuestIds[questId] then
		return false, "QuestAlreadyCompleted"
	end

	local questState = snapshotResult.Data.QuestStates[questId]
	if questState and questState.Status == QuestStatus.Active then
		return false, "QuestAlreadyActive"
	end

	local previousQuestId = findPreviousQuestId(questDefinition)
	if previousQuestId and not snapshotResult.Data.CompletedQuestIds[previousQuestId] then
		return false, "PreviousQuestIncomplete"
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

	return result(true, "QuestStarted", nil, {
		QuestId = questId,
	})
end

function QuestService.GetQuestState(player, questId)
	local snapshotResult = playerDataService.GetSnapshot(player, "Quests")
	if not snapshotResult.Success then
		return snapshotResult
	end

	if questId == nil then
		return result(true, "QuestStateRead", nil, snapshotResult.Data)
	end

	local questDefinition, errorResult = getQuestDefinition(questId)
	if errorResult then
		return errorResult
	end

	local questState = snapshotResult.Data.QuestStates[questId] or {
		QuestId = questId,
		EpisodeId = questDefinition.EpisodeId,
		ZoneId = questDefinition.ZoneId,
		Status = QuestStatus.Inactive,
		ObjectiveStates = buildObjectiveStates(questDefinition),
	}

	return result(true, "QuestStateRead", nil, questState)
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

	return result(true, "ObjectiveProgressApplied", nil, {
		QuestId = questId,
		ObjectiveId = objectiveId,
		ObjectiveState = updatedStateResult.Data.ObjectiveStates[objectiveId],
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
		return result(false, "RequiredObjectiveIncomplete", "Required objective `" .. missingObjectiveId .. "` is incomplete.")
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

	return result(true, "QuestCompleted", nil, {
		QuestId = questId,
		GrantedRewardBundleIds = grantedRewardBundleIds,
		NextQuestId = nextQuestId,
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

	return result(true, "QuestAbandoned", nil, {
		QuestId = questId,
		Reason = tostring(reason or "Unspecified"),
	})
end

QuestService.QuestStatus = QuestStatus

return QuestService
