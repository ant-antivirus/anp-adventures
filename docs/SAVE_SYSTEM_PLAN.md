# ANP Adventures Save System Plan

## Phase 5A: Save Readiness Foundation

Phase 5A prepares player data for future persistence without using real Roblox persistence.

Implemented foundation:

- `SaveSchema` defines save version `1` and stable sections.
- `SaveSerializationService` builds, validates, and applies sanitized save payloads.
- `MockPersistenceService` stores cloned payloads in memory for tests.
- `SaveService` provides a server-only facade for manual/test save and load calls.
- `Phase5ASaveReadinessSmokeTest` verifies fresh, partial quest, and full Episode 1 round trips.

Phase 5A does not save automatically and does not load real players from persistent storage.

## Server Ownership Rules

- The server owns save payload creation.
- Clients never send save payloads.
- Save payloads are generated from `PlayerDataService` only.
- Save payloads are validated before apply.
- Save payloads are versioned.
- Phase 5A uses mock persistence only.

## Persisted Sections

Save payloads include stable player progression sections:

- Profile
- Progression
- Episodes
- Quests
- Inventory
- Discoveries
- Journal
- Lore
- Badges
- Memories
- Zones
- Companion
- Settings
- Reward claim idempotency markers
- Lifetime analytics summary

## Not Persisted Yet

Runtime-only state is excluded:

- Session stats
- UI state
- Feedback popups
- Prompt state
- Quest tracker display payloads
- Studio skeleton objects
- Temporary cooldowns

## Future Phase 5B

Phase 5B can add a real persistence adapter behind `SaveService`.

Planned work:

- Real Roblox save adapter.
- Load on player join.
- Save on player leaving.
- Autosave interval.
- Retry and backoff policy.
- Migration handling.
- Rollback and recovery tests.
