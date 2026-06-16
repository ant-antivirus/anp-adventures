# Decoration Handoff Guide

## Purpose

This guide is for the human builder who will later create the real handcrafted Episode 1 map in Roblox Studio.

Phase 7C does not create or decorate the final map. It documents the safe workflow for doing that later.

## 1. Current Project Status

- EP1 system work is closed.
- EP1 internal release candidate is signed off.
- Controlled Studio DataStore pilot passed.
- Manual map authoring and binding tools are ready.
- Final handcrafted map has not started.
- Real DataStore remains disabled by default.
- EP1 remains the only active episode.

## 2. What Codex Prepared

- `WorldBuildConfig` with explicit `Skeleton` and `Manual` build modes.
- Manual mode that does not auto-build or overwrite `Workspace.ANP_World`.
- `MapAuthoringValidator` for Studio-authored map validation.
- Attribute-based gameplay object discovery.
- `PromptBindingService` support for manual objects.
- Builder docs and checklists for map structure, attributes, naming, backups, and playtesting.

## 3. What The Builder Should Do Later

- Build the real EP1 world in Roblox Studio.
- Create each active EP1 zone under `Workspace.ANP_World.Zones`.
- Place gameplay objects as Models where possible.
- Add a child `PromptPart`, set a `PrimaryPart`, or use a direct `BasePart` host.
- Set required gameplay Attributes on gameplay objects.
- Put visual decoration in `Decor`, not on gameplay IDs.
- Run `MapAuthoringValidator`.
- Bind prompts and playtest Quest 001 through Quest 008.

## 4. What The Builder Must Not Do

- Do not rename locked quest, objective, interaction, reward, item, or zone IDs.
- Do not delete required QuestStart, QuestObjective, or QuestComplete objects.
- Do not put `InteractionId` on decor objects.
- Do not leave `BuildMode` wrong before running tests.
- Do not commit `StudioDataStorePilot` config.
- Do not commit real Roblox UserIds.
- Do not overwrite `Workspace.ANP_World` accidentally.
- Do not rely on object names for gameplay logic. Runtime binding uses Attributes.

## 5. Recommended First Manual Build Target

Build Command Center / Quest 001 first:

- `Q1_Start`
- `Q1_Obj1_ExpeditionTerminal`
- `Q1_Obj2_MissionBriefing`
- `Q1_Obj3_LaunchPanel`
- `Q1_Complete`

Validate and playtest Quest 001 before expanding to Quest 002 through Quest 008.

## 6. Recommended Map-Building Order

1. Layout.
2. Zone boundaries.
3. Gameplay object placeholders.
4. Validation.
5. Prompt binding test.
6. Route readability.
7. Decoration.
8. Lighting.
9. Polish.
10. Final Quest 001 through Quest 008 playthrough.
