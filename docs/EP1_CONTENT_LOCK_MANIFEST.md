# EP1 Content Lock Manifest

This manifest records the locked runtime IDs and MVP contracts for Episode 1. Future work must not rename, reuse, delete, or change these IDs without a migration/versioning plan.

## Episode

- `ep01_lost_star_core`

## Quests

- `quest_ep01_main_001`
- `quest_ep01_main_002`
- `quest_ep01_main_003`
- `quest_ep01_main_004`
- `quest_ep01_main_005`
- `quest_ep01_main_006`
- `quest_ep01_main_007`
- `quest_ep01_main_008`

## Required Objective Counts

- Q1: 4 required objectives
- Q2: 4 required objectives
- Q3: 4 required objectives
- Q4: 4 required objectives
- Q5: 4 required objectives, with optional objectives allowed outside the required count
- Q6: 4 required objectives
- Q7: 4 required objectives
- Q8: 5 required objectives

Quest Tracker totals must count `RequiredObjectiveIds`, not optional objectives, visible prompts, or currently available objectives.

## Final Reward Rule

- `reward_ep01_main_008` grants `item_star_core_segment_01`.
- EP1 must not grant a complete Star Core item.
- EP1 must not grant future Star Core segments such as `item_star_core_segment_02` through `item_star_core_segment_05`.
- The Moon Fragment objective reward remains `reward_ep01_objective_008_moon_fragment`.

## Active EP1 Zones

- `zone_ep01_command_center`
- `zone_ep01_universe_explorer`
- `zone_ep01_terrain_sandbox`
- `zone_ep01_theos_satellite_center`
- `zone_ep01_rocket_mission`
- `zone_ep01_astronaut_training`
- `zone_ep01_moon_walk`

Reserved or future spaces, including social hub style content, must remain inactive unless a future phase explicitly enables them.

## Runtime Contracts

- Server remains authoritative for quests, objectives, rewards, inventory, discovery, episode, and save state.
- Client UI remains display-only.
- Quest Tracker totals count required objectives only.
- Save payloads use `SaveSchema` v1.
- Real DataStore remains disabled by default.
- Studio DataStore pilot remains canary-gated.

## Lock Meaning

- Do not rename locked IDs.
- Do not reuse locked IDs for different content.
- Do not delete locked IDs without a migration plan.
- Do not change EP1 final reward semantics without explicit save/version migration planning.
- Do not add active EP2 gameplay content into the EP1 MVP baseline.
