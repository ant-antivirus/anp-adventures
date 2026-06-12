local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TableUtil = require(Shared.Util.TableUtil)

local DefaultPlayerData = require(script.Parent.Parent.Data.DefaultPlayerData)

local PlayerDataService = {}

local sessionsByUserId = {}
local studioSessionUserIdsByPlayer = {}
local nextStudioSessionUserId = -1000000000

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function getUserId(player)
	if player == nil then
		return nil
	end

	if type(player) == "table" then
		return player.UserId
	end

	return player.UserId
end

local function allocateStudioSessionUserId(player)
	local existingUserId = studioSessionUserIdsByPlayer[player]
	if existingUserId then
		return existingUserId
	end

	while sessionsByUserId[nextStudioSessionUserId] ~= nil do
		nextStudioSessionUserId -= 1
	end

	local userId = nextStudioSessionUserId
	nextStudioSessionUserId -= 1
	studioSessionUserIdsByPlayer[player] = userId

	return userId
end

local function resolveSessionUserId(player)
	local userId = getUserId(player)
	if type(userId) == "number" then
		if userId > 0 then
			return userId
		end

		if RunService:IsStudio() then
			if userId ~= 0 then
				return userId
			end

			return allocateStudioSessionUserId(player)
		end

		return nil, "InvalidUserId", "Player must have a positive numeric UserId outside Studio."
	end

	if RunService:IsStudio() and player ~= nil then
		local numericUserId = tonumber(userId)
		if numericUserId ~= nil then
			if numericUserId ~= 0 then
				return numericUserId
			end

			return allocateStudioSessionUserId(player)
		end

		return allocateStudioSessionUserId(player)
	end

	return nil, "InvalidUserId", "Player must have a numeric UserId."
end

function PlayerDataService.IsValidPlayerForSession(player)
	local userId, code, message = resolveSessionUserId(player)
	if userId == nil then
		return false, code, message
	end

	return true
end

local function getSession(player)
	local userId = resolveSessionUserId(player)
	if userId == nil then
		return nil, "InvalidUserId"
	end

	local session = sessionsByUserId[userId]
	if not session or session.Released then
		return nil, "PlayerDataNotLoaded"
	end

	return session
end

function PlayerDataService.InitPlayer(player)
	local userId, invalidCode, invalidMessage = resolveSessionUserId(player)
	if userId == nil then
		return result(false, invalidCode, invalidMessage)
	end

	if sessionsByUserId[userId] and not sessionsByUserId[userId].Released then
		return result(false, "PlayerDataAlreadyLoaded", "Player data is already loaded.")
	end

	local now = os.time()
	local playerData = DefaultPlayerData.Create(userId, now)

	sessionsByUserId[userId] = {
		Player = player,
		Data = playerData,
		RewardClaimIds = {},
		LoadedAt = now,
		Released = false,
	}

	return result(true, "PlayerDataLoaded", nil, {
		PlayerDataSnapshot = TableUtil.DeepCopy(playerData),
		WasCreated = true,
		WasMigrated = false,
	})
end

function PlayerDataService.ReleasePlayer(player)
	local userId, invalidCode, invalidMessage = resolveSessionUserId(player)
	if userId == nil then
		return result(false, invalidCode or "InvalidUserId", invalidMessage or "Player has an invalid UserId.")
	end

	local session = sessionsByUserId[userId]

	if not session or session.Released then
		return result(false, "PlayerDataNotLoaded", "Player data is not loaded.")
	end

	session.Released = true
	sessionsByUserId[userId] = nil
	studioSessionUserIdsByPlayer[player] = nil

	return result(true, "PlayerDataReleased", nil, {
		Saved = false,
		SaveAttemptCount = 0,
	})
end

function PlayerDataService.IsLoaded(player)
	local session = getSession(player)
	return session ~= nil
end

