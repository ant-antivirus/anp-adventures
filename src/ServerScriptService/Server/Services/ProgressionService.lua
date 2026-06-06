local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RankConfig = require(Shared.Config.RankConfig)

local ProgressionService = {}

local playerDataService = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

function ProgressionService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	assert(playerDataService, "ProgressionService requires PlayerDataService.")
end

function ProgressionService.GetRankForScore(explorerScore)
	if type(explorerScore) ~= "number" or explorerScore < 0 then
		return nil
	end

	for _, rank in ipairs(RankConfig.Ranks) do
		if explorerScore >= rank.MinimumScore and explorerScore <= rank.MaximumScore then
			return rank.RankId, rank
		end
	end

	return nil
end

function ProgressionService.GetProgression(player)
	return playerDataService.GetSnapshot(player, "Progression")
end

function ProgressionService.AddExplorerScore(player, amount, sourceContext)
	if type(amount) ~= "number" or amount <= 0 then
		return result(false, "InvalidExplorerScoreAmount", "Explorer Score amount must be positive.")
	end

	return playerDataService.Mutate(player, "AddExplorerScore", sourceContext, function(playerData)
		local progression = playerData.Progression
		local previousScore = progression.ExplorerScore
		local previousRankId = progression.ExplorerRankId
		local newScore = previousScore + amount
		local newRankId = ProgressionService.GetRankForScore(newScore)

		if not newRankId then
			error("No rank configured for Explorer Score " .. tostring(newScore))
		end

		progression.ExplorerScore = newScore
		progression.LifetimeExplorerScore += amount
		progression.ExplorerRankId = newRankId

		return {
			PreviousScore = previousScore,
			NewScore = newScore,
			PreviousRankId = previousRankId,
			NewRankId = newRankId,
			RankChanged = previousRankId ~= newRankId,
		}
	end)
end

return ProgressionService
