local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)
local Logger = require(script.Parent.Parent.Utils.Logger)

local PromptBindingService = {}

local PROMPT_NAME = "ANP_InteractionPrompt"

local worldRegistryService = nil
local interactionService = nil
local interactionVisibilityService = nil
local boundPromptsByInteractionId = {}
local boundConnectionsByInteractionId = {}

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function hostResult(success, code, message, instance)
	return {
		Success = success,
		Code = code,
		Message = message,
		Instance = instance,
		Data = instance,
	}
end

local function getDefaultActionText(interactionType)
	if interactionType == "NPCGuide" then
		return "Ask"
	elseif interactionType == "QuestStart" then
		return "Start Quest"
	elseif interactionType == "QuestComplete" then
		return "Complete Quest"
	elseif interactionType == "Discovery" then
		return "Inspect"
	elseif interactionType == "ZoneTravel" then
		return "Travel"
	elseif interactionType == "NPC" or interactionType == "NPCMarker" then
		return "Talk"
	elseif interactionType == "Generic" then
		return "Use"
	end

	return "Interact"
end

local function getDefaultObjectText(definition)
	if definition.Type == "NPCGuide" then
		return definition.CharacterId or definition.InteractionId
	elseif definition.Type == "QuestStart" then
		return definition.QuestId or definition.InteractionId
	elseif definition.Type == "QuestComplete" then
		return definition.QuestId or definition.InteractionId
	elseif definition.Type == "Discovery" then
		return definition.DiscoveryId or definition.InteractionId
	elseif definition.Type == "ZoneTravel" then
		return definition.ZoneId or definition.InteractionId
	elseif definition.Type == "QuestObjective" then
		return definition.ObjectiveId or definition.InteractionId
	end

	return definition.InteractionId
end

local function resolvePromptHost(definition)
	if not definition then
		return hostResult(false, "InteractionDefinitionMissing", "Interaction definition is required.")
	end

	if definition.Type == "NPCGuide" then
		if type(definition.CharacterId) == "string" and definition.CharacterId ~= "" then
			local markerByCharacter = worldRegistryService.GetNPCMarker(definition.CharacterId)
			if markerByCharacter.Success then
				return hostResult(true, "PromptHostResolved", nil, markerByCharacter.Data)
			end
		end

		if worldRegistryService.GetNPCMarkerByInteractionId then
			local markerByInteraction = worldRegistryService.GetNPCMarkerByInteractionId(definition.InteractionId)
			if markerByInteraction.Success then
				return hostResult(true, "PromptHostResolved", nil, markerByInteraction.Data)
			end
		end

		return hostResult(false, "NPCGuidePromptHostMissing", "NPCGuide prompt host was not found.")
	end

	if definition.Type == "Discovery" then
		local discoveryPoint = worldRegistryService.GetDiscoveryPoint(definition.DiscoveryId)
		if discoveryPoint.Success then
			return hostResult(true, "PromptHostResolved", nil, discoveryPoint.Data)
		end

		local interactionPoint = worldRegistryService.GetInteractionPoint(definition.InteractionId)
		if interactionPoint.Success then
			return hostResult(true, "PromptHostResolved", nil, interactionPoint.Data)
		end

		return hostResult(false, "DiscoveryPromptHostMissing", "Discovery prompt host was not found.")
	end

	local interactionPoint = worldRegistryService.GetInteractionPoint(definition.InteractionId)
	if interactionPoint.Success then
		return hostResult(true, "PromptHostResolved", nil, interactionPoint.Data)
	end

	return hostResult(false, "InteractionPointMissing", "Interaction prompt host was not found.")
end

local function getExistingPrompt(object, interactionId)
	local namedPrompt = object:FindFirstChild(PROMPT_NAME)
	if namedPrompt and namedPrompt:IsA("ProximityPrompt") then
		return namedPrompt
	end

	for _, child in ipairs(object:GetChildren()) do
		if child:IsA("ProximityPrompt") and child:GetAttribute("InteractionId") == interactionId then
			return child
		end
	end

	return nil
end

local function configurePrompt(prompt, definition)
	prompt.Name = PROMPT_NAME
	prompt.ActionText = definition.PromptActionText or getDefaultActionText(definition.Type)
	prompt.ObjectText = definition.PromptObjectText or getDefaultObjectText(definition)
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Enabled = false
	prompt:SetAttribute("InteractionId", definition.InteractionId)
end

local function getOrCreatePrompt(object, definition)
	local prompt = getExistingPrompt(object, definition.InteractionId)
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = object
	end

	configurePrompt(prompt, definition)
	return prompt
end

