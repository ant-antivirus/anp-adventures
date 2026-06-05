# ANP Adventures - Quest Bible

## Episode

The Lost Star Core

Location:

Space Inspirium

## Purpose

This document defines production-ready quest and content specifications for Episode 1. It provides stable quest IDs, objective IDs, reward bundle IDs, discovery IDs, companion assist IDs, prerequisites, Explorer Score rewards, solo support rules, multiplayer bonus rules, structured lore definitions, and Star Core Segment progression requirements.

This document does not define implementation code.

## Canon Rules

- Atom leads adventures and acts as the main expedition guide.
- Neutron supports puzzle, science, invention, and analysis moments.
- Proton supports tutorials, hints, fast travel, and solo companion assistance.
- Every main quest must be completable by a solo player.
- Multiplayer may improve speed, convenience, and bonus rewards, but may never be required for progression.
- Any required mechanic that benefits from co-op must include Proton Companion fallback support.
- All rewards must be granted through `RewardService`.
- All progression must be server-authoritative and persistent.
- Episode 1 restores one Star Core Segment, not the complete Star Core.
- Future episodes restore additional Star Core Segments without save schema changes.

## ID Conventions

Episode ID:

- `ep01_lost_star_core`

Zone IDs:

- `zone_ep01_command_center`
- `zone_ep01_universe_explorer`
- `zone_ep01_terrain_sandbox`
- `zone_ep01_theos_satellite_center`
- `zone_ep01_rocket_mission`
- `zone_ep01_astronaut_training`
- `zone_ep01_moon_walk`

Quest ID format:

- `quest_ep01_main_###`

Objective ID format:

- `obj_ep01_main_###_###`
- `obj_ep01_main_###_optional_###`

Reward Bundle ID format:

- `reward_ep01_main_###`
- `reward_ep01_optional_###`
- `reward_ep01_teamwork_main_###`

Discovery ID format:

- `disc_ep01_<location>_<descriptor>`

Companion Assist ID format:

- `assist_ep01_main_###_<descriptor>`

## Star Core Content Definitions

Episode 1 fragment items:

| Item ID | Display Name | Narrative Meaning | Source Quest |
| --- | --- | --- | --- |
| `item_ep01_fragment_universe` | Universe Fragment | Represents understanding the universe. | `quest_ep01_main_003` |
| `item_ep01_fragment_earth` | Earth Fragment | Represents understanding Earth systems and terrain. | `quest_ep01_main_004` |
| `item_ep01_fragment_theos` | THEOS Fragment | Represents observation of Earth from space using Thai satellite technology. | `quest_ep01_main_005` |
| `item_ep01_fragment_rocket` | Rocket Fragment | Represents transportation into space. | `quest_ep01_main_006` |
| `item_ep01_fragment_moon` | Moon Fragment | Represents exploration beyond Earth. | `quest_ep01_main_008` |

Star Core Segment items:

| Item ID | Episode Source | Status |
| --- | --- | --- |
| `item_star_core_segment_01` | Episode 1: The Lost Star Core | Awarded on Episode 1 completion. |
| `item_star_core_segment_02` | Future Episode | Reserved for future episode progression. |
| `item_star_core_segment_03` | Future Episode | Reserved for future episode progression. |
| `item_star_core_segment_04` | Future Episode | Reserved for future episode progression. |
| `item_star_core_segment_05` | Future Episode | Reserved for future episode progression. |

Star Core restoration rule:

- Episode 1 restoration requires all five Episode 1 fragments.
- `InventoryService` must verify ownership of `item_ep01_fragment_universe`, `item_ep01_fragment_earth`, `item_ep01_fragment_theos`, `item_ep01_fragment_rocket`, and `item_ep01_fragment_moon`.
- Quest 8 restores `item_star_core_segment_01`.
- The full Star Core remains incomplete after Episode 1 because additional future segments are required.
- Episode progression must store segment ownership by item ID so future segment items can be added without root save schema changes.

## Episode Progression Summary

| Order | Quest ID | Title | Primary Location | Primary Guide | Reward Bundle |
| --- | --- | --- | --- | --- | --- |
| 1 | `quest_ep01_main_001` | Join the ANP Expedition | Command Center | Atom | `reward_ep01_main_001` |
| 2 | `quest_ep01_main_002` | Map the Broken Star Signal | Universe Explorer | Neutron | `reward_ep01_main_002` |
| 3 | `quest_ep01_main_003` | Recover the Universe Fragment | Universe Explorer | Atom | `reward_ep01_main_003` |
| 4 | `quest_ep01_main_004` | Stabilize the Terrain Flow | Terrain Sandbox | Neutron | `reward_ep01_main_004` |
| 5 | `quest_ep01_main_005` | Calibrate the THEOS Link | THEOS Satellite Center | Proton | `reward_ep01_main_005` |
| 6 | `quest_ep01_main_006` | Prepare the Rocket Mission | Rocket Mission | Atom | `reward_ep01_main_006` |
| 7 | `quest_ep01_main_007` | Complete Astronaut Readiness | Astronaut Training | Neutron | `reward_ep01_main_007` |
| 8 | `quest_ep01_main_008` | Restore Star Core Segment 01 | Moon Walk | Atom, Neutron, Proton | `reward_ep01_main_008` |

