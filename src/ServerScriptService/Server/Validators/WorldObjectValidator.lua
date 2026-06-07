local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)
local DiscoveryDefinitions = require(Shared.Definitions.DiscoveryDefinitions)
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local CharacterConfig = require(Shared.Config.CharacterConfig)

local WorldObjectValidator = {}

local WORLD_ROOT_NAME = "ANP_World"
local REQUIRED_FOLDERS = {
	"Zones",
	"SpawnPoints",
	"InteractionPoints",
	"DiscoveryPoints",
	"NPCMarkers",
}

local EPISODE_ONE_ZONE_IDS = {
	"zone_ep01_command_center",
	"zone_ep01_universe_explorer",
	"zone_ep01_terrain_sandbox",
	"zone_ep01_theos_satellite_center",
	"zone_ep01_rocket_mission",
	"zone_ep01_astronaut_training",
	"zone_ep01_moon_walk",
}

local function makeResult()
	return {
		Success = true,
		Code = "WorldObjectValidationComplete",
		Errors = {},
		Warnings = {},
		Summary = {
			Zones = 0,
			SpawnPoints = 0,
			InteractionPoints = 0,
			DiscoveryPoints = 0,
			NPCMarkers = 0,
			DuplicateIds = 0,
		},
	}
end

local function addError(validationResult, message)
	validationResult.Success = false
	table.insert(validationResult.Errors, message)
end

local function validateDuplicate(idMap, id, idType, object, validationResult)
	if type(id) ~= "string" or id == "" then
		return
	end

	if idMap[id] then
		validationResult.Summary.DuplicateIds += 1
		addError(validationResult, "Duplicate " .. idType .. " `" .. id .. "` on `" .. object:GetFullName() .. "`.")
		return
	end

	idMap[id] = object
end

local function characterIdExists(characterId)
	for _, configuredCharacterId in pairs(CharacterConfig.Ids) do
		if configuredCharacterId == characterId then
			return true
		end
	end

	return false
end

local function questContainsObjective(questDefinition, objectiveId)
	for _, questObjectiveId in ipairs(questDefinition.ObjectiveIds or {}) do
		if questObjectiveId == objectiveId then
			return true
		end
	end

	return false
end

