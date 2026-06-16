# DataStore Pilot Test Log

Use this template when running a controlled Studio DataStore pilot. Do not commit pilot-enabled config or personal canary UserIds.

## Sanitized Phase 6H Pilot Result

- Roblox account: Atom_Neutron
- UserId: [masked]
- PersistenceMode tested locally: `StudioDataStorePilot`
- DataStoreName: `ANPAdventures_PlayerData_StudioPilot_v1`
- Load result: Passed
- Save result: Passed
- Evidence codes observed:
  - `DataStoreSaveLoaded`
  - `PlayerLoaded`
  - `DataStoreSaveStored`
  - `PlayerSaved`
- Controlled Studio DataStore Pilot: Passed

Notes:

- Pilot-enabled config was local-only.
- Committed config must remain `PersistenceMode = "Mock"`.
- Committed canary UserId list must remain empty.
- Production DataStore was not enabled.

## 1. Test Environment

- Date:
- Roblox account:
- UserId:
- Place:
- Studio API Services enabled:
- PersistenceMode:
- DataStoreName:

## 2. Test A: Fresh Save

- Join with no existing pilot save.
- Confirm StartupHealth and persistence logs show Studio pilot mode.
- Confirm smoke tests skipped with `SmokeTestGate: RealDataStoreEnabled`.
- Confirm `Workspace.ANP_World` exists or skeleton world bootstrap log appeared.
- Confirm quest prompts appear before starting the playtest.
- Complete Quest 001.
- Leave game.
- Expected: Save success.
- Result:
- Notes:

## 3. Test B: Load Partial Progress

- Rejoin.
- Expected: Quest 001 progress restored.
- Continue to Quest 002 or more.
- Leave game.
- Expected: Save success.
- Result:
- Notes:

## 4. Test C: Full EP1 Completion Persistence

- Complete EP1.
- Leave game.
- Rejoin.
- Expected:
  - Episode 1 complete restored.
  - `item_star_core_segment_01` restored.
  - No future Star Core segment granted.
- Result:
- Notes:

## 5. Safety Checks

- Non-canary player cannot save/load.
- Load failure blocks save.
- Production DataStore is not used.
- Config reverted before commit.
- Smoke tests were skipped only because real DataStore was enabled.
- Skeleton world bootstrap did not overwrite an existing manual world.

## 6. Final Decision

- Pilot passed? Yes, controlled Studio pilot passed with sanitized result above.
- Blockers? None for EP1 RC pause.
- Follow-up issues? Production DataStore enablement remains future work and must require a separate explicit phase.
