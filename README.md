# ANP Adventures

## Project Overview

ANP Adventures is a family-friendly Roblox adventure prototype where players explore, discover, and learn through story-driven quests.

Current focus: Episode 1 playable prototype with minimal player feedback and quest tracker UI.

## Current Status

- Episode 1: Lost Star Core
- Quest 001-008 implemented
- Episode 1 finale restores `item_star_core_segment_01`
- Early discovery anti-stuck fix implemented
- Phase 3H playtest polish implemented
- Phase 4A minimal player feedback UI implemented
- Phase 4B object state polish implemented
- Phase 4C quest tracker UI implemented
- Phase 4D compact skeleton quest test track implemented
- Phase 4E EP1 MVP QA pass implemented
- Phase 5A save readiness foundation implemented
- Phase 5B safe DataStore adapter implemented
- Real DataStore persistence disabled by default
- Studio verification pending for Phase 5B

## How To Run

1. Open the Rojo project.
2. Sync with Roblox Studio.
3. Run the experience in Studio.
4. Watch Server Output for smoke test results.

## Expected Studio Smoke Test Lines

```text
[ANP DiscoveryBridgeRegressionSmokeTest] Discovery bridge regression smoke test passed.
[ANP Phase3G4SmokeTest] Phase 3G-4 smoke test passed.
[ANP Phase3HPlaytestPolishSmokeTest] Phase 3H playtest polish smoke test passed.
[ANP Phase4AFeedbackSmokeTest] Phase 4A feedback smoke test passed.
[ANP Phase4BObjectStateSmokeTest] Phase 4B object state smoke test passed.
[ANP Phase4CQuestTrackerSmokeTest] Phase 4C quest tracker smoke test passed.
[ANP Phase4EFullEP1MvpSmokeTest] Phase 4E full EP1 MVP smoke test passed.
[ANP Phase5ASaveReadinessSmokeTest] Phase 5A save readiness smoke test passed.
[ANP Phase5BDataStoreAdapterSmokeTest] Phase 5B DataStore adapter smoke test passed.
[ANP SmokeTestSummary]
All Studio smoke tests passed.
```

## Quest Tracker

Phase 4C adds a small display-only quest tracker panel. The server sends `QuestTracker` payloads through the existing `PlayerFeedbackEvent`; the client only displays the current quest, current objective, progress text, and hint text.

The client does not calculate quest progress, grant rewards, or mutate player state.

## Skeleton Test Track

The current Studio skeleton world uses a compact developer test-track layout for faster Episode 1 playtesting. Quest markers are arranged in short rows from start to objectives to completion.

This is not final world art. IDs and progression logic remain unchanged.

Dev labels are compact and configurable so the test track remains readable without covering nearby objects.

## MVP Playtest Checklist

Use `docs/EP1_MVP_PLAYTEST_CHECKLIST.md` for the current internal Episode 1 playtest pass.

## Save Readiness

Phase 5A adds save schema, serialization, validation, and mock in-memory persistence for tests. It does not use real Roblox persistence and does not autosave live players yet.

Phase 5B adds a server-side DataStore adapter behind config. Real DataStore load/save, autosave, and shutdown flush remain disabled by default; Studio uses mock persistence unless explicitly configured otherwise.

See `docs/SAVE_SYSTEM_PLAN.md`.

## Logging

`LogConfig` controls developer log noise.

Normal mode keeps bootstrap summary, smoke test pass/fail lines, warnings/errors, prompt failures, and guidance visible. It suppresses analytics spam and prompt success spam.

Use Verbose mode for deeper debugging when detailed analytics and prompt success logs are needed.

## Current Non-Goals

- No DataStore persistence
- No RemoteFunctions
- No Marketplace / monetization
- No trading
- No party system
- No pet system
- No cosmetic system
- No CompanionService implementation
