local GameConfig = {
	GameId = "anp_adventures",
	DisplayName = "ANP Adventures",
	CurrentEpisodeId = "ep01_lost_star_core",
	MaxPlayers = 8,
	SupportedPlayModes = {
		Solo = "Solo",
		Coop = "Coop",
	},
	SchemaVersion = 1,
}

return table.freeze(GameConfig)