## Global Reward Rules

Base Explorer Score rewards:

- Main quest completion: `100`
- Required puzzle or challenge completion inside a quest: included in the quest reward bundle unless listed separately.
- Optional educational objective completion: `25`
- Discovery found: `10` to `50`, based on discovery importance.
- Hidden secret found: `100`, optional and never required for main progression.
- Teamwork bonus: `25`, optional and never required for main progression.

Multiplayer bonus rule:

- Award `25` Explorer Score through a teamwork reward when at least two players make valid server-authoritative contribution to the same eligible quest stage.
- Teamwork bonuses must be duplicate-safe per quest per player.
- Teamwork bonuses must not unlock required progression by themselves.
- Solo players must be able to complete the same quest using normal solo rules or Proton Companion support.

## Quest Specifications

## Quest 1: Join the ANP Expedition

Quest ID:

- `quest_ep01_main_001`

Location:

- Command Center

Primary guide:

- Atom

Support characters:

- Proton
- Neutron

Prerequisites:

- None.

Purpose:

- Introduce the player to the ANP Adventure Team, initialize Episode 1 progression, and teach the core interaction loop.

Objectives:

| Objective ID | Objective | Required | Notes |
| --- | --- | --- | --- |
| `obj_ep01_main_001_001` | Register with the ANP expedition terminal. | Yes | Starts Episode 1 player state. |
| `obj_ep01_main_001_002` | Meet Atom at the expedition briefing point. | Yes | Atom establishes leadership role. |
| `obj_ep01_main_001_003` | Activate Proton Companion support. | Yes | Enables tutorial, hint, and solo assist systems. |
| `obj_ep01_main_001_004` | Review the Star Core Segment status display. | Yes | Establishes that Episode 1 restores one segment of a larger Star Core. |

Reward Bundle ID:

- `reward_ep01_main_001`

Explorer Score rewards:

- Quest completion: `100`
- First expedition registration discovery: `25`

Discovery IDs:

- `disc_ep01_command_expedition_terminal`
- `disc_ep01_command_star_core_display`

Companion Assist IDs:

- `assist_ep01_main_001_tutorial_prompt`
- `assist_ep01_main_001_objective_reminder`

Solo support rules:

- All objectives are single-player interactions.
- Proton must provide tutorial prompts if the player does not interact with the expedition terminal within the configured guidance window.
- No timing or simultaneous interaction requirement is allowed.

Multiplayer bonus rules:

- Eligible teamwork bonus ID: `reward_ep01_teamwork_main_001`
- Award `25` Explorer Score if players register during the same party session and all complete the briefing.
- Bonus does not affect quest completion or unlock state.

Completion unlocks:

- Unlocks `quest_ep01_main_002`.
- Unlocks travel guidance for `zone_ep01_universe_explorer`.

## Quest 2: Map the Broken Star Signal

Quest ID:

- `quest_ep01_main_002`

Location:

- Universe Explorer

Primary guide:

- Neutron

Support characters:

- Proton
- Atom

Prerequisites:

- Complete `quest_ep01_main_001`.
- Unlock `zone_ep01_universe_explorer`.

Purpose:

- Establish the first signal-tracking objective and introduce exploration-based discovery.

Objectives:

| Objective ID | Objective | Required | Notes |
| --- | --- | --- | --- |
| `obj_ep01_main_002_001` | Enter the Universe Explorer zone. | Yes | Server records zone entry. |
| `obj_ep01_main_002_002` | Locate the first signal marker. | Yes | Discovery-driven objective. |
| `obj_ep01_main_002_003` | Scan the signal marker. | Yes | Server-valid interaction. |
| `obj_ep01_main_002_004` | Return signal data to Neutron's analysis station. | Yes | Completes signal mapping loop. |

Reward Bundle ID:

- `reward_ep01_main_002`

Explorer Score rewards:

- Quest completion: `100`
- Exploration reward: `25`
- Signal marker discovery: `25`

Discovery IDs:

- `disc_ep01_universe_first_signal_marker`
- `disc_ep01_universe_analysis_station`

Companion Assist IDs:

- `assist_ep01_main_002_signal_hint`
- `assist_ep01_main_002_route_guidance`

Solo support rules:

- Signal marker scanning must be completable by one player.
- Proton must provide route guidance if the player cannot locate the marker.
- Any visual search mechanic must allow hint escalation without another human player.

Multiplayer bonus rules:

- Eligible teamwork bonus ID: `reward_ep01_teamwork_main_002`
- Award `25` Explorer Score if multiple players discover or scan valid signal points within the same quest session.
- Shared discovery credit may be granted only to players within the valid participation radius.

Completion unlocks:

- Unlocks `quest_ep01_main_003`.

