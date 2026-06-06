local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RewardDefinitions = require(Shared.Definitions.RewardDefinitions)
local ItemDefinitions = require(Shared.Definitions.ItemDefinitions)
local BadgeConfig = require(Shared.Config.BadgeConfig)

local RewardService = {}

local playerDataService = nil
local progressionService = nil
local inventoryService = nil

local EP01_FRAGMENT_IDS = {
	item_ep01_fragment_universe = true,
	item_ep01_fragment_earth = true,
	item_ep01_fragment_theos = true,
	item_ep01_fragment_rocket = true,
	item_ep01_fragment_moon = true,
}

local REQUIRED_EP01_ASSEMBLY_ITEMS = {
	"item_ep01_fragment_universe",
	"item_ep01_fragment_earth",
	"item_ep01_fragment_theos",
	"item_ep01_fragment_rocket",
	"item_ep01_fragment_moon",
}

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function append(target, values)
	for _, value in ipairs(values) do
		table.insert(target, value)
	end
end

local function validateRewardDefinition(rewardBundleId, rewardDefinition)
	if not rewardDefinition then
		return result(false, "UnknownRewardBundleId", "Unknown reward bundle `" .. tostring(rewardBundleId) .. "`.")
	end

	if rewardDefinition.RewardBundleId ~= rewardBundleId then
		return result(false, "RewardBundleIdMismatch", "Reward bundle key does not match RewardBundleId.")
	end

	if rewardDefinition.GrantService ~= "RewardService" then
		return result(false, "InvalidRewardGrantService", "Reward bundle must route through RewardService.")
	end

	if type(rewardDefinition.ExplorerScore) ~= "number" or rewardDefinition.ExplorerScore < 0 then
		return result(false, "InvalidRewardExplorerScore", "Reward ExplorerScore must be non-negative.")
	end

	if type(rewardDefinition.DuplicatePolicy) ~= "string" or rewardDefinition.DuplicatePolicy == "" then
		return result(false, "MissingRewardDuplicatePolicy", "Reward bundle must define DuplicatePolicy.")
	end

	for _, itemGrant in ipairs(rewardDefinition.Items or {}) do
		if not ItemDefinitions[itemGrant.ItemId] then
			return result(false, "InvalidRewardItemReference", "Reward references unknown item `" .. tostring(itemGrant.ItemId) .. "`.")
		end

		if type(itemGrant.Quantity) ~= "number" or itemGrant.Quantity <= 0 then
			return result(false, "InvalidRewardItemQuantity", "Reward item quantity must be positive.")
		end
	end

	for _, badgeId in ipairs(rewardDefinition.Badges or {}) do
		if not BadgeConfig.Badges[badgeId] then
			return result(false, "InvalidRewardBadgeReference", "Reward references unknown badge `" .. tostring(badgeId) .. "`.")
		end
	end

	for _, consumedItemId in ipairs(rewardDefinition.ConsumesItems or {}) do
		if EP01_FRAGMENT_IDS[consumedItemId] then
			return result(false, "RewardConsumesRetainedFragment", "Reward bundle may not consume Episode 1 fragment `" .. consumedItemId .. "`.")
		end
	end

	return result(true, "RewardDefinitionValid")
end

local function canGrantEpisodeOneFinalReward(player)
	for _, itemId in ipairs(REQUIRED_EP01_ASSEMBLY_ITEMS) do
		if not inventoryService.HasItem(player, itemId, 1) then
			return false, itemId
		end
	end

	return true, nil
end

function RewardService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	progressionService = dependencies.ProgressionService
	inventoryService = dependencies.InventoryService

	assert(playerDataService, "RewardService requires PlayerDataService.")
	assert(progressionService, "RewardService requires ProgressionService.")
	assert(inventoryService, "RewardService requires InventoryService.")
end

