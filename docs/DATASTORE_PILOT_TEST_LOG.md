# DataStore Pilot Test Log

Use this template when running a controlled Studio DataStore pilot. Do not commit pilot-enabled config or personal canary UserIds.

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

## 6. Final Decision

- Pilot passed?
- Blockers?
- Follow-up issues?
