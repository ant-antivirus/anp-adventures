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

local function addError(result, code, message, context)
	table.insert(result.Errors, message)
	table.insert(result.ErrorDetails, {
		Code = code,
		Message = message,
		InteractionId = context and context.InteractionId,
		ZoneId = context and context.ZoneId,
		ObjectPath = context and context.ObjectPath,
		Expected = context and context.Expected,
		Actual = context and context.Actual,
	})
	result.Success = false
	result.Code = "MapAuthoringInvalid"
end

local function addWarning(result, code, message, context)
	table.insert(result.Warnings, message)
	table.insert(result.WarningDetails, {
		Code = code,
		Message = message,
		InteractionId = context and context.InteractionId,
		ZoneId = context and context.ZoneId,
		ObjectPath = context and context.ObjectPath,
		Expected = context and context.Expected,
		Actual = context and context.Actual,
	})
end

local function objectPath(instance)
	if instance == nil then
		return nil
	end

	return instance:GetFullName()
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

	if instance:IsA("Model") and instance.PrimaryPart then
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
				addError(result, "DecorContainsGameplayAttribute", "Decor object `" .. descendant:GetFullName() .. "` must not define gameplay attribute `" .. attributeName .. "`.", {
					ObjectPath = objectPath(descendant),
					Expected = "No " .. attributeName,
					Actual = attributeName,
				})
			end
		end
	end
end

