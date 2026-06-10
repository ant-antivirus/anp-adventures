local DefinitionValidator = {}

local REQUIRED_EP01_FRAGMENTS = {
	"item_ep01_fragment_universe",
	"item_ep01_fragment_earth",
	"item_ep01_fragment_theos",
	"item_ep01_fragment_rocket",
	"item_ep01_fragment_moon",
}

local EP01_ID = "ep01_lost_star_core"
local EP01_RESTORED_SEGMENT_ID = "item_star_core_segment_01"
local EP01_FINAL_REWARD_ID = "reward_ep01_main_008"
local EP01_MOON_FRAGMENT_REWARD_ID = "reward_ep01_objective_008_moon_fragment"
local RESERVED_SOCIAL_HUB_ZONE_ID = "zone_social_hub_anp_town"
local VALID_CONTENT_STATUS = {
	Prototype = true,
	Playable = true,
	Polished = true,
	Deprecated = true,
}

local function newResult()
	return {
		Success = true,
		Code = "DefinitionValidationPassed",
		Errors = {},
		Warnings = {},
		Summary = {
			Episodes = 0,
			Zones = 0,
			Quests = 0,
			Rewards = 0,
			Items = 0,
			Discoveries = 0,
			Lore = 0,
			Journal = 0,
		},
	}
end

local function addError(result, message)
	result.Success = false
	result.Code = "DefinitionValidationFailed"
	table.insert(result.Errors, message)
end

local function addWarning(result, message)
	table.insert(result.Warnings, message)
end

local function countMap(map)
	local count = 0

	for _ in pairs(map or {}) do
		count += 1
	end

	return count
end

local function contains(list, value)
	for _, item in ipairs(list or {}) do
		if item == value then
			return true
		end
	end

	return false
end

local function mapHas(map, key)
	return key ~= nil and map ~= nil and map[key] ~= nil
end

local function validateUniqueIds(result, label, definitions, idField)
	local seen = {}

	for key, definition in pairs(definitions or {}) do
		local id = definition[idField]

		if type(id) ~= "string" or id == "" then
			addError(result, label .. " entry `" .. tostring(key) .. "` is missing `" .. idField .. "`.")
		elseif key ~= id then
			addError(result, label .. " entry key `" .. tostring(key) .. "` does not match `" .. idField .. "` `" .. id .. "`.")
		elseif seen[id] then
			addError(result, label .. " has duplicate ID `" .. id .. "`.")
		else
			seen[id] = true
		end
	end
end

local function validateIdList(result, sourceLabel, values, targetMap, targetLabel)
	for _, id in ipairs(values or {}) do
		if not mapHas(targetMap, id) then
			addError(result, sourceLabel .. " references missing " .. targetLabel .. " `" .. tostring(id) .. "`.")
		end
	end
end

local function validateEpisodeReferences(result, catalog)
	for episodeId, episode in pairs(catalog.Episodes or {}) do
		validateIdList(result, "Episode `" .. episodeId .. "` Zones", episode.Zones, catalog.Zones, "zone")
		validateIdList(result, "Episode `" .. episodeId .. "` QuestIds", episode.QuestIds, catalog.Quests, "quest")
		validateIdList(result, "Episode `" .. episodeId .. "` RewardBundleIds", episode.RewardBundleIds, catalog.Rewards, "reward")

		local requirements = episode.CompletionRequirements or {}
		validateIdList(result, "Episode `" .. episodeId .. "` CompletedQuestIds", requirements.CompletedQuestIds, catalog.Quests, "quest")
		validateIdList(result, "Episode `" .. episodeId .. "` RequiredItemIds", requirements.RequiredItemIds, catalog.Items, "item")

		if requirements.RestoredSegmentItemId and not mapHas(catalog.Items, requirements.RestoredSegmentItemId) then
			addError(result, "Episode `" .. episodeId .. "` references missing restored segment item `" .. requirements.RestoredSegmentItemId .. "`.")
		end
	end
end

