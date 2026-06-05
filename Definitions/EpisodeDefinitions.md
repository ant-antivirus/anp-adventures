# Episode Definitions

## Purpose

This document defines implementation-facing episode records derived from the existing ANP Adventures canon. It preserves existing IDs and supports future episode expansion through keyed episode records rather than root save schema changes.

## Episode Record Schema

```text
EpisodeDefinition
  EpisodeId: string
  Title: string
  Zones: array<ZoneId>
  QuestIds: array<QuestId>
  CompletionRequirements: array<Requirement>
  RewardBundleIds: array<RewardBundleId>
```

## Episode Records

| EpisodeId | Title | Zones[] | QuestIds[] | CompletionRequirements[] | RewardBundleIds[] |
| --- | --- | --- | --- | --- | --- |
| `ep01_lost_star_core` | The Lost Star Core | `zone_ep01_command_center`, `zone_ep01_universe_explorer`, `zone_ep01_terrain_sandbox`, `zone_ep01_theos_satellite_center`, `zone_ep01_rocket_mission`, `zone_ep01_astronaut_training`, `zone_ep01_moon_walk` | `quest_ep01_main_001`, `quest_ep01_main_002`, `quest_ep01_main_003`, `quest_ep01_main_004`, `quest_ep01_main_005`, `quest_ep01_main_006`, `quest_ep01_main_007`, `quest_ep01_main_008` | Complete all Episode 1 main quests; own `item_ep01_fragment_universe`; own `item_ep01_fragment_earth`; own `item_ep01_fragment_theos`; own `item_ep01_fragment_rocket`; own `item_ep01_fragment_moon`; restore `item_star_core_segment_01` | `reward_ep01_main_001`, `reward_ep01_main_002`, `reward_ep01_main_003`, `reward_ep01_main_004`, `reward_ep01_main_005`, `reward_ep01_main_006`, `reward_ep01_main_007`, `reward_ep01_main_008` |

## Expansion Rule

Future episode records must add new episode IDs, zone IDs, quest IDs, rewards, discoveries, journal entries, lore entries, and segment item rewards through definition maps. They must not add new root fields to `PlayerData`.
