# Journal Definitions

## Purpose

This document defines journal entry records for implementation. Journal unlock state is persistent, while journal text remains definition content.

## Journal Record Schema

```text
JournalDefinition
  JournalEntryId: string
  UnlockSourceType: string
  UnlockSourceId: string
  Category: string
```

## Episode 1 Journal Records

| JournalEntryId | UnlockSourceType | UnlockSourceId | Category |
| --- | --- | --- | --- |
| `journal_ep01_expedition_started` | Quest | `quest_ep01_main_001` | Episode |
| `journal_ep01_star_core_segment_status` | Discovery | `disc_ep01_command_star_core_display` | StarCore |
| `journal_ep01_broken_star_signal` | Quest | `quest_ep01_main_002` | Quest |
| `journal_ep01_fragment_universe` | Item | `item_ep01_fragment_universe` | Fragment |
| `journal_ep01_fragment_earth` | Item | `item_ep01_fragment_earth` | Fragment |
| `journal_ep01_fragment_theos` | Item | `item_ep01_fragment_theos` | Fragment |
| `journal_ep01_fragment_rocket` | Item | `item_ep01_fragment_rocket` | Fragment |
| `journal_ep01_astronaut_readiness` | Quest | `quest_ep01_main_007` | Badge |
| `journal_ep01_fragment_moon` | Item | `item_ep01_fragment_moon` | Fragment |
| `journal_ep01_star_core_segment_01_restored` | Item | `item_star_core_segment_01` | StarCore |
| `journal_ep01_episode_complete` | Episode | `ep01_lost_star_core` | Episode |
| `journal_ep01_theos_satellite_history` | Discovery | `disc_ep01_theos_satellite_history` | Lore |
| `journal_ep01_theos_theos_1` | Discovery | `disc_ep01_theos_theos_1` | Lore |
| `journal_ep01_theos_theos_2` | Discovery | `disc_ep01_theos_theos_2` | Lore |
| `journal_ep01_theos_thailand_map` | Discovery | `disc_ep01_theos_thailand_map` | Lore |
| `journal_ep01_theos_satellite_imagery` | Discovery | `disc_ep01_theos_satellite_imagery` | Lore |
| `journal_ep01_theos_flood_monitoring` | Discovery | `disc_ep01_theos_disaster_monitoring` | Lore |
| `journal_ep01_theos_agriculture_monitoring` | Discovery | `disc_ep01_theos_agriculture_monitoring` | Lore |
| `journal_ep01_theos_water_resource_monitoring` | Discovery | `disc_ep01_theos_water_resource_monitoring` | Lore |
| `journal_ep01_theos_forest_monitoring` | Discovery | `disc_ep01_theos_forest_monitoring` | Lore |
| `journal_ep01_hidden_space_inspirium_secret` | Discovery | `disc_ep01_hidden_space_inspirium_secret` | Secret |

## Journal Rules

- Journal unlocks must be granted only from approved server sources.
- Viewing state may be client-requested only after the entry is unlocked.
- Journal entry IDs are persistent progression keys and must not be renamed after release.
