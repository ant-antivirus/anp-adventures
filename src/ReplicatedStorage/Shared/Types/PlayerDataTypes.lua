export type PlayerData = {
	SchemaVersion: number,
	Profile: {
		UserId: number,
		CreatedAt: number,
		LastLoginAt: number,
		TotalPlaytimeSeconds: number,
	},
	Progression: {
		ExplorerScore: number,
		ExplorerRankId: string,
		LifetimeExplorerScore: number,
	},
	SessionStats: {
		SessionStartTime: number,
		DiscoveriesFound: number,
		QuestsStarted: number,
		QuestsCompleted: number,
		NPCInteractions: number,
		ZoneTravels: number,
	},
	Episodes: {
		ActiveEpisodeId: string?,
		UnlockedEpisodeIds: { [string]: boolean },
		CompletedEpisodeIds: { [string]: boolean },
		EpisodeProgress: { [string]: any },
	},
	Quests: {
		ActiveQuestIds: { string },
		CompletedQuestIds: { [string]: boolean },
		QuestStates: { [string]: any },
	},
	Inventory: {
		Items: { [string]: any },
	},
	Discoveries: {
		FoundDiscoveryIds: { [string]: boolean },
		ZoneDiscoveryProgress: { [string]: any },
	},
	Journal: {
		UnlockedEntryIds: { [string]: boolean },
		EntryStates: { [string]: any },
		UnlockedLore: { [string]: boolean },
		UnlockedCharacters: { [string]: boolean },
		UnlockedZones: { [string]: boolean },
	},
	Lore: {
		UnlockedLoreIds: { [string]: boolean },
		LoreStates: { [string]: any },
	},
	Badges: {
		AwardedBadgeIds: { [string]: boolean },
		PendingRobloxBadgeAwards: { string },
	},
	Memories: {
		FirstQuestCompletedId: string?,
		FirstDiscoveryId: string?,
		FirstEpisodeCompletedId: string?,
		FirstPartyQuestCompletedId: string?,
		FavoriteCompanionId: string?,
		SharedMoments: { [string]: any },
		Milestones: { [string]: any },
	},
	Zones: {
		UnlockedZoneIds: { [string]: boolean },
		FastTravelUnlockedZoneIds: { [string]: boolean },
		LastZoneId: string?,
		LastSpawnPointId: string?,
	},
	Companion: {
		TutorialFlags: { [string]: boolean },
		HintHistory: { [string]: any },
		SoloAssistHistory: { [string]: any },
	},
	Settings: {
		InputMode: "Auto" | "KeyboardMouse" | "Gamepad" | "Touch",
		HintsEnabled: boolean,
		DialogueSpeed: number,
		ReducedMotion: boolean,
	},
	Timestamps: {
		CreatedAt: number,
		LastSavedAt: number,
		LastLoadedAt: number,
	},
}

return {}
