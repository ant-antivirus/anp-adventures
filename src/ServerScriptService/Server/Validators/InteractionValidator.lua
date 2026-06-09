local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local DiscoveryDefinitions = require(Shared.Definitions.DiscoveryDefinitions)
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)
local EpisodeDefinitions = require(Shared.Definitions.EpisodeDefinitions)
local CharacterConfig = require(Shared.Config.CharacterConfig)

local InteractionValidator = {}

local VALID_TYPES = {
	NPCGuide = true,
	QuestStart = true,
	QuestObjective = true,
	Discovery = true,
	ZoneTravel = true,
	Generic = true,
}

local VALID_VISIBILITY_POLICIES = {
	NPCGuide = true,
	QuestStart = true,
	QuestObjective = true,
	Discovery = true,
	ZoneTravel = true,
	Generic = true,
}

local function newResult()
	return {
		Success = true,
		Code = "InteractionValidationPassed",
		Errors = {},
		Warnings = {},
		Summary = {
			Interactions = 0,
			Duplicates = 0,
		},
	}
end

local function addError(validationResult, message)
	validationResult.Success = false
	validationResult.Code = "InteractionValidationFailed"
	table.insert(validationResult.Errors, message)
end

local function questContainsObjective(questDefinition, objectiveId)
	for _, questObjectiveId in ipairs(questDefinition.ObjectiveIds or {}) do
		if questObjectiveId == objectiveId then
			return true
		end
	end

	return false
end

local function characterIdExists(characterId)
	for _, configuredCharacterId in pairs(CharacterConfig.Ids) do
		if configuredCharacterId == characterId then
			return true
		end
	end

	return false
end

local function objectiveIdExists(objectiveId)
	for _, questDefinition in pairs(QuestDefinitions) do
		if questContainsObjective(questDefinition, objectiveId) then
			return true
		end
	end

	return false
end

local function validateOptionalReferences(validationResult, definition)
	local seenObjectiveProgressIds = {}
	for _, objectiveId in ipairs(definition.ObjectiveProgressIds or {}) do
		if seenObjectiveProgressIds[objectiveId] then
			addError(validationResult, "Interaction `" .. tostring(definition.InteractionId) .. "` has duplicate ObjectiveProgressId `" .. tostring(objectiveId) .. "`.")
		else
			seenObjectiveProgressIds[objectiveId] = true
		end

		if not objectiveIdExists(objectiveId) then
			addError(validationResult, "Interaction `" .. tostring(definition.InteractionId) .. "` has invalid ObjectiveProgressId `" .. tostring(objectiveId) .. "`.")
		end
	end

	for _, questId in ipairs(definition.RequiredQuestIds or {}) do
		if not QuestDefinitions[questId] then
			addError(validationResult, "Interaction `" .. tostring(definition.InteractionId) .. "` has invalid RequiredQuestId `" .. tostring(questId) .. "`.")
		end
	end

	for _, zoneId in ipairs(definition.RequiredZoneIds or {}) do
		if not ZoneDefinitions[zoneId] then
			addError(validationResult, "Interaction `" .. tostring(definition.InteractionId) .. "` has invalid RequiredZoneId `" .. tostring(zoneId) .. "`.")
		end
	end

	for _, episodeId in ipairs(definition.RequiredEpisodeIds or {}) do
		if not EpisodeDefinitions[episodeId] then
			addError(validationResult, "Interaction `" .. tostring(definition.InteractionId) .. "` has invalid RequiredEpisodeId `" .. tostring(episodeId) .. "`.")
		end
	end
end

local function validateInteractionWorldObject(validationResult, definition, worldRegistryService)
	if definition.Type == "NPCGuide" then
		local npcMarkerResult = worldRegistryService.GetNPCMarker(definition.CharacterId)
		if not npcMarkerResult.Success then
			addError(validationResult, "NPCGuide interaction `" .. definition.InteractionId .. "` has no matching NPC marker.")
			return
		end

		local object = npcMarkerResult.Data
		if object:GetAttribute("InteractionId") ~= definition.InteractionId then
			addError(validationResult, "NPCGuide interaction `" .. definition.InteractionId .. "` InteractionId does not match NPC marker.")
		end
		if object:GetAttribute("ZoneId") ~= definition.ZoneId then
			addError(validationResult, "NPCGuide interaction `" .. definition.InteractionId .. "` ZoneId does not match NPC marker.")
		end
		return
	end

	if definition.Type == "Discovery" then
		local discoveryPointResult = worldRegistryService.GetDiscoveryPoint(definition.DiscoveryId)
		if not discoveryPointResult.Success then
			addError(validationResult, "Discovery interaction `" .. definition.InteractionId .. "` has no matching discovery point.")
			return
		end

		local object = discoveryPointResult.Data
		if object:GetAttribute("ZoneId") ~= definition.ZoneId then
			addError(validationResult, "Discovery interaction `" .. definition.InteractionId .. "` ZoneId does not match world object.")
		end
		return
	end

	local interactionObjectResult = worldRegistryService.GetInteraction(definition.InteractionId)
	if not interactionObjectResult.Success then
		addError(validationResult, "Interaction `" .. definition.InteractionId .. "` has no matching world interaction object.")
		return
	end

	local object = interactionObjectResult.Data
	if object:GetAttribute("ZoneId") ~= definition.ZoneId then
		addError(validationResult, "Interaction `" .. definition.InteractionId .. "` ZoneId does not match world object.")
	end

	if definition.Type == "QuestStart" or definition.Type == "QuestObjective" then
		if object:GetAttribute("QuestId") ~= definition.QuestId then
			addError(validationResult, "Interaction `" .. definition.InteractionId .. "` QuestId does not match world object.")
		end
	end

	if definition.Type == "QuestObjective" then
		if object:GetAttribute("ObjectiveId") ~= definition.ObjectiveId then
			addError(validationResult, "Interaction `" .. definition.InteractionId .. "` ObjectiveId does not match world object.")
		end
	end