function RewardService.GrantRewardBundle(player, rewardBundleId, sourceContext)
	local rewardDefinition = RewardDefinitions[rewardBundleId]
	local validationResult = validateRewardDefinition(rewardBundleId, rewardDefinition)

	if not validationResult.Success then
		return validationResult
	end

	if rewardBundleId == "reward_ep01_main_008" then
		local canGrant, missingItemId = canGrantEpisodeOneFinalReward(player)
		if not canGrant then
			return result(false, "MissingEpisodeOneAssemblyItem", "Cannot grant Episode 1 final reward without `" .. missingItemId .. "`.")
		end
	end

	if playerDataService.HasRewardClaim(player, rewardBundleId) then
		return result(false, "DuplicateRewardBlocked", "Reward bundle has already been granted.", {
			RewardBundleId = rewardBundleId,
			SkippedDuplicate = true,
		})
	end

	local rewardSourceContext = sourceContext or {
		SourceType = "RewardBundle",
		SourceId = rewardBundleId,
	}

	local summary = {
		RewardBundleId = rewardBundleId,
		GrantedExplorerScore = 0,
		GrantedItems = {},
		GrantedBadges = {},
		UnlockedZones = {},
		UnlockedEpisodes = {},
		UnlockedJournalEntries = {},
		UnlockedLoreEntries = {},
		SkippedDuplicates = {},
	}

	if rewardDefinition.ExplorerScore > 0 then
		local scoreResult = progressionService.AddExplorerScore(player, rewardDefinition.ExplorerScore, rewardSourceContext)
		if not scoreResult.Success then
			return scoreResult
		end

		summary.GrantedExplorerScore = rewardDefinition.ExplorerScore
	end

	for _, itemGrant in ipairs(rewardDefinition.Items or {}) do
		local itemResult = inventoryService.AddItem(player, itemGrant.ItemId, itemGrant.Quantity, rewardSourceContext)
		if not itemResult.Success then
			return itemResult
		end

		table.insert(summary.GrantedItems, itemGrant.ItemId)
	end

	local stateResult = playerDataService.Mutate(player, "ApplyRewardState", rewardSourceContext, function(playerData)
		for _, badgeId in ipairs(rewardDefinition.Badges or {}) do
			if playerData.Badges.AwardedBadgeIds[badgeId] then
				table.insert(summary.SkippedDuplicates, badgeId)
			else
				playerData.Badges.AwardedBadgeIds[badgeId] = true
				table.insert(summary.GrantedBadges, badgeId)
			end
		end

		for _, zoneId in ipairs(rewardDefinition.UnlockZones or {}) do
			if playerData.Zones.UnlockedZoneIds[zoneId] then
				table.insert(summary.SkippedDuplicates, zoneId)
			else
				playerData.Zones.UnlockedZoneIds[zoneId] = true
				table.insert(summary.UnlockedZones, zoneId)
			end
		end

		for _, episodeId in ipairs(rewardDefinition.UnlockEpisodes or {}) do
			if playerData.Episodes.UnlockedEpisodeIds[episodeId] then
				table.insert(summary.SkippedDuplicates, episodeId)
			else
				playerData.Episodes.UnlockedEpisodeIds[episodeId] = true
				table.insert(summary.UnlockedEpisodes, episodeId)
			end
		end

		for _, journalEntryId in ipairs(rewardDefinition.JournalUnlocks or {}) do
			if playerData.Journal.UnlockedEntryIds[journalEntryId] then
				table.insert(summary.SkippedDuplicates, journalEntryId)
			else
				playerData.Journal.UnlockedEntryIds[journalEntryId] = true
				playerData.Journal.EntryStates[journalEntryId] = {
					JournalEntryId = journalEntryId,
					SourceType = rewardSourceContext.SourceType,
					SourceId = rewardSourceContext.SourceId,
					UnlockedAt = os.time(),
					ViewedAt = nil,
				}
				table.insert(summary.UnlockedJournalEntries, journalEntryId)
			end
		end

		for _, loreId in ipairs(rewardDefinition.LoreUnlocks or {}) do
			if playerData.Lore.UnlockedLoreIds[loreId] then
				table.insert(summary.SkippedDuplicates, loreId)
			else
				playerData.Lore.UnlockedLoreIds[loreId] = true
				playerData.Lore.LoreStates[loreId] = {
					LoreId = loreId,
					SourceType = rewardSourceContext.SourceType,
					SourceId = rewardSourceContext.SourceId,
					UnlockedAt = os.time(),
					ViewedAt = nil,
				}
				table.insert(summary.UnlockedLoreEntries, loreId)
			end
		end
	end)

	if not stateResult.Success then
		return stateResult
	end

	local claimResult = playerDataService.MarkRewardClaim(player, rewardBundleId)
	if not claimResult.Success then
		return claimResult
	end

	return result(true, "RewardGranted", nil, summary)
end

function RewardService.GetRewardDefinition(rewardBundleId)
	return RewardDefinitions[rewardBundleId]
end

return RewardService
