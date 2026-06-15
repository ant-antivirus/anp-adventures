# Manual Map Authoring Guide

Phase 7A prepares ANP Adventures for Studio-authored EP1 maps without replacing the current skeleton test track.

The handcrafted map is not implemented in this phase. This guide defines the contract future map work must follow.

## World Build Modes

`WorldBuildConfig.BuildMode` controls startup behavior:

- `Skeleton`: current dev/test mode. Studio may build the compact skeleton world when `Workspace.ANP_World` is missing.
- `Manual`: future authoring mode. Startup must not auto-build or overwrite the handcrafted map.

Default remains `Skeleton` so existing smoke tests and fast playtesting continue to work.

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

## Gameplay Objects

Gameplay objects must use attributes. Runtime IDs stay English and stable.

- Use `InteractionId` to bind server interaction logic.
- Use `ZoneId` to identify the owning zone.
- Use `ObjectType` to identify the object role, such as `QuestStart`, `QuestObjective`, or `QuestComplete`.
- Use `DisplayName` for human-readable Thai display copy when useful.
- Keep a reachable `BasePart` or child `PromptPart` for prompt attachment.

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

Manual mode validation is read-only and does not mutate the map.
