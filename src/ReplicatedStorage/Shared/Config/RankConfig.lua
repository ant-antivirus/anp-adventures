local RankConfig = {
	Ids = {
		Cadet = "rank_cadet",
		JuniorExplorer = "rank_junior_explorer",
		Explorer = "rank_explorer",
		SeniorExplorer = "rank_senior_explorer",
		MasterExplorer = "rank_master_explorer",
	},

	Ranks = {
		{
			RankId = "rank_cadet",
			MinimumScore = 0,
			MaximumScore = 999,
		},
		{
			RankId = "rank_junior_explorer",
			MinimumScore = 1000,
			MaximumScore = 4999,
		},
		{
			RankId = "rank_explorer",
			MinimumScore = 5000,
			MaximumScore = 9999,
		},
		{
			RankId = "rank_senior_explorer",
			MinimumScore = 10000,
			MaximumScore = 24999,
		},
		{
			RankId = "rank_master_explorer",
			MinimumScore = 25000,
			MaximumScore = math.huge,
		},
	},
}

return table.freeze(RankConfig)
