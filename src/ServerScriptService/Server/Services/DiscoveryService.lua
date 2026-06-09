local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DiscoveryDefinitions = require(Shared.Definitions.DiscoveryDefinitions)
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)

local DiscoveryService = {}

local playerDataService = nil
local rewardService = nil
local zoneService = nil
local interactionVisibilityService = nil

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
	interactionVisibilityService = dependencies.InteractionVisibilityService

	assert(playerDataService, "DiscoveryService requires PlayerDataService.")
	assert(rewardService, "DiscoveryService requires RewardService.")
	assert(zoneService, "DiscoveryService requires ZoneService.")
end

function DiscoveryService.SetInteractionVisibilityService(service)
	interactionVisibilityService = service
end

local function refreshInteractionVisibility(player)
	if interactionVisibilityService then
		interactionVisibilityService.RefreshPlayer(player)
	end
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
	local discoveryState = discoveryData.DiscoveryStates and discoveryData.DiscoveryStates[discoveryId]
	return result(true, "DiscoveryStateRead", nil, {
		DiscoveryId = discoveryId,
		ZoneId = discoveryDefinition.ZoneId,
		IsFound = discoveryData.FoundDiscoveryIds[discoveryId] == true,
		RewardBundleId = discoveryDefinition.RewardBundleId,
		RewardIncludedInQuestBundle = discoveryDefinition.RewardIncludedInQuestBundle == true,
		RewardPending = discoveryState and discoveryState.RewardPending == true,
		RewardFailureCode = discoveryState and discoveryState.RewardFailureCode or nil,
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

	if not zoneService.IsZoneUnlocked(player, discoveryDefinition.ZoneId) then
		return result(false, "ZoneLocked", "Cannot record discovery in locked zone `" .. discoveryDefinition.ZoneId .. "`.")
	end

	local existingStateResult = DiscoveryService.GetDiscoveryState(player, discoveryId)
	if not existingStateResult.Success then
		return existingStateResult
	end

	local rewardSourceContext = sourceContext or {
		SourceType = "Discovery",
		SourceId = discoveryId,
	}
	local shouldGrantReward = discoveryDefinition.RewardBundleId and discoveryDefinition.RewardIncludedInQuestBundle ~= true

	if existingStateResult.Data.IsFound then
		if existingStateResult.Data.RewardPending == true and shouldGrantReward then
			local retryRewardResult = rewardService.GrantRewardBundle(player, discoveryDefinition.RewardBundleId, rewardSourceContext)
			if not retryRewardResult.Success then
				return result(false, "DiscoveryRewardRetryFailed", "Pending discovery reward retry failed.", {
					DiscoveryId = discoveryId,
					RewardBundleId = discoveryDefinition.RewardBundleId,
					FailureCode = retryRewardResult.Code,
				})
			end

			local retryAppliedResult = playerDataService.Mutate(player, "MarkDiscoveryRewardRetryApplied", rewardSourceContext, function(playerData)
				playerData.Discoveries.DiscoveryStates = playerData.Discoveries.DiscoveryStates or {}
				local discoveryState = playerData.Discoveries.DiscoveryStates[discoveryId]
				if discoveryState then
					discoveryState.RewardPending = false
					discoveryState.RewardFailureCode = nil
					discoveryState.UpdatedAt = os.time()
				end
				return true
			end)

			if not retryAppliedResult.Success then
				return retryAppliedResult
			end

			refreshInteractionVisibility(player)

			return result(true, "DiscoveryRewardRetried", nil, {
				DiscoveryId = discoveryId,
				RewardResult = retryRewardResult,
			})
		end

		return result(false, "DiscoveryAlreadyRecorded", "Cannot record duplicate discovery `" .. discoveryId .. "`.")
	end

	if shouldGrantReward then
		local preflightResult = rewardService.CanGrantRewardBundle(player, discoveryDefinition.RewardBundleId, rewardSourceContext)
		if not preflightResult.Success then
			return preflightResult
		end
	end

	local now = os.time()
	local mutationResult = playerDataService.Mutate(player, "RecordDiscovery", rewardSourceContext, function(playerData)
		playerData.Discoveries.DiscoveryStates = playerData.Discoveries.DiscoveryStates or {}
		playerData.Discoveries.FoundDiscoveryIds[discoveryId] = true
		playerData.Discoveries.DiscoveryStates[discoveryId] = {
			DiscoveryId = discoveryId,
			ZoneId = discoveryDefinition.ZoneId,
			RecordedAt = now,
			UpdatedAt = now,
			RewardPending = shouldGrantReward == true,
			RewardBundleId = discoveryDefinition.RewardBundleId,
			RewardFailureCode = nil,
		}
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

	local rewardResult = nil
	if shouldGrantReward then
		rewardResult = rewardService.GrantRewardBundle(player, discoveryDefinition.RewardBundleId, rewardSourceContext)
		if not rewardResult.Success then
			playerDataService.Mutate(player, "MarkDiscoveryRewardFailed", rewardSourceContext, function(playerData)
				playerData.Discoveries.DiscoveryStates = playerData.Discoveries.DiscoveryStates or {}
				local discoveryState = playerData.Discoveries.DiscoveryStates[discoveryId]
				if discoveryState then
					discoveryState.RewardPending = true
					discoveryState.RewardFailureCode = rewardResult.Code
					discoveryState.UpdatedAt = os.time()
				end
				return true
			end)

			return result(false, "DiscoveryRewardFailed", "Discovery recorded but reward grant failed.", {
				DiscoveryId = discoveryId,
				RewardBundleId = discoveryDefinition.RewardBundleId,
				FailureCode = rewardResult.Code,
			})
		end

		local rewardAppliedResult = playerDataService.Mutate(player, "MarkDiscoveryRewardApplied", rewardSourceContext, function(playerData)
			local discoveryState = playerData.Discoveries.DiscoveryStates and playerData.Discoveries.DiscoveryStates[discoveryId]
			if discoveryState then
				discoveryState.RewardPending = false
				discoveryState.RewardFailureCode = nil
				discoveryState.UpdatedAt = os.time()
			end
			return true
		end)

		if not rewardAppliedResult.Success then
			return rewardAppliedResult
		end
	end

	refreshInteractionVisibility(player)

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
