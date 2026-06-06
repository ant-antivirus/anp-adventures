local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EpisodeDefinitions = require(Shared.Definitions.EpisodeDefinitions)

local EpisodeService = {}

local playerDataService = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function getEpisodeDefinition(episodeId)
	local episodeDefinition = EpisodeDefinitions[episodeId]
	if not episodeDefinition then
		return nil, result(false, "UnknownEpisodeId", "Unknown episode `" .. tostring(episodeId) .. "`.")
	end

	return episodeDefinition, nil
end

function EpisodeService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService

	assert(playerDataService, "EpisodeService requires PlayerDataService.")
end

function EpisodeService.GetEpisodeDefinition(episodeId)
	local episodeDefinition, errorResult = getEpisodeDefinition(episodeId)
	if errorResult then
		return errorResult
	end

	return result(true, "EpisodeDefinitionRead", nil, episodeDefinition)
end

function EpisodeService.GetEpisodeCatalog()
	return result(true, "EpisodeCatalogRead", nil, EpisodeDefinitions)
end

function EpisodeService.GetPlayerEpisodeState(player, episodeId)
	local episodeDefinition, errorResult = getEpisodeDefinition(episodeId)
	if errorResult then
		return errorResult
	end

	local snapshotResult = playerDataService.GetSnapshot(player, "Episodes")
	if not snapshotResult.Success then
		return snapshotResult
	end

	local episodeData = snapshotResult.Data
	local episodeProgress = episodeData.EpisodeProgress[episodeId] or {
		StartedAt = nil,
		CompletedAt = nil,
		CompletedQuestCount = 0,
		TotalQuestCount = #(episodeDefinition.QuestIds or {}),
	}

	return result(true, "EpisodeStateRead", nil, {
		EpisodeId = episodeId,
		IsUnlocked = episodeData.UnlockedEpisodeIds[episodeId] == true,
		IsCompleted = episodeData.CompletedEpisodeIds[episodeId] == true,
		IsActive = episodeData.ActiveEpisodeId == episodeId,
		Progress = episodeProgress,
	})
end

function EpisodeService.IsEpisodeUnlocked(player, episodeId)
	local stateResult = EpisodeService.GetPlayerEpisodeState(player, episodeId)
	if not stateResult.Success then
		return false, stateResult.Code
	end

	return stateResult.Data.IsUnlocked == true
end

function EpisodeService.UnlockEpisode(player, episodeId, sourceContext)
	local episodeDefinition, errorResult = getEpisodeDefinition(episodeId)
	if errorResult then
		return errorResult
	end

	local mutationResult = playerDataService.Mutate(player, "UnlockEpisode", sourceContext, function(playerData)
		local wasUnlocked = playerData.Episodes.UnlockedEpisodeIds[episodeId] == true
		playerData.Episodes.UnlockedEpisodeIds[episodeId] = true

		playerData.Episodes.EpisodeProgress[episodeId] = playerData.Episodes.EpisodeProgress[episodeId] or {
			StartedAt = nil,
			CompletedAt = nil,
			CompletedQuestCount = 0,
			TotalQuestCount = #(episodeDefinition.QuestIds or {}),
		}

		return not wasUnlocked
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	return result(true, "EpisodeUnlocked", nil, {
		EpisodeId = episodeId,
		WasAlreadyUnlocked = mutationResult.Data.Changed == false,
	})
end

function EpisodeService.SetActiveEpisode(player, episodeId, sourceContext)
	local _, errorResult = getEpisodeDefinition(episodeId)
	if errorResult then
		return errorResult
	end

	if not EpisodeService.IsEpisodeUnlocked(player, episodeId) then
		return result(false, "EpisodeLocked", "Cannot activate locked episode `" .. episodeId .. "`.")
	end

	local mutationResult = playerDataService.Mutate(player, "SetActiveEpisode", sourceContext, function(playerData)
		local wasActive = playerData.Episodes.ActiveEpisodeId == episodeId
		playerData.Episodes.ActiveEpisodeId = episodeId

		local progress = playerData.Episodes.EpisodeProgress[episodeId]
		if progress and progress.StartedAt == nil then
			progress.StartedAt = os.time()
		end

		return not wasActive
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	return result(true, "ActiveEpisodeSet", nil, {
		EpisodeId = episodeId,
		WasAlreadyActive = mutationResult.Data.Changed == false,
	})
end

function EpisodeService.CompleteEpisode(player, episodeId, sourceContext)
	local _, errorResult = getEpisodeDefinition(episodeId)
	if errorResult then
		return errorResult
	end

	if not EpisodeService.IsEpisodeUnlocked(player, episodeId) then
		return result(false, "EpisodeLocked", "Cannot complete locked episode `" .. episodeId .. "`.")
	end

	local completedAt = os.time()
	local mutationResult = playerDataService.Mutate(player, "CompleteEpisode", sourceContext, function(playerData)
		local wasCompleted = playerData.Episodes.CompletedEpisodeIds[episodeId] == true
		playerData.Episodes.CompletedEpisodeIds[episodeId] = true

		local progress = playerData.Episodes.EpisodeProgress[episodeId]
		if progress then
			progress.StartedAt = progress.StartedAt or completedAt
			progress.CompletedAt = progress.CompletedAt or completedAt
		end

		return not wasCompleted
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	return result(true, "EpisodeCompleted", nil, {
		EpisodeId = episodeId,
		WasAlreadyCompleted = mutationResult.Data.Changed == false,
	})
end

return EpisodeService
