local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")

local EpisodeDefinitions = require(Definitions.EpisodeDefinitions)
local InteractionDefinitions = require(Definitions.InteractionDefinitions)
local QuestDefinitions = require(Definitions.QuestDefinitions)
local ZoneDefinitions = require(Definitions.ZoneDefinitions)

local MapAuthoringValidator = {}

local WORLD_ROOT_NAME = "ANP_World"
local EP1_ID = "ep01_lost_star_core"
local DECOR_FORBIDDEN_ATTRIBUTES = {
	"InteractionId",
	"QuestId",
	"ObjectiveId",
	"RewardId",
}

local function addError(result, message)
	table.insert(result.Errors, message)
	result.Success = false
	result.Code = "MapAuthoringInvalid"
end

local function addWarning(result, message)
	table.insert(result.Warnings, message)
end

local function getActiveEp1ZoneIds()
	local zoneIds = {}
	local episodeDefinition = EpisodeDefinitions[EP1_ID] or {}
	for _, zoneId in ipairs(episodeDefinition.ZoneIds or episodeDefinition.Zones or {}) do
		local zoneDefinition = ZoneDefinitions[zoneId]
		if zoneDefinition and zoneDefinition.Enabled ~= false and zoneDefinition.Reserved ~= true then
			table.insert(zoneIds, zoneId)
		end
	end
	return zoneIds
end

local function findZoneFolder(zonesFolder, zoneId)
	local direct = zonesFolder:FindFirstChild(zoneId)
	if direct then
		return direct
	end

	for _, child in ipairs(zonesFolder:GetChildren()) do
		if child:GetAttribute("ZoneId") == zoneId then
			return child
		end
	end

	return nil
end

local function hasPromptHost(instance)
	if instance:IsA("BasePart") or instance:IsA("Attachment") then
		return true
	end

	local promptPartName = instance:GetAttribute("PromptPartName")
	if type(promptPartName) == "string" then
		local namedPromptPart = instance:FindFirstChild(promptPartName, true)
		if namedPromptPart and (namedPromptPart:IsA("BasePart") or namedPromptPart:IsA("Attachment")) then
			return true
		end
	end

	local promptPart = instance:FindFirstChild("PromptPart", true)
	if promptPart and (promptPart:IsA("BasePart") or promptPart:IsA("Attachment")) then
		return true
	end

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") or descendant:IsA("Attachment") then
			return true
		end
	end

	return false
end

local function collectExpectedInteractions()
	local expected = {}
	local ep1QuestIds = {}

	for _, questId in ipairs((EpisodeDefinitions[EP1_ID] and EpisodeDefinitions[EP1_ID].QuestIds) or {}) do
		ep1QuestIds[questId] = true
	end

	for interactionId, interactionDefinition in pairs(InteractionDefinitions) do
		if interactionDefinition.Enabled ~= false and interactionDefinition.EnabledInWorld ~= false then
			local questId = interactionDefinition.QuestId
			local zoneId = interactionDefinition.ZoneId
			if ep1QuestIds[questId] or (questId == nil and ZoneDefinitions[zoneId] and ZoneDefinitions[zoneId].EpisodeId == EP1_ID) then
				expected[interactionId] = interactionDefinition
			end
		end
	end

	return expected
end

local function scanDecorFolder(result, decorFolder)
	for _, descendant in ipairs(decorFolder:GetDescendants()) do
		for _, attributeName in ipairs(DECOR_FORBIDDEN_ATTRIBUTES) do
			if descendant:GetAttribute(attributeName) ~= nil then
				addError(result, "Decor object `" .. descendant:GetFullName() .. "` must not define gameplay attribute `" .. attributeName .. "`.")
			end
		end
	end
end

