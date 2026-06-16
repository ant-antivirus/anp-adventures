# EP1 Decoration Checklist

Use this checklist before and during handcrafted EP1 map decoration.

## 1. Before Decoration

- Git status is clean.
- Default config is safe.
- `PersistenceMode = "Mock"`.
- `WorldBuildConfig.BuildMode` is selected intentionally.
- No real UserId is in config.
- Studio place is backed up.

## 2. Folder Structure

- `Workspace.ANP_World` exists.
- `Workspace.ANP_World.Zones` exists.
- Each active EP1 zone exists.
- Each zone has a `Gameplay` folder.
- Each zone has a `Decor` folder.
- Gameplay objects are Models where practical.
- Each gameplay Model has `PromptPart`, `PrimaryPart`, or a usable `BasePart`.

## 3. Gameplay Safety

- Every gameplay Model has correct Attributes.
- No duplicate `InteractionId`.
- No unknown `InteractionId`.
- `ZoneId` matches parent zone.
- Quest 001 through Quest 008 starts exist.
- Quest 001 through Quest 008 completes exist.
- Quest 008 has five objective objects/routes.
- Decor has no gameplay IDs.

## 4. Visual Readability

- Route is readable.
- Objective objects stand out.
- QuestStart markers are easy to find.
- QuestComplete objects are clear.
- NPC guides are easy to recognize.
- Prompts are not blocked by decor.
- Collision does not trap players.

## 5. UI And Gameplay Playtest

- Quest tracker is readable.
- Thai text is readable.
- Onboarding remains helpful.
- Quest 001 starts.
- Objective progress works.
- Quest completion works.
- Quest 008 finale still works.
- Episode 1 completes.

## 6. Save Safety

- Real DataStore is off by default.
- Use Mock persistence for decoration tests.
- Use `StudioDataStorePilot` only when explicitly testing persistence.
- Revert config before commit.

## 7. Final Pass/Fail Table

| Area | Pass? | Notes | Needs Fix? |
| --- | --- | --- | --- |
| Config safety |  |  |  |
| Folder structure |  |  |  |
| Gameplay objects |  |  |  |
| Prompt binding |  |  |  |
| Visual readability |  |  |  |
| Q1-Q8 playthrough |  |  |  |
| Save defaults |  |  |  |
