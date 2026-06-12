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
- Studio pilot persistence requires an allowlisted canary UserId by default.
- Production DataStore mode requires explicit confirmation flags.
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
RequirePilotCanaryUserId = true
PilotCanaryUserIds = { 123456789 }
```

Replace `123456789` with your Roblox UserId.

Start with save-on-leave before enabling autosave.

Never commit pilot-enabled config unless intentionally preparing a controlled test branch.

## Test Case A: Fresh Save

1. Start fresh in Studio with API services enabled.
2. Confirm the log says `mode=StudioDataStorePilot`.
3. Confirm your player is canary eligible.
4. Complete Quest 001 or several objectives.
5. Leave the game to trigger save-on-leave.
6. Confirm a save success log.

## Test Case B: Load Save

1. Rejoin with the same test account.
2. Confirm load success or expected `SaveNotFound` behavior.
3. Verify Quest 001 progress restored.
4. Continue to Episode 1 complete.
5. Leave and confirm save success.

## Test Case C: Episode Complete Load

1. Rejoin again.
2. Verify Episode 1 remains complete.
3. Verify `item_star_core_segment_01` exists.
4. Verify future Star Core segments do not exist.

## Failure Safety

- If load fails, saving should be blocked for that session.
- Do not overwrite with default data after a load failure.
- Check `[ANP Persistence]` logs for load/save codes.
- If a player is not in `PilotCanaryUserIds`, load/save should be skipped.
- Do not log or copy full save payloads into bug reports unless intentionally debugging private test data.

## Cleanup

- Return `PersistenceMode` to `"Mock"`.
- Set `EnableRealDataStore = false`.
- Remove your canary UserId before committing config.
- Confirm normal Studio runs use mock persistence.

## Production Enablement Checklist

- Studio pilot passes with multiple fresh and returning sessions.
- Migration plan is documented.
- Backup and rollback strategy exists.
- Autosave interval is conservative.
- Logs are monitored for load/save failures.
- Rollout starts with a small test group.
- `AllowProductionDataStore` and `ProductionDataStoreConfirm` are enabled only for the production rollout branch.
