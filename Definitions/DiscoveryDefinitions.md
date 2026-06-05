# Discovery Definitions

## Purpose

This document defines Episode 1 discovery records for implementation validation. Discovery claims must be server-validatable and duplicate-safe.

## Discovery Record Schema

```text
DiscoveryDefinition
  DiscoveryId: string
  ZoneId: string
  ExplorerScore: number
  RewardBundleId: string?
  LoreUnlockIds: array<LoreId>
  JournalUnlockIds: array<JournalEntryId>
```

## Discovery Records

| DiscoveryId | ZoneId | ExplorerScore | RewardBundleId | LoreUnlockIds[] | JournalUnlockIds[] |
| --- | --- | --- | --- | --- | --- |
| `disc_ep01_command_expedition_terminal` | `zone_ep01_command_center` | `10` | Included in `reward_ep01_main_001` | None | `journal_ep01_expedition_started` |
| `disc_ep01_command_star_core_display` | `zone_ep01_command_center` | `15` | Included in `reward_ep01_main_001` | None | `journal_ep01_star_core_segment_status` |
| `disc_ep01_universe_first_signal_marker` | `zone_ep01_universe_explorer` | `25` | Included in `reward_ep01_main_002` | None | `journal_ep01_broken_star_signal` |
| `disc_ep01_universe_analysis_station` | `zone_ep01_universe_explorer` | `10` | Included in `reward_ep01_main_002` | None | None |
| `disc_ep01_universe_puzzle_station` | `zone_ep01_universe_explorer` | `25` | Included in `reward_ep01_main_003` | None | None |
| `disc_ep01_universe_fragment` | `zone_ep01_universe_explorer` | `25` | Included in `reward_ep01_main_003` | None | `journal_ep01_fragment_universe` |
| `disc_ep01_terrain_flow_console` | `zone_ep01_terrain_sandbox` | `25` | Included in `reward_ep01_main_004` | None | None |
| `disc_ep01_terrain_fragment` | `zone_ep01_terrain_sandbox` | `25` | Included in `reward_ep01_main_004` | None | `journal_ep01_fragment_earth` |
| `disc_ep01_terrain_observation_point` | `zone_ep01_terrain_sandbox` | `25` | Included in `reward_ep01_main_004` | None | None |
| `disc_ep01_theos_calibration_console` | `zone_ep01_theos_satellite_center` | `25` | Included in `reward_ep01_main_005` | `lore_ep01_theos_calibration_console` | None |
| `disc_ep01_theos_fragment` | `zone_ep01_theos_satellite_center` | `25` | Included in `reward_ep01_main_005` | `lore_ep01_theos_fragment` | `journal_ep01_fragment_theos` |
| `disc_ep01_theos_satellite_history` | `zone_ep01_theos_satellite_center` | `25` | None | `lore_ep01_theos_satellite_history` | `journal_ep01_theos_satellite_history` |
| `disc_ep01_theos_theos_1` | `zone_ep01_theos_satellite_center` | `25` | None | `lore_ep01_theos_theos_1` | `journal_ep01_theos_theos_1` |
| `disc_ep01_theos_theos_2` | `zone_ep01_theos_satellite_center` | `25` | None | `lore_ep01_theos_theos_2` | `journal_ep01_theos_theos_2` |
| `disc_ep01_theos_thailand_map` | `zone_ep01_theos_satellite_center` | `25` | None | `lore_ep01_theos_thailand_map` | `journal_ep01_theos_thailand_map` |
| `disc_ep01_theos_satellite_imagery` | `zone_ep01_theos_satellite_center` | `25` | `reward_ep01_optional_005_satellite_imagery` | `lore_ep01_theos_satellite_imagery` | `journal_ep01_theos_satellite_imagery` |
| `disc_ep01_theos_disaster_monitoring` | `zone_ep01_theos_satellite_center` | `25` | `reward_ep01_optional_005_flood_monitoring` | `lore_ep01_theos_disaster_monitoring` | `journal_ep01_theos_flood_monitoring` |
| `disc_ep01_theos_agriculture_monitoring` | `zone_ep01_theos_satellite_center` | `25` | `reward_ep01_optional_005_agriculture_monitoring` | `lore_ep01_theos_agriculture_monitoring` | `journal_ep01_theos_agriculture_monitoring` |
| `disc_ep01_theos_water_resource_monitoring` | `zone_ep01_theos_satellite_center` | `25` | None | `lore_ep01_theos_water_resource_monitoring` | `journal_ep01_theos_water_resource_monitoring` |
| `disc_ep01_theos_forest_monitoring` | `zone_ep01_theos_satellite_center` | `25` | None | `lore_ep01_theos_forest_monitoring` | `journal_ep01_theos_forest_monitoring` |
| `disc_ep01_rocket_preflight_console` | `zone_ep01_rocket_mission` | `25` | Included in `reward_ep01_main_006` | None | None |
| `disc_ep01_rocket_launch_platform` | `zone_ep01_rocket_mission` | `25` | Included in `reward_ep01_main_006` | None | None |
| `disc_ep01_rocket_fragment` | `zone_ep01_rocket_mission` | `25` | Included in `reward_ep01_main_006` | None | `journal_ep01_fragment_rocket` |
| `disc_ep01_astronaut_training_entry` | `zone_ep01_astronaut_training` | `10` | Included in `reward_ep01_main_007` | None | None |
| `disc_ep01_astronaut_readiness_station` | `zone_ep01_astronaut_training` | `25` | Included in `reward_ep01_main_007` | None | `journal_ep01_astronaut_readiness` |
| `disc_ep01_astronaut_badge_terminal` | `zone_ep01_astronaut_training` | `25` | Included in `reward_ep01_main_007` | None | None |
| `disc_ep01_moon_walk_entry` | `zone_ep01_moon_walk` | `10` | Included in `reward_ep01_main_008` | None | None |
| `disc_ep01_moon_low_gravity_route` | `zone_ep01_moon_walk` | `25` | Included in `reward_ep01_main_008` | None | None |
| `disc_ep01_moon_fragment` | `zone_ep01_moon_walk` | `50` | Included in `reward_ep01_main_008` | None | `journal_ep01_fragment_moon` |
| `disc_ep01_moon_star_core_segment_restoration_point` | `zone_ep01_moon_walk` | `50` | Included in `reward_ep01_main_008` | None | `journal_ep01_star_core_segment_01_restored` |
| `disc_ep01_hidden_space_inspirium_secret` | `zone_ep01_command_center` | `100` | `reward_ep01_hidden_space_inspirium_secret` | None | `journal_ep01_hidden_space_inspirium_secret` |

## Discovery Rules

- `RewardBundleId` may be a dedicated bundle or marked as included in a quest reward bundle when the discovery reward is bundled into main quest completion.
- Hidden discovery placement may vary inside Episode 1, but the implementation must assign it to one valid Episode 1 zone for validation.
