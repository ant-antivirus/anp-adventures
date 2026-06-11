# ANP Adventures

## Project Overview

ANP Adventures is a family-friendly Roblox adventure prototype where players explore, discover, and learn through story-driven quests.

Current focus: Episode 1 playable prototype with minimal player feedback UI.

## Current Status

- Episode 1: Lost Star Core
- Quest 001-008 implemented
- Episode 1 finale restores `item_star_core_segment_01`
- Early discovery anti-stuck fix implemented
- Phase 3H playtest polish implemented
- Phase 4A minimal player feedback UI implemented
- Phase 4B object state polish implemented
- Studio verification pending for Phase 4B

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
[ANP SmokeTestSummary]
All Studio smoke tests passed.
```

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