local function validateZoneReferences(result, catalog)
	for zoneId, zone in pairs(catalog.Zones or {}) do
		local isReservedDisabledZone = zone.Reserved == true and zone.Enabled == false
		if not isReservedDisabledZone and not mapHas(catalog.Episodes, zone.EpisodeId) then
			addError(result, "Zone `" .. zoneId .. "` references missing episode `" .. tostring(zone.EpisodeId) .. "`.")
		end

		if zone.ContentStatus ~= nil and not VALID_CONTENT_STATUS[zone.ContentStatus] then
			addError(result, "Zone `" .. zoneId .. "` has invalid ContentStatus `" .. tostring(zone.ContentStatus) .. "`.")
		end

		validateIdList(result, "Zone `" .. zoneId .. "` DiscoveryRequirements", zone.DiscoveryRequirements, catalog.Discoveries, "discovery")

		for _, rule in ipairs(zone.UnlockRules or {}) do
			if rule.QuestId and not mapHas(catalog.Quests, rule.QuestId) then
				addError(result, "Zone `" .. zoneId .. "` unlock rule references missing quest `" .. rule.QuestId .. "`.")
			end

			if rule.RewardBundleId and not mapHas(catalog.Rewards, rule.RewardBundleId) then
				addError(result, "Zone `" .. zoneId .. "` unlock rule references missing reward `" .. rule.RewardBundleId .. "`.")
			end
		end
	end
end

local function validateReservedFutureZones(result, catalog)
	local socialHub = (catalog.Zones or {})[RESERVED_SOCIAL_HUB_ZONE_ID]
	if not socialHub then
		addError(result, "Reserved social hub zone `" .. RESERVED_SOCIAL_HUB_ZONE_ID .. "` is missing.")
		return
	end

	if socialHub.Reserved ~= true or socialHub.Enabled ~= false then
		addError(result, "Reserved social hub zone `" .. RESERVED_SOCIAL_HUB_ZONE_ID .. "` must be Reserved=true and Enabled=false.")
	end

	for episodeId, episode in pairs(catalog.Episodes or {}) do
		if contains(episode.Zones, RESERVED_SOCIAL_HUB_ZONE_ID) then
			addError(result, "Episode `" .. episodeId .. "` must not include reserved social hub zone `" .. RESERVED_SOCIAL_HUB_ZONE_ID .. "`.")
		end
	end

	for questId, quest in pairs(catalog.Quests or {}) do
		if quest.ZoneId == RESERVED_SOCIAL_HUB_ZONE_ID then
			addError(result, "Quest `" .. questId .. "` must not target reserved social hub zone `" .. RESERVED_SOCIAL_HUB_ZONE_ID .. "`.")
		end
	end

	for rewardId, reward in pairs(catalog.Rewards or {}) do
		if contains(reward.UnlockZones, RESERVED_SOCIAL_HUB_ZONE_ID) then
			addError(result, "Reward `" .. rewardId .. "` must not unlock reserved social hub zone `" .. RESERVED_SOCIAL_HUB_ZONE_ID .. "`.")
		end
	end

	for discoveryId, discovery in pairs(catalog.Discoveries or {}) do
		if discovery.ZoneId == RESERVED_SOCIAL_HUB_ZONE_ID then
			addError(result, "Discovery `" .. discoveryId .. "` must not target reserved social hub zone `" .. RESERVED_SOCIAL_HUB_ZONE_ID .. "`.")
		end
	end

	for interactionId, interaction in pairs(catalog.Interactions or {}) do
		if interaction.ZoneId == RESERVED_SOCIAL_HUB_ZONE_ID then
			addError(result, "Interaction `" .. interactionId .. "` must not target reserved social hub zone `" .. RESERVED_SOCIAL_HUB_ZONE_ID .. "`.")
		end
	end
end

