local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)

local ZoneService = {}

local playerDataService = nil
local interactionVisibilityService = nil
local analyticsService = nil
local questTrackerService = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function getZoneDefinition(zoneId)
	local zoneDefinition = ZoneDefinitions[zoneId]
	if not zoneDefinition then
		return nil, result(false, "UnknownZoneId", "Unknown zone `" .. tostring(zoneId) .. "`.")
	end

	return zoneDefinition, nil
end

local function containsValue(values, expectedValue)
	for _, value in ipairs(values or {}) do
		if value == expectedValue then
			return true
		end
	end

	return false
end

function ZoneService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	interactionVisibilityService = dependencies.InteractionVisibilityService
	analyticsService = dependencies.AnalyticsService
	questTrackerService = dependencies.QuestTrackerService

	assert(playerDataService, "ZoneService requires PlayerDataService.")
end

local function incrementSessionStat(player, statName)
	playerDataService.Mutate(player, "IncrementSessionStat", {
		SourceType = "SessionStats",
		SourceId = statName,
	}, function(playerData)
		playerData.SessionStats = playerData.SessionStats or {}
		playerData.SessionStats[statName] = (playerData.SessionStats[statName] or 0) + 1
		return true
	end)
end

local function trackAnalytics(player, eventName, metadata)
	if analyticsService then
		analyticsService.Track(player, eventName, metadata)
	end
end

function ZoneService.SetInteractionVisibilityService(service)
	interactionVisibilityService = service
end

function ZoneService.SetQuestTrackerService(service)
	questTrackerService = service
end

local function refreshInteractionVisibility(player)
	if interactionVisibilityService then
		interactionVisibilityService.RefreshPlayer(player)
	end
end

local function sendQuestTrackerUpdate(player)
	if questTrackerService then
		questTrackerService.SendTrackerUpdate(player)
	end
end

function ZoneService.GetZoneState(player, zoneId)
	local zoneDefinition, errorResult = getZoneDefinition(zoneId)
	if errorResult then
		return errorResult
	end

	local snapshotResult = playerDataService.GetSnapshot(player, "Zones")
	if not snapshotResult.Success then
		return snapshotResult
	end

	local zoneData = snapshotResult.Data
	return result(true, "ZoneStateRead", nil, {
		ZoneId = zoneId,
		EpisodeId = zoneDefinition.EpisodeId,
		IsUnlocked = zoneData.UnlockedZoneIds[zoneId] == true,
		IsFastTravelUnlocked = zoneData.FastTravelUnlockedZoneIds[zoneId] == true,
		IsLastZone = zoneData.LastZoneId == zoneId,
		LastSpawnPointId = zoneData.LastSpawnPointId,
		TravelEligibility = zoneDefinition.TravelEligibility or {},
	})
end

function ZoneService.IsZoneUnlocked(player, zoneId)
	local stateResult = ZoneService.GetZoneState(player, zoneId)
	if not stateResult.Success then
		return false, stateResult.Code
	end

	return stateResult.Data.IsUnlocked == true
end

function ZoneService.UnlockZone(player, zoneId, sourceContext)
	local _, errorResult = getZoneDefinition(zoneId)
	if errorResult then
		return errorResult
	end

	local mutationResult = playerDataService.Mutate(player, "UnlockZone", sourceContext, function(playerData)
		local wasUnlocked = playerData.Zones.UnlockedZoneIds[zoneId] == true
		playerData.Zones.UnlockedZoneIds[zoneId] = true
		return not wasUnlocked
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	refreshInteractionVisibility(player)

	return result(true, "ZoneUnlocked", nil, {
		ZoneId = zoneId,
		WasAlreadyUnlocked = mutationResult.Data.Changed == false,
	})
end

function ZoneService.CanTravelToZone(player, zoneId, travelMode)
	local zoneDefinition, errorResult = getZoneDefinition(zoneId)
	if errorResult then
		return false, errorResult.Code
	end

	if not ZoneService.IsZoneUnlocked(player, zoneId) then
		return false, "ZoneLocked"
	end

	local mode = travelMode or "Spawn"
	if mode == "FastTravel" then
		local zoneStateResult = ZoneService.GetZoneState(player, zoneId)
		if not zoneStateResult.Success then
			return false, zoneStateResult.Code
		end

		if zoneStateResult.Data.IsFastTravelUnlocked ~= true then
			return false, "FastTravelLocked"
		end
	end

	if (zoneDefinition.TravelEligibility or {})[mode] ~= true then
		return false, "TravelModeUnavailable"
	end

	return true
end

function ZoneService.TravelToZone(player, zoneId, spawnPointId, travelMode, sourceContext)
	local zoneDefinition, errorResult = getZoneDefinition(zoneId)
	if errorResult then
		return errorResult
	end

	local canTravel, blockCode = ZoneService.CanTravelToZone(player, zoneId, travelMode)
	if not canTravel then
		return result(false, blockCode, "Cannot travel to zone `" .. zoneId .. "`.")
	end

	local targetSpawnPointId = spawnPointId or zoneDefinition.SpawnPoints[1]
	if not containsValue(zoneDefinition.SpawnPoints, targetSpawnPointId) then
		return result(false, "InvalidSpawnPointId", "Zone `" .. zoneId .. "` does not contain spawn point `" .. tostring(targetSpawnPointId) .. "`.")
	end

	local mutationResult = playerDataService.Mutate(player, "TravelToZone", sourceContext, function(playerData)
		playerData.Zones.LastZoneId = zoneId
		playerData.Zones.LastSpawnPointId = targetSpawnPointId
		return true
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	incrementSessionStat(player, "ZoneTravels")
	trackAnalytics(player, "ZoneTravelSucceeded", {
		ZoneId = zoneId,
		SpawnPointId = targetSpawnPointId,
		TravelMode = travelMode or "Spawn",
	})
	sendQuestTrackerUpdate(player)

	return result(true, "ZoneTravelRecorded", nil, {
		ZoneId = zoneId,
		SpawnPointId = targetSpawnPointId,
		TravelMode = travelMode or "Spawn",
	})
end

function ZoneService.UnlockFastTravel(player, zoneId, sourceContext)
	local zoneDefinition, errorResult = getZoneDefinition(zoneId)
	if errorResult then
		return errorResult
	end

	if (zoneDefinition.TravelEligibility or {}).FastTravel ~= true then
		return result(false, "FastTravelUnavailable", "Zone `" .. zoneId .. "` does not support fast travel.")
	end

	if not ZoneService.IsZoneUnlocked(player, zoneId) then
		return result(false, "ZoneLocked", "Cannot unlock fast travel for locked zone `" .. zoneId .. "`.")
	end

	local mutationResult = playerDataService.Mutate(player, "UnlockFastTravel", sourceContext, function(playerData)
		local wasUnlocked = playerData.Zones.FastTravelUnlockedZoneIds[zoneId] == true
		playerData.Zones.FastTravelUnlockedZoneIds[zoneId] = true
		return not wasUnlocked
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	refreshInteractionVisibility(player)

	return result(true, "FastTravelUnlocked", nil, {
		ZoneId = zoneId,
		WasAlreadyUnlocked = mutationResult.Data.Changed == false,
	})
end

return ZoneService