## Quest 3: Recover the Universe Fragment

Quest ID:

- `quest_ep01_main_003`

Location:

- Universe Explorer

Primary guide:

- Atom

Support characters:

- Neutron
- Proton

Prerequisites:

- Complete `quest_ep01_main_002`.

Purpose:

- Recover the Universe Fragment, representing understanding the universe, through a simple exploration and puzzle sequence.

Objectives:

| Objective ID | Objective | Required | Notes |
| --- | --- | --- | --- |
| `obj_ep01_main_003_001` | Reach the universe puzzle station. | Yes | Uses zone navigation. |
| `obj_ep01_main_003_002` | Align the universe puzzle controls. | Yes | Server validates completed state. |
| `obj_ep01_main_003_003` | Collect the Universe Fragment. | Yes | Grants `item_ep01_fragment_universe`. |
| `obj_ep01_main_003_004` | Confirm fragment recovery with Atom. | Yes | Completes quest state. |

Reward Bundle ID:

- `reward_ep01_main_003`

Explorer Score rewards:

- Quest completion: `100`
- Puzzle completion: `50`
- Fragment collection: included in reward bundle

Inventory reward:

- `item_ep01_fragment_universe`

Discovery IDs:

- `disc_ep01_universe_puzzle_station`
- `disc_ep01_universe_fragment`

Companion Assist IDs:

- `assist_ep01_main_003_universe_hint`
- `assist_ep01_main_003_solo_alignment_support`

Solo support rules:

- Universe alignment must not require simultaneous multi-player input.
- If the puzzle supports multi-point co-op interaction, Proton must provide solo alignment support.
- Fragment collection must be duplicate-safe and persistent.

Multiplayer bonus rules:

- Eligible teamwork bonus ID: `reward_ep01_teamwork_main_003`
- Award `25` Explorer Score if two or more players contribute to valid universe alignment steps.
- Fragment ownership remains per-player and must not depend on another player collecting it.

Completion unlocks:

- Unlocks `quest_ep01_main_004`.
- Unlocks `zone_ep01_terrain_sandbox`.

## Quest 4: Stabilize the Terrain Flow

Quest ID:

- `quest_ep01_main_004`

Location:

- Terrain Sandbox

Primary guide:

- Neutron

Support characters:

- Proton
- Atom

Prerequisites:

- Complete `quest_ep01_main_003`.
- Unlock `zone_ep01_terrain_sandbox`.

Purpose:

- Recover the Earth Fragment, representing understanding Earth systems and terrain, through terrain interaction systems.

Objectives:

| Objective ID | Objective | Required | Notes |
| --- | --- | --- | --- |
| `obj_ep01_main_004_001` | Enter the Terrain Sandbox zone. | Yes | Records zone progression. |
| `obj_ep01_main_004_002` | Inspect the terrain flow console. | Yes | Neutron-led technical objective. |
| `obj_ep01_main_004_003` | Complete the terrain flow adjustment. | Yes | Server validates final state. |
| `obj_ep01_main_004_004` | Collect the Earth Fragment. | Yes | Grants `item_ep01_fragment_earth`. |

Reward Bundle ID:

- `reward_ep01_main_004`

Explorer Score rewards:

- Quest completion: `100`
- Puzzle completion: `50`
- Exploration reward: `25`

Inventory reward:

- `item_ep01_fragment_earth`

Discovery IDs:

- `disc_ep01_terrain_flow_console`
- `disc_ep01_terrain_fragment`
- `disc_ep01_terrain_observation_point`

Companion Assist IDs:

- `assist_ep01_main_004_flow_hint`
- `assist_ep01_main_004_solo_flow_support`

Solo support rules:

- Terrain flow adjustment must have a solo-valid completion state.
- Proton must assist if the mechanic would otherwise be easier with one player observing and one player adjusting.
- Optional observation shortcuts may help co-op players but must not be required.

Multiplayer bonus rules:

- Eligible teamwork bonus ID: `reward_ep01_teamwork_main_004`
- Award `25` Explorer Score if multiple players contribute valid terrain adjustments or observation confirmations.
- Co-op may reduce the number of adjustment attempts but cannot change required completion criteria.

Completion unlocks:

- Unlocks `quest_ep01_main_005`.
- Unlocks `zone_ep01_theos_satellite_center`.

## Quest 5: Calibrate the THEOS Link

Quest ID:

- `quest_ep01_main_005`

Location:

- THEOS Satellite Center

Primary guide:

- Proton

Support characters:

- Neutron
- Atom

Prerequisites:

- Complete `quest_ep01_main_004`.
- Unlock `zone_ep01_theos_satellite_center`.

Purpose:

- Recover the THEOS Fragment, representing observation of Earth from space using Thai satellite technology, while making THEOS a major educational pillar of Episode 1.

Objectives:

| Objective ID | Objective | Required | Notes |
| --- | --- | --- | --- |
| `obj_ep01_main_005_001` | Enter the THEOS Satellite Center. | Yes | Records zone entry. |
| `obj_ep01_main_005_002` | Locate the satellite calibration console. | Yes | Discovery-driven navigation objective. |
| `obj_ep01_main_005_003` | Calibrate the satellite link. | Yes | Server validates calibrated state. |
| `obj_ep01_main_005_004` | Collect the THEOS Fragment. | Yes | Grants `item_ep01_fragment_theos`. |
| `obj_ep01_main_005_optional_001` | Review satellite imagery of Thailand. | No | Optional educational objective. |
| `obj_ep01_main_005_optional_002` | Identify flood monitoring example. | No | Optional educational objective. |
| `obj_ep01_main_005_optional_003` | Identify agricultural monitoring example. | No | Optional educational objective. |

Reward Bundle ID:

- `reward_ep01_main_005`

Optional Reward Bundle IDs:

- `reward_ep01_optional_005_satellite_imagery`
- `reward_ep01_optional_005_flood_monitoring`
- `reward_ep01_optional_005_agriculture_monitoring`

Explorer Score rewards:

- Quest completion: `100`
- Puzzle completion: `50`
- Required discovery reward: `25`
- Optional satellite imagery objective: `25`
- Optional flood monitoring objective: `25`
- Optional agricultural monitoring objective: `25`

Inventory reward:

- `item_ep01_fragment_theos`

Discovery IDs:

- `disc_ep01_theos_calibration_console`
- `disc_ep01_theos_signal_array`
- `disc_ep01_theos_fragment`
- `disc_ep01_theos_thailand_map`
- `disc_ep01_theos_satellite_imagery`
- `disc_ep01_theos_disaster_monitoring`
- `disc_ep01_theos_agriculture_monitoring`
- `disc_ep01_theos_water_resource_monitoring`

Companion Assist IDs:

- `assist_ep01_main_005_calibration_hint`
- `assist_ep01_main_005_solo_signal_lock`
- `assist_ep01_main_005_imagery_hint`
- `assist_ep01_main_005_monitoring_hint`

Solo support rules:

- Satellite calibration must not require simultaneous console control from multiple players.
- If multi-station calibration exists, Proton must provide a solo signal lock assist.
- Optional educational objectives must be completable solo.
- Optional objectives may reward Explorer Score but must not block quest completion.
- Proton guidance must use stable hint IDs and must not bypass server validation.

Multiplayer bonus rules:

- Eligible teamwork bonus ID: `reward_ep01_teamwork_main_005`
- Award `25` Explorer Score if two or more players operate valid satellite stations during the same calibration session.
- Bonus is optional and duplicate-safe.
- Optional THEOS educational objectives may be discussed or completed in parallel by co-op players, but each player's reward claim must be validated per player.

Completion unlocks:

- Unlocks `quest_ep01_main_006`.
- Unlocks `zone_ep01_rocket_mission`.

## Quest 6: Prepare the Rocket Mission

Quest ID:

- `quest_ep01_main_006`

Location:

- Rocket Mission

Primary guide:

- Atom

Support characters:

- Neutron
- Proton

Prerequisites:

- Complete `quest_ep01_main_005`.
- Unlock `zone_ep01_rocket_mission`.

Purpose:

- Recover the Rocket Fragment, representing transportation into space, through a rocket preparation and launch sequence.

Objectives:

| Objective ID | Objective | Required | Notes |
| --- | --- | --- | --- |
| `obj_ep01_main_006_001` | Enter the Rocket Mission zone. | Yes | Records zone entry. |
| `obj_ep01_main_006_002` | Complete rocket preparation checks. | Yes | Server validates checklist state. |
| `obj_ep01_main_006_003` | Complete the launch challenge. | Yes | Target or timing challenge must be solo-valid. |
| `obj_ep01_main_006_004` | Collect the Rocket Fragment. | Yes | Grants `item_ep01_fragment_rocket`. |

Reward Bundle ID:

- `reward_ep01_main_006`

Explorer Score rewards:

- Quest completion: `100`
- Challenge completion: `50`
- Exploration reward: `25`

Inventory reward:

- `item_ep01_fragment_rocket`

Discovery IDs:

- `disc_ep01_rocket_preflight_console`
- `disc_ep01_rocket_launch_platform`
- `disc_ep01_rocket_fragment`

Companion Assist IDs:

- `assist_ep01_main_006_preflight_hint`
- `assist_ep01_main_006_solo_launch_support`

Solo support rules:

- Preflight checks must be sequentially completable by one player.
- If co-op players can divide checklist steps, solo players must receive Proton routing and reminder support.
- Launch challenge success must rely on server-validated player action, not client-only state.

Multiplayer bonus rules:

- Eligible teamwork bonus ID: `reward_ep01_teamwork_main_006`
- Award `25` Explorer Score if multiple players complete distinct valid preparation contributions before launch.
- Co-op may speed up checklist completion but cannot skip required solo-valid steps.

Completion unlocks:

- Unlocks `quest_ep01_main_007`.
- Unlocks `zone_ep01_astronaut_training`.

