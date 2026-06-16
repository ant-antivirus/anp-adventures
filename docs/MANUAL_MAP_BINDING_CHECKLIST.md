# Manual Map Binding Checklist

Use this checklist before decorating or playtesting a Studio-authored EP1 map.

## Setup

- Confirm `WorldBuildConfig.BuildMode` is intentional.
- Keep `BuildMode = "Skeleton"` for normal dev smoke tests.
- Use `BuildMode = "Manual"` only when validating a Studio-authored map.
- In Manual mode, expect `SmokeTestGate: WorldBuildModeManual`; manual map validation still runs, but the full Skeleton smoke suite is skipped.
- Manual mode only reports missing objects. It does not create skeleton gameplay objects or overwrite `Workspace.ANP_World`.
- Do not commit pilot-enabled DataStore config.

## World Structure

- `Workspace.ANP_World` exists.
- `Workspace.ANP_World.Zones` exists.
- All active EP1 zone folders exist.
- Each EP1 zone has `Gameplay` and `Decor` folders.

## Gameplay Attributes

- Every gameplay object has `InteractionId`.
- Every gameplay object has `ZoneId`.
- Every gameplay object has `ObjectType`.
- `QuestStart` objects have `QuestId`.
- `QuestObjective` objects have `QuestId` and `ObjectiveId`.
- `QuestComplete` objects have `QuestId`.
- Runtime IDs remain English and unchanged.
- `DisplayName` or prompt display text may be Thai.

## Prompt Binding

- Prefer a child `PromptPart` for prompt attachment.
- If no `PromptPart` exists and the gameplay object is a `Model`, set `PrimaryPart`.
- If the gameplay object is a `BasePart`, the prompt may attach directly to it.
- Every prompt host is reachable and not blocked by decor.
- Running prompt binding twice does not create duplicate prompts.

## Validation

- No duplicate `InteractionId`.
- No unknown `InteractionId`.
- No unknown `ZoneId`.
- Object `ZoneId` matches its parent zone.
- Q1-Q8 start/objective/complete objects exist.
- Quest 008 has five required objective objects/routes.
- Decor objects do not contain `InteractionId`, `QuestId`, `ObjectiveId`, or `RewardId`.
- `MapAuthoringValidator` reports zero errors before serious decoration begins.
- If validation fails, read the structured report for `Code`, `InteractionId`, `ZoneId`, `Expected`, `Actual`, and `ObjectPath`.

## Playtest

- Run Studio validation.
- Confirm prompts bind.
- Play Quest 001 through Quest 008.
- Confirm Quest 008 still shows five objectives.
- Confirm Episode 1 completes.
- Confirm real DataStore remains disabled unless doing a separate controlled pilot.

## Phase 7C Handoff Status

- Manual map authoring and binding tooling is ready for builder handoff.
- Final handcrafted EP1 map creation and decoration have not started.
- Read `DECORATION_HANDOFF_GUIDE.md`, `EP1_DECORATION_CHECKLIST.md`, `MAP_NAMING_CONVENTIONS.md`, and `STUDIO_MAP_BACKUP_GUIDE.md` before manual handcrafted map planning.
