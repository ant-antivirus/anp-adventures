local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DiscoveryDefinitions = require(Shared.Definitions.DiscoveryDefinitions)
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)

local DiscoveryService = {}

local playerDataService = nil
local rewardService = nil
local zoneService = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function getDiscoveryDefinition(discoveryId)
	local discoveryDefinition = DiscoveryDefinitions[discoveryId]
	if not discoveryDefinition then
		return nil, result(false, "UnknownDiscoveryId", "Unknown discovery `" .. tostring(discoveryId) .. "`.")
	end

	if not ZoneDefinitions[discoveryDefinition.ZoneId] then
		return nil, result(false, "InvalidDiscoveryZoneReference", "Discovery `" .. discoveryId .. "` references an unknown zone.")
	end

	return discoveryDefinition, nil
end

local function countZoneDiscoveries(zoneId)
	local total = 0
	for _, discoveryDefinition in pairs(DiscoveryDefinitions) do
		if discoveryDefinition.ZoneId == zoneId then
			total += 1
		end
	end

	return total
end

local function countFoundZoneDiscoveries(foundDiscoveryIds, zoneId)
	local found = 0
	for discoveryId in pairs(foundDiscoveryIds) do
		local discoveryDefinition = DiscoveryDefinitions[discoveryId]
		if discoveryDefinition and discoveryDefinition.ZoneId == zoneId then
			found += 1
		end
	end

	return found
end

function DiscoveryService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	rewardService = dependencies.RewardService
	zoneService = dependencies.ZoneService

	assert(playerDataService, "DiscoveryService requires PlayerDataService.")
	assert(rewardService, "DiscoveryService requires RewardService.")
	assert(zoneService, "DiscoveryService requires ZoneService.")
end

function DiscoveryService.GetDiscoveryState(player, discoveryId)
	local discoveryDefinition, errorResult = getDiscoveryDefinition(discoveryId)
	if errorResult then
		return errorResult
	end

	local snapshotResult = playerDataService.GetSnapshot(player, "Discoveries")
	if not snapshotResult.Success then
		return snapshotResult
	end

	local discoveryData = snapshotResult.Data
	return result(true, "DiscoveryStateRead", nil, {
		DiscoveryId = discoveryId,
		ZoneId = discoveryDefinition.ZoneId,
		IsFound = discoveryData.FoundDiscoveryIds[discoveryId] == true,
		RewardBundleId = discoveryDefinition.RewardBundleId,
		RewardIncludedInQuestBundle = discoveryDefinition.RewardIncludedInQuestBundle == true,
	})
end

function DiscoveryService.GetZoneDiscoveryProgress(player, zoneId)
	if not ZoneDefinitions[zoneId] then
		return result(false, "UnknownZoneId", "Unknown zone `" .. tostring(zoneId) .. "`.")
	end

	local snapshotResult = playerDataService.GetSnapshot(player, "Discoveries")
	if not snapshotResult.Success then
		return snapshotResult
	end

	local foundCount = countFoundZoneDiscoveries(snapshotResult.Data.FoundDiscoveryIds, zoneId)
	local totalCount = countZoneDiscoveries(zoneId)

	return result(true, "ZoneDiscoveryProgressRead", nil, {
		ZoneId = zoneId,
		FoundCount = foundCount,
		TotalCount = totalCount,
		IsComplete = totalCount > 0 and foundCount >= totalCount,
	})
end

function DiscoveryService.CanRecordDiscovery(player, discoveryId)
	local discoveryDefinition, errorResult = getDiscoveryDefinition(discoveryId)
	if errorResult then
		return false, errorResult.Code
	end

	if not zoneService.IsZoneUnlocked(player, discoveryDefinition.ZoneId) then
		return false, "ZoneLocked"
	end

	local stateResult = DiscoveryService.GetDiscoveryState(player, discoveryId)
	if not stateResult.Success then
		return false, stateResult.Code
	end

	if stateResult.Data.IsFound then
		return false, "DiscoveryAlreadyRecorded"
	end

	return true
end

function DiscoveryService.RecordDiscovery(player, discoveryId, sourceContext)
	local discoveryDefinition, errorResult = getDiscoveryDefinition(discoveryId)
	if errorResult then
		return errorResult
	end

	local canRecord, blockCode = DiscoveryService.CanRecordDiscovery(player, discoveryId)
	if not canRecord then
		return result(false, blockCode, "Cannot record discovery `" .. discoveryId .. "`.")
	end

	local rewardResult = nil
	if discoveryDefinition.RewardBundleId and discoveryDefinition.RewardIncludedInQuestBundle ~= true then
		rewardResult = rewardService.GrantRewardBundle(player, discoveryDefinition.RewardBundleId, sourceContext or {
			SourceType = "Discovery",
			SourceId = discoveryId,
		})

		if not rewardResult.Success then
			return rewardResult
		end
	end

	local now = os.time()
	local mutationResult = playerDataService.Mutate(player, "RecordDiscovery", sourceContext, function(playerData)
		playerData.Discoveries.FoundDiscoveryIds[discoveryId] = true
		playerData.Discoveries.ZoneDiscoveryProgress[discoveryDefinition.ZoneId] = {
			FoundCount = countFoundZoneDiscoveries(playerData.Discoveries.FoundDiscoveryIds, discoveryDefinition.ZoneId),
			TotalCount = countZoneDiscoveries(discoveryDefinition.ZoneId),
			UpdatedAt = now,
		}
		return true
	end)

	if not mutationResult.Success then
		return mutationResult
	end

	return result(true, "DiscoveryRecorded", nil, {
		DiscoveryId = discoveryId,
		ZoneId = discoveryDefinition.ZoneId,
		RewardBundleId = discoveryDefinition.RewardBundleId,
		RewardGranted = rewardResult ~= nil,
		RewardResult = rewardResult,
		RewardIncludedInQuestBundle = discoveryDefinition.RewardIncludedInQuestBundle == true,
	})
end

return DiscoveryService
