# Content Build Pipeline

## Purpose

This document describes the production content flow from documentation-backed definitions to runtime server validation.

## Pipeline

```text
Definitions
  ↓
Validation
  ↓
Packaging
  ↓
Runtime Load
  ↓
Server Validation
```

## Definitions

Definitions are the source records for episodes, zones, quests, rewards, discoveries, items, journal entries, lore entries, companion assists, ranks, badges, and remotes.

Definition files must use stable IDs and must not rely on player-facing text for logic.

## Validation

Validation checks definitions before they are packaged.

Required validation includes:

- Duplicate ID detection.
- Broken reference detection.
- Reward reference validation.
- Quest solo support validation.
- Companion assist validation.
- Episode completion validation.
- Journal and lore unlock validation.
- Future episode expansion validation.

Validation failures must block packaging.

## Packaging

Packaging converts validated definitions into Roblox-friendly content modules.

Packaging output should be deterministic and grouped by content type:

- Episode definitions.
- Quest definitions.
- Reward definitions.
- Discovery definitions.
- Item definitions.
- Zone definitions.
- Journal definitions.
- Lore definitions.

Packaged content must not include raw authoring-only notes that are not needed at runtime.

## Runtime Load

Server startup loads packaged definitions before player data is accepted for gameplay.

Recommended order:

1. Load constants and config.
2. Load packaged definitions.
3. Validate packaged definition integrity.
4. Initialize services.
5. Load player data.
6. Send state snapshots to clients.

Runtime definition loading must fail closed. If required definitions are missing, the affected episode should not become active.

## Server Validation

Gameplay services validate all player actions against loaded definitions and current server-authoritative player state.

Server validation must ensure:

- Requested IDs exist.
- Player has required unlock state.
- Objective progress is possible.
- Rewards are server-derived.
- Duplicate grants are skipped.
- Solo assist is definition-approved.
- Analytics payloads use stable IDs and sanitized aggregate data only.
