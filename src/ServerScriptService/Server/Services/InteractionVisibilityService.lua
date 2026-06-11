local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local Logger = require(script.Parent.Parent.Utils.Logger)

local InteractionVisibilityService = {}

local playerDataService = nil
local questService = nil
local discoveryService = nil
local zoneService = nil
local promptBindingService = nil
local lastRefreshPlayer = nil

local FOCUSED_OBJECT_STATE_DEBUG_INTERACTIONS = {
	interaction_ep01_main_003_003 = true,
	interaction_ep01_main_003_004 = true,
}

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

local function unavailableState(definition, reason)
	if reason == "ObjectiveDependencyMissing" then
		return interactionState(false, false, reason)
	end

	if definition.VisibleBeforeAvailable == true and definition.InspectableBeforeAvailable == true then
		return interactionState(true, true, reason)
	end

	return interactionState(false, false, reason)
end

local function shouldHideAfterObjectiveComplete(definition)
	if definition.HidePromptAfterObjectiveComplete ~= nil then
		return definition.HidePromptAfterObjectiveComplete == true
	end

	return definition.ObjectBehaviorType == "CollectibleItem"
end

local function shouldLogObjectState(definition)
	return definition
		and (
			FOCUSED_OBJECT_STATE_DEBUG_INTERACTIONS[definition.InteractionId] == true
			or shouldHideAfterObjectiveComplete(definition)
		)
end

local function getPlayerName(player)
	return player and player.Name or "UnknownPlayer"
end

local function logQuestObjectiveState(player, definition, questState, objectiveCompleted, state)
	if not shouldLogObjectState(definition) then
		return
	end

	local active = questState and questState.Status == questService.QuestStatus.Active
	local questCompleted = questState and questState.Status == questService.QuestStatus.Completed

	Logger.ObjectStateDebug(
		tostring(definition.InteractionId)
			.. " player="
			.. getPlayerName(player)
			.. " behavior="
			.. tostring(definition.ObjectBehaviorType)
			.. " hideAfterComplete="
			.. tostring(shouldHideAfterObjectiveComplete(definition))
			.. " questId="
			.. tostring(definition.QuestId)
			.. " objectiveId="
			.. tostring(definition.ObjectiveId)
			.. " active="
			.. tostring(active)
			.. " questCompleted="
			.. tostring(questCompleted)
			.. " objectiveCompleted="
			.. tostring(objectiveCompleted)
			.. " visible="
			.. tostring(state.Visible)
			.. " enabled="
			.. tostring(state.Enabled)
			.. " reason="
			.. tostring(state.Reason)
	)
end

local function finalizeQuestObjectiveState(player, definition, questState, objectiveCompleted, state)
	logQuestObjectiveState(player, definition, questState, objectiveCompleted, state)
	return state
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
		return unavailableState(definition, blockCode)
	end

	return interactionState(true, true, "QuestStartAvailable")
end

local function getQuestObjectiveState(player, definition)
	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return finalizeQuestObjectiveState(player, definition, nil, false, unavailableState(definition, "ZoneLocked"))
	end

	local questDefinition = QuestDefinitions[definition.QuestId]
	if not questDefinition then
		return finalizeQuestObjectiveState(player, definition, nil, false, interactionState(false, false, "UnknownQuestId"))
	end

	local questStateResult = questService.GetQuestState(player, definition.QuestId)
	if not questStateResult.Success then
		return finalizeQuestObjectiveState(player, definition, nil, false, interactionState(false, false, questStateResult.Code))
	end

	local objectiveCompleted = false
	local objectiveCompletedResult, objectiveCompletedCode = questService.IsObjectiveCompleted(player, definition.QuestId, definition.ObjectiveId)
	if objectiveCompletedResult == true then
		objectiveCompleted = true
	end

	if objectiveCompleted and shouldHideAfterObjectiveComplete(definition) then
		return finalizeQuestObjectiveState(
			player,
			definition,
			questStateResult.Data,
			objectiveCompleted,
			interactionState(false, false, "ObjectiveCompletedHidePrompt")
		)
	end

	if questStateResult.Data.Status ~= questService.QuestStatus.Active then
		return finalizeQuestObjectiveState(player, definition, questStateResult.Data, objectiveCompleted, unavailableState(definition, "QuestNotActive"))
	end

	local objectiveState = questStateResult.Data.ObjectiveStates and questStateResult.Data.ObjectiveStates[definition.ObjectiveId]
	if not objectiveState then
		return finalizeQuestObjectiveState(player, definition, questStateResult.Data, objectiveCompleted, interactionState(false, false, "UnknownQuestObjectiveId"))
	end

	if objectiveState.Completed == true then
		if shouldHideAfterObjectiveComplete(definition) then
			return finalizeQuestObjectiveState(player, definition, questStateResult.Data, true, interactionState(false, false, "ObjectiveCompletedHidePrompt"))
		end

		return finalizeQuestObjectiveState(player, definition, questStateResult.Data, true, unavailableState(definition, "ObjectiveComplete"))
	end

	local objectiveDefinition = questDefinition.ObjectiveDefinitions and questDefinition.ObjectiveDefinitions[definition.ObjectiveId]
	for _, requiredObjectiveId in ipairs((objectiveDefinition and objectiveDefinition.RequiresObjectiveIds) or {}) do
		local requiredObjectiveState = questStateResult.Data.ObjectiveStates and questStateResult.Data.ObjectiveStates[requiredObjectiveId]
		if not requiredObjectiveState or requiredObjectiveState.Completed ~= true then
			return finalizeQuestObjectiveState(
				player,
				definition,
				questStateResult.Data,
				objectiveCompleted,
				unavailableState(definition, "ObjectiveDependencyMissing")
			)
		end
	end

	if objectiveCompletedCode == "UnknownQuestObjectiveId" then
		return finalizeQuestObjectiveState(player, definition, questStateResult.Data, objectiveCompleted, interactionState(false, false, objectiveCompletedCode))
	end

	return finalizeQuestObjectiveState(player, definition, questStateResult.Data, objectiveCompleted, interactionState(true, true, "QuestObjectiveAvailable"))
