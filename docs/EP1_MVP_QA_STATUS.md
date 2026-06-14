# EP1 MVP QA Status

## Current Status

EP1 MVP internal release candidate preparation.

Release readiness: Pending Phase 6G Studio smoke confirmation.

## Passed Automated Coverage

The following smoke tests are part of the expected Studio pass:

- `Phase4EFullEP1MvpSmokeTest`
- `Phase5ASaveReadinessSmokeTest`
- `Phase5BDataStoreAdapterSmokeTest`
- `Phase5CControlledPersistencePilotSmokeTest`
- `Phase5DStudioDataStorePilotSafetySmokeTest`
- `Phase6APlayerFacingUISmokeTest`
- `Phase6BVisualWorldPresentationSmokeTest`
- `Phase6COnboardingFlowSmokeTest`
- `Phase6DEP1ContentLockSmokeTest`
- `Phase6DEP1FinalMvpRegressionSmokeTest`
- `Phase6EThaiLocalizationSmokeTest`
- `Phase6FEP1FinalQASmokeTest`
- `Phase6GEP1ReleaseCandidateSmokeTest`

## QA Status Labels

| Area | Status | Notes |
| --- | --- | --- |
| Automated smoke coverage | Pending latest Studio confirmation | Phase 6G must pass before RC sign-off. |
| Manual QA | Passed | Latest gameplay manual playthrough completed Quest 001 through Quest 008 successfully. |
| Thai localization | Passed | Thai player-facing copy is active; continue watching for UI fit issues during RC checks. |
| Persistence default safety | Passed automated coverage | Real DataStore remains disabled by default. |
| DataStore live pilot | Not started | Separate canary-run procedure only. |
| Release candidate | Pending | Waiting for Phase 6G Studio smoke confirmation. |

## Manual QA Result

- Manual gameplay playthrough passed from Quest 001 to Quest 008.
- Quest 008 finale and `/5` tracker progress were included in the playthrough.
- Episode 1 completion and Star Core Segment 01 restoration were confirmed.
- Real DataStore pilot has not started.
- Production DataStore remains disabled.

## Known Intentionally Missing

- Inventory UI.
- Shop and monetization.
- Social hub.
- EP2 active gameplay.
- Production DataStore enablement.
- Final map art.
- Final audio/VFX.

## Release Readiness Labels

- Not started
- In progress
- Passed
- Blocked

Current label: Pending Phase 6G Studio smoke confirmation.
