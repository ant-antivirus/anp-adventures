local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneDefinitions = require(ReplicatedStorage.Shared.Definitions.ZoneDefinitions)

local WorldRegistryService = {}

local WORLD_ROOT_NAME = "ANP_World"
local REQUIRED_FOLDERS = {
	"Zones",
	"SpawnPoints",
	"InteractionPoints",
	"DiscoveryPoints",
	"NPCMarkers",
}

local registry = {
	WorldRoot = nil,
	Folders = {},
	Zones = {},
	SpawnPoints = {},
	InteractionPoints = {},
	DiscoveryPoints = {},
	NPCMarkers = {},
	NPCMarkersByInteractionId = {},
	Duplicates = {},
}

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function resetRegistry()
	registry.WorldRoot = nil
	table.clear(registry.Folders)
	table.clear(registry.Zones)
	table.clear(registry.SpawnPoints)
	table.clear(registry.InteractionPoints)
	table.clear(registry.DiscoveryPoints)
	table.clear(registry.NPCMarkers)
	table.clear(registry.NPCMarkersByInteractionId)
	table.clear(registry.Duplicates)
end

local function recordDuplicate(idType, id, object)
	table.insert(registry.Duplicates, {
		IdType = idType,
		Id = id,
		Object = object,
	})
end

local function isDescendantOfFolder(object, folder)
	return folder ~= nil and object ~= nil and object:IsDescendantOf(folder)
end

local function shouldAllowSkeletonManualInteractionDuplicate(existingObject, object)
	local interactionPointsFolder = registry.Folders.InteractionPoints
	local zonesFolder = registry.Folders.Zones
	if not interactionPointsFolder or not zonesFolder then
		return false
	end

	return (
		isDescendantOfFolder(existingObject, interactionPointsFolder)
		and isDescendantOfFolder(object, zonesFolder)
	)
		or (
			isDescendantOfFolder(existingObject, zonesFolder)
			and isDescendantOfFolder(object, interactionPointsFolder)
		)
end

local function chooseInteractionRegistryObject(existingObject, object)
	if isDescendantOfFolder(object, registry.Folders.InteractionPoints) then
		return object
	end

	return existingObject
end

local function registerObjectByAttribute(object, attributeName, idType, target)
	if object:IsA("ProximityPrompt") then
		return
	end

	local id = object:GetAttribute(attributeName)
	if type(id) == "string" and id ~= "" then
		if target[id] == nil then
			target[id] = object
		elseif attributeName == "InteractionId" and shouldAllowSkeletonManualInteractionDuplicate(target[id], object) then
			target[id] = chooseInteractionRegistryObject(target[id], object)
		else
			recordDuplicate(idType, id, object)
		end
	end
end

local function registerChildrenByAttribute(folder, attributeName, idType, target)
	if not folder then
		return
	end

	for _, object in ipairs(folder:GetChildren()) do
		registerObjectByAttribute(object, attributeName, idType, target)
	end
end

local function registerDescendantsByAttribute(folder, attributeName, idType, target)
	if not folder then
		return
	end

	for _, object in ipairs(folder:GetDescendants()) do
		registerObjectByAttribute(object, attributeName, idType, target)
	end
end

local function isManualZoneContainer(object, zoneId)
	return object:IsA("Folder") and object.Name == zoneId
end

local function isSkeletonZoneMarker(object, zoneId)
	return object:IsA("BasePart") and object.Name == "Zone_" .. zoneId
end

local function shouldAllowZoneCompatibilityDuplicate(existingObject, object, zoneId)
	if not existingObject or not object then
		return false
	end

	return (isManualZoneContainer(existingObject, zoneId) and isSkeletonZoneMarker(object, zoneId))
		or (isSkeletonZoneMarker(existingObject, zoneId) and isManualZoneContainer(object, zoneId))
end

local function chooseZoneRegistryObject(existingObject, object, zoneId)
	if isSkeletonZoneMarker(object, zoneId) then
		return object
	end

	return existingObject
end

local function registerZoneObjects(folder)
	if not folder then
		return
	end

	for _, object in ipairs(folder:GetChildren()) do
		local zoneId = object:GetAttribute("ZoneId")
		if type(zoneId) ~= "string" or zoneId == "" then
			zoneId = ZoneDefinitions[object.Name] and object.Name or nil
		end

		if zoneId then
			if registry.Zones[zoneId] == nil then
				registry.Zones[zoneId] = object
			elseif shouldAllowZoneCompatibilityDuplicate(registry.Zones[zoneId], object, zoneId) then
				registry.Zones[zoneId] = chooseZoneRegistryObject(registry.Zones[zoneId], object, zoneId)
			else
				recordDuplicate("ZoneId", zoneId, object)
			end
		end
	end
end

local function registerNPCMarkerInteractionHosts(folder)
	if not folder then
		return
	end

	for _, object in ipairs(folder:GetChildren()) do
		local interactionId = object:GetAttribute("InteractionId")
		if type(interactionId) == "string" and interactionId ~= "" then
			if registry.InteractionPoints[interactionId] ~= nil then
				registry.NPCMarkersByInteractionId[interactionId] = object
			elseif registry.NPCMarkersByInteractionId[interactionId] == nil then
				registry.NPCMarkersByInteractionId[interactionId] = object
			else
				recordDuplicate("NPCMarkerInteractionId", interactionId, object)
			end
		end
	end
end

