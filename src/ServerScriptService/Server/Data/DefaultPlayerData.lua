local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local EpisodeConfig = require(Shared.Config.EpisodeConfig)
local RankConfig = require(Shared.Config.RankConfig)
local ZoneConfig = require(Shared.Config.ZoneConfig)
local TableUtil = require(Shared.Util.TableUtil)

local DefaultPlayerData = {}

local function buildTemplate(userId, timestamp)
	local activeEpisodeId = EpisodeConfig.Ids.Episode01
	local startingZoneId = ZoneConfig.Ids.CommandCenter

	return {
		SchemaVersion = GameConfig.SchemaVersion,

		Profile = {
			UserId = userId,
			CreatedAt = timestamp,
			LastLoginAt = timestamp,
			TotalPlaytimeSeconds = 0,
		},

		Progression = {
			ExplorerScore = 0,
			ExplorerRankId = RankConfig.Ids.Cadet,
			LifetimeExplorerScore = 0,
		},

		SessionStats = {
			SessionStartTime = timestamp,
			DiscoveriesFound = 0,
			QuestsStarted = 0,
			QuestsCompleted = 0,
			NPCInteractions = 0,
			ZoneTravels = 0,
		},

		Episodes = {
			ActiveEpisodeId = activeEpisodeId,
			UnlockedEpisodeIds = {
				[activeEpisodeId] = true,
			},
			CompletedEpisodeIds = {},
			EpisodeProgress = {
				[activeEpisodeId] = {
					StartedAt = nil,
					CompletedAt = nil,
					CompletedQuestCount = 0,
					TotalQuestCount = 8,
				},
			},
		},

		Quests = {
			ActiveQuestIds = {},
			CompletedQuestIds = {},
			QuestStates = {},
		},

		Inventory = {
			Items = {},
		},

		Discoveries = {
			FoundDiscoveryIds = {},
			DiscoveryStates = {},
			ZoneDiscoveryProgress = {},
		},

		Journal = {
			UnlockedEntryIds = {},
			EntryStates = {},
			UnlockedLore = {},
			UnlockedCharacters = {},
			UnlockedZones = {},
		},

		Lore = {
			UnlockedLoreIds = {},
			LoreStates = {},
		},

		Badges = {
			AwardedBadgeIds = {},
			PendingRobloxBadgeAwards = {},
		},

		Memories = {
			FirstQuestCompletedId = nil,
			FirstDiscoveryId = nil,
			FirstEpisodeCompletedId = nil,
			FirstPartyQuestCompletedId = nil,
			FavoriteCompanionId = nil,
			SharedMoments = {},
			Milestones = {},
		},

		Zones = {
			UnlockedZoneIds = {
				[startingZoneId] = true,
			},
			FastTravelUnlockedZoneIds = {},
			LastZoneId = startingZoneId,
			LastSpawnPointId = "spawn_ep01_command_default",
		},

		Companion = {
			TutorialFlags = {},
			HintHistory = {},
			SoloAssistHistory = {},
		},

		Settings = {
			InputMode = "Auto",
			HintsEnabled = true,
			DialogueSpeed = 1,
			ReducedMotion = false,
		},

		Timestamps = {
			CreatedAt = timestamp,
			LastSavedAt = 0,
			LastLoadedAt = timestamp,
		},
	}
end

function DefaultPlayerData.Create(userId, timestamp)
	local createdAt = timestamp or os.time()
	return TableUtil.DeepCopy(buildTemplate(userId, createdAt))
end

return DefaultPlayerData
