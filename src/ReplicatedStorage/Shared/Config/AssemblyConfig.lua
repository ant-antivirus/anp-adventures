local AssemblyConfig = {
	EpisodeOne = {
		FinalRewardBundleId = "reward_ep01_main_008",
		RestoredSegmentItemId = "item_star_core_segment_01",
		RequiredFragmentItemIds = {
			"item_ep01_fragment_universe",
			"item_ep01_fragment_earth",
			"item_ep01_fragment_theos",
			"item_ep01_fragment_rocket",
			"item_ep01_fragment_moon",
		},
		RetainedFragmentItemIds = {
			item_ep01_fragment_universe = true,
			item_ep01_fragment_earth = true,
			item_ep01_fragment_theos = true,
			item_ep01_fragment_rocket = true,
			item_ep01_fragment_moon = true,
		},
	},
}

return table.freeze(AssemblyConfig)
