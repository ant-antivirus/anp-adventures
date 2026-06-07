# ANP Adventures World Object Contract

This contract defines the minimum Workspace object structure needed to connect server systems to world placeholders. Phase 3C establishes registration and validation only.

## Required Workspace Structure

```text
Workspace
+-- ANP_World
    +-- Zones
    +-- SpawnPoints
    +-- InteractionPoints
    +-- DiscoveryPoints
    +-- NPCMarkers
```

Required folder names are exact and case-sensitive.

## Naming Conventions

- World root must be named `ANP_World`.
- Placeholder parts should use stable ID-based names.
- Zone objects should be named `Zone_<ZoneId>`.
- Spawn points should be named `Spawn_<SpawnPointId>`.
- Interaction points should be named `Interaction_<InteractionId>`.
- Discovery points should be named `Discovery_<DiscoveryId>`.
- NPC markers should be named `NPCMarker_<CharacterId>`.

## Required Attributes

Zone objects:
- `ZoneId`

Spawn points:
- `SpawnPointId`
- `ZoneId`

Interaction points:
- `InteractionId`
- `QuestId`
- `ObjectiveId`
- `ZoneId`

Discovery points:
- `DiscoveryId`
- `ZoneId`

NPC markers:
- `CharacterId`
- `ZoneId`

## Zone Object Rules

- Zone objects must be descendants of `Workspace.ANP_World.Zones`.
- `ZoneId` must exist in `ZoneDefinitions`.
- Episode 1 requires one zone object for each Episode 1 zone.
- Zone placeholders may be simple anchored parts.

## Spawn Point Rules

- Spawn points must be descendants of `Workspace.ANP_World.SpawnPoints`.
- `SpawnPointId` must be unique.
- `ZoneId` must exist in `ZoneDefinitions`.
- Phase 3C spawn points are registry markers only and must not move characters.

## Interaction Point Rules

- Interaction points must be descendants of `Workspace.ANP_World.InteractionPoints`.
- `InteractionId` must be unique.
- `QuestId` must exist in `QuestDefinitions`.
- `ObjectiveId` must exist in the referenced quest definition.
- `ZoneId` must exist in `ZoneDefinitions`.
- Phase 3C interaction points must not trigger quest progress.

## Discovery Point Rules

- Discovery points must be descendants of `Workspace.ANP_World.DiscoveryPoints`.
- `DiscoveryId` must be unique.
- `DiscoveryId` must exist in `DiscoveryDefinitions`.
- `ZoneId` must match the discovery definition `ZoneId`.
- Phase 3C discovery points must not grant rewards.

## NPC Marker Rules

- NPC markers must be descendants of `Workspace.ANP_World.NPCMarkers`.
- `CharacterId` must exist in `CharacterConfig`.
- `CharacterId` marker entries must be unique in Phase 3C.
- NPC markers are placement markers only, not NPC models or dialogue systems.

## Placeholder Object Rules

- Placeholders may be simple anchored Parts.
- Placeholders may be semi-transparent or invisible.
- Placeholders must include required attributes.
- Placeholder creation must be idempotent.
- Placeholder creation must not delete or overwrite user-built objects.

## Allowed In Phase 3C

- Creating the required Workspace folders in Studio.
- Creating placeholder Parts in Studio.
- Setting required attributes.
- Registering world objects.
- Validating world object contracts.
- Reporting validation summaries.

## Not Allowed In Phase 3C

- Final map art.
- NPC models.
- Dialogue UI.
- Client UI.
- Remotes.
- DataStore persistence.
- Full InteractionService.
- Quest progress triggers.
- Reward grants.
- Character movement or teleportation.
- Workspace scanning that mutates player data.
