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
PilotCanaryUserIds = { YOUR_ROBLOX_USER_ID }
```

Replace `YOUR_ROBLOX_USER_ID` with your Roblox UserId in your local test copy only.

Start with save-on-leave before enabling autosave.

Never commit pilot-enabled config unless intentionally preparing a controlled test branch.

Keep `SmokeTestConfig.lua` at its default values. When `EnableRealDataStore = true`,
Studio smoke tests skip automatically because several normal smoke tests assert safe mock defaults.
`WorldBootstrapConfig.lua` stays at its default values too. If `Workspace.ANP_World` is missing in Studio,
Bootstrap builds the skeleton EP1 world before prompt binding so manual quest gameplay can run without smoke tests.

The expected pilot log is:

```text
[ANP StartupHealth] SmokeTests: false
[ANP StartupHealth] SmokeTestGate: RealDataStoreEnabled
[ANP WorldBootstrap] Built skeleton world for Studio pilot/dev playtest.
[ANP SmokeTests] Skipped reason=RealDataStoreEnabled
```

Do not permanently set `RunStudioSmokeTests = false`, and do not set
`AllowSmokeTestsDuringRealDataStorePilot = true` unless debugging a specific smoke test issue.

Before committing any work after a pilot, revert these values:

```lua
PersistenceMode = "Mock"
EnableRealDataStore = false
EnableLoadOnPlayerAdded = false
EnableSaveOnPlayerRemoving = false
EnableBindToCloseSave = false
EnableAutosave = false
PilotCanaryUserIds = {}
```

Record manual pilot results in `docs/DATASTORE_PILOT_TEST_LOG.md`.

## Phase 6H Result

The controlled Studio DataStore pilot passed with the sanitized result recorded in `docs/DATASTORE_PILOT_TEST_LOG.md`.

Committed defaults remain safe:

- `PersistenceMode = "Mock"`
- `EnableRealDataStore = false`
- `PilotCanaryUserIds = {}`
- Production DataStore remains blocked.

After reverting to Mock mode, normal Studio smoke tests should run again and report:

```text
[ANP StartupHealth] SmokeTests: true
[ANP StartupHealth] SmokeTestGate: Enabled
[ANP SmokeTestSummary]
All Studio smoke tests passed.
```

## Test Case A: Fresh Save

1. Start fresh in Studio with API services enabled.
2. Confirm the log says `mode=StudioDataStorePilot`.
3. Confirm `SmokeTestGate: RealDataStoreEnabled` and smoke tests are skipped.
4. Confirm `Workspace.ANP_World` exists or the log says the skeleton world was built.
5. Confirm prompts appear on the compact EP1 route.
6. Confirm your player is canary eligible.
7. Complete Quest 001 or several objectives.
8. Leave the game to trigger save-on-leave.
9. Confirm a save success log.

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
