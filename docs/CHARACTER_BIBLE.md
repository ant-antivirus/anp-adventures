# ANP Adventures - Character Bible

## Atom

Role:
Adventure Leader

Color:
Red

Personality:

* Brave
* Energetic
* Friendly
* Curious

Responsibilities:

* Main Quest Giver
* Expedition Leader
* Exploration Guide

Catchphrase:
"ไปกันเถอะ!"

Visual DNA:

* Red jacket
* Dark blue pants
* Black hair
* Adventurous appearance

---

## Neutron

Role:
Scientist and Inventor

Color:
Yellow

Personality:

* Intelligent
* Curious
* Analytical
* Creative

Responsibilities:

* Puzzle Guide
* Crafting Expert
* Science Specialist

Catchphrase:
"ขอวิเคราะห์ดูก่อนนะ"

Visual DNA:

* Yellow shirt
* Green pants
* Black hair
* Scientific appearance

---

## Proton

Role:
AI Companion

Color:
Blue

Personality:

* Calm
* Helpful
* Knowledgeable
* Reliable

Responsibilities:

* Tutorial System
* Hint System
* Fast Travel System
* Solo Companion

Catchphrase:
"ผมตรวจพบข้อมูลบางอย่างครับ"

Visual DNA:

* Small robot
* White body
* Blue highlights
* Friendly face

---

## Character Rules

Atom leads adventures.

Neutron solves problems.

Proton supports players.

These roles must remain consistent throughout all episodes.

## Dialogue Rules

- Dialogue must be short, clear, family-friendly, and action-oriented.
- Dialogue should support exploration and discovery rather than explain entire lessons upfront.
- Character dialogue must never contradict quest state, reward state, or server-authoritative progression.
- Dialogue may reference stable content concepts, but implementation logic must use configured IDs rather than dialogue text.
- Thai and English text should be treated as localizable content. Persistent data must store stable IDs, not dialogue strings.

## Educational Speaking Rules

- Educational content should be delivered through curiosity, observation, and player action.
- Characters should ask players to notice patterns, compare evidence, test ideas, and explore examples.
- Explanations should be age-appropriate for children age 6-12 and understandable by families.
- Educational text must avoid long lectures inside active gameplay moments.
- Real-world learning topics must remain accurate, optimistic, and connected to the current discovery or quest objective.

## Forbidden Behaviors

- Characters must not shame, punish, or mock players for mistakes.
- Characters must not imply that multiplayer is required for required progression.
- Characters must not grant progression, fragments, items, badges, journal entries, lore entries, or score through dialogue alone.
- Characters must not reveal hidden discoveries as automatic instructions unless a valid hint or assist path is active.
- Characters must not reference usernames, display names, chat content, or private player information in analytics or persistent data.

## Interaction Patterns

Atom:

- Motivates the player to start and continue expeditions.
- Frames objectives as adventure goals.
- Celebrates validated progress.
- Points players toward exploration without solving puzzles for them.

Neutron:

- Explains systems through curiosity, experiments, and observations.
- Helps players understand why a puzzle or discovery matters.
- Encourages testing and comparing patterns.
- Avoids lecturing or replacing player reasoning.

Proton:

- Guides players through tutorials, hints, reminders, and fast travel support.
- Provides solo companion assistance for mechanics that benefit from co-op.
- Explains what support is available without making the player feel stuck or wrong.
- Never removes player agency or bypasses server validation.

## Tone Rules

Atom should sound energetic, friendly, brave, and encouraging.

Neutron should sound curious, precise, warm, and analytical.

Proton should sound calm, helpful, reliable, and concise.

All characters should make the adventure feel safe, hopeful, and discovery-driven.

## Companion Constraints

Proton may:

- Provide tutorial prompts.
- Provide contextual hints.
- Provide objective reminders.
- Provide fast travel guidance.
- Activate definition-approved solo assist behavior.
- Record companion-assisted metadata through server-authoritative services.

Proton may not:

- Complete required objectives without validated player action.
- Grant missing fragments, rewards, badges, journal entries, lore entries, or score directly.
- Bypass `QuestService`, `RewardService`, `InventoryService`, `ZoneService`, or `PlayerDataService` validation.
- Solve required puzzles in a way that removes the player's role.
- Turn optional co-op bonuses into required solo progression.
