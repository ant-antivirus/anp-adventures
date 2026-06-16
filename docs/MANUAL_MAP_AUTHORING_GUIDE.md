# Manual Map Authoring Guide

Phase 7A prepares ANP Adventures for Studio-authored EP1 maps without replacing the current skeleton test track.

The handcrafted map is not implemented in this phase. This guide defines the contract future map work must follow.

Phase 7C adds the builder handoff package. Read `DECORATION_HANDOFF_GUIDE.md`, `EP1_DECORATION_CHECKLIST.md`, `MAP_NAMING_CONVENTIONS.md`, and `STUDIO_MAP_BACKUP_GUIDE.md` before editing the real map.

## World Build Modes

`WorldBuildConfig.BuildMode` controls startup behavior:

- `Skeleton`: current dev/test mode. Studio may build the compact skeleton world when `Workspace.ANP_World` is missing.
- `Manual`: future authoring mode. Startup must not auto-build or overwrite the handcrafted map.

Default remains `Skeleton` so existing smoke tests and fast playtesting continue to work.

When `BuildMode = "Manual"`, the full Studio smoke suite is skipped with `SmokeTestGate: WorldBuildModeManual` because many smoke tests intentionally assert the committed Skeleton/default workflow. Manual map validation and prompt binding still run during startup so the Studio-authored map can be checked and playtested.

Manual mode is report-only. If required gameplay objects are missing, startup logs list the missing or invalid requirements with codes, IDs, expected values, and object paths where available. Manual mode must not auto-create skeleton gameplay objects or overwrite `Workspace.ANP_World`.

## Recommended Studio Structure

```text
Workspace
  ANP_World
    Zones
      zone_ep01_command_center
        Gameplay
        Decor
        Lighting
      zone_ep01_universe_explorer
        Gameplay
        Decor
        Lighting
      zone_ep01_terrain_sandbox
        Gameplay
        Decor
        Lighting
      zone_ep01_theos_satellite_center
        Gameplay
        Decor
        Lighting
      zone_ep01_rocket_mission
        Gameplay
        Decor
        Lighting
      zone_ep01_astronaut_training
        Gameplay
        Decor
        Lighting
      zone_ep01_moon_walk
        Gameplay
        Decor
        Lighting
```

Each zone folder may be named by its `ZoneId` or may carry a `ZoneId` attribute. The validator expects active EP1 zone folders and a `Gameplay` folder under each one.

Skeleton/dev validators also accept zone folders named by `ZoneId`, so switching between Manual and Skeleton mode does not fail only because a zone folder lacks a duplicate `ZoneId` attribute.

## Gameplay Objects

Gameplay objects must use attributes. Runtime IDs stay English and stable.

- Use `InteractionId` to bind server interaction logic.
- Use `ZoneId` to identify the owning zone.
- Use `ObjectType` to identify the object role, such as `QuestStart`, `QuestObjective`, or `QuestComplete`.
- Use `DisplayName` for human-readable Thai display copy when useful.
- Keep a reachable prompt host:
  - preferred: child `PromptPart`
  - model fallback: `PrimaryPart`
  - direct fallback: gameplay object is a `BasePart`

Manual map objects should not contain scripts that complete quests, grant rewards, or save data. The server services remain authoritative.

## Decor Objects

Decor belongs in `Decor` folders and must not contain gameplay IDs:

- `InteractionId`
- `QuestId`
- `ObjectiveId`
- `RewardId`

Decor should not block prompt reachability. Keep prompt parts visible and reachable.

## Locked EP1 Content

Do not rename, delete, or reuse locked EP1 runtime IDs. This includes:

- Quest IDs
- Objective IDs
- Interaction IDs
- Reward IDs
- Item IDs
- Zone IDs

Quest 008 must keep five required objective routes. EP1 final reward semantics must remain Star Core Segment 01 only.

## Validation

Run the Studio smoke tests after map edits. `MapAuthoringValidator` checks:

- `Workspace.ANP_World` and `Zones` exist.
- Active EP1 zones exist.
- Each zone has `Gameplay`.
- Gameplay objects carry valid attributes.
- No duplicate `InteractionId`.
- Required start, objective, and complete interactions are mapped.
- Decor folders do not contain gameplay IDs.
- Prompt hosts exist and can receive server-owned `ProximityPrompt` instances.

Manual mode validation is read-only and does not mutate the map.
