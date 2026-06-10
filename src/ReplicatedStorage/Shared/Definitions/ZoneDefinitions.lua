return {
	zone_ep01_command_center = {
		ZoneId = "zone_ep01_command_center",
		EpisodeId = "ep01_lost_star_core",
		ContentStatus = "Playable",
		UnlockRules = {
			{ Type = "DefaultUnlocked" },
		},
		SpawnPoints = { "spawn_ep01_command_default", "spawn_ep01_command_return" },
		TravelEligibility = {
			Spawn = true,
			Checkpoint = true,
			FastTravel = false,
		},
		DiscoveryRequirements = {
			"disc_ep01_command_expedition_terminal",
			"disc_ep01_command_star_core_display",
		},
	},
	zone_ep01_universe_explorer = {
		ZoneId = "zone_ep01_universe_explorer",
		EpisodeId = "ep01_lost_star_core",
		ContentStatus = "Playable",
		UnlockRules = {
			{ Type = "QuestCompleted", QuestId = "quest_ep01_main_001" },
			{ Type = "RewardGranted", RewardBundleId = "reward_ep01_main_001" },
		},
		SpawnPoints = { "spawn_ep01_universe_default" },
		TravelEligibility = {
			Spawn = true,
			FastTravel = true,
		},
		DiscoveryRequirements = {
			"disc_ep01_universe_first_signal_marker",
			"disc_ep01_universe_analysis_station",
			"disc_ep01_universe_puzzle_station",
			"disc_ep01_universe_fragment",
		},
	},
	zone_ep01_terrain_sandbox = {
		ZoneId = "zone_ep01_terrain_sandbox",
		EpisodeId = "ep01_lost_star_core",
		ContentStatus = "Prototype",
		UnlockRules = {
			{ Type = "QuestCompleted", QuestId = "quest_ep01_main_003" },
			{ Type = "RewardGranted", RewardBundleId = "reward_ep01_main_003" },
		},
		SpawnPoints = { "spawn_ep01_terrain_default" },
		TravelEligibility = {
			Spawn = true,
			FastTravel = true,
		},
		DiscoveryRequirements = {
			"disc_ep01_terrain_flow_console",
			"disc_ep01_terrain_fragment",
			"disc_ep01_terrain_observation_point",
		},
	},
	zone_ep01_theos_satellite_center = {
		ZoneId = "zone_ep01_theos_satellite_center",
		EpisodeId = "ep01_lost_star_core",
		ContentStatus = "Prototype",
		UnlockRules = {
			{ Type = "QuestCompleted", QuestId = "quest_ep01_main_004" },
			{ Type = "RewardGranted", RewardBundleId = "reward_ep01_main_004" },
		},
		SpawnPoints = { "spawn_ep01_theos_default" },
		TravelEligibility = {
			Spawn = true,
			FastTravel = true,
		},
		DiscoveryRequirements = {
			"disc_ep01_theos_calibration_console",
			"disc_ep01_theos_fragment",
			"disc_ep01_theos_satellite_history",
			"disc_ep01_theos_theos_1",
			"disc_ep01_theos_theos_2",
			"disc_ep01_theos_thailand_map",
			"disc_ep01_theos_satellite_imagery",
			"disc_ep01_theos_disaster_monitoring",
			"disc_ep01_theos_agriculture_monitoring",
			"disc_ep01_theos_water_resource_monitoring",
			"disc_ep01_theos_forest_monitoring",
		},
	},
	zone_ep01_rocket_mission = {
		ZoneId = "zone_ep01_rocket_mission",
		EpisodeId = "ep01_lost_star_core",
		ContentStatus = "Prototype",
		UnlockRules = {
			{ Type = "QuestCompleted", QuestId = "quest_ep01_main_005" },
			{ Type = "RewardGranted", RewardBundleId = "reward_ep01_main_005" },
		},
		SpawnPoints = { "spawn_ep01_rocket_default" },
		TravelEligibility = {
			Spawn = true,
			FastTravel = true,
		},
		DiscoveryRequirements = {
			"disc_ep01_rocket_preflight_console",
			"disc_ep01_rocket_launch_platform",
			"disc_ep01_rocket_fragment",
		},
	},
	zone_ep01_astronaut_training = {
		ZoneId = "zone_ep01_astronaut_training",
		EpisodeId = "ep01_lost_star_core",
		ContentStatus = "Prototype",
		UnlockRules = {
			{ Type = "QuestCompleted", QuestId = "quest_ep01_main_006" },
			{ Type = "RewardGranted", RewardBundleId = "reward_ep01_main_006" },
		},
		SpawnPoints = { "spawn_ep01_astronaut_default" },
		TravelEligibility = {
			Spawn = true,
			FastTravel = true,
		},
		DiscoveryRequirements = {
			"disc_ep01_astronaut_training_entry",
			"disc_ep01_astronaut_readiness_station",
			"disc_ep01_astronaut_badge_terminal",
		},
	},
	zone_ep01_moon_walk = {
		ZoneId = "zone_ep01_moon_walk",
		EpisodeId = "ep01_lost_star_core",
		ContentStatus = "Prototype",
		UnlockRules = {
			{ Type = "QuestCompleted", QuestId = "quest_ep01_main_007" },
			{ Type = "RewardGranted", RewardBundleId = "reward_ep01_main_007" },
		},
		SpawnPoints = { "spawn_ep01_moon_default" },
		TravelEligibility = {
			Spawn = true,
			FastTravel = true,
		},
		DiscoveryRequirements = {
			"disc_ep01_moon_walk_entry",
			"disc_ep01_moon_low_gravity_route",
			"disc_ep01_moon_fragment",
			"disc_ep01_moon_star_core_segment_restoration_point",
		},
	},
	zone_social_hub_anp_town = {
		ZoneId = "zone_social_hub_anp_town",
		DisplayName = "ANP Town",
		Purpose = "Future central community area for meeting players, showing achievements, organizing parties, seasonal events, and memory-sharing.",
		Reserved = true,
		Enabled = false,
		ContentStatus = "Prototype",
		EpisodeId = nil,
		UnlockRules = {},
		SpawnPoints = {},
		TravelEligibility = {},
		DiscoveryRequirements = {},
	},
}
