# EP1 MVP QA Status

## Current Status

EP1 MVP internal release candidate sign-off.

Release readiness: Passed / Ready for clean pause before final handcrafted map work.

## Passed Automated Coverage

The following smoke tests are part of the expected Studio pass:

- `Phase4EFullEP1MvpSmokeTest`
- `Phase5ASaveReadinessSmokeTest`
- `Phase5BDataStoreAdapterSmokeTest`
- `Phase5CControlledPersistencePilotSmokeTest`
- `Phase5DStudioDataStorePilotSafetySmokeTest`
- `Phase5EControlledDataStorePilotReadinessSmokeTest`
- `Phase6APlayerFacingUISmokeTest`
- `Phase6BVisualWorldPresentationSmokeTest`
- `Phase6COnboardingFlowSmokeTest`
- `Phase6DEP1ContentLockSmokeTest`
- `Phase6DEP1FinalMvpRegressionSmokeTest`
- `Phase6EThaiLocalizationSmokeTest`
- `Phase6FEP1FinalQASmokeTest`
- `Phase6GEP1ReleaseCandidateSmokeTest`
- `Phase6HEP1RCSignOffSmokeTest`
- `Phase7AManualMapAuthoringSmokeTest`
- `Phase7BManualMapBindingSmokeTest`

## QA Status Labels

| Area | Status | Notes |
| --- | --- | --- |
| Automated smoke coverage | Passed | EP1 RC baseline coverage includes Phase 6H sign-off checks. |
| Manual gameplay playthrough Q1-Q8 | Passed | Latest gameplay manual playthrough completed Quest 001 through Quest 008 successfully. |
| Thai localization | Passed | Thai player-facing copy is active; continue watching for UI fit issues during RC checks. |
| EP1 release candidate baseline | Passed / Ready | Non-map system work is ready to pause before final handcrafted map decoration. |
| DataStore default safety | Passed | Real DataStore remains disabled by default and production mode remains blocked. |
| Controlled Studio DataStore pilot | Passed | Load/save pilot was verified with sanitized result recorded separately. |
| Manual Map Authoring Contract | Passed | Phase 7A contract, folder structure, attributes, and validation are documented. |
| Manual Map Binding sample test | Passed | Phase 7B sample objects validate and bind through server prompt binding. |
| Final handcrafted map | Not started / postponed | Manual tooling is ready, but final world building and decoration are intentionally postponed. |
| Production DataStore enablement | Not started | Production persistence remains blocked and requires a separate explicit phase. |
| EP2 | Not started | No active EP2 gameplay content exists. |

## Manual QA Result

- Manual gameplay playthrough passed from Quest 001 to Quest 008.
- Quest 008 finale and `/5` tracker progress were included in the playthrough.
- Episode 1 completion and Star Core Segment 01 restoration were confirmed.
- Controlled Studio DataStore pilot passed with masked UserId record.
- Production DataStore remains disabled.
- Final handcrafted manual map is not done.

## Known Intentionally Missing

- Inventory UI.
- Shop and monetization.
- Social hub.
- EP2 active gameplay.
- Production DataStore enablement.
- Final map art.
- Final handcrafted manual map.
- Final audio/VFX.

## Release Readiness Labels

- Not started
- In progress
- Passed
- Blocked

Current label: Passed / Ready for clean pause before final handcrafted map work.
