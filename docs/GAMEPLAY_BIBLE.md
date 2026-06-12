# ANP Adventures - Gameplay Bible

## Gameplay Loop

1. Meet NPC
2. Receive Quest
3. Explore Zone
4. Solve Challenges
5. Discover Secrets
6. Collect Rewards
7. Gain Explorer Score

---

## Explorer Score

Purpose:
Primary progression system

Sources:

Discovery
+10 to +50

Exploration
+25

Puzzle Completion
+50

Quest Completion
+100

Teamwork Bonus
+25

Hidden Secret Found
+100

---

## Explorer Ranks

Cadet
0 - 999

Junior Explorer
1,000 - 4,999

Explorer
5,000 - 9,999

Senior Explorer
10,000 - 24,999

Master Explorer
25,000+

---

## Multiplayer Rules

Players:
1-8

Multiplayer should provide advantages but never be required.

---

## Solo Play Rules

All quests must be completable alone.

If a multiplayer mechanic exists:

Proton Companion must assist the player.

---

## Objective Dependency Rules

Quest objectives are flexible by default.

Use `RequiresObjectiveIds[]` only when an objective logically depends on another objective in the same quest. Dependency locking should guide progression without turning every quest into a strict global sequence.

---

## Discovery System

Players receive rewards for:

* Finding hidden areas
* Discovering secrets
* Completing optional objectives
* Exploring all zones

Discovery recording and quest objective progress are independent. If a discovery is found before its related quest objective is active, the discovery remains recorded and the interaction must become usable again when an active linked objective needs it.

---

## Playtest Polish Rules

Phase 3H adds developer log noise control, structured blocked hints, Episode 1 anti-stuck smoke coverage, and clearer placeholder prompt text. Blocked server-side interactions should preserve their existing result codes and include `HintText` when a player action is unavailable because of quest prerequisites, objective dependencies, incomplete turn-in requirements, or duplicate discoveries.

Phase 4C adds a display-only quest tracker. The tracker should show the active quest, next objective, objective progress, and a short server-authored hint. It is guidance only; the server remains authoritative for all quest, reward, discovery, inventory, and episode state.

Phase 4D-Dev arranges the skeleton Studio world as a compact quest test track for faster Episode 1 playtesting. This layout is developer scaffolding only, not final world art, and does not change IDs or progression logic.

Phase 4E adds an EP1 MVP QA pass, compact configurable developer labels, a full Episode 1 regression smoke test, and a practical playtest checklist. It does not add new gameplay systems or persistence.

Phase 5A adds save-readiness coverage for Episode 1 player progression. It validates that EP1 quest, inventory, discovery, journal, and episode state can round-trip through a server-owned mock save payload without enabling live persistence.

Phase 5B adds a server-side DataStore adapter behind config. Real persistence remains disabled by default during development, and clients never send save payloads or decide save timing.

Phase 5C adds a controlled Studio DataStore pilot profile. The default mode remains mock-only; pilot testing must explicitly enable the Studio pilot mode and should use the separate pilot DataStore name.

Phase 5D adds canary UserId gating and pilot diagnostics so real Studio DataStore tests can be run with a controlled test account while normal Studio runs remain mock-only.

Phase 6A polishes the player-facing quest tracker, feedback notifications, and Episode Complete banner. These UI elements are display-only and must not decide quest progress, rewards, inventory, or save/load state.

Phase 6B improves the Studio skeleton world with MVP decorative zone identity, route strips, marker presentation, and simple landmarks. This remains developer/playtest scaffolding and must not change quest IDs, objective IDs, interaction IDs, rewards, save/load behavior, or progression logic.

Phase 6C adds first-time onboarding guidance for fresh Episode 1 players. Onboarding should explain the adventure premise, Episode 1 goal, marker colors, and first green Quest Start marker without adding gameplay gates or client authority.

Phase 6D locks Episode 1 as the current active MVP content baseline. Quest 001 through Quest 008, required objective counts, Episode 1 final reward semantics, active zone IDs, and save/tracker contracts are documented in `EP1_CONTENT_LOCK_MANIFEST.md`. Future content must not alter locked EP1 IDs without migration planning.

---

## Badge System

Explorer Badge

Astronaut Badge

Discovery Badge

Space Pioneer Badge

---

## Inventory

Players can collect:

* Episode Fragments
* Star Core Segment Items
* Mission Items
* Event Items
* Achievement Rewards

---

## Win Condition

Restore `item_star_core_segment_01` and complete Episode 1.

Episode 1 does not restore the full Star Core. It restores Segment 01, keeps all five Episode 1 fragments as collectible achievement items, and sets up future Star Core Segment restoration.