## Quest 7: Complete Astronaut Readiness

Quest ID:

- `quest_ep01_main_007`

Location:

- Astronaut Training

Primary guide:

- Neutron

Support characters:

- Atom
- Proton

Prerequisites:

- Complete `quest_ep01_main_006`.
- Unlock `zone_ep01_astronaut_training`.

Purpose:

- Complete astronaut readiness checks before the final Moon Walk mission.

Objectives:

| Objective ID | Objective | Required | Notes |
| --- | --- | --- | --- |
| `obj_ep01_main_007_001` | Enter the Astronaut Training zone. | Yes | Records zone entry. |
| `obj_ep01_main_007_002` | Complete the movement readiness challenge. | Yes | Must support all input modes. |
| `obj_ep01_main_007_003` | Complete the balance readiness challenge. | Yes | Must be solo-completable. |
| `obj_ep01_main_007_004` | Earn the Astronaut Badge. | Yes | Persistent badge reward. |

Reward Bundle ID:

- `reward_ep01_main_007`

Explorer Score rewards:

- Quest completion: `100`
- Challenge completion: `50`
- Badge milestone: included in reward bundle

Badge reward:

- `badge_ep01_astronaut`

Discovery IDs:

- `disc_ep01_astronaut_training_entry`
- `disc_ep01_astronaut_readiness_station`
- `disc_ep01_astronaut_badge_terminal`

Companion Assist IDs:

- `assist_ep01_main_007_movement_hint`
- `assist_ep01_main_007_balance_support`

Solo support rules:

- Movement and balance challenges must support mobile, gamepad, and PC players.
- No challenge may require another player to hold, trigger, or stabilize an object for required completion.
- Proton must provide recovery guidance after repeated failed attempts.

Multiplayer bonus rules:

- Eligible teamwork bonus ID: `reward_ep01_teamwork_main_007`
- Award `25` Explorer Score if players complete readiness stages in a valid party training session.
- Co-op bonus cannot affect badge eligibility.

Completion unlocks:

- Unlocks `quest_ep01_main_008`.
- Unlocks `zone_ep01_moon_walk`.

## Quest 8: Restore Star Core Segment 01

Quest ID:

- `quest_ep01_main_008`

Location:

- Moon Walk

Primary guide:

- Atom

Support characters:

- Neutron
- Proton

Prerequisites:

- Complete `quest_ep01_main_007`.
- Unlock `zone_ep01_moon_walk`.
- Own `item_ep01_fragment_universe`.
- Own `item_ep01_fragment_earth`.
- Own `item_ep01_fragment_theos`.
- Own `item_ep01_fragment_rocket`.

Purpose:

- Recover the Moon Fragment, validate all five Episode 1 fragments, and restore Star Core Segment 01.

Objectives:

| Objective ID | Objective | Required | Notes |
| --- | --- | --- | --- |
| `obj_ep01_main_008_001` | Enter the Moon Walk zone. | Yes | Records final zone entry. |
| `obj_ep01_main_008_002` | Complete the low-gravity exploration route. | Yes | Must be solo-valid. |
| `obj_ep01_main_008_003` | Collect the Moon Fragment. | Yes | Grants `item_ep01_fragment_moon`. |
| `obj_ep01_main_008_004` | Assemble the five Episode 1 fragments. | Yes | InventoryService validates all required fragment ownership. |
| `obj_ep01_main_008_005` | Restore Star Core Segment 01. | Yes | Grants `item_star_core_segment_01` and completes Episode 1. |

Reward Bundle ID:

- `reward_ep01_main_008`

Explorer Score rewards:

- Quest completion: `100`
- Final challenge completion: `50`
- Episode segment completion: `100`
- Hidden secret bonus eligibility: `100`, optional only

Inventory rewards:

- `item_ep01_fragment_moon`
- `item_star_core_segment_01`

Badge rewards:

- `badge_ep01_explorer`
- `badge_ep01_space_pioneer`

Discovery IDs:

- `disc_ep01_moon_walk_entry`
- `disc_ep01_moon_low_gravity_route`
- `disc_ep01_moon_fragment`
- `disc_ep01_moon_star_core_segment_restoration_point`

Companion Assist IDs:

- `assist_ep01_main_008_low_gravity_hint`
- `assist_ep01_main_008_fragment_check`
- `assist_ep01_main_008_solo_restoration_support`

Solo support rules:

- Final route, Moon Fragment collection, fragment assembly, and Star Core Segment restoration must be completable by one player.
- If restoration supports multiple players placing fragments together, Proton must provide solo restoration support.
- Required item ownership checks must use server-authoritative `InventoryService` state.
- Proton may remind the player about missing required fragments but must not grant missing fragments.

Multiplayer bonus rules:

- Eligible teamwork bonus ID: `reward_ep01_teamwork_main_008`
- Award `25` Explorer Score if multiple eligible players participate in the final restoration sequence.
- Co-op may create shared celebration feedback but cannot be required for restoration.
- Episode completion must be recorded per player.

