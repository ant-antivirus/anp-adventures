local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local DiscoveryDefinitions = require(Shared.Definitions.DiscoveryDefinitions)
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)

local InteractionValidator = {}

local VALID_TYPES = {
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

local function validateInteractionWorldObject(validationResult, definition, worldRegistryService)
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

	if definition.Type == "QuestObjective" then
		if object:GetAttribute("QuestId") ~= definition.QuestId then
			addError(validationResult, "Interaction `" .. definition.InteractionId .. "` QuestId does not match world object.")
		end

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

		if not ZoneDefinitions[definition.ZoneId] then
			addError(validationResult, "Interaction `" .. tostring(definition.InteractionId) .. "` references invalid ZoneId `" .. tostring(definition.ZoneId) .. "`.")
		end

		if definition.Type == "QuestObjective" then
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
