local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local EpisodeDefinitions = require(Shared.Definitions.EpisodeDefinitions)
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)

local QuestTrackerService = {}

local playerDataService = nil
local questService = nil
local episodeService = nil
local playerFeedbackService = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function listContains(values, expectedValue)
	for _, value in ipairs(values or {}) do
		if value == expectedValue then
			return true
		end
	end

	return false
end

local function countRequiredObjectives(questDefinition, objectiveStates)
	local completedCount = 0
	local totalCount = 0

	for _, objectiveId in ipairs(questDefinition.RequiredObjectiveIds or questDefinition.ObjectiveIds or {}) do
		totalCount += 1
		local objectiveState = objectiveStates and objectiveStates[objectiveId]
		if objectiveState and objectiveState.Completed == true then
			completedCount += 1
		end
	end

	return completedCount, totalCount
end

local function dependenciesComplete(objectiveDefinition, objectiveStates)
	for _, requiredObjectiveId in ipairs((objectiveDefinition and objectiveDefinition.RequiresObjectiveIds) or {}) do
		local requiredObjectiveState = objectiveStates and objectiveStates[requiredObjectiveId]
		if not requiredObjectiveState or requiredObjectiveState.Completed ~= true then
			return false, requiredObjectiveId
		end
	end

	return true, nil
end

local function findCurrentObjective(questDefinition, objectiveStates)
	local blockedObjective = nil
	local missingDependencyId = nil

	for _, objectiveId in ipairs(questDefinition.RequiredObjectiveIds or questDefinition.ObjectiveIds or {}) do
		local objectiveState = objectiveStates and objectiveStates[objectiveId]
		if not objectiveState or objectiveState.Completed ~= true then
			local objectiveDefinition = questDefinition.ObjectiveDefinitions and questDefinition.ObjectiveDefinitions[objectiveId]
			local dependenciesReady, missingObjectiveId = dependenciesComplete(objectiveDefinition, objectiveStates)
			if dependenciesReady then
				return objectiveId, objectiveDefinition, nil
			end

			blockedObjective = blockedObjective or objectiveId
			missingDependencyId = missingDependencyId or missingObjectiveId
		end
	end

	if blockedObjective then
		return blockedObjective, questDefinition.ObjectiveDefinitions and questDefinition.ObjectiveDefinitions[blockedObjective], missingDependencyId
	end

	return nil, nil, nil
end

local function findActiveQuestId(questSnapshot)
	for questId in pairs(questSnapshot.ActiveQuestIds or {}) do
		return questId
	end

	for questId, questState in pairs(questSnapshot.QuestStates or {}) do
		if questState.Status == questService.QuestStatus.Active then
			return questId
		end
	end

	return nil
end

local function getPreviousQuestId(episodeDefinition, questId)
	local previousQuestId = nil
	for _, episodeQuestId in ipairs(episodeDefinition.QuestIds or {}) do
		if episodeQuestId == questId then
			return previousQuestId
		end

		previousQuestId = episodeQuestId
	end

	return nil
end

local function findNextAvailableQuest(questSnapshot, episodeDefinition)
	for _, questId in ipairs(episodeDefinition.QuestIds or {}) do
		if not questSnapshot.CompletedQuestIds[questId] then
			local questState = questSnapshot.QuestStates[questId]
			if not questState or questState.Status ~= questService.QuestStatus.Active then
				local previousQuestId = getPreviousQuestId(episodeDefinition, questId)
				if previousQuestId == nil or questSnapshot.CompletedQuestIds[previousQuestId] == true then
					return questId
				end
			end
		end
	end

	return nil
end

local function countCompletedEpisodeQuests(questSnapshot, episodeDefinition)
	local completedCount = 0
	for _, questId in ipairs(episodeDefinition.QuestIds or {}) do
		if questSnapshot.CompletedQuestIds[questId] == true then
			completedCount += 1
		end
	end

	return completedCount
end

local function getZoneName(zoneId)
	local zoneDefinition = ZoneDefinitions[zoneId]
	return (zoneDefinition and (zoneDefinition.DisplayName or zoneDefinition.Name)) or zoneId
end

local function buildBasePayload(state)
	return {
		Type = "QuestTracker",
		State = state,
	}
end

function QuestTrackerService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	questService = dependencies.QuestService
	episodeService = dependencies.EpisodeService
	playerFeedbackService = dependencies.PlayerFeedbackService

	assert(playerDataService, "QuestTrackerService requires PlayerDataService.")
	assert(questService, "QuestTrackerService requires QuestService.")
	assert(episodeService, "QuestTrackerService requires EpisodeService.")
	assert(playerFeedbackService, "QuestTrackerService requires PlayerFeedbackService.")
end