Completion unlocks:

- Completes `ep01_lost_star_core`.
- Marks Episode 1 completion in persistent data.
- Grants `item_star_core_segment_01`.
- Registers that future Star Core Segments remain unresolved.
- Enables future episode progression hooks for `item_star_core_segment_02`, `item_star_core_segment_03`, `item_star_core_segment_04`, and `item_star_core_segment_05`.

## Reward Bundle Index

| Reward Bundle ID | Source Quest | Explorer Score | Persistent Rewards | Notes |
| --- | --- | --- | --- | --- |
| `reward_ep01_main_001` | `quest_ep01_main_001` | `125` | Episode start state | Includes registration discovery. |
| `reward_ep01_main_002` | `quest_ep01_main_002` | `150` | None required | Includes exploration and discovery rewards. |
| `reward_ep01_main_003` | `quest_ep01_main_003` | `150` | `item_ep01_fragment_universe` | Universe Fragment reward. |
| `reward_ep01_main_004` | `quest_ep01_main_004` | `175` | `item_ep01_fragment_earth` | Earth Fragment reward. |
| `reward_ep01_main_005` | `quest_ep01_main_005` | `175` | `item_ep01_fragment_theos` | THEOS Fragment reward. Optional THEOS objectives use separate reward bundles. |
| `reward_ep01_main_006` | `quest_ep01_main_006` | `175` | `item_ep01_fragment_rocket` | Rocket Fragment reward. |
| `reward_ep01_main_007` | `quest_ep01_main_007` | `150` | `badge_ep01_astronaut` | Badge milestone reward. |
| `reward_ep01_main_008` | `quest_ep01_main_008` | `250` | `item_ep01_fragment_moon`, `item_star_core_segment_01`, `badge_ep01_explorer`, `badge_ep01_space_pioneer` | Moon Fragment and Episode 1 segment completion reward. |

Optional THEOS educational reward bundles:

| Reward Bundle ID | Source Objective | Explorer Score | Notes |
| --- | --- | --- | --- |
| `reward_ep01_optional_005_satellite_imagery` | `obj_ep01_main_005_optional_001` | `25` | Optional. Reviews satellite imagery of Thailand. |
| `reward_ep01_optional_005_flood_monitoring` | `obj_ep01_main_005_optional_002` | `25` | Optional. Identifies flood monitoring use. |
| `reward_ep01_optional_005_agriculture_monitoring` | `obj_ep01_main_005_optional_003` | `25` | Optional. Identifies agricultural monitoring use. |

Teamwork reward bundles:

| Reward Bundle ID | Source Quest | Explorer Score | Eligibility |
| --- | --- | --- | --- |
| `reward_ep01_teamwork_main_001` | `quest_ep01_main_001` | `25` | Valid shared briefing participation. |
| `reward_ep01_teamwork_main_002` | `quest_ep01_main_002` | `25` | Valid shared signal discovery or scan. |
| `reward_ep01_teamwork_main_003` | `quest_ep01_main_003` | `25` | Valid shared universe alignment contribution. |
| `reward_ep01_teamwork_main_004` | `quest_ep01_main_004` | `25` | Valid shared terrain adjustment contribution. |
| `reward_ep01_teamwork_main_005` | `quest_ep01_main_005` | `25` | Valid shared satellite calibration contribution. |
| `reward_ep01_teamwork_main_006` | `quest_ep01_main_006` | `25` | Valid shared rocket preparation contribution. |
| `reward_ep01_teamwork_main_007` | `quest_ep01_main_007` | `25` | Valid shared astronaut readiness participation. |
| `reward_ep01_teamwork_main_008` | `quest_ep01_main_008` | `25` | Valid shared final restoration participation. |

## Discovery Index

