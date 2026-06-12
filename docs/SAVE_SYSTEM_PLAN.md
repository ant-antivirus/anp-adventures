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

## Phase 5B: Safe DataStore Adapter

Phase 5B adds a real persistence adapter behind `SaveService`, but keeps it disabled by default.

Implemented adapter readiness:

- `PersistenceConfig` controls real persistence, lifecycle hooks, autosave, and shutdown save.
- `DataStorePersistenceService` wraps Roblox `DataStoreService` with bounded retry/backoff.
- `SaveService` selects mock or DataStore adapter from config.
- Default Studio behavior remains mock-only.
- Load failure blocks later saves by default so default data does not overwrite an existing cloud save.

Default disabled settings:

- `EnableRealDataStore = false`
- `EnableLoadOnPlayerAdded = false`
- `EnableSaveOnPlayerRemoving = false`
- `EnableBindToCloseSave = false`
- `EnableAutosave = false`

Optional live testing later:

1. Enable Studio API access in Roblox Studio game settings if needed.
2. Set `EnableRealDataStore = true`.
3. Set `EnableLoadOnPlayerAdded = true`.
4. Set `EnableSaveOnPlayerRemoving = true`.
5. Test with a controlled account before production data.

Future hardening:

- Migration handling.
- Save budgeting and telemetry.
- Rollback and recovery tests.
- Production rollout checklist.

## Phase 5C: Controlled Live Persistence Pilot

Phase 5C adds a controlled pilot layer for testing real Roblox DataStore persistence in a dev environment without making real persistence the default.

Implemented pilot controls:

- `PersistenceMode` defaults to `Mock`.
- Supported modes are `Mock`, `StudioDataStorePilot`, and `ProductionDataStore`.
- `StudioPilotDataStoreName` is separate from `ProductionDataStoreName`.
- `PersistenceConfig.Validate` rejects unsafe combinations before lifecycle save/load is used.
- `SaveService` tracks server-only persistence session state for load/save diagnostics.
- Load failure still blocks later saves by default to avoid overwriting cloud saves with default data.

Default safety remains:

- `EnableRealDataStore = false`
- `EnableLoadOnPlayerAdded = false`
- `EnableSaveOnPlayerRemoving = false`
- `EnableBindToCloseSave = false`
- `EnableAutosave = false`
- `AllowProductionDataStore = false`
- `AllowSaveAfterLoadFailure = false`

Use `docs/DATASTORE_PILOT_RUNBOOK.md` for manual Studio pilot steps. Production DataStore rollout remains a future step after pilot verification, migration planning, and conservative monitoring.
