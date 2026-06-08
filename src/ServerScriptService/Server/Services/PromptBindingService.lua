local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)

local PromptBindingService = {}

local PROMPT_NAME = "ANP_InteractionPrompt"

local worldRegistryService = nil
local interactionService = nil
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

local function getDefaultActionText(interactionType)
	if interactionType == "Discovery" then
		return "Discover"
	elseif interactionType == "ZoneTravel" then
		return "Travel"
	elseif interactionType == "Generic" then
		return "Use"
	end

	return "Interact"
end

local function getDefaultObjectText(definition)
	if definition.Type == "Discovery" then
		return definition.DiscoveryId or definition.InteractionId
	elseif definition.Type == "ZoneTravel" then
		return definition.ZoneId or definition.InteractionId
	elseif definition.Type == "QuestObjective" then
		return definition.ObjectiveId or definition.InteractionId
	end

	return definition.InteractionId
end

local function getWorldObjectForDefinition(definition)
	if definition.Type == "Discovery" then
		return worldRegistryService.GetDiscoveryPoint(definition.DiscoveryId)
	end

	return worldRegistryService.GetInteractionPoint(definition.InteractionId)
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
	prompt.Enabled = definition.Enabled == true
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
		print("[ANP PromptBindingService] Interaction `" .. interactionId .. "` succeeded for " .. playerName .. ".")
	else
		warn("[ANP PromptBindingService] Interaction `" .. interactionId .. "` failed for " .. playerName .. ": " .. tostring(interactionResult.Code))
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

	assert(worldRegistryService, "PromptBindingService requires WorldRegistryService.")
	assert(interactionService, "PromptBindingService requires InteractionService.")
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

		local objectResult = getWorldObjectForDefinition(definition)
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

function PromptBindingService.GetPromptForInteraction(interactionId)
	local prompt = boundPromptsByInteractionId[interactionId]
	return result(prompt ~= nil, prompt and "PromptRead" or "PromptMissing", nil, prompt)
end

function PromptBindingService.SimulatePromptTrigger(player, interactionId, metadata)
	local promptResult = PromptBindingService.GetPromptForInteraction(interactionId)
	if not promptResult.Success then
		return result(false, "PromptNotBound", "Interaction prompt is not bound.")
	end

	return handlePromptTriggered(player, interactionId, metadata or {
		SourceType = "PromptSmokeTest",
		InteractionId = interactionId,
	})
end

function PromptBindingService.ResetForTests()
	for interactionId, connection in pairs(boundConnectionsByInteractionId) do
		connection:Disconnect()
		boundConnectionsByInteractionId[interactionId] = nil
	end

	table.clear(boundPromptsByInteractionId)
end

return PromptBindingService