| Discovery ID | Location | Related Quest | Explorer Score |
| --- | --- | --- | --- |
| `disc_ep01_command_expedition_terminal` | Command Center | `quest_ep01_main_001` | `10` |
| `disc_ep01_command_star_core_display` | Command Center | `quest_ep01_main_001` | `15` |
| `disc_ep01_universe_first_signal_marker` | Universe Explorer | `quest_ep01_main_002` | `25` |
| `disc_ep01_universe_analysis_station` | Universe Explorer | `quest_ep01_main_002` | `10` |
| `disc_ep01_universe_puzzle_station` | Universe Explorer | `quest_ep01_main_003` | `25` |
| `disc_ep01_universe_fragment` | Universe Explorer | `quest_ep01_main_003` | `25` |
| `disc_ep01_terrain_flow_console` | Terrain Sandbox | `quest_ep01_main_004` | `25` |
| `disc_ep01_terrain_fragment` | Terrain Sandbox | `quest_ep01_main_004` | `25` |
| `disc_ep01_terrain_observation_point` | Terrain Sandbox | `quest_ep01_main_004` | `25` |
| `disc_ep01_theos_calibration_console` | THEOS Satellite Center | `quest_ep01_main_005` | `25` |
| `disc_ep01_theos_signal_array` | THEOS Satellite Center | `quest_ep01_main_005` | `25` |
| `disc_ep01_theos_fragment` | THEOS Satellite Center | `quest_ep01_main_005` | `25` |
| `disc_ep01_theos_thailand_map` | THEOS Satellite Center | `quest_ep01_main_005` | `25` |
| `disc_ep01_theos_satellite_imagery` | THEOS Satellite Center | `quest_ep01_main_005` | `25` |
| `disc_ep01_theos_disaster_monitoring` | THEOS Satellite Center | `quest_ep01_main_005` | `25` |
| `disc_ep01_theos_agriculture_monitoring` | THEOS Satellite Center | `quest_ep01_main_005` | `25` |
| `disc_ep01_theos_water_resource_monitoring` | THEOS Satellite Center | `quest_ep01_main_005` | `25` |
| `disc_ep01_rocket_preflight_console` | Rocket Mission | `quest_ep01_main_006` | `25` |
| `disc_ep01_rocket_launch_platform` | Rocket Mission | `quest_ep01_main_006` | `25` |
| `disc_ep01_rocket_fragment` | Rocket Mission | `quest_ep01_main_006` | `25` |
| `disc_ep01_astronaut_training_entry` | Astronaut Training | `quest_ep01_main_007` | `10` |
| `disc_ep01_astronaut_readiness_station` | Astronaut Training | `quest_ep01_main_007` | `25` |
| `disc_ep01_astronaut_badge_terminal` | Astronaut Training | `quest_ep01_main_007` | `25` |
| `disc_ep01_moon_walk_entry` | Moon Walk | `quest_ep01_main_008` | `10` |
| `disc_ep01_moon_low_gravity_route` | Moon Walk | `quest_ep01_main_008` | `25` |
| `disc_ep01_moon_fragment` | Moon Walk | `quest_ep01_main_008` | `50` |
| `disc_ep01_moon_star_core_segment_restoration_point` | Moon Walk | `quest_ep01_main_008` | `50` |

Optional hidden discovery:

| Discovery ID | Location | Related Quest | Explorer Score |
| --- | --- | --- | --- |
| `disc_ep01_hidden_space_inspirium_secret` | Any Episode 1 location | Optional | `100` |

## Structured Discovery Lore Definitions

Lore definition schema:

| Field | Purpose |
| --- | --- |
| `DiscoveryId` | Stable discovery ID. |
| `LoreId` | Stable lore entry ID. |
| `Topic` | Educational topic category. |
| `Summary` | Short educational summary for UI or journal display. |
| `CharacterVoice` | Character responsible for presenting or contextualizing the lore. |
| `RelatedConcepts` | Stable concept tags for analytics, journal grouping, and future localization. |

THEOS lore entries:

| DiscoveryId | LoreId | Topic | Summary | CharacterVoice | RelatedConcepts |
| --- | --- | --- | --- | --- | --- |
| `disc_ep01_theos_thailand_map` | `lore_ep01_theos_thailand_map` | Thai Earth observation | THEOS missions help observe Thailand from space so people can better understand land, water, cities, farms, and natural areas. | Proton | `thai_satellite`, `earth_observation`, `map_reading` |
| `disc_ep01_theos_satellite_imagery` | `lore_ep01_theos_satellite_imagery` | Satellite imagery | Satellite images show patterns on Earth that are difficult to see from the ground, helping scientists compare change over time. | Neutron | `satellite_imagery`, `earth_science`, `change_detection` |
| `disc_ep01_theos_disaster_monitoring` | `lore_ep01_theos_disaster_monitoring` | Flood monitoring | Earth observation satellites can help identify flood-affected areas and support faster planning during disasters. | Proton | `flood_monitoring`, `disaster_monitoring`, `public_safety` |
| `disc_ep01_theos_agriculture_monitoring` | `lore_ep01_theos_agriculture_monitoring` | Agriculture monitoring | Satellite data can help monitor farmland health, crop patterns, and changes in growing areas. | Neutron | `agriculture_monitoring`, `food_systems`, `remote_sensing` |
| `disc_ep01_theos_water_resource_monitoring` | `lore_ep01_theos_water_resource_monitoring` | Water resource monitoring | Satellite observations can help track rivers, reservoirs, and water resources across large areas. | Proton | `water_resources`, `earth_systems`, `remote_sensing` |
| `disc_ep01_theos_signal_array` | `lore_ep01_theos_forest_monitoring` | Forest monitoring | Satellite imagery can help observe forests and detect changes in land cover over time. | Neutron | `forest_monitoring`, `land_cover`, `earth_observation` |

Lore validation rules:

- Every lore entry must reference a valid `DiscoveryId`.
- Lore entries must use stable `LoreId` values.
- Lore summaries must be educational, family-friendly, and free of personal information.
- Lore text must be separate from discovery IDs so future localization can replace text without changing progression data.

## Companion Assist Index