local function validateQuestReferences(result, catalog, companionConfig)
	local validAssistIds = {}

	for _, assistId in ipairs((companionConfig and companionConfig.AssistIds) or {}) do
		validAssistIds[assistId] = true
	end

	for questId, quest in pairs(catalog.Quests or {}) do
		if not mapHas(catalog.Episodes, quest.EpisodeId) then
			addError(result, "Quest `" .. questId .. "` references missing episode `" .. tostring(quest.EpisodeId) .. "`.")
		end

		if not mapHas(catalog.Zones, quest.ZoneId) then
			addError(result, "Quest `" .. questId .. "` references missing zone `" .. tostring(quest.ZoneId) .. "`.")
		end

		validateIdList(result, "Quest `" .. questId .. "` RewardBundleIds", quest.RewardBundleIds, catalog.Rewards, "reward")

		local objectiveSeen = {}
		for _, objectiveId in ipairs(quest.ObjectiveIds or {}) do
			if objectiveSeen[objectiveId] then
				addError(result, "Quest `" .. questId .. "` has duplicate objective `" .. objectiveId .. "`.")
			end
			objectiveSeen[objectiveId] = true

			local objectiveDefinition = quest.ObjectiveDefinitions and quest.ObjectiveDefinitions[objectiveId]
			if objectiveDefinition and (type(objectiveDefinition.RequiredAmount) ~= "number" or objectiveDefinition.RequiredAmount <= 0) then
				addError(result, "Quest `" .. questId .. "` objective `" .. objectiveId .. "` has invalid RequiredAmount.")
			end
		end

		for objectiveId in pairs(quest.ObjectiveDefinitions or {}) do
			if not objectiveSeen[objectiveId] then
				addError(result, "Quest `" .. questId .. "` ObjectiveDefinitions contains unknown objective `" .. objectiveId .. "`.")
			end
		end

		for objectiveId, objectiveDefinition in pairs(quest.ObjectiveDefinitions or {}) do
			validateIdList(result, "Quest `" .. questId .. "` objective `" .. objectiveId .. "` RewardBundleIds", objectiveDefinition.RewardBundleIds, catalog.Rewards, "reward")

			local requiresObjectiveIds = objectiveDefinition.RequiresObjectiveIds
			if requiresObjectiveIds ~= nil and type(requiresObjectiveIds) ~= "table" then
				addError(result, "Quest `" .. questId .. "` objective `" .. objectiveId .. "` RequiresObjectiveIds must be a list.")
			elseif type(requiresObjectiveIds) == "table" then
				local dependencySeen = {}
				for _, requiredObjectiveId in ipairs(requiresObjectiveIds) do
					if type(requiredObjectiveId) ~= "string" or requiredObjectiveId == "" then
						addError(result, "Quest `" .. questId .. "` objective `" .. objectiveId .. "` has an invalid RequiresObjectiveIds entry.")
					elseif requiredObjectiveId == objectiveId then
						addError(result, "Quest `" .. questId .. "` objective `" .. objectiveId .. "` cannot require itself.")
					elseif dependencySeen[requiredObjectiveId] then
						addError(result, "Quest `" .. questId .. "` objective `" .. objectiveId .. "` has duplicate dependency `" .. requiredObjectiveId .. "`.")
					elseif not objectiveSeen[requiredObjectiveId] then
						addError(result, "Quest `" .. questId .. "` objective `" .. objectiveId .. "` requires unknown objective `" .. requiredObjectiveId .. "`.")
					else
						local requiredObjectiveDefinition = quest.ObjectiveDefinitions and quest.ObjectiveDefinitions[requiredObjectiveId]
						if contains((requiredObjectiveDefinition and requiredObjectiveDefinition.RequiresObjectiveIds) or {}, objectiveId) then
							addError(result, "Quest `" .. questId .. "` objectives `" .. objectiveId .. "` and `" .. requiredObjectiveId .. "` have a direct circular dependency.")
						end
					end

					dependencySeen[requiredObjectiveId] = true
				end
			end
		end

		for _, requiredObjectiveId in ipairs(quest.RequiredObjectiveIds or {}) do
			if not objectiveSeen[requiredObjectiveId] then
				addError(result, "Quest `" .. questId .. "` required objective `" .. requiredObjectiveId .. "` is not listed in ObjectiveIds.")
			end
		end

		for _, assistId in ipairs(quest.RequiredCompanionAssists or {}) do
			if not validAssistIds[assistId] then
				addError(result, "Quest `" .. questId .. "` references missing Proton assist `" .. tostring(assistId) .. "`.")
			end
		end

		local solo = quest.SoloSupportMetadata or {}
		if solo.SoloCompletable ~= true then
			addError(result, "Quest `" .. questId .. "` is not marked solo-completable.")
		end

		if solo.HasCoopStyleRequiredMechanic then
			local fallbackIds = solo.RequiredSoloFallbackAssistIds or {}
			if #fallbackIds == 0 then
				addError(result, "Quest `" .. questId .. "` has a co-op-style required mechanic without Proton fallback assists.")
			end

			for _, assistId in ipairs(fallbackIds) do
				if not contains(quest.RequiredCompanionAssists, assistId) then
					addError(result, "Quest `" .. questId .. "` fallback assist `" .. assistId .. "` is not listed in RequiredCompanionAssists.")
				end

				if not validAssistIds[assistId] then
					addError(result, "Quest `" .. questId .. "` fallback assist `" .. assistId .. "` is not in CompanionConfig.")
				end
			end
		end
	end