local function scanGameplayFolder(result, gameplayFolder, parentZoneId, mappedInteractions, duplicateInteractions)
	for _, descendant in ipairs(gameplayFolder:GetDescendants()) do
		local interactionId = descendant:GetAttribute("InteractionId")
		if interactionId ~= nil then
			if type(interactionId) ~= "string" or interactionId == "" then
				addError(result, "InvalidInteractionId", "Gameplay object `" .. descendant:GetFullName() .. "` has invalid InteractionId.", {
					ObjectPath = objectPath(descendant),
					Expected = "non-empty string",
					Actual = tostring(interactionId),
				})
				continue
			end

			local zoneId = descendant:GetAttribute("ZoneId")
			local objectType = descendant:GetAttribute("ObjectType")
			local interactionDefinition = InteractionDefinitions[interactionId]

			if type(zoneId) ~= "string" or zoneId == "" then
				addError(result, "ZoneIdMissing", "Gameplay object `" .. descendant:GetFullName() .. "` has missing ZoneId.", {
					InteractionId = interactionId,
					ObjectPath = objectPath(descendant),
					Expected = "ZoneId",
					Actual = tostring(zoneId),
				})
			elseif ZoneDefinitions[zoneId] == nil then
				addError(result, "UnknownZoneId", "Gameplay object `" .. descendant:GetFullName() .. "` has unknown ZoneId `" .. zoneId .. "`.", {
					InteractionId = interactionId,
					ZoneId = zoneId,
					ObjectPath = objectPath(descendant),
					Expected = "ZoneDefinitions entry",
					Actual = zoneId,
				})
			elseif zoneId ~= parentZoneId then
				addError(result, "ZoneMismatch", "Gameplay object `" .. descendant:GetFullName() .. "` ZoneId `" .. zoneId .. "` does not match parent zone `" .. parentZoneId .. "`.", {
					InteractionId = interactionId,
					ZoneId = zoneId,
					ObjectPath = objectPath(descendant),
					Expected = parentZoneId,
					Actual = zoneId,
				})
			end

			if type(objectType) ~= "string" or objectType == "" then
				addError(result, "ObjectTypeMissing", "Gameplay object `" .. descendant:GetFullName() .. "` has missing ObjectType.", {
					InteractionId = interactionId,
					ZoneId = zoneId,
					ObjectPath = objectPath(descendant),
					Expected = "ObjectType",
					Actual = tostring(objectType),
				})
				if descendant:GetAttribute("InteractionType") ~= nil then
					addWarning(result, "LegacyInteractionType", "Gameplay object `" .. descendant:GetFullName() .. "` uses legacy InteractionType; manual maps should use ObjectType.", {
						InteractionId = interactionId,
						ZoneId = zoneId,
						ObjectPath = objectPath(descendant),
						Expected = "ObjectType",
						Actual = "InteractionType",
					})
				end
			end

			if interactionDefinition == nil then
				addError(result, "UnknownInteractionId", "Gameplay object `" .. descendant:GetFullName() .. "` uses unknown InteractionId `" .. interactionId .. "`.", {
					InteractionId = interactionId,
					ZoneId = zoneId,
					ObjectPath = objectPath(descendant),
					Expected = "InteractionDefinitions entry",
					Actual = interactionId,
				})
			else
				if zoneId == interactionDefinition.ZoneId and objectType ~= nil and objectType ~= interactionDefinition.Type then
					addError(result, "ObjectTypeMismatch", "Gameplay object `" .. descendant:GetFullName() .. "` ObjectType `" .. tostring(objectType) .. "` does not match interaction type `" .. tostring(interactionDefinition.Type) .. "`.", {
						InteractionId = interactionId,
						ZoneId = zoneId,
						ObjectPath = objectPath(descendant),
						Expected = interactionDefinition.Type,
						Actual = objectType,
					})
				end

				if descendant:GetAttribute("QuestId") ~= nil and descendant:GetAttribute("QuestId") ~= interactionDefinition.QuestId then
					addError(result, "QuestIdMismatch", "Gameplay object `" .. descendant:GetFullName() .. "` QuestId does not match interaction definition.", {
						InteractionId = interactionId,
						ZoneId = zoneId,
						ObjectPath = objectPath(descendant),
						Expected = interactionDefinition.QuestId,
						Actual = descendant:GetAttribute("QuestId"),
					})
				end

				if descendant:GetAttribute("ObjectiveId") ~= nil and descendant:GetAttribute("ObjectiveId") ~= interactionDefinition.ObjectiveId then
					addError(result, "ObjectiveIdMismatch", "Gameplay object `" .. descendant:GetFullName() .. "` ObjectiveId does not match interaction definition.", {
						InteractionId = interactionId,
						ZoneId = zoneId,
						ObjectPath = objectPath(descendant),
						Expected = interactionDefinition.ObjectiveId,
						Actual = descendant:GetAttribute("ObjectiveId"),
					})
				end
			end

			if not hasPromptHost(descendant) then
				addError(result, "MissingPromptPart", "Gameplay object `" .. descendant:GetFullName() .. "` needs a BasePart or Attachment prompt host.", {
					InteractionId = interactionId,
					ZoneId = zoneId,
					ObjectPath = objectPath(descendant),
					Expected = "BasePart, Attachment, PrimaryPart, PromptPart, or PromptPartName target",
					Actual = "none",
				})
			end

			if mappedInteractions[interactionId] then
				duplicateInteractions[interactionId] = true
				addError(result, "DuplicateInteractionId", "Duplicate InteractionId `" .. interactionId .. "` found in manual map.", {
					InteractionId = interactionId,
					ZoneId = zoneId,
					ObjectPath = objectPath(descendant),
					Expected = "unique InteractionId",
					Actual = interactionId,
				})
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
			local interactionDefinition = expectedInteractions[interactionId]
			local errorCode = "MissingInteractionObject"
			if interactionDefinition.Type == "QuestStart" then
				errorCode = "MissingQuestStartObject"
			elseif interactionDefinition.Type == "QuestObjective" then
				errorCode = "MissingQuestObjectiveObject"
			elseif interactionDefinition.Type == "QuestComplete" then
				errorCode = "MissingQuestCompleteObject"
			end
			addError(result, errorCode, "Required EP1 interaction `" .. interactionId .. "` is missing from manual map.", {
				InteractionId = interactionId,
				ZoneId = interactionDefinition.ZoneId,
				Expected = "mapped " .. tostring(interactionDefinition.Type) .. " object",
				Actual = "missing",
			})
		end
	end

	local q8Definition = QuestDefinitions.quest_ep01_main_008
	local q8RequiredObjectiveIds = (q8Definition and q8Definition.RequiredObjectiveIds) or {}
	if #q8RequiredObjectiveIds ~= 5 then
		addError(result, "Q8RequiredObjectiveCountChanged", "Quest 008 definition must keep five required objectives.", {
			Expected = 5,
			Actual = #q8RequiredObjectiveIds,
		})
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
			addError(result, "Q8RequiredObjectiveMissing", "Quest 008 required objective `" .. objectiveId .. "` is missing a mapped interaction route.", {
				ZoneId = "zone_ep01_moon_walk",
				Expected = "mapped interaction route",
				Actual = objectiveId,
			})
		end
	end
end

