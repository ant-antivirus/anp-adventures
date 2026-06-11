# ANP Adventures

## Project Overview

ANP Adventures is a family-friendly Roblox adventure prototype where players explore, discover, and learn through story-driven quests.

Current focus: Episode 1 server-side playable prototype.

## Current Status

- Episode 1: Lost Star Core
- Quest 001-008 implemented
- Episode 1 finale restores `item_star_core_segment_01`
- Early discovery anti-stuck fix implemented
- Phase 3H playtest polish implemented
- Studio verification pending

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
[ANP SmokeTestSummary]
All Studio smoke tests passed.
```

## Logging

`LogConfig` controls developer log noise.

Normal mode keeps bootstrap summary, smoke test pass/fail lines, warnings/errors, and prompt failures visible. It suppresses analytics spam, prompt success spam, and guidance spam.

Use Verbose mode for deeper debugging when detailed analytics, prompt success, and guidance logs are needed.

## Current Non-Goals

- No UI
- No DataStore persistence
- No RemoteEvents / RemoteFunctions
- No Marketplace / monetization
- No trading
- No party system
- No pet system
- No cosmetic system
- No CompanionService implementation