end

local function validateRewardReferences(result, catalog, badgeConfig)
	for rewardId, reward in pairs(catalog.Rewards or {}) do
		if reward.GrantService ~= "RewardService" then
			addError(result, "Reward `" .. rewardId .. "` must route through RewardService.")
		end

		if type(reward.ExplorerScore) ~= "number" or reward.ExplorerScore < 0 then
			addError(result, "Reward `" .. rewardId .. "` has invalid ExplorerScore.")
		end

		if type(reward.DuplicatePolicy) ~= "string" or reward.DuplicatePolicy == "" then
			addError(result, "Reward `" .. rewardId .. "` is missing DuplicatePolicy.")
		end

		for _, itemGrant in ipairs(reward.Items or {}) do
			if not mapHas(catalog.Items, itemGrant.ItemId) then
				addError(result, "Reward `" .. rewardId .. "` references missing item `" .. tostring(itemGrant.ItemId) .. "`.")
			end

			if type(itemGrant.Quantity) ~= "number" or itemGrant.Quantity <= 0 then
				addError(result, "Reward `" .. rewardId .. "` has invalid quantity for item `" .. tostring(itemGrant.ItemId) .. "`.")
			end
		end

		for _, badgeId in ipairs(reward.Badges or {}) do
			if not (badgeConfig and badgeConfig.Badges and badgeConfig.Badges[badgeId]) then
				addError(result, "Reward `" .. rewardId .. "` references missing badge `" .. tostring(badgeId) .. "`.")
			end
		end

		validateIdList(result, "Reward `" .. rewardId .. "` UnlockZones", reward.UnlockZones, catalog.Zones, "zone")
		validateIdList(result, "Reward `" .. rewardId .. "` UnlockEpisodes", reward.UnlockEpisodes, catalog.Episodes, "episode")
		validateIdList(result, "Reward `" .. rewardId .. "` JournalUnlocks", reward.JournalUnlocks, catalog.Journal, "journal entry")
		validateIdList(result, "Reward `" .. rewardId .. "` LoreUnlocks", reward.LoreUnlocks, catalog.Lore, "lore entry")

		for _, consumedItemId in ipairs(reward.ConsumesItems or {}) do
			if not mapHas(catalog.Items, consumedItemId) then
				addError(result, "Reward `" .. rewardId .. "` consumes missing item `" .. tostring(consumedItemId) .. "`.")
			end
		end
	end
end

