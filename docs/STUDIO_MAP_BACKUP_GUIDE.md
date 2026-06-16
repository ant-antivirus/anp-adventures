# Studio Map Backup Guide

Use this before editing the handcrafted EP1 map in Roblox Studio.

## 1. Before Editing Map

- Commit code.
- Duplicate the Studio place or save a new version.
- Export `Workspace.ANP_World` as a model/package if needed.
- Confirm `PersistenceMode = "Mock"` before ordinary map work.

## 2. Recommended Backup Naming

- `ANP_World_EP1_YYYYMMDD_v01`
- `ANP_World_Q1_Blockout_v01`
- `ANP_World_Q1_Playable_v02`
- `ANP_World_EP1_DecorPass_v01`

## 3. What To Back Up

- `Workspace.ANP_World`
- Lighting settings if changed.
- Terrain if used.
- ServerStorage assets if used.
- ReplicatedStorage map assets if used.

## 4. What Not To Commit Accidentally

- Local pilot config.
- Real UserId.
- Temporary test copies.
- Studio cache.
- Exported binary files unless intentionally tracked.

## 5. Recovery Workflow

1. Restore previous `ANP_World`.
2. Reset `WorldBuildConfig.BuildMode`.
3. Run `MapAuthoringValidator`.
4. Run a Quest 001 test.
5. Run Quest 001 through Quest 008 final playtest when ready.