end

function InteractionValidator.Validate(worldRegistryService)
	local validationResult = newResult()
	local seenInteractionIds = {}

	for key, definition in pairs(InteractionDefinitions) do
		validationResult.Summary.Interactions += 1

		if type(definition.InteractionId) ~= "string" or definition.InteractionId == "" then
			addError(validationResult, "Interaction entry `" .. tostring(key) .. "` is missing InteractionId.")
		elseif definition.InteractionId ~= key then
			addError(validationResult, "Interaction entry key `" .. tostring(key) .. "` does not match InteractionId `" .. definition.InteractionId .. "`.")
		elseif seenInteractionIds[definition.InteractionId] then
			validationResult.Summary.Duplicates += 1
			addError(validationResult, "Duplicate interaction id `" .. definition.InteractionId .. "`.")
		else
			seenInteractionIds[definition.InteractionId] = true
		end

		if not VALID_TYPES[definition.Type] then
			addError(validationResult, "Interaction `" .. tostring(definition.InteractionId) .. "` has invalid Type `" .. tostring(definition.Type) .. "`.")
		end

		if not VALID_VISIBILITY_POLICIES[definition.VisibilityPolicy or definition.Type] then
			addError(validationResult, "Interaction `" .. tostring(definition.InteractionId) .. "` has invalid VisibilityPolicy `" .. tostring(definition.VisibilityPolicy) .. "`.")
		end

		if not ZoneDefinitions[definition.ZoneId] then
			addError(validationResult, "Interaction `" .. tostring(definition.InteractionId) .. "` references invalid ZoneId `" .. tostring(definition.ZoneId) .. "`.")
		end

		validateOptionalReferences(validationResult, definition)

		if definition.Type == "NPCGuide" then
			if type(definition.CharacterId) ~= "string" or definition.CharacterId == "" then
				addError(validationResult, "Interaction `" .. definition.InteractionId .. "` is missing CharacterId.")
			elseif not characterIdExists(definition.CharacterId) then
				addError(validationResult, "Interaction `" .. definition.InteractionId .. "` references invalid CharacterId `" .. tostring(definition.CharacterId) .. "`.")
			end
		elseif definition.Type == "QuestStart" then
			if not QuestDefinitions[definition.QuestId] then
				addError(validationResult, "Interaction `" .. definition.InteractionId .. "` references invalid QuestId `" .. tostring(definition.QuestId) .. "`.")
			end
		elseif definition.Type == "QuestObjective" then
			local questDefinition = QuestDefinitions[definition.QuestId]
			if not questDefinition then
				addError(validationResult, "Interaction `" .. definition.InteractionId .. "` references invalid QuestId `" .. tostring(definition.QuestId) .. "`.")
			elseif not questContainsObjective(questDefinition, definition.ObjectiveId) then
				addError(validationResult, "Interaction `" .. definition.InteractionId .. "` references objective not present in quest definition.")
			end
		elseif definition.Type == "Discovery" then
			local discoveryDefinition = DiscoveryDefinitions[definition.DiscoveryId]
			if not discoveryDefinition then
				addError(validationResult, "Interaction `" .. definition.InteractionId .. "` references invalid DiscoveryId `" .. tostring(definition.DiscoveryId) .. "`.")
			elseif discoveryDefinition.ZoneId ~= definition.ZoneId then
				addError(validationResult, "Interaction `" .. definition.InteractionId .. "` ZoneId does not match discovery definition.")
			end
		end

		if worldRegistryService then
			validateInteractionWorldObject(validationResult, definition, worldRegistryService)
		end
	end

	return validationResult
end

return InteractionValidator
