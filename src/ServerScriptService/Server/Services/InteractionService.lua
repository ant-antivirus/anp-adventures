local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)

local InteractionService = {}

local VALID_TYPES = {
	QuestObjective = true,
	Discovery = true,
	ZoneTravel = true,
	Generic = true,
}

local playerDataService = nil
local worldRegistryService = nil
local questService = nil
local discoveryService = nil
local zoneService = nil

local function result(success, code, failureReason, data)
	local response = {
		Success = success,
		Code = code,
		FailureReason = failureReason,
		GrantedQuestProgress = false,
		GrantedDiscovery = false,
		GrantedZoneTravel = false,
		Data = data,
	}

	if data then
		if data.GrantedQuestProgress ~= nil then
			response.GrantedQuestProgress = data.GrantedQuestProgress
		end
		if data.GrantedDiscovery ~= nil then
			response.GrantedDiscovery = data.GrantedDiscovery
		end
		if data.GrantedZoneTravel ~= nil then
			response.GrantedZoneTravel = data.GrantedZoneTravel
		end
	end

	return response
end

local function getInteractionDefinition(interactionId)
	local definition = InteractionDefinitions[interactionId]
	if not definition then
		return nil, result(false, "UnknownInteractionId", "UnknownInteractionId")
	end

	return definition, nil
end

local function buildSourceContext(interactionId)
	return {
		SourceType = "Interaction",
		SourceId = interactionId,
	}
end

local function validateWorldObject(definition)
	if definition.Type == "Discovery" then
		local discoveryPointResult = worldRegistryService.GetDiscoveryPoint(definition.DiscoveryId)
		if not discoveryPointResult.Success then
			return result(false, "InteractionWorldObjectMissing", "InteractionWorldObjectMissing")
		end
		return nil
	end

	local interactionObjectResult = worldRegistryService.GetInteraction(definition.InteractionId)
	if not interactionObjectResult.Success then
		return result(false, "InteractionWorldObjectMissing", "InteractionWorldObjectMissing")
	end

	return nil
end

function InteractionService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	worldRegistryService = dependencies.WorldRegistryService
	questService = dependencies.QuestService
	discoveryService = dependencies.DiscoveryService
	zoneService = dependencies.ZoneService

	assert(playerDataService, "InteractionService requires PlayerDataService.")
	assert(worldRegistryService, "InteractionService requires WorldRegistryService.")
	assert(questService, "InteractionService requires QuestService.")
	assert(discoveryService, "InteractionService requires DiscoveryService.")
	assert(zoneService, "InteractionService requires ZoneService.")
end

function InteractionService.GetInteractionDefinition(interactionId)
	local definition, errorResult = getInteractionDefinition(interactionId)
	if errorResult then
		return errorResult
	end

	return result(true, "InteractionDefinitionRead", nil, definition)
end

function InteractionService.GetInteractionCatalog()
	return result(true, "InteractionCatalogRead", nil, InteractionDefinitions)
end

function InteractionService.RegisterWorldInteractions()
	return worldRegistryService.Init()
end

function InteractionService.AttemptInteraction(player, interactionId, metadata)
	if not playerDataService.IsLoaded(player) then
		return result(false, "PlayerDataNotLoaded", "PlayerDataNotLoaded")
	end

	local definition, definitionError = getInteractionDefinition(interactionId)
	if definitionError then
		return definitionError
	end

	if definition.Enabled ~= true then
		return result(false, "InteractionDisabled", "InteractionDisabled")
	end

	if not VALID_TYPES[definition.Type] then
		return result(false, "InvalidInteractionType", "InvalidInteractionType")
	end

	local worldObjectError = validateWorldObject(definition)
	if worldObjectError then
		return worldObjectError
	end

	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return result(false, "ZoneLocked", "ZoneLocked")
	end

	local sourceContext = buildSourceContext(interactionId)
	local safeMetadata = if type(metadata) == "table" then metadata else {}

	if definition.Type == "QuestObjective" then
		local progressResult = questService.ApplyObjectiveProgress(
			player,
			definition.QuestId,
			definition.ObjectiveId,
			safeMetadata.Amount or 1,
			sourceContext,
			safeMetadata
		)

		if not progressResult.Success then
			return result(false, progressResult.Code, progressResult.Code, {
				ServiceResult = progressResult,
			})
		end

		return result(true, "InteractionQuestProgressApplied", nil, {
			GrantedQuestProgress = true,
			ServiceResult = progressResult,
		})
	elseif definition.Type == "Discovery" then
		local discoveryResult = discoveryService.RecordDiscovery(player, definition.DiscoveryId, sourceContext)
		if not discoveryResult.Success then
			return result(false, discoveryResult.Code, discoveryResult.Code, {
				ServiceResult = discoveryResult,
			})
		end

		return result(true, "InteractionDiscoveryRecorded", nil, {
			GrantedDiscovery = true,
			ServiceResult = discoveryResult,
		})
	elseif definition.Type == "ZoneTravel" then
		local travelResult = zoneService.TravelToZone(
			player,
			definition.ZoneId,
			safeMetadata.SpawnPointId,
			safeMetadata.TravelMode or "Spawn",
			sourceContext
		)

		if not travelResult.Success then
			return result(false, travelResult.Code, travelResult.Code, {
				ServiceResult = travelResult,
			})
		end

		return result(true, "InteractionZoneTravelRecorded", nil, {
			GrantedZoneTravel = true,
			ServiceResult = travelResult,
		})
	end

	return result(true, "InteractionGenericHandled", nil, {})
end

return InteractionService