function WorldRegistryService.Init()
	resetRegistry()

	local worldRoot = Workspace:FindFirstChild(WORLD_ROOT_NAME)
	if not worldRoot then
		return result(false, "WorldRootMissing", "Workspace.ANP_World was not found.")
	end

	registry.WorldRoot = worldRoot

	for _, folderName in ipairs(REQUIRED_FOLDERS) do
		registry.Folders[folderName] = worldRoot:FindFirstChild(folderName)
	end

	registerZoneObjects(registry.Folders.Zones)
	registerChildrenByAttribute(registry.Folders.SpawnPoints, "SpawnPointId", "SpawnPointId", registry.SpawnPoints)
	registerDescendantsByAttribute(registry.Folders.InteractionPoints, "InteractionId", "InteractionId", registry.InteractionPoints)
	registerDescendantsByAttribute(registry.Folders.DiscoveryPoints, "DiscoveryId", "DiscoveryId", registry.DiscoveryPoints)
	registerDescendantsByAttribute(registry.Folders.NPCMarkers, "CharacterId", "CharacterId", registry.NPCMarkers)
	registerDescendantsByAttribute(registry.Folders.Zones, "InteractionId", "InteractionId", registry.InteractionPoints)
	registerDescendantsByAttribute(registry.Folders.Zones, "DiscoveryId", "DiscoveryId", registry.DiscoveryPoints)
	registerDescendantsByAttribute(registry.Folders.Zones, "CharacterId", "CharacterId", registry.NPCMarkers)
	registerNPCMarkerInteractionHosts(registry.Folders.NPCMarkers)

	return result(true, "WorldRegistered", nil, {
		WorldRoot = worldRoot,
		ZoneCount = if registry.Folders.Zones then #registry.Folders.Zones:GetChildren() else 0,
		SpawnPointCount = if registry.Folders.SpawnPoints then #registry.Folders.SpawnPoints:GetChildren() else 0,
		InteractionPointCount = if registry.Folders.InteractionPoints then #registry.Folders.InteractionPoints:GetChildren() else 0,
		DiscoveryPointCount = if registry.Folders.DiscoveryPoints then #registry.Folders.DiscoveryPoints:GetChildren() else 0,
		NPCMarkerCount = if registry.Folders.NPCMarkers then #registry.Folders.NPCMarkers:GetChildren() else 0,
		Duplicates = registry.Duplicates,
	})
end

function WorldRegistryService.GetWorldRoot()
	return result(registry.WorldRoot ~= nil, registry.WorldRoot and "WorldRootRead" or "WorldRootMissing", nil, registry.WorldRoot)
end

function WorldRegistryService.GetZones()
	return result(true, "ZonesRead", nil, registry.Zones)
end

function WorldRegistryService.GetZoneObject(zoneId)
	local object = registry.Zones[zoneId]
	return result(object ~= nil, object and "ZoneObjectRead" or "ZoneObjectMissing", nil, object)
end

function WorldRegistryService.GetSpawnPoints()
	return result(true, "SpawnPointsRead", nil, registry.SpawnPoints)
end

function WorldRegistryService.GetSpawnPoint(spawnPointId)
	local object = registry.SpawnPoints[spawnPointId]
	return result(object ~= nil, object and "SpawnPointRead" or "SpawnPointMissing", nil, object)
end

function WorldRegistryService.GetInteractionPoints()
	return result(true, "InteractionPointsRead", nil, registry.InteractionPoints)
end

function WorldRegistryService.GetInteractions()
	local interactionIds = {}
	for interactionId in pairs(registry.InteractionPoints) do
		table.insert(interactionIds, interactionId)
	end
	table.sort(interactionIds)

	local interactions = {}
	for _, interactionId in ipairs(interactionIds) do
		table.insert(interactions, {
			InteractionId = interactionId,
			Object = registry.InteractionPoints[interactionId],
		})
	end

	return result(true, "InteractionsRead", nil, interactions)
end

function WorldRegistryService.GetInteractionPoint(interactionId)
	local object = registry.InteractionPoints[interactionId]
	return result(object ~= nil, object and "InteractionPointRead" or "InteractionPointMissing", nil, object)
end

function WorldRegistryService.GetInteraction(interactionId)
	return WorldRegistryService.GetInteractionPoint(interactionId)
end

function WorldRegistryService.GetDiscoveryPoints()
	return result(true, "DiscoveryPointsRead", nil, registry.DiscoveryPoints)
end

function WorldRegistryService.GetDiscoveryPoint(discoveryId)
	local object = registry.DiscoveryPoints[discoveryId]
	return result(object ~= nil, object and "DiscoveryPointRead" or "DiscoveryPointMissing", nil, object)
end

function WorldRegistryService.GetNPCMarkers()
	return result(true, "NPCMarkersRead", nil, registry.NPCMarkers)
end

function WorldRegistryService.GetNPCMarker(characterId)
	local object = registry.NPCMarkers[characterId]
	return result(object ~= nil, object and "NPCMarkerRead" or "NPCMarkerMissing", nil, object)
end

function WorldRegistryService.GetNPCMarkerByInteractionId(interactionId)
	local object = registry.NPCMarkersByInteractionId[interactionId]
	return result(object ~= nil, object and "NPCMarkerInteractionRead" or "NPCMarkerInteractionMissing", nil, object)
end

function WorldRegistryService.GetDuplicates()
	return result(true, "WorldRegistryDuplicatesRead", nil, registry.Duplicates)
end

WorldRegistryService.WorldRootName = WORLD_ROOT_NAME
WorldRegistryService.RequiredFolders = REQUIRED_FOLDERS

return WorldRegistryService
