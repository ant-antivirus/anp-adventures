# Quest Definitions

## Purpose

This document defines implementation-facing quest records for Episode 1. It does not replace `docs/QUEST_BIBLE.md`; it turns its stable quest content into a validation-ready definition layer.

## Quest Record Schema

```text
QuestDefinition
  QuestId: string
  EpisodeId: string
  ZoneId: string
  ObjectiveIds: array<ObjectiveId>
  ObjectiveDefinitions: map<ObjectiveId, ObjectiveDefinition>
  RewardBundleIds: array<RewardBundleId>
  RequiredCompanionAssists: array<CompanionAssistId>
  SoloSupportMetadata: map

ObjectiveDefinition
  RequiredAmount: number
  ObjectiveText: string
  RequiresObjectiveIds: optional array<ObjectiveId>
  RewardBundleIds: optional array<RewardBundleId>
```

## Episode 1 Quest Records

| QuestId | EpisodeId | ZoneId | ObjectiveIds[] | RewardBundleIds[] | RequiredCompanionAssists[] | SoloSupportMetadata |
| --- | --- | --- | --- | --- | --- | --- |
| `quest_ep01_main_001` | `ep01_lost_star_core` | `zone_ep01_command_center` | `obj_ep01_main_001_001`, `obj_ep01_main_001_002`, `obj_ep01_main_001_003`, `obj_ep01_main_001_004` | `reward_ep01_main_001`, `reward_ep01_teamwork_main_001` | `assist_ep01_main_001_tutorial_prompt`, `assist_ep01_main_001_objective_reminder` | All objectives are single-player interactions; no simultaneous input requirement. |
| `quest_ep01_main_002` | `ep01_lost_star_core` | `zone_ep01_universe_explorer` | `obj_ep01_main_002_001`, `obj_ep01_main_002_002`, `obj_ep01_main_002_003`, `obj_ep01_main_002_004` | `reward_ep01_main_002`, `reward_ep01_teamwork_main_002` | `assist_ep01_main_002_signal_hint`, `assist_ep01_main_002_route_guidance` | Signal search and scan must be completable by one player; Proton can escalate route guidance. |
| `quest_ep01_main_003` | `ep01_lost_star_core` | `zone_ep01_universe_explorer` | `obj_ep01_main_003_001`, `obj_ep01_main_003_002`, `obj_ep01_main_003_003`, `obj_ep01_main_003_004` | `reward_ep01_main_003`, `reward_ep01_teamwork_main_003` | `assist_ep01_main_003_universe_hint`, `assist_ep01_main_003_solo_alignment_support` | Universe alignment must not require simultaneous human inputs; Proton supports solo alignment if co-op inputs exist. |
| `quest_ep01_main_004` | `ep01_lost_star_core` | `zone_ep01_terrain_sandbox` | `obj_ep01_main_004_001`, `obj_ep01_main_004_002`, `obj_ep01_main_004_003`, `obj_ep01_main_004_004` | `reward_ep01_main_004`, `reward_ep01_teamwork_main_004` | `assist_ep01_main_004_flow_hint`, `assist_ep01_main_004_solo_flow_support` | Terrain flow adjustment must have a solo-valid completion state; Proton may support observation or routing. |
| `quest_ep01_main_005` | `ep01_lost_star_core` | `zone_ep01_theos_satellite_center` | `obj_ep01_main_005_001`, `obj_ep01_main_005_002`, `obj_ep01_main_005_003`, `obj_ep01_main_005_004`, `obj_ep01_main_005_optional_001`, `obj_ep01_main_005_optional_002`, `obj_ep01_main_005_optional_003` | `reward_ep01_main_005`, `reward_ep01_optional_005_satellite_imagery`, `reward_ep01_optional_005_flood_monitoring`, `reward_ep01_optional_005_agriculture_monitoring`, `reward_ep01_teamwork_main_005` | `assist_ep01_main_005_calibration_hint`, `assist_ep01_main_005_solo_signal_lock`, `assist_ep01_main_005_imagery_hint`, `assist_ep01_main_005_monitoring_hint` | Satellite calibration and optional education objectives must be solo-completable; optional objectives must not block quest completion. |
| `quest_ep01_main_006` | `ep01_lost_star_core` | `zone_ep01_rocket_mission` | `obj_ep01_main_006_001`, `obj_ep01_main_006_002`, `obj_ep01_main_006_003`, `obj_ep01_main_006_004` | `reward_ep01_main_006`, `reward_ep01_teamwork_main_006` | `assist_ep01_main_006_preflight_hint`, `assist_ep01_main_006_solo_launch_support` | Preflight checks must be sequentially completable by one player; Proton can route and remind. |
| `quest_ep01_main_007` | `ep01_lost_star_core` | `zone_ep01_astronaut_training` | `obj_ep01_main_007_001`, `obj_ep01_main_007_002`, `obj_ep01_main_007_003`, `obj_ep01_main_007_004` | `reward_ep01_main_007`, `reward_ep01_teamwork_main_007` | `assist_ep01_main_007_movement_hint`, `assist_ep01_main_007_balance_support` | Movement and balance challenges must support mobile, gamepad, and PC; Proton provides recovery guidance after repeated failures. |
| `quest_ep01_main_008` | `ep01_lost_star_core` | `zone_ep01_moon_walk` | `obj_ep01_main_008_001`, `obj_ep01_main_008_002`, `obj_ep01_main_008_003`, `obj_ep01_main_008_004`, `obj_ep01_main_008_005` | `reward_ep01_main_008`, `reward_ep01_teamwork_main_008` | `assist_ep01_main_008_low_gravity_hint`, `assist_ep01_main_008_fragment_check`, `assist_ep01_main_008_solo_restoration_support` | Final route, Moon Fragment collection, assembly, and restoration must be completable by one player; fragment ownership validation uses `InventoryService`. |

## Quest Definition Rules

- Optional objectives must be listed in `ObjectiveIds[]` and marked optional in the full quest definition implementation.
- `RequiresObjectiveIds[]` is optional and only locks the objective that declares it; quests are not globally sequential by default.
- `RequiresObjectiveIds[]` entries must refer to objectives in the same quest, must not duplicate, and must not require the objective itself.
- Objective-level `RewardBundleIds[]` are allowed only for server-side objective rewards that still route through `RewardService`.
- Teamwork reward bundles are optional and must not be listed as required completion rewards.
- Required companion assists listed here must resolve to companion support definitions before a quest is considered valid.