local function validateDiscoveryReferences(result, catalog)
	for discoveryId, discovery in pairs(catalog.Discoveries or {}) do
		if not mapHas(catalog.Zones, discovery.ZoneId) then
			addError(result, "Discovery `" .. discoveryId .. "` references missing zone `" .. tostring(discovery.ZoneId) .. "`.")
		end

		if discovery.RewardBundleId and not mapHas(catalog.Rewards, discovery.RewardBundleId) then
			addError(result, "Discovery `" .. discoveryId .. "` references missing reward `" .. discovery.RewardBundleId .. "`.")
		end

		validateIdList(result, "Discovery `" .. discoveryId .. "` LoreUnlockIds", discovery.LoreUnlockIds, catalog.Lore, "lore entry")
		validateIdList(result, "Discovery `" .. discoveryId .. "` JournalUnlockIds", discovery.JournalUnlockIds, catalog.Journal, "journal entry")

		if discovery.ExplorerScore > 0 and not discovery.RewardBundleId and not discovery.RewardIncludedInQuestBundle then
			addWarning(result, "Discovery `" .. discoveryId .. "` has ExplorerScore without a reward bundle or quest-bundle inclusion flag.")
		end
	end
end

local function validateLoreReferences(result, catalog)
	for loreId, lore in pairs(catalog.Lore or {}) do
		if not mapHas(catalog.Discoveries, lore.DiscoveryId) then
			addError(result, "Lore `" .. loreId .. "` references missing discovery `" .. tostring(lore.DiscoveryId) .. "`.")
		end
	end
end

local function validateJournalReferences(result, catalog)
	for journalId, journal in pairs(catalog.Journal or {}) do
		local sourceType = journal.UnlockSourceType
		local sourceId = journal.UnlockSourceId

		if sourceType == "Quest" and not mapHas(catalog.Quests, sourceId) then
			addError(result, "Journal `" .. journalId .. "` references missing quest `" .. tostring(sourceId) .. "`.")
		elseif sourceType == "Discovery" and not mapHas(catalog.Discoveries, sourceId) then
			addError(result, "Journal `" .. journalId .. "` references missing discovery `" .. tostring(sourceId) .. "`.")
		elseif sourceType == "Item" and not mapHas(catalog.Items, sourceId) then
			addError(result, "Journal `" .. journalId .. "` references missing item `" .. tostring(sourceId) .. "`.")
		elseif sourceType == "Episode" and not mapHas(catalog.Episodes, sourceId) then
			addError(result, "Journal `" .. journalId .. "` references missing episode `" .. tostring(sourceId) .. "`.")
		elseif sourceType ~= "Quest" and sourceType ~= "Discovery" and sourceType ~= "Item" and sourceType ~= "Episode" then
			addError(result, "Journal `" .. journalId .. "` has unknown unlock source type `" .. tostring(sourceType) .. "`.")
		end
	end
end