local function scanGameplayFolder(result, gameplayFolder, parentZoneId, mappedInteractions, duplicateInteractions)
	for _, descendant in ipairs(gameplayFolder:GetDescendants()) do
		local interactionId = descendant:GetAttribute("InteractionId")
		if interactionId ~= nil then
			if type(interactionId) ~= "string" or interactionId == "" then
				addError(result, "Gameplay object `" .. descendant:GetFullName() .. "` has invalid InteractionId.")
				continue
			end

			local zoneId = descendant:GetAttribute("ZoneId")
			local objectType = descendant:GetAttribute("ObjectType")
			local interactionDefinition = InteractionDefinitions[interactionId]

			if type(zoneId) ~= "string" or zoneId == "" then
				addError(result, "Gameplay object `" .. descendant:GetFullName() .. "` has missing ZoneId.")
			elseif ZoneDefinitions[zoneId] == nil then
				addError(result, "Gameplay object `" .. descendant:GetFullName() .. "` has unknown ZoneId `" .. zoneId .. "`.")
			elseif zoneId ~= parentZoneId then
				addError(result, "Gameplay object `" .. descendant:GetFullName() .. "` ZoneId `" .. zoneId .. "` does not match parent zone `" .. parentZoneId .. "`.")
			end

			if type(objectType) ~= "string" or objectType == "" then
				addError(result, "Gameplay object `" .. descendant:GetFullName() .. "` has missing ObjectType.")
				if descendant:GetAttribute("InteractionType") ~= nil then
					addWarning(result, "Gameplay object `" .. descendant:GetFullName() .. "` uses legacy InteractionType; manual maps should use ObjectType.")
				end
			end

			if interactionDefinition == nil then
				addError(result, "Gameplay object `" .. descendant:GetFullName() .. "` uses unknown InteractionId `" .. interactionId .. "`.")
			else
				if zoneId == interactionDefinition.ZoneId and objectType ~= nil and objectType ~= interactionDefinition.Type then
					addError(result, "Gameplay object `" .. descendant:GetFullName() .. "` ObjectType `" .. tostring(objectType) .. "` does not match interaction type `" .. tostring(interactionDefinition.Type) .. "`.")
				end

				if descendant:GetAttribute("QuestId") ~= nil and descendant:GetAttribute("QuestId") ~= interactionDefinition.QuestId then
					addError(result, "Gameplay object `" .. descendant:GetFullName() .. "` QuestId does not match interaction definition.")
				end

				if descendant:GetAttribute("ObjectiveId") ~= nil and descendant:GetAttribute("ObjectiveId") ~= interactionDefinition.ObjectiveId then
					addError(result, "Gameplay object `" .. descendant:GetFullName() .. "` ObjectiveId does not match interaction definition.")
				end
			end

			if not hasPromptHost(descendant) then
				addError(result, "Gameplay object `" .. descendant:GetFullName() .. "` needs a BasePart or Attachment prompt host.")
			end

			if mappedInteractions[interactionId] then
				duplicateInteractions[interactionId] = true
				addError(result, "Duplicate InteractionId `" .. interactionId .. "` found in manual map.")
			else
				mappedInteractions[interactionId] = descendant
				result.Summary.InteractionsMapped += 1
			end
		end
	end
end

local function validateRequiredInteractionCoverage(result, mappedInteractions)
	local expectedInteractions = collectExpectedInteractions()

	for interactionId in pairs(expectedInteractions) do
		if mappedInteractions[interactionId] == nil then
			result.Summary.MissingInteractions += 1
			addError(result, "Required EP1 interaction `" .. interactionId .. "` is missing from manual map.")
		end
	end

	local q8Definition = QuestDefinitions.quest_ep01_main_008
	local q8RequiredObjectiveIds = (q8Definition and q8Definition.RequiredObjectiveIds) or {}
	if #q8RequiredObjectiveIds ~= 5 then
		addError(result, "Quest 008 definition must keep five required objectives.")
	end

	for _, objectiveId in ipairs(q8RequiredObjectiveIds) do
		local foundObjectiveRoute = false
		for interactionId, interactionDefinition in pairs(InteractionDefinitions) do
			if interactionDefinition.ObjectiveId == objectiveId and mappedInteractions[interactionId] ~= nil then
				foundObjectiveRoute = true
				break
			end
		end

		if not foundObjectiveRoute then
			addError(result, "Quest 008 required objective `" .. objectiveId .. "` is missing a mapped interaction route.")
		end
	end
end

function MapAuthoringValidator.ValidateWorldRoot(worldRoot)
	local result = {
		Success = true,
		Code = "MapAuthoringValid",
		Errors = {},
		Warnings = {},
		Summary = {
			ZonesChecked = 0,
			InteractionsMapped = 0,
			MissingInteractions = 0,
			DuplicateInteractions = 0,
		},
	}

	if worldRoot == nil then
		addError(result, "Workspace." .. WORLD_ROOT_NAME .. " is missing.")
		return result
	end

	local zonesFolder = worldRoot:FindFirstChild("Zones")
	if zonesFolder == nil then
		addError(result, "Workspace." .. WORLD_ROOT_NAME .. ".Zones is missing.")
		return result
	end

	local mappedInteractions = {}
	local duplicateInteractions = {}

	for _, zoneId in ipairs(getActiveEp1ZoneIds()) do
		local zoneFolder = findZoneFolder(zonesFolder, zoneId)
		if zoneFolder == nil then
			addError(result, "Active EP1 zone `" .. zoneId .. "` is missing from manual map.")
			continue
		end

		result.Summary.ZonesChecked += 1

		local gameplayFolder = zoneFolder:FindFirstChild("Gameplay")
		if gameplayFolder == nil then
			addError(result, "Zone `" .. zoneId .. "` is missing Gameplay folder.")
		else
			scanGameplayFolder(result, gameplayFolder, zoneId, mappedInteractions, duplicateInteractions)
		end

		local decorFolder = zoneFolder:FindFirstChild("Decor")
		if decorFolder ~= nil then
			scanDecorFolder(result, decorFolder)
		else
			addWarning(result, "Zone `" .. zoneId .. "` has no Decor folder.")
		end
	end

	for _ in pairs(duplicateInteractions) do
		result.Summary.DuplicateInteractions += 1
	end

	validateRequiredInteractionCoverage(result, mappedInteractions)

	return result
end

function MapAuthoringValidator.Validate()
	return MapAuthoringValidator.ValidateWorldRoot(Workspace:FindFirstChild(WORLD_ROOT_NAME))
end

return table.freeze(MapAuthoringValidator)
