local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)

local InteractionVisibilityService = {}

local playerDataService = nil
local questService = nil
local discoveryService = nil
local zoneService = nil
local promptBindingService = nil
local lastRefreshPlayer = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function interactionState(visible, enabled, reason)
	return {
		Visible = visible,
		Enabled = enabled,
		Reason = reason,
	}
end

local function getDefinition(interactionId)
	local definition = InteractionDefinitions[interactionId]
	if not definition then
		return nil, result(false, "UnknownInteractionId", "Unknown interaction `" .. tostring(interactionId) .. "`.")
	end

	return definition, nil
end

local function requiredZonesUnlocked(player, definition)
	for _, zoneId in ipairs(definition.RequiredZoneIds or {}) do
		if not zoneService.IsZoneUnlocked(player, zoneId) then
			return false, "RequiredZoneLocked"
		end
	end

	return true, nil
end

local function requiredQuestsCompleted(player, definition)
	if #(definition.RequiredQuestIds or {}) == 0 then
		return true, nil
	end

	local questSnapshot = playerDataService.GetSnapshot(player, "Quests")
	if not questSnapshot.Success then
		return false, questSnapshot.Code
	end

	for _, questId in ipairs(definition.RequiredQuestIds or {}) do
		if questSnapshot.Data.CompletedQuestIds[questId] ~= true then
			return false, "RequiredQuestIncomplete"
		end
	end

	return true, nil
end

local function requiredEpisodesUnlocked(player, definition)
	if #(definition.RequiredEpisodeIds or {}) == 0 then
		return true, nil
	end

	local episodeSnapshot = playerDataService.GetSnapshot(player, "Episodes")
	if not episodeSnapshot.Success then
		return false, episodeSnapshot.Code
	end

	for _, episodeId in ipairs(definition.RequiredEpisodeIds or {}) do
		if episodeSnapshot.Data.UnlockedEpisodeIds[episodeId] ~= true then
			return false, "RequiredEpisodeLocked"
		end
	end

	return true, nil
end

local function checkCommonRequirements(player, definition)
	if definition.Enabled ~= true then
		return false, "InteractionDisabled"
	end

	local zonesReady, zoneReason = requiredZonesUnlocked(player, definition)
	if not zonesReady then
		return false, zoneReason
	end

	local questsReady, questReason = requiredQuestsCompleted(player, definition)
	if not questsReady then
		return false, questReason
	end

	local episodesReady, episodeReason = requiredEpisodesUnlocked(player, definition)
	if not episodesReady then
		return false, episodeReason
	end

	return true, nil
end

local function getQuestStartState(player, definition)
	local canStart, blockCode = questService.CanStartQuest(player, definition.QuestId)
	if not canStart then
		return interactionState(false, false, blockCode)
	end

	return interactionState(true, true, "QuestStartAvailable")
end

local function getQuestObjectiveState(player, definition)
	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return interactionState(false, false, "ZoneLocked")
	end

	local questStateResult = questService.GetQuestState(player, definition.QuestId)
	if not questStateResult.Success then
		return interactionState(false, false, questStateResult.Code)
	end

	if questStateResult.Data.Status ~= questService.QuestStatus.Active then
		return interactionState(false, false, "QuestNotActive")
	end

	local objectiveState = questStateResult.Data.ObjectiveStates and questStateResult.Data.ObjectiveStates[definition.ObjectiveId]
	if not objectiveState then
		return interactionState(false, false, "UnknownQuestObjectiveId")
	end

	if objectiveState.Completed == true then
		return interactionState(false, false, "ObjectiveComplete")
	end

	return interactionState(true, true, "QuestObjectiveAvailable")
end

local function getDiscoveryState(player, definition)
	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return interactionState(false, false, "ZoneLocked")
	end

	local discoveryStateResult = discoveryService.GetDiscoveryState(player, definition.DiscoveryId)
	if not discoveryStateResult.Success then
		return interactionState(false, false, discoveryStateResult.Code)
	end

	if discoveryStateResult.Data.IsFound == true then
		return interactionState(false, false, "DiscoveryAlreadyRecorded")
	end

	return interactionState(true, true, "DiscoveryAvailable")
