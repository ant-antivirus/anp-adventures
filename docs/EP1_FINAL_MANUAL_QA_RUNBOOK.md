# EP1 Final Manual QA Runbook

This runbook is the final internal manual QA guide for the Episode 1 MVP candidate.

## 1. Preconditions

- Work from a clean branch with the latest committed code.
- Run Studio and confirm the smoke test summary reports all tests passed.
- Confirm `PersistenceMode = "Mock"`.
- Confirm real DataStore is disabled by default.
- Confirm the Studio test place is synced from Rojo.
- Do not enable production DataStore for this QA pass.

## 2. Fresh Start Test

- Start a fresh Studio play session.
- Confirm Thai onboarding appears.
- Confirm the quest tracker says there is no active quest in Thai.
- Confirm the first hint points to the green Quest Start marker.
- Confirm the marker legend is understandable:
  - Green: start quest.
  - Blue: current objective.
  - Cyan: complete quest.
  - Yellow: discovery.
  - Purple: travel.
  - Orange: guide.

## 3. Quest-By-Quest Test

For each Quest 001 through Quest 008:

- Start marker is visible when expected.
- Thai quest title is readable.
- Quest tracker updates after start.
- Objective marker is visible.
- Objective Thai text is readable.
- Blocked or locked messages are friendly and understandable.
- Required objectives complete correctly.
- Complete marker is usable only when required objectives are done.
- Quest complete feedback appears.
- Tracker moves to the next quest guidance.

## 4. Quest 008 Finale Test

- Quest 008 has five required objectives.
- Tracker progress always uses `/5`.
- Moon Fragment objective works.
- Final Star Core restoration flow works.
- Episode 1 complete message appears in Thai.
- Star Core Segment 01 restored text appears.

## 5. Reward Safety

- `item_star_core_segment_01` is granted after Quest 008 completion.
- Complete Star Core item is not granted.
- `item_star_core_segment_02` and future segment items are not granted.
- Repeating final completion attempts does not duplicate final rewards.

## 6. UI Test

- Tracker text is readable.
- Notifications are readable and stack cleanly.
- Onboarding does not spam after progress exists.
- Episode complete banner is readable.
- Thai text does not overflow badly.
- Thai text does not show mojibake or replacement characters.

## 7. World Test

- Q1-Q8 route remains clear and fast.
- Zones are visually readable.
- Prompts are not blocked by decorative parts.
- Developer labels are not too obstructive.
- Compact test-track layout is still usable.

## 8. Persistence Safety

- SaveSchema v1 smoke test passes.
- Mock save/load round trip passes.
- Real DataStore remains off.
- Controlled DataStore pilot is not enabled unless running a separate pilot test.
- No save UI is present.

## 9. Pass/Fail Table

| Area | Pass? | Notes | Bug/Follow-up |
| --- | --- | --- | --- |
| Fresh start |  |  |  |
| Onboarding |  |  |  |
| Quest 001 |  |  |  |
| Quest 002 |  |  |  |
| Quest 003 |  |  |  |
| Quest 004 |  |  |  |
| Quest 005 |  |  |  |
| Quest 006 |  |  |  |
| Quest 007 |  |  |  |
| Quest 008 finale |  |  |  |
| Rewards |  |  |  |
| UI |  |  |  |
| World route |  |  |  |
| Persistence safety |  |  |  |
