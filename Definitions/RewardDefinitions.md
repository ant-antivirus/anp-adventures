# Reward Definitions

## Purpose

This document defines stable reward bundle records for Episode 1 implementation. All grants must route through `RewardService`.

## Reward Bundle Schema

```text
RewardBundle
  RewardBundleId: string
  ExplorerScore: number
  Items: array<ItemGrant>
  Badges: array<BadgeId>
  UnlockZones: array<ZoneId>
  UnlockEpisodes: array<EpisodeId>
  JournalUnlocks: array<JournalEntryId>
  LoreUnlocks: array<LoreId>
  DuplicatePolicy: string
```

## Main Reward Bundles

| RewardBundleId | ExplorerScore | Items[] | Badges[] | UnlockZones[] | UnlockEpisodes[] | JournalUnlocks[] | LoreUnlocks[] | DuplicatePolicy |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `reward_ep01_main_001` | `125` | None | None | `zone_ep01_universe_explorer` | None | `journal_ep01_expedition_started`, `journal_ep01_star_core_segment_status` | None | Once per player per quest completion. |
| `reward_ep01_main_002` | `150` | None | None | None | None | `journal_ep01_broken_star_signal` | None | Once per player per quest completion. |
| `reward_ep01_main_003` | `150` | `item_ep01_fragment_universe:1` | None | `zone_ep01_terrain_sandbox` | None | `journal_ep01_fragment_universe` | None | Once per player per quest completion. |
| `reward_ep01_main_004` | `175` | `item_ep01_fragment_earth:1` | None | `zone_ep01_theos_satellite_center` | None | `journal_ep01_fragment_earth` | None | Once per player per quest completion. |
| `reward_ep01_main_005` | `175` | `item_ep01_fragment_theos:1` | None | `zone_ep01_rocket_mission` | None | `journal_ep01_fragment_theos` | `lore_ep01_theos_calibration_console`, `lore_ep01_theos_fragment` | Once per player per quest completion. |
| `reward_ep01_main_006` | `175` | `item_ep01_fragment_rocket:1` | None | `zone_ep01_astronaut_training` | None | `journal_ep01_fragment_rocket` | None | Once per player per quest completion. |
| `reward_ep01_main_007` | `150` | None | `badge_ep01_astronaut` | `zone_ep01_moon_walk` | None | `journal_ep01_astronaut_readiness` | None | Once per player per quest completion. |
| `reward_ep01_main_008` | `250` | `item_star_core_segment_01:1` | `badge_ep01_explorer`, `badge_ep01_space_pioneer` | None | None | `journal_ep01_star_core_segment_01_restored`, `journal_ep01_episode_complete` | None | Once per player per quest completion and fragment assembly validation. |

## Objective Reward Bundles

| RewardBundleId | ExplorerScore | Items[] | Badges[] | UnlockZones[] | UnlockEpisodes[] | JournalUnlocks[] | LoreUnlocks[] | DuplicatePolicy |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `reward_ep01_objective_008_moon_fragment` | `0` | `item_ep01_fragment_moon:1` | None | None | None | `journal_ep01_fragment_moon` | None | Once per player per quest objective. |

## Optional Reward Bundles

| RewardBundleId | ExplorerScore | Items[] | Badges[] | UnlockZones[] | UnlockEpisodes[] | JournalUnlocks[] | LoreUnlocks[] | DuplicatePolicy |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `reward_ep01_optional_005_satellite_imagery` | `25` | None | None | None | None | `journal_ep01_theos_satellite_imagery` | `lore_ep01_theos_satellite_imagery` | Once per player per optional objective. |
| `reward_ep01_optional_005_flood_monitoring` | `25` | None | None | None | None | `journal_ep01_theos_flood_monitoring` | `lore_ep01_theos_disaster_monitoring` | Once per player per optional objective. |
| `reward_ep01_optional_005_agriculture_monitoring` | `25` | None | None | None | None | `journal_ep01_theos_agriculture_monitoring` | `lore_ep01_theos_agriculture_monitoring` | Once per player per optional objective. |
| `reward_ep01_hidden_space_inspirium_secret` | `100` | None | None | None | None | `journal_ep01_hidden_space_inspirium_secret` | None | Once per player per hidden discovery. |

## Discovery Reward Bundles

| RewardBundleId | ExplorerScore | Items[] | Badges[] | UnlockZones[] | UnlockEpisodes[] | JournalUnlocks[] | LoreUnlocks[] | DuplicatePolicy |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `reward_ep01_discovery_theos_satellite_history` | `25` | None | None | None | None | `journal_ep01_theos_satellite_history` | `lore_ep01_theos_satellite_history` | Once per player per discovery. |
| `reward_ep01_discovery_theos_theos_1` | `25` | None | None | None | None | `journal_ep01_theos_theos_1` | `lore_ep01_theos_theos_1` | Once per player per discovery. |
| `reward_ep01_discovery_theos_theos_2` | `25` | None | None | None | None | `journal_ep01_theos_theos_2` | `lore_ep01_theos_theos_2` | Once per player per discovery. |
| `reward_ep01_discovery_theos_thailand_map` | `25` | None | None | None | None | `journal_ep01_theos_thailand_map` | `lore_ep01_theos_thailand_map` | Once per player per discovery. |
| `reward_ep01_discovery_theos_water_resource_monitoring` | `25` | None | None | None | None | `journal_ep01_theos_water_resource_monitoring` | `lore_ep01_theos_water_resource_monitoring` | Once per player per discovery. |
| `reward_ep01_discovery_theos_forest_monitoring` | `25` | None | None | None | None | `journal_ep01_theos_forest_monitoring` | `lore_ep01_theos_forest_monitoring` | Once per player per discovery. |

## Teamwork Reward Bundles

| RewardBundleId | ExplorerScore | Items[] | Badges[] | UnlockZones[] | UnlockEpisodes[] | JournalUnlocks[] | LoreUnlocks[] | DuplicatePolicy |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `reward_ep01_teamwork_main_001` | `25` | None | None | None | None | None | None | Once per player per eligible quest teamwork contribution. |
| `reward_ep01_teamwork_main_002` | `25` | None | None | None | None | None | None | Once per player per eligible quest teamwork contribution. |
| `reward_ep01_teamwork_main_003` | `25` | None | None | None | None | None | None | Once per player per eligible quest teamwork contribution. |
| `reward_ep01_teamwork_main_004` | `25` | None | None | None | None | None | None | Once per player per eligible quest teamwork contribution. |
| `reward_ep01_teamwork_main_005` | `25` | None | None | None | None | None | None | Once per player per eligible quest teamwork contribution. |
| `reward_ep01_teamwork_main_006` | `25` | None | None | None | None | None | None | Once per player per eligible quest teamwork contribution. |
| `reward_ep01_teamwork_main_007` | `25` | None | None | None | None | None | None | Once per player per eligible quest teamwork contribution. |
| `reward_ep01_teamwork_main_008` | `25` | None | None | None | None | None | None | Once per player per eligible quest teamwork contribution. |

## Reward Rules

- Reward definitions may reference future episode IDs only after those episodes have definition records.
- Fragments must not be consumed by any reward or assembly operation.
- The Moon Fragment is granted by `reward_ep01_objective_008_moon_fragment` before the final Episode 1 assembly reward.
- `reward_ep01_main_008` must only grant `item_star_core_segment_01` after all five Episode 1 fragments already exist.
- Teamwork rewards must never unlock required progression.
