local InventoryConfig = {
	Categories = {
		EpisodeFragment = "EpisodeFragment",
		StarCoreSegment = "StarCoreSegment",
		MissionItem = "MissionItem",
		EventItem = "EventItem",
		AchievementReward = "AchievementReward",
	},

	FragmentItemIds = {
		"item_ep01_fragment_universe",
		"item_ep01_fragment_earth",
		"item_ep01_fragment_theos",
		"item_ep01_fragment_rocket",
		"item_ep01_fragment_moon",
	},

	StarCoreSegmentItemIds = {
		"item_star_core_segment_01",
		"item_star_core_segment_02",
		"item_star_core_segment_03",
		"item_star_core_segment_04",
		"item_star_core_segment_05",
	},
}

return table.freeze(InventoryConfig)