end

local function getZoneTravelState(player, definition)
	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return interactionState(false, false, "ZoneLocked")
	end

	return interactionState(true, true, "ZoneTravelAvailable")
end

local function getNPCGuideState(player, definition)
	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return interactionState(false, false, "ZoneLocked")
	end

	return interactionState(true, true, "NPCGuideAvailable")
end

local function getGenericState()
	return interactionState(true, true, "GenericAvailable")
end

function InteractionVisibilityService.Initialize(dependencies)
	playerDataService = dependencies.PlayerDataService
	questService = dependencies.QuestService
	discoveryService = dependencies.DiscoveryService
	zoneService = dependencies.ZoneService
	promptBindingService = dependencies.PromptBindingService

	assert(playerDataService, "InteractionVisibilityService requires PlayerDataService.")
	assert(questService, "InteractionVisibilityService requires QuestService.")
	assert(discoveryService, "InteractionVisibilityService requires DiscoveryService.")
	assert(zoneService, "InteractionVisibilityService requires ZoneService.")
	assert(promptBindingService, "InteractionVisibilityService requires PromptBindingService.")
end

function InteractionVisibilityService.CanSeeInteraction(player, interactionId)
	local stateResult = InteractionVisibilityService.GetInteractionState(player, interactionId)
	if not stateResult.Success then
		return false, stateResult.Code
	end

	return stateResult.Data.Visible == true, stateResult.Data.Reason
end

function InteractionVisibilityService.GetInteractionState(player, interactionId)
	if not playerDataService.IsLoaded(player) then
		return result(false, "PlayerDataNotLoaded", "Player data is not loaded.")
	end

	local definition, definitionError = getDefinition(interactionId)
	if definitionError then
		return definitionError
	end

	local commonReady, commonReason = checkCommonRequirements(player, definition)
	if not commonReady then
		return result(true, "InteractionStateRead", nil, interactionState(false, false, commonReason))
	end

	local policy = definition.VisibilityPolicy or definition.Type
	local state

	if policy == "NPCGuide" then
		state = getNPCGuideState(player, definition)
	elseif policy == "QuestStart" then
		state = getQuestStartState(player, definition)
	elseif policy == "QuestObjective" then
		state = getQuestObjectiveState(player, definition)
	elseif policy == "Discovery" then
		state = getDiscoveryState(player, definition)
	elseif policy == "ZoneTravel" then
		state = getZoneTravelState(player, definition)
	elseif policy == "Generic" then
		state = getGenericState()
	else
		state = interactionState(false, false, "InvalidVisibilityPolicy")
	end

	return result(true, "InteractionStateRead", nil, state)
end

function InteractionVisibilityService.RefreshPlayer(player)
	if not playerDataService.IsLoaded(player) then
		return result(false, "PlayerDataNotLoaded", "Player data is not loaded.")
	end

	local refreshed = {}
	lastRefreshPlayer = player

	for interactionId in pairs(InteractionDefinitions) do
		local stateResult = InteractionVisibilityService.GetInteractionState(player, interactionId)
		if stateResult.Success then
			promptBindingService.SetPromptEnabled(interactionId, stateResult.Data.Visible == true and stateResult.Data.Enabled == true)
			refreshed[interactionId] = stateResult.Data
		end
	end

	return result(true, "PlayerInteractionVisibilityRefreshed", nil, refreshed)
end

function InteractionVisibilityService.RefreshInteraction(interactionId)
	local _, definitionError = getDefinition(interactionId)
	if definitionError then
		return definitionError
	end

	if not lastRefreshPlayer then
		return result(true, "InteractionVisibilityRefreshSkipped", "No player has been refreshed yet.", {
			InteractionId = interactionId,
		})
	end

	local stateResult = InteractionVisibilityService.GetInteractionState(lastRefreshPlayer, interactionId)
	if not stateResult.Success then
		return stateResult
	end

	promptBindingService.SetPromptEnabled(interactionId, stateResult.Data.Visible == true and stateResult.Data.Enabled == true)
	return result(true, "InteractionVisibilityRefreshed", nil, stateResult.Data)
end

return InteractionVisibilityService