| Companion Assist ID | Related Quest | Purpose | Required For Solo Fallback |
| --- | --- | --- | --- |
| `assist_ep01_main_001_tutorial_prompt` | `quest_ep01_main_001` | Tutorial guidance. | Yes |
| `assist_ep01_main_001_objective_reminder` | `quest_ep01_main_001` | Objective reminder. | Yes |
| `assist_ep01_main_002_signal_hint` | `quest_ep01_main_002` | Signal location hint. | Yes |
| `assist_ep01_main_002_route_guidance` | `quest_ep01_main_002` | Navigation guidance. | Yes |
| `assist_ep01_main_003_universe_hint` | `quest_ep01_main_003` | Universe puzzle hint. | Yes |
| `assist_ep01_main_003_solo_alignment_support` | `quest_ep01_main_003` | Solo puzzle fallback. | Yes |
| `assist_ep01_main_004_flow_hint` | `quest_ep01_main_004` | Terrain flow hint. | Yes |
| `assist_ep01_main_004_solo_flow_support` | `quest_ep01_main_004` | Solo terrain adjustment fallback. | Yes |
| `assist_ep01_main_005_calibration_hint` | `quest_ep01_main_005` | Satellite calibration hint. | Yes |
| `assist_ep01_main_005_solo_signal_lock` | `quest_ep01_main_005` | Solo satellite fallback. | Yes |
| `assist_ep01_main_005_imagery_hint` | `quest_ep01_main_005` | Satellite imagery educational hint. | Yes |
| `assist_ep01_main_005_monitoring_hint` | `quest_ep01_main_005` | Monitoring example educational hint. | Yes |
| `assist_ep01_main_006_preflight_hint` | `quest_ep01_main_006` | Rocket preparation hint. | Yes |
| `assist_ep01_main_006_solo_launch_support` | `quest_ep01_main_006` | Solo launch fallback. | Yes |
| `assist_ep01_main_007_movement_hint` | `quest_ep01_main_007` | Movement challenge hint. | Yes |
| `assist_ep01_main_007_balance_support` | `quest_ep01_main_007` | Balance recovery support. | Yes |
| `assist_ep01_main_008_low_gravity_hint` | `quest_ep01_main_008` | Moon Walk route hint. | Yes |
| `assist_ep01_main_008_fragment_check` | `quest_ep01_main_008` | Missing fragment reminder. | Yes |
| `assist_ep01_main_008_solo_restoration_support` | `quest_ep01_main_008` | Solo final restoration fallback. | Yes |

## Validation Requirements

Quest validation:

- Every quest ID must be unique.
- Every objective ID must be unique.
- Every quest must define prerequisites.
- Every quest must define a reward bundle ID.
- Optional objectives must be marked optional and must not block quest or episode completion.
- Every required objective must be solo-completable.
- Every co-op-benefiting required mechanic must define at least one companion assist ID.
- Quest completion must be server-authoritative.
- Quest rewards must be duplicate-safe.

Reward validation:

- Every reward bundle ID must exist in reward definitions.
- Explorer Score must be granted through `RewardService`.
- Inventory items must be granted through `InventoryService` via `RewardService`.
- Badge awards must be routed through the badge reward pipeline.
- Teamwork rewards must be optional and duplicate-safe.
- Optional THEOS objective rewards must be duplicate-safe per objective per player.

Inventory and assembly validation:

- Quest 8 assembly must verify ownership through `InventoryService`.
- Required Episode 1 fragment IDs are `item_ep01_fragment_universe`, `item_ep01_fragment_earth`, `item_ep01_fragment_theos`, `item_ep01_fragment_rocket`, and `item_ep01_fragment_moon`.
- `item_star_core_segment_01` must be granted only after all five Episode 1 fragments are validated.
- Future segment items `item_star_core_segment_02`, `item_star_core_segment_03`, `item_star_core_segment_04`, and `item_star_core_segment_05` must be representable as inventory items without root save schema changes.

Discovery validation:

- Every discovery ID must be unique.
- Discovery rewards must be duplicate-safe.
- Discovery claims must be server-validatable.
- Optional discoveries must not block main quest completion.
- THEOS discoveries must include structured lore definitions.

Companion validation:

- Every companion assist ID must be unique.
- Required solo fallback assists must be declared in quest definitions.
- Proton assist may guide or support but must not bypass server quest validation.
- Proton assist may not directly grant missing required rewards or fragments.

Multiplayer validation:

- Multiplayer may award optional teamwork bonuses.
- Multiplayer may speed up valid contribution steps.
- Multiplayer may not be required for required quest completion.
- Player join or leave events must not break solo completion.

EpisodeService progression hooks:

- Episode completion must support segment-item rewards.
- Episode 1 completion grants `item_star_core_segment_01`.
- Future episode completion hooks must support `item_star_core_segment_02`, `item_star_core_segment_03`, `item_star_core_segment_04`, and `item_star_core_segment_05`.
- Segment tracking must use inventory item ownership and episode progress maps, not new root save fields.