function QuestTrackerService.BuildTrackerState(player)
	if not playerDataService.IsLoaded(player) then
		return result(false, "PlayerDataNotLoaded", "Player data is not loaded.")
	end

	local questSnapshot = playerDataService.GetSnapshot(player, "Quests")
	if not questSnapshot.Success then
		return questSnapshot
	end

	local episodeSnapshot = playerDataService.GetSnapshot(player, "Episodes")
	if not episodeSnapshot.Success then
		return episodeSnapshot
	end

	local activeEpisodeId = episodeSnapshot.Data.ActiveEpisodeId or "ep01_lost_star_core"
	local episodeDefinition = EpisodeDefinitions[activeEpisodeId]
	if episodeDefinition and episodeSnapshot.Data.CompletedEpisodeIds[activeEpisodeId] == true then
		local payload = buildBasePayload("EpisodeCompleted")
		payload.EpisodeId = activeEpisodeId
		payload.ProgressText = "Episode 1 complete"
		payload.HintText = "Star Core Segment 01 restored."
		payload.QuestTitle = "Episode 1 complete!"
		payload.CurrentObjectiveText = "Star Core Segment 01 restored."
		return result(true, "QuestTrackerStateBuilt", nil, payload)
	end

	local activeQuestId = findActiveQuestId(questSnapshot.Data)
	if activeQuestId then
		local questDefinition = QuestDefinitions[activeQuestId]
		local questState = questSnapshot.Data.QuestStates[activeQuestId]
		if not questDefinition or not questState then
			return result(false, "QuestTrackerQuestMissing", "Active quest state is missing.")
		end

		local completedCount, totalCount = countRequiredObjectives(questDefinition, questState.ObjectiveStates)
		local currentObjectiveId, currentObjectiveDefinition, missingDependencyId = findCurrentObjective(questDefinition, questState.ObjectiveStates)
		local payload = buildBasePayload("ActiveQuest")
		payload.QuestId = activeQuestId
		payload.QuestTitle = questDefinition.Title or activeQuestId
		payload.QuestDescription = questDefinition.Description
		payload.CurrentObjectiveId = currentObjectiveId
		payload.CurrentObjectiveText = currentObjectiveDefinition and (currentObjectiveDefinition.TrackerText or currentObjectiveDefinition.ObjectiveText) or "All objectives complete."
		payload.CompletedObjectiveCount = completedCount
		payload.TotalObjectiveCount = totalCount
		payload.ProgressText = tostring(completedCount) .. " / " .. tostring(totalCount) .. " objectives"
		payload.ZoneId = questDefinition.ZoneId
		payload.ZoneName = getZoneName(questDefinition.ZoneId)

		if completedCount >= totalCount then
			payload.HintText = "Use the cyan Quest Complete marker."
		elseif missingDependencyId then
			payload.HintText = "Finish the previous step first."
			payload.BlockedByObjectiveId = missingDependencyId
		elseif currentObjectiveDefinition and currentObjectiveDefinition.HintText then
			payload.HintText = currentObjectiveDefinition.HintText
		else
			payload.HintText = "Follow the blue objective marker."
		end

		return result(true, "QuestTrackerStateBuilt", nil, payload)
	end

	if episodeDefinition then
		local nextQuestId = findNextAvailableQuest(questSnapshot.Data, episodeDefinition)
		if nextQuestId then
			local questDefinition = QuestDefinitions[nextQuestId]
			if countCompletedEpisodeQuests(questSnapshot.Data, episodeDefinition) == 0 then
				local payload = buildBasePayload("NoQuest")
				payload.QuestId = nextQuestId
				payload.QuestTitle = "ANP Adventures"
				payload.ProgressText = "No active quest"
				payload.HintText = "Look for a green Quest Start marker."
				payload.CurrentObjectiveText = "No active quest. Find the green Quest Start marker."
				payload.ZoneId = questDefinition and questDefinition.ZoneId
				payload.ZoneName = questDefinition and getZoneName(questDefinition.ZoneId)
				return result(true, "QuestTrackerStateBuilt", nil, payload)
			end

			local payload = buildBasePayload("QuestCompleted")
			payload.QuestId = nextQuestId
			payload.QuestTitle = questDefinition and (questDefinition.Title or nextQuestId) or nextQuestId
			payload.ProgressText = "Quest complete"
			payload.HintText = "Start the next quest at the green marker."
			payload.ZoneId = questDefinition and questDefinition.ZoneId
			payload.ZoneName = questDefinition and getZoneName(questDefinition.ZoneId)
			return result(true, "QuestTrackerStateBuilt", nil, payload)
		end
	end

	local payload = buildBasePayload("NoQuest")
	payload.QuestTitle = "ANP Adventures"
	payload.ProgressText = "No active quest"
	payload.HintText = "Look for a green Quest Start marker."
	payload.CurrentObjectiveText = "No active quest. Find the green Quest Start marker."
	return result(true, "QuestTrackerStateBuilt", nil, payload)
end

function QuestTrackerService.SendTrackerUpdate(player)
	local trackerResult = QuestTrackerService.BuildTrackerState(player)
	if not trackerResult.Success then
		return trackerResult
	end

	return playerFeedbackService.SendQuestTracker(player, trackerResult.Data)
end

return QuestTrackerService