function PlayerDataService.GetSnapshot(player, path)
	local session, code = getSession(player)
	if not session then
		return result(false, code, "Player data is not loaded.")
	end

	if path == nil then
		return result(true, "SnapshotRead", nil, TableUtil.DeepCopy(session.Data))
	end

	local section = session.Data[path]
	if section == nil then
		return result(false, "UnknownDataPath", "Unknown player data path `" .. tostring(path) .. "`.")
	end

	return result(true, "SnapshotRead", nil, TableUtil.DeepCopy(section))
end

function PlayerDataService.Mutate(player, mutationName, sourceContext, mutator)
	local session, code = getSession(player)
	if not session then
		return result(false, code, "Player data is not loaded.")
	end

	if type(mutationName) ~= "string" or mutationName == "" then
		return result(false, "InvalidMutationName", "MutationName must be a non-empty string.")
	end

	if type(mutator) ~= "function" then
		return result(false, "InvalidMutationRequest", "Mutate requires a mutator function.")
	end

	local ok, mutationResult = pcall(mutator, session.Data, sourceContext)
	if not ok then
		return result(false, "MutationFailed", tostring(mutationResult))
	end

	return result(true, "MutationApplied", nil, {
		Changed = mutationResult ~= false,
	})
end

function PlayerDataService.Read(player, readName, reader)
	local session, code = getSession(player)
	if not session then
		return result(false, code, "Player data is not loaded.")
	end

	if type(readName) ~= "string" or readName == "" then
		return result(false, "InvalidReadName", "ReadName must be a non-empty string.")
	end

	if type(reader) ~= "function" then
		return result(false, "InvalidReadRequest", "Read requires a reader function.")
	end

	local ok, readResult = pcall(reader, session.Data)
	if not ok then
		return result(false, "ReadFailed", tostring(readResult))
	end

	return result(true, "ReadApplied", nil, readResult)
end

function PlayerDataService.ApplyPlayerData(player, playerData, sourceContext, rewardClaimIds)
	local session, code = getSession(player)
	if not session then
		return result(false, code, "Player data is not loaded.")
	end

	if type(playerData) ~= "table" then
		return result(false, "InvalidPlayerData", "Player data must be a table.")
	end

	session.Data = TableUtil.DeepCopy(playerData)
	session.RewardClaimIds = TableUtil.DeepCopy(rewardClaimIds or {})

	return result(true, "PlayerDataApplied", nil, {
		SourceContext = sourceContext,
		PlayerDataSnapshot = TableUtil.DeepCopy(session.Data),
	})
end

function PlayerDataService.GetRewardClaimsSnapshot(player)
	local session, code = getSession(player)
	if not session then
		return result(false, code, "Player data is not loaded.")
	end

	return result(true, "RewardClaimsSnapshotRead", nil, {
		RewardClaimIds = TableUtil.DeepCopy(session.RewardClaimIds),
	})
end

function PlayerDataService.HasRewardClaim(player, rewardClaimId)
	local session, code = getSession(player)
	if not session then
		return false, code
	end

	return session.RewardClaimIds[rewardClaimId] == true
end

function PlayerDataService.HasRewardBundleClaim(player, rewardBundleId)
	local session, code = getSession(player)
	if not session then
		return false, code
	end

	local expectedSuffix = ":" .. rewardBundleId
	for rewardClaimId in pairs(session.RewardClaimIds) do
		if string.sub(rewardClaimId, -#expectedSuffix) == expectedSuffix then
			return true
		end
	end

	return false
end

function PlayerDataService.MarkRewardClaim(player, rewardClaimId)
	local session, code = getSession(player)
	if not session then
		return result(false, code, "Player data is not loaded.")
	end

	if type(rewardClaimId) ~= "string" or rewardClaimId == "" then
		return result(false, "InvalidRewardClaimId", "RewardClaimId must be a non-empty string.")
	end

	session.RewardClaimIds[rewardClaimId] = true

	return result(true, "RewardClaimMarked", nil, {
		RewardClaimId = rewardClaimId,
	})
end

function PlayerDataService.ResetForTests()
	table.clear(sessionsByUserId)
	table.clear(studioSessionUserIdsByPlayer)
	nextStudioSessionUserId = -1000000000
end

return PlayerDataService
