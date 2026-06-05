export type RewardBundle = {
	RewardBundleId: string,
	ExplorerScore: number,
	Items: { { ItemId: string, Quantity: number } },
	Badges: { string },
	UnlockZones: { string },
	UnlockEpisodes: { string },
	JournalUnlocks: { string },
	LoreUnlocks: { string },
	DuplicatePolicy: string,
	GrantService: string,
	ConsumesItems: { string },
}

export type RewardSummary = {
	GrantedExplorerScore: number,
	GrantedItems: { string },
	GrantedBadges: { string },
	UnlockedZones: { string },
	UnlockedEpisodes: { string },
	SkippedDuplicates: { string },
}

return {}
