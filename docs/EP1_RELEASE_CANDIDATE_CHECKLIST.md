# EP1 Release Candidate Checklist

Use this checklist before marking Episode 1 as an internal release candidate.

## 1. Automated Checks

- All Studio smoke tests pass.
- Forbidden-system scan is clean.
- EP1 content lock test passes.
- Thai localization test passes.
- Final QA smoke test passes.
- Release candidate smoke test passes.

## 2. Manual Playthrough

- Fresh start works.
- Thai onboarding appears.
- Quest 001 through Quest 008 can be completed.
- Quest 008 has five required objectives.
- Episode 1 completes.
- Star Core Segment 01 is restored.

## 3. UI

- Quest tracker is readable.
- Notifications are readable.
- Onboarding is readable.
- Episode complete banner is readable.
- No obvious Thai text overflow.

## 4. World

- Route is readable.
- Zones are visually distinct.
- Prompts are not blocked.
- Decorations do not break interaction.

## 5. Persistence Defaults

- Real DataStore is off.
- Mock mode is default.
- Production mode is blocked.
- Studio DataStore pilot requires explicit canary configuration.

## 6. Known Not Included

- EP2 active gameplay.
- Inventory UI.
- Shop or monetization.
- Social hub.
- Cosmetics.
- Party, trading, or pet systems.
- Production DataStore enablement.
- Final handcrafted map art.

## 7. RC Decision

| Area | Status | Notes | Blocker? |
| --- | --- | --- | --- |
| Automated smoke tests |  |  |  |
| Manual playthrough |  |  |  |
| Thai UI fit |  |  |  |
| World route |  |  |  |
| Reward safety |  |  |  |
| Persistence defaults |  |  |  |
| Final RC decision |  |  |  |