end

local function findQuestIdForObjective(objectiveId)
	for questId, questDefinition in pairs(QuestDefinitions) do
		for _, questObjectiveId in ipairs(questDefinition.ObjectiveIds or {}) do
			if questObjectiveId == objectiveId then
				return questId
			end
		end
	end

	return nil
end

local function hasActiveIncompleteLinkedObjective(player, definition)
	for _, objectiveId in ipairs(definition.ObjectiveProgressIds or {}) do
		local questId = findQuestIdForObjective(objectiveId)
		if questId then
			local questStateResult = questService.GetQuestState(player, questId)
			if questStateResult.Success and questStateResult.Data.Status == questService.QuestStatus.Active then
				local objectiveState = questStateResult.Data.ObjectiveStates and questStateResult.Data.ObjectiveStates[objectiveId]
				if objectiveState and objectiveState.Completed ~= true then
					return true
				end
			end
		end
	end

	return false
end

local function requiredQuestObjectivesComplete(questDefinition, questState)
	for _, objectiveId in ipairs(questDefinition.RequiredObjectiveIds or {}) do
		local objectiveState = questState.ObjectiveStates and questState.ObjectiveStates[objectiveId]
		if not objectiveState or objectiveState.Completed ~= true then
			return false
		end
	end

	return true
end

local function getQuestCompleteState(player, definition)
	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return unavailableState(definition, "ZoneLocked")
	end

	local questDefinition = QuestDefinitions[definition.QuestId]
	if not questDefinition then
		return interactionState(false, false, "UnknownQuestId")
	end

	local questStateResult = questService.GetQuestState(player, definition.QuestId)
	if not questStateResult.Success then
		return interactionState(false, false, questStateResult.Code)
	end

	if questStateResult.Data.Status == questService.QuestStatus.Completed then
		return unavailableState(definition, "QuestAlreadyCompleted")
	end

	if questStateResult.Data.Status ~= questService.QuestStatus.Active then
		return unavailableState(definition, "QuestNotActive")
	end

	if not requiredQuestObjectivesComplete(questDefinition, questStateResult.Data) then
		return unavailableState(definition, "QuestObjectivesIncomplete")
	end

	return interactionState(true, true, "QuestCompleteAvailable")
end

local function getDiscoveryState(player, definition)
	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return unavailableState(definition, "ZoneLocked")
	end

	local discoveryStateResult = discoveryService.GetDiscoveryState(player, definition.DiscoveryId)
	if not discoveryStateResult.Success then
		return interactionState(false, false, discoveryStateResult.Code)
	end

	if discoveryStateResult.Data.IsFound == true then
		if hasActiveIncompleteLinkedObjective(player, definition) then
			return interactionState(true, true, "DiscoveryRecordedObjectiveAvailable")
		end

		return interactionState(false, false, "DiscoveryAlreadyRecorded")
	end

	return interactionState(true, true, "DiscoveryAvailable")
end

local function getZoneTravelState(player, definition)
	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return unavailableState(definition, "ZoneLocked")
	end

	return interactionState(true, true, "ZoneTravelAvailable")
end

local function getNPCGuideState(player, definition)
	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return unavailableState(definition, "ZoneLocked")
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
		return result(true, "InteractionStateRead", nil, unavailableState(definition, commonReason))
	end

	local policy = definition.VisibilityPolicy or definition.Type
	local state

	if policy == "NPCGuide" then
		state = getNPCGuideState(player, definition)
	elseif policy == "QuestStart" then
		state = getQuestStartState(player, definition)
	elseif policy == "QuestComplete" then
		state = getQuestCompleteState(player, definition)
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
			promptBindingService.SetPromptEnabled(
				interactionId,
				stateResult.Data.Visible == true and stateResult.Data.Enabled == true,
				player,
				stateResult.Data.Reason
			)
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

	promptBindingService.SetPromptEnabled(
		interactionId,
		stateResult.Data.Visible == true and stateResult.Data.Enabled == true,
		lastRefreshPlayer,
		stateResult.Data.Reason
	)
	return result(true, "InteractionVisibilityRefreshed", nil, stateResult.Data)
end

return InteractionVisibilityService