local function handlePromptTriggered(player, interactionId, metadata)
	local interactionResult = interactionService.AttemptInteraction(player, interactionId, metadata or {
		SourceType = "ProximityPrompt",
		InteractionId = interactionId,
	})

	local playerName = player and player.Name or "UnknownPlayer"
	if interactionResult.Success then
		Logger.PromptSuccess("Interaction `" .. interactionId .. "` succeeded for " .. playerName .. ".")
		if interactionVisibilityService then
			interactionVisibilityService.RefreshPlayer(player)
		end
	else
		Logger.PromptFailure("Interaction `" .. interactionId .. "` failed for " .. playerName .. ": " .. tostring(interactionResult.Code))
	end

	return interactionResult
end

local function bindPrompt(interactionId, prompt)
	local existingPrompt = boundPromptsByInteractionId[interactionId]
	if existingPrompt == prompt and boundConnectionsByInteractionId[interactionId] ~= nil then
		return
	end

	local existingConnection = boundConnectionsByInteractionId[interactionId]
	if existingConnection then
		existingConnection:Disconnect()
	end

	boundPromptsByInteractionId[interactionId] = prompt
	boundConnectionsByInteractionId[interactionId] = prompt.Triggered:Connect(function(player)
		handlePromptTriggered(player, interactionId, {
			SourceType = "ProximityPrompt",
			InteractionId = interactionId,
		})
	end)
end

function PromptBindingService.Init(dependencies)
	worldRegistryService = dependencies.WorldRegistryService
	interactionService = dependencies.InteractionService
	interactionVisibilityService = dependencies.InteractionVisibilityService

	assert(worldRegistryService, "PromptBindingService requires WorldRegistryService.")
	assert(interactionService, "PromptBindingService requires InteractionService.")
end

function PromptBindingService.SetInteractionVisibilityService(service)
	interactionVisibilityService = service
end

function PromptBindingService.BindAllPrompts()
	local errors = {}
	local boundCount = 0
	local skippedCount = 0

	for interactionId, definition in pairs(InteractionDefinitions) do
		if definition.EnabledInWorld == false then
			skippedCount += 1
			continue
		end

		local objectResult = resolvePromptHost(definition)
		if not objectResult.Success then
			table.insert(errors, {
				InteractionId = interactionId,
				Code = objectResult.Code,
			})
			continue
		end

		local prompt = getOrCreatePrompt(objectResult.Data, definition)
		bindPrompt(interactionId, prompt)
		boundCount += 1
	end

	if #errors > 0 then
		return result(false, "PromptBindingFailed", "One or more interaction prompts could not bind.", {
			BoundCount = boundCount,
			SkippedCount = skippedCount,
			Errors = errors,
		})
	end

	return result(true, "PromptsBound", nil, {
		BoundCount = boundCount,
		SkippedCount = skippedCount,
		Errors = errors,
	})
end

function PromptBindingService.ResolvePromptHost(interactionDefinition)
	return resolvePromptHost(interactionDefinition)
end

function PromptBindingService.GetPromptForInteraction(interactionId)
	local prompt = boundPromptsByInteractionId[interactionId]
	return result(prompt ~= nil, prompt and "PromptRead" or "PromptMissing", nil, prompt)
end

function PromptBindingService.SetPromptEnabled(interactionId, enabled)
	local prompt = boundPromptsByInteractionId[interactionId]
	if not prompt then
		return result(false, "PromptMissing", "Interaction prompt is not bound.")
	end

	prompt.Enabled = enabled == true
	return result(true, "PromptEnabledStateUpdated", nil, {
		InteractionId = interactionId,
		Enabled = prompt.Enabled,
	})
end

function PromptBindingService.RefreshPlayer(player)
	if not interactionVisibilityService then
		return result(false, "InteractionVisibilityServiceMissing", "InteractionVisibilityService has not been configured.")
	end

	return interactionVisibilityService.RefreshPlayer(player)
end

function PromptBindingService.SimulatePromptTrigger(player, interactionId, metadata)
	local promptResult = PromptBindingService.GetPromptForInteraction(interactionId)
	if not promptResult.Success then
		return result(false, "PromptNotBound", "Interaction prompt is not bound.")
	end

	local simulatedMetadata = metadata or {
		SourceType = "PromptSmokeTest",
		InteractionId = interactionId,
	}
	if simulatedMetadata.BypassCooldownForTests == nil then
		simulatedMetadata.BypassCooldownForTests = true
	end

	return handlePromptTriggered(player, interactionId, simulatedMetadata)
end

function PromptBindingService.ResetForTests()
	for interactionId, connection in pairs(boundConnectionsByInteractionId) do
		connection:Disconnect()
		boundConnectionsByInteractionId[interactionId] = nil
	end

	table.clear(boundPromptsByInteractionId)
end

return PromptBindingService
