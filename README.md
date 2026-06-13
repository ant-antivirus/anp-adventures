# ANP Adventures

## Project Overview

ANP Adventures is a family-friendly Roblox adventure prototype where players explore, discover, and learn through story-driven quests.

Current focus: Episode 1 playable prototype with player feedback, quest tracker UI, and MVP skeleton-world presentation.

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
- Phase 5C controlled live persistence pilot implemented
- Phase 5D Studio DataStore pilot safety polish implemented
- Phase 6A player-facing UI polish implemented
- Phase 6B EP1 visual world presentation pass implemented
- Phase 6C first-time onboarding flow implemented
- Phase 6D EP1 content lock and final MVP hardening implemented
- Phase 6E Thai player-facing localization implemented
- Real DataStore persistence disabled by default
- Mock persistence remains the default Studio mode

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
[ANP Phase5CControlledPersistencePilotSmokeTest] Phase 5C controlled persistence pilot smoke test passed.
[ANP Phase5DStudioDataStorePilotSafetySmokeTest] Phase 5D Studio DataStore pilot safety smoke test passed.
[ANP Phase6APlayerFacingUISmokeTest] Phase 6A player-facing UI smoke test passed.
[ANP Phase6BVisualWorldPresentationSmokeTest] Phase 6B visual world presentation smoke test passed.
[ANP Phase6COnboardingFlowSmokeTest] Phase 6C onboarding flow smoke test passed.
[ANP Phase6DEP1ContentLockSmokeTest] Phase 6D EP1 content lock smoke test passed.
[ANP Phase6DEP1FinalMvpRegressionSmokeTest] Phase 6D EP1 final MVP regression smoke test passed.
[ANP Phase6EThaiLocalizationSmokeTest] Phase 6E Thai localization smoke test passed.
[ANP SmokeTestSummary]
All Studio smoke tests passed.
```

## Quest Tracker

Phase 4C adds a small display-only quest tracker panel. The server sends `QuestTracker` payloads through the existing `PlayerFeedbackEvent`; the client only displays the current quest, current objective, progress text, and hint text.

The client does not calculate quest progress, grant rewards, or mutate player state.

Phase 6A polishes the display-only tracker, notification stack, and Episode Complete banner. UI still does not control gameplay, rewards, save/load, or inventory state.

Phase 6C adds server-owned first-time onboarding payloads for welcome text, Episode 1 goal, marker legend, and first quest guidance. The client only displays these payloads.

Phase 6E sets EP1 MVP player-facing text to Thai. Runtime IDs, enum/state values, RemoteEvent field names, and save schema fields remain English/stable.

## Skeleton Test Track

The current Studio skeleton world uses a compact developer test-track layout for faster Episode 1 playtesting. Quest markers are arranged in short rows from start to objectives to completion.

Phase 6B adds simple decorative zone platforms, route strips, marker presentation parts, and lightweight landmarks. This is not final world art. IDs and progression logic remain unchanged.

Dev labels are compact and configurable so the test track remains readable without covering nearby objects.

## MVP Playtest Checklist

Use `docs/EP1_MVP_PLAYTEST_CHECKLIST.md` for the current internal Episode 1 playtest pass.

Use `docs/EP1_UI_PLAYTEST_CHECKLIST.md` for the Phase 6A UI presentation pass.

Use `docs/EP1_WORLD_PRESENTATION_CHECKLIST.md` for the Phase 6B skeleton-world presentation pass.

Use `docs/EP1_ONBOARDING_PLAYTEST_CHECKLIST.md` for the Phase 6C first-time onboarding pass.

Use `docs/EP1_FINAL_MVP_CHECKLIST.md` for the Phase 6D final MVP hardening pass.

See `docs/EP1_CONTENT_LOCK_MANIFEST.md` for locked Episode 1 runtime IDs and reward contracts. See `docs/EP1_MVP_RELEASE_NOTES_DRAFT.md` for the internal milestone summary.

Use `docs/EP1_THAI_LOCALIZATION_CHECKLIST.md` for Thai text and UI fit verification.

## Save Readiness

Phase 5A adds save schema, serialization, validation, and mock in-memory persistence for tests. It does not use real Roblox persistence and does not autosave live players yet.

Phase 5B adds a server-side DataStore adapter behind config. Phase 5C adds persistence mode validation, pilot DataStore naming, session diagnostics, and a runbook for controlled Studio API testing. Phase 5D adds canary UserId gating and pilot status/session reports. Real DataStore load/save, autosave, and shutdown flush remain disabled by default; Studio uses mock persistence unless explicitly configured otherwise.

See `docs/SAVE_SYSTEM_PLAN.md` and `docs/DATASTORE_PILOT_RUNBOOK.md`.

## Logging

`LogConfig` controls developer log noise.

Normal mode keeps bootstrap summary, smoke test pass/fail lines, warnings/errors, prompt failures, and guidance visible. It suppresses analytics spam and prompt success spam.

Use Verbose mode for deeper debugging when detailed analytics and prompt success logs are needed.

## Current Non-Goals

- No production DataStore persistence enabled by default
- No RemoteFunctions
- No Marketplace / monetization
- No trading
- No party system
- No pet system
- No cosmetic system
- No CompanionService implementation
- No active EP2 gameplay