function WorldObjectValidator.Validate()
	local validationResult = makeResult()
	local worldRoot = Workspace:FindFirstChild(WORLD_ROOT_NAME)

	if not worldRoot then
		addError(validationResult, "Workspace.ANP_World is missing.")
		return validationResult
	end

	local folders = {}
	for _, folderName in ipairs(REQUIRED_FOLDERS) do
		local folder = worldRoot:FindFirstChild(folderName)
		if not folder then
			addError(validationResult, "Required world folder `" .. folderName .. "` is missing.")
		end
		folders[folderName] = folder
	end

	local zoneIds = {}
	if folders.Zones then
		for _, object in ipairs(folders.Zones:GetChildren()) do
			validationResult.Summary.Zones += 1
			local zoneId = object:GetAttribute("ZoneId")
			if type(zoneId) ~= "string" or zoneId == "" then
				addError(validationResult, "Zone object `" .. object:GetFullName() .. "` is missing ZoneId.")
			else
				validateDuplicate(zoneIds, zoneId, "ZoneId", object, validationResult)
				if not ZoneDefinitions[zoneId] then
					addError(validationResult, "ZoneId `" .. zoneId .. "` does not exist in ZoneDefinitions.")
				end
			end
		end
	end

	for _, zoneId in ipairs(EPISODE_ONE_ZONE_IDS) do
		if not zoneIds[zoneId] then
			addError(validationResult, "Required Episode 1 zone object is missing: `" .. zoneId .. "`.")
		end
	end

	local spawnPointIds = {}
	if folders.SpawnPoints then
		for _, object in ipairs(folders.SpawnPoints:GetChildren()) do
			validationResult.Summary.SpawnPoints += 1
			local spawnPointId = object:GetAttribute("SpawnPointId")
			local zoneId = object:GetAttribute("ZoneId")
			if type(spawnPointId) ~= "string" or spawnPointId == "" then
				addError(validationResult, "Spawn point `" .. object:GetFullName() .. "` is missing SpawnPointId.")
			else
				validateDuplicate(spawnPointIds, spawnPointId, "SpawnPointId", object, validationResult)
			end
			if type(zoneId) ~= "string" or not ZoneDefinitions[zoneId] then
				addError(validationResult, "Spawn point `" .. object:GetFullName() .. "` has invalid ZoneId `" .. tostring(zoneId) .. "`.")
			end
		end
	end

	local discoveryIds = {}
	if folders.DiscoveryPoints then
		for _, object in ipairs(folders.DiscoveryPoints:GetChildren()) do
			validationResult.Summary.DiscoveryPoints += 1
			local discoveryId = object:GetAttribute("DiscoveryId")
			local zoneId = object:GetAttribute("ZoneId")
			local discoveryDefinition = DiscoveryDefinitions[discoveryId]
			if type(discoveryId) ~= "string" or discoveryId == "" then
				addError(validationResult, "Discovery point `" .. object:GetFullName() .. "` is missing DiscoveryId.")
			else
				validateDuplicate(discoveryIds, discoveryId, "DiscoveryId", object, validationResult)
				if not discoveryDefinition then
					addError(validationResult, "DiscoveryId `" .. discoveryId .. "` does not exist in DiscoveryDefinitions.")
				elseif discoveryDefinition.ZoneId ~= zoneId then
					addError(validationResult, "Discovery point `" .. discoveryId .. "` ZoneId does not match DiscoveryDefinitions.")
				end
			end
			if type(zoneId) ~= "string" or not ZoneDefinitions[zoneId] then
				addError(validationResult, "Discovery point `" .. object:GetFullName() .. "` has invalid ZoneId `" .. tostring(zoneId) .. "`.")
			end
		end
	end

	local interactionIds = {}
	if folders.InteractionPoints then
		for _, object in ipairs(folders.InteractionPoints:GetChildren()) do
			validationResult.Summary.InteractionPoints += 1
			local interactionId = object:GetAttribute("InteractionId")
			local questId = object:GetAttribute("QuestId")
			local objectiveId = object:GetAttribute("ObjectiveId")
			local zoneId = object:GetAttribute("ZoneId")
			local questDefinition = QuestDefinitions[questId]

			if type(interactionId) ~= "string" or interactionId == "" then
				addError(validationResult, "Interaction point `" .. object:GetFullName() .. "` is missing InteractionId.")
			else
				validateDuplicate(interactionIds, interactionId, "InteractionId", object, validationResult)
			end

			if not questDefinition then
				addError(validationResult, "Interaction point `" .. object:GetFullName() .. "` has invalid QuestId `" .. tostring(questId) .. "`.")
			elseif not questContainsObjective(questDefinition, objectiveId) then
				addError(validationResult, "Interaction point `" .. object:GetFullName() .. "` has ObjectiveId not present in QuestDefinitions.")
			end

			if type(zoneId) ~= "string" or not ZoneDefinitions[zoneId] then
				addError(validationResult, "Interaction point `" .. object:GetFullName() .. "` has invalid ZoneId `" .. tostring(zoneId) .. "`.")
			end
		end
	end

	local characterIds = {}
	if folders.NPCMarkers then
		for _, object in ipairs(folders.NPCMarkers:GetChildren()) do
			validationResult.Summary.NPCMarkers += 1
			local characterId = object:GetAttribute("CharacterId")
			local zoneId = object:GetAttribute("ZoneId")
			if type(characterId) ~= "string" or characterId == "" then
				addError(validationResult, "NPC marker `" .. object:GetFullName() .. "` is missing CharacterId.")
			else
				validateDuplicate(characterIds, characterId, "CharacterId", object, validationResult)
				if not characterIdExists(characterId) then
					addError(validationResult, "NPC marker CharacterId `" .. characterId .. "` does not exist in CharacterConfig.")
				end
			end
			if type(zoneId) ~= "string" or not ZoneDefinitions[zoneId] then
				addError(validationResult, "NPC marker `" .. object:GetFullName() .. "` has invalid ZoneId `" .. tostring(zoneId) .. "`.")
			end
		end
	end

	return validationResult
end

return WorldObjectValidator