local function validateEpisodeOneAssembly(result, catalog)
	local episode = (catalog.Episodes or {})[EP01_ID]
	if not episode then
		addError(result, "Episode 1 definition `" .. EP01_ID .. "` is missing.")
		return
	end

	local requirements = episode.CompletionRequirements or {}
	local requiredItems = requirements.RequiredItemIds or {}

	for _, fragmentId in ipairs(REQUIRED_EP01_FRAGMENTS) do
		if not contains(requiredItems, fragmentId) then
			addError(result, "Episode 1 assembly is missing required fragment `" .. fragmentId .. "`.")
		end

		local item = (catalog.Items or {})[fragmentId]
		if not item then
			addError(result, "Episode 1 required fragment item `" .. fragmentId .. "` is not defined.")
		elseif item.Persistent ~= true or item.ConsumedOnAssembly ~= false then
			addError(result, "Episode 1 fragment `" .. fragmentId .. "` must be persistent and retained after assembly.")
		end
	end

	if #requiredItems ~= #REQUIRED_EP01_FRAGMENTS then
		addError(result, "Episode 1 assembly must require exactly the five Episode 1 fragment items.")
	end

	if requirements.RestoredSegmentItemId ~= EP01_RESTORED_SEGMENT_ID then
		addError(result, "Episode 1 must restore only `" .. EP01_RESTORED_SEGMENT_ID .. "`.")
	end

	local finalReward = (catalog.Rewards or {})[EP01_FINAL_REWARD_ID]
	if not finalReward then
		addError(result, "Episode 1 final reward `" .. EP01_FINAL_REWARD_ID .. "` is missing.")
		return
	end

	local grantsSegment = false
	for _, itemGrant in ipairs(finalReward.Items or {}) do
		if itemGrant.ItemId == EP01_RESTORED_SEGMENT_ID then
			grantsSegment = true
		elseif itemGrant.ItemId == "item_ep01_fragment_moon" then
			addError(result, "Episode 1 Moon Fragment must be granted before final reward `" .. EP01_FINAL_REWARD_ID .. "`.")
		elseif string.match(itemGrant.ItemId, "^item_star_core_segment_0[2-5]$") then
			addError(result, "Episode 1 final reward must not grant future Star Core segment `" .. itemGrant.ItemId .. "`.")
		end
	end

	if not grantsSegment then
		addError(result, "Episode 1 final reward must grant `" .. EP01_RESTORED_SEGMENT_ID .. "`.")
	end

	local moonFragmentReward = (catalog.Rewards or {})[EP01_MOON_FRAGMENT_REWARD_ID]
	if not moonFragmentReward then
		addError(result, "Episode 1 Moon Fragment objective reward `" .. EP01_MOON_FRAGMENT_REWARD_ID .. "` is missing.")
		return
	end

	local grantsMoonFragment = false
	for _, itemGrant in ipairs(moonFragmentReward.Items or {}) do
		if itemGrant.ItemId == "item_ep01_fragment_moon" then
			grantsMoonFragment = true
		elseif itemGrant.ItemId == EP01_RESTORED_SEGMENT_ID then
			addError(result, "Episode 1 Moon Fragment objective reward must not grant `" .. EP01_RESTORED_SEGMENT_ID .. "`.")
		end
	end

	if not grantsMoonFragment then
		addError(result, "Episode 1 Moon Fragment objective reward must grant `item_ep01_fragment_moon`.")
	end
end

local function validateFragmentsAreRetained(result, catalog)
	for rewardId, reward in pairs(catalog.Rewards or {}) do
		for _, fragmentId in ipairs(REQUIRED_EP01_FRAGMENTS) do
			if contains(reward.ConsumesItems, fragmentId) then
				addError(result, "Reward `" .. rewardId .. "` consumes retained Episode 1 fragment `" .. fragmentId .. "`.")
			end
		end
	end
end

function DefinitionValidator.Validate(catalog, config)
	local result = newResult()
	local safeConfig = config or {}

	result.Summary.Episodes = countMap(catalog.Episodes)
	result.Summary.Zones = countMap(catalog.Zones)
	result.Summary.Quests = countMap(catalog.Quests)
	result.Summary.Rewards = countMap(catalog.Rewards)
	result.Summary.Items = countMap(catalog.Items)
	result.Summary.Discoveries = countMap(catalog.Discoveries)
	result.Summary.Lore = countMap(catalog.Lore)
	result.Summary.Journal = countMap(catalog.Journal)

	validateUniqueIds(result, "Episode", catalog.Episodes, "EpisodeId")
	validateUniqueIds(result, "Zone", catalog.Zones, "ZoneId")
	validateUniqueIds(result, "Quest", catalog.Quests, "QuestId")
	validateUniqueIds(result, "Reward", catalog.Rewards, "RewardBundleId")
	validateUniqueIds(result, "Item", catalog.Items, "ItemId")
	validateUniqueIds(result, "Discovery", catalog.Discoveries, "DiscoveryId")
	validateUniqueIds(result, "Lore", catalog.Lore, "LoreId")
	validateUniqueIds(result, "Journal", catalog.Journal, "JournalEntryId")

	validateEpisodeReferences(result, catalog)
	validateZoneReferences(result, catalog)
	validateReservedFutureZones(result, catalog)
	validateQuestReferences(result, catalog, safeConfig.CompanionConfig)
	validateRewardReferences(result, catalog, safeConfig.BadgeConfig)
	validateDiscoveryReferences(result, catalog)
	validateLoreReferences(result, catalog)
	validateJournalReferences(result, catalog)
	validateEpisodeOneAssembly(result, catalog)
	validateFragmentsAreRetained(result, catalog)

	return result
end

return DefinitionValidator
