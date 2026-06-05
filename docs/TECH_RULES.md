# ANP Adventures - Technical Rules

## Core Rules

All gameplay content must support:

- Solo Play
- Multiplayer Co-op

No quest may require multiple human players.

Use the design rule:

- Solo First, Co-op Better

Solo players must always be able to complete required progression. Co-op may provide speed, convenience, shared celebration, or optional teamwork bonuses, but it must never be required.

## Server Authority

All progression must be server-authoritative.

The client must never be trusted for:

- Quest completion
- Objective completion
- Explorer Score changes
- Inventory grants
- Fragment ownership
- Star Core Segment ownership
- Discovery unlocks
- Journal or lore unlocks
- Badge awards
- Zone unlocks
- Episode completion

## Reward Rules

All rewards must be granted through `RewardService`.

Rewards include:

- Explorer Score
- Inventory items
- Episode fragments
- Star Core Segment items
- Badges
- Discovery rewards
- Journal or lore unlock rewards
- Zone unlocks
- Episode unlocks
- Teamwork bonuses

Fragments are collectible achievement items and must not be consumed during assembly.

## Stable ID Rules

Use stable IDs only.

Do not hardcode:

- Quest IDs
- Objective IDs
- Item IDs
- Zone IDs
- Discovery IDs
- Lore IDs
- Journal entry IDs
- Reward Bundle IDs
- Badge IDs
- NPC IDs
- Companion Assist IDs

IDs must come from shared config or content definition modules.

## Proton Companion Rules

Proton Companion must provide fallback support for solo players.

If a required mechanic has a co-op-style advantage, the mechanic must define Proton solo support.

Proton may:

- Guide
- Hint
- Remind
- Stabilize
- Simulate a missing support role when allowed by definitions

Proton may not:

- Bypass server validation
- Grant missing progression
- Grant missing fragments
- Complete required objectives without the required player action

## Analytics Privacy Rules

Analytics must not store personal information.

Analytics must not store:

- Usernames
- Display names
- Chat messages
- Private user content
- Free-form player text
- Contact information

Analytics may store stable content IDs and aggregate gameplay metrics.

## Episode Expansion Rules

Episode expansion must not require root save schema changes.

Future episodes must support additional Star Core Segment items through inventory and episode progress maps:

- `item_star_core_segment_02`
- `item_star_core_segment_03`
- `item_star_core_segment_04`
- `item_star_core_segment_05`

New episodes should add content definitions, not rewrite core services.
