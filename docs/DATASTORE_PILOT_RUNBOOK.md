# DataStore Pilot Runbook

## Purpose

This runbook describes a controlled test of real Roblox DataStore persistence for ANP Adventures.

The pilot is not the production default. Normal Studio runs use mock persistence.

## Default Safety

- Real DataStore is disabled by default.
- Mock persistence is the default adapter.
- Load on player join is disabled by default.
- Save on player leave is disabled by default.
- Autosave and BindToClose save are disabled by default.
- Client code never sends save payloads or decides save timing.

## Studio Setup

1. Use a test account.
2. Enable Studio access to API services in Roblox Studio game settings.
3. Use `StudioPilotDataStoreName`, not the production DataStore name.
4. Do not test against production player data first.

## Temporary Local Pilot Config

Temporarily set these flags in `PersistenceConfig.lua` for a local pilot branch or throwaway test copy:

```lua
PersistenceMode = "StudioDataStorePilot"
EnableRealDataStore = true
AllowStudioRealDataStore = true
EnableLoadOnPlayerAdded = true
EnableSaveOnPlayerRemoving = true
EnableBindToCloseSave = true
EnableAutosave = false
```

Start with save-on-leave before enabling autosave.

## Test Steps

1. Start fresh in Studio with API services enabled.
2. Complete Quest 001 or several objectives.
3. Leave the game to trigger save-on-leave.
4. Rejoin and verify progress restored.
5. Complete Episode 1.
6. Leave and rejoin again.
7. Verify Episode 1 remains complete and `item_star_core_segment_01` is present.

## Failure Safety

- If load fails, saving should be blocked for that session.
- Do not overwrite with default data after a load failure.
- Check `[ANP Persistence]` logs for load/save codes.
- Do not log or copy full save payloads into bug reports unless intentionally debugging private test data.

## Production Enablement Checklist

- Studio pilot passes with multiple fresh and returning sessions.
- Migration plan is documented.
- Backup and rollback strategy exists.
- Autosave interval is conservative.
- Logs are monitored for load/save failures.
- Rollout starts with a small test group.
- `AllowProductionDataStore` is enabled only for the production rollout branch.
