local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SaveSchema = require(Shared.Definitions.SaveSchema)
local TableUtil = require(Shared.Util.TableUtil)

local DefaultPlayerData = require(script.Parent.Parent.Data.DefaultPlayerData)

local SaveSerializationService = {}

local playerDataService = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function isDictionary(value)
	return type(value) == "table"
end

local function hasForbiddenRuntimeField(payload)
	for fieldName in pairs(SaveSchema.ForbiddenRuntimeFields) do
		if payload[fieldName] ~= nil then
			return true, fieldName
		end
	end

	return false, nil
end

local function copyStableSectionsFromPlayerData(playerData)
	local payload = {
		SaveVersion = SaveSchema.SaveVersion,
		UserId = playerData.Profile.UserId,
		CreatedAt = playerData.Timestamps.CreatedAt,
		UpdatedAt = os.time(),
		Profile = {
			DisplayName = playerData.Profile.DisplayName,
			CreatedAt = playerData.Profile.CreatedAt,
			LastLoginAt = playerData.Profile.LastLoginAt,
			TotalPlaytimeSeconds = playerData.Profile.TotalPlaytimeSeconds,
		},
		Analytics = {
			LifetimeStats = {
				ExplorerScore = playerData.Progression.LifetimeExplorerScore or playerData.Progression.ExplorerScore or 0,
			},
		},
		RewardClaims = {
			RewardClaimIds = {},
		},
	}

	for _, sectionName in ipairs(SaveSchema.StableSections) do
		if sectionName ~= "Profile" then
			payload[sectionName] = TableUtil.DeepCopy(playerData[sectionName] or {})
		end
	end

	return payload
end

local function applyStableSectionsToPlayerData(defaultData, payload)
	defaultData.SchemaVersion = SaveSchema.SaveVersion
	defaultData.Profile.UserId = payload.UserId
	defaultData.Profile.DisplayName = payload.Profile.DisplayName
	defaultData.Profile.CreatedAt = payload.Profile.CreatedAt or payload.CreatedAt or defaultData.Profile.CreatedAt
	defaultData.Profile.LastLoginAt = payload.Profile.LastLoginAt or defaultData.Profile.LastLoginAt
	defaultData.Profile.TotalPlaytimeSeconds = payload.Profile.TotalPlaytimeSeconds or 0

	for _, sectionName in ipairs(SaveSchema.StableSections) do
		if sectionName ~= "Profile" and payload[sectionName] ~= nil then
			defaultData[sectionName] = TableUtil.DeepCopy(payload[sectionName])
		end
	end

	defaultData.Timestamps.CreatedAt = payload.CreatedAt or defaultData.Timestamps.CreatedAt
	defaultData.Timestamps.LastLoadedAt = os.time()
	defaultData.Timestamps.LastSavedAt = payload.UpdatedAt or 0

	defaultData.SessionStats = {
		SessionStartTime = os.time(),
		DiscoveriesFound = 0,
		QuestsStarted = 0,
		QuestsCompleted = 0,
		NPCInteractions = 0,
		ZoneTravels = 0,
	}

	return defaultData
end

function SaveSerializationService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService

	assert(playerDataService, "SaveSerializationService requires PlayerDataService.")
end

function SaveSerializationService.BuildSavePayload(player)
	local snapshotResult = playerDataService.GetSnapshot(player)
	if not snapshotResult.Success then
		return snapshotResult
	end

	local payload = copyStableSectionsFromPlayerData(snapshotResult.Data)
	local rewardClaimsResult = playerDataService.GetRewardClaimsSnapshot(player)
	if not rewardClaimsResult.Success then
		return rewardClaimsResult
	end
	payload.RewardClaims = rewardClaimsResult.Data
	local validationResult = SaveSerializationService.ValidateSavePayload(payload)
	if not validationResult.Success then
		return validationResult
	end

	return result(true, "SavePayloadBuilt", nil, payload)
end

function SaveSerializationService.ValidateSavePayload(payload)
	if type(payload) ~= "table" then
		return result(false, "InvalidSavePayload", "Save payload must be a table.")
	end

	if payload.SaveVersion == nil then
		return result(false, "MissingSaveVersion", "Save payload is missing SaveVersion.")
	end

	if payload.SaveVersion ~= SaveSchema.SaveVersion then
		return result(false, "MigrationRequired", "Save payload version is not supported.")
	end

	if type(payload.UserId) ~= "number" then
		return result(false, "InvalidSaveUserId", "Save payload UserId must be a number.")
	end

	local hasForbidden, forbiddenField = hasForbiddenRuntimeField(payload)
	if hasForbidden then
		return result(false, "ForbiddenRuntimeField", "Save payload includes runtime field `" .. forbiddenField .. "`.", {
			FieldName = forbiddenField,
		})
	end

	if not isDictionary(payload.Profile) then
		return result(false, "InvalidSaveProfile", "Save payload Profile must be a table.")
	end

	for _, sectionName in ipairs(SaveSchema.StableSections) do
		if sectionName ~= "Profile" and not isDictionary(payload[sectionName]) then
			return result(false, "InvalidSaveSection", "Save payload section `" .. sectionName .. "` must be a table.", {
				SectionName = sectionName,
			})
		end
	end

	if not isDictionary(payload.Quests.CompletedQuestIds) or not isDictionary(payload.Quests.QuestStates) then
		return result(false, "MalformedQuestData", "Save payload quest data is malformed.")
	end

	if payload.Analytics ~= nil and not isDictionary(payload.Analytics) then
		return result(false, "InvalidSaveAnalytics", "Save payload Analytics must be a table.")
	end

	if not isDictionary(payload.RewardClaims) or not isDictionary(payload.RewardClaims.RewardClaimIds) then
		return result(false, "MalformedRewardClaimData", "Save payload reward claim data is malformed.")
	end

	return result(true, "SavePayloadValid", nil, {
		SaveVersion = payload.SaveVersion,
		UserId = payload.UserId,
	})
end

function SaveSerializationService.ApplySavePayload(player, payload)
	local validationResult = SaveSerializationService.ValidateSavePayload(payload)
	if not validationResult.Success then
		return validationResult
	end

	local loadedData = applyStableSectionsToPlayerData(DefaultPlayerData.Create(payload.UserId, payload.CreatedAt), payload)
	local applyResult = playerDataService.ApplyPlayerData(player, loadedData, {
		SourceType = "SaveSerialization",
		SourceId = "ApplySavePayload",
	}, payload.RewardClaims.RewardClaimIds)
	if not applyResult.Success then
		return applyResult
	end

	return result(true, "SavePayloadApplied", nil, {
		UserId = payload.UserId,
		SaveVersion = payload.SaveVersion,
	})
end

return SaveSerializationService