function MapAuthoringValidator.ValidateWorldRoot(worldRoot)
	local result = {
		Success = true,
		Code = "MapAuthoringValid",
		Errors = {},
		Warnings = {},
		ErrorDetails = {},
		WarningDetails = {},
		Summary = {
			ZonesChecked = 0,
			InteractionsMapped = 0,
			MissingInteractions = 0,
			DuplicateInteractions = 0,
		},
	}

	if worldRoot == nil then
		addError(result, "WorldRootMissing", "Workspace." .. WORLD_ROOT_NAME .. " is missing.", {
			Expected = WORLD_ROOT_NAME,
			Actual = "missing",
		})
		return result
	end

	local zonesFolder = worldRoot:FindFirstChild("Zones")
	if zonesFolder == nil then
		addError(result, "ZonesFolderMissing", "Workspace." .. WORLD_ROOT_NAME .. ".Zones is missing.", {
			ObjectPath = objectPath(worldRoot),
			Expected = "Zones",
			Actual = "missing",
		})
		return result
	end

	local mappedInteractions = {}
	local duplicateInteractions = {}

	for _, zoneId in ipairs(getActiveEp1ZoneIds()) do
		local zoneFolder = findZoneFolder(zonesFolder, zoneId)
		if zoneFolder == nil then
			addError(result, "ZoneFolderMissing", "Active EP1 zone `" .. zoneId .. "` is missing from manual map.", {
				ZoneId = zoneId,
				Expected = zoneId,
				Actual = "missing",
			})
			continue
		end

		result.Summary.ZonesChecked += 1

		local gameplayFolder = zoneFolder:FindFirstChild("Gameplay")
		if gameplayFolder == nil then
			addError(result, "GameplayFolderMissing", "Zone `" .. zoneId .. "` is missing Gameplay folder.", {
				ZoneId = zoneId,
				ObjectPath = objectPath(zoneFolder),
				Expected = "Gameplay",
				Actual = "missing",
			})
		else
			scanGameplayFolder(result, gameplayFolder, zoneId, mappedInteractions, duplicateInteractions)
		end

		local decorFolder = zoneFolder:FindFirstChild("Decor")
		if decorFolder ~= nil then
			scanDecorFolder(result, decorFolder)
		else
			addWarning(result, "DecorFolderMissing", "Zone `" .. zoneId .. "` has no Decor folder.", {
				ZoneId = zoneId,
				ObjectPath = objectPath(zoneFolder),
				Expected = "Decor",
				Actual = "missing",
			})
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

function MapAuthoringValidator.FormatSummary(validationResult)
	local summary = validationResult and validationResult.Summary or {}
	return "[ANP MapAuthoringValidator]\n"
		.. "ZonesChecked: "
		.. tostring(summary.ZonesChecked or 0)
		.. "\nInteractionsMapped: "
		.. tostring(summary.InteractionsMapped or 0)
		.. "\nErrors: "
		.. tostring(#((validationResult and validationResult.Errors) or {}))
		.. "\nWarnings: "
		.. tostring(#((validationResult and validationResult.Warnings) or {}))
end

function MapAuthoringValidator.FormatIssueReport(validationResult, maxItems)
	maxItems = maxItems or 40
	local details = (validationResult and validationResult.ErrorDetails) or {}
	if #details == 0 then
		return "[ANP MapAuthoringValidator] No validation errors."
	end

	local lines = {
		"[ANP MapAuthoringValidator] Missing/invalid manual map requirements:",
	}

	for index, detail in ipairs(details) do
		if index > maxItems then
			table.insert(lines, "...and " .. tostring(#details - maxItems) .. " more validation errors.")
			break
		end

		local parts = {
			tostring(index) .. ".",
			tostring(detail.Code),
		}
		if detail.InteractionId then
			table.insert(parts, "InteractionId=" .. tostring(detail.InteractionId))
		end
		if detail.ZoneId then
			table.insert(parts, "ZoneId=" .. tostring(detail.ZoneId))
		end
		if detail.Expected then
			table.insert(parts, "Expected=" .. tostring(detail.Expected))
		end
		if detail.Actual then
			table.insert(parts, "Actual=" .. tostring(detail.Actual))
		end
		if detail.ObjectPath then
			table.insert(parts, "ObjectPath=" .. tostring(detail.ObjectPath))
		end

		table.insert(lines, table.concat(parts, " "))
	end

	return table.concat(lines, "\n")
end

return table.freeze(MapAuthoringValidator)
