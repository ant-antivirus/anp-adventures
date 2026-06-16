# Map Naming Conventions

Object names are for humans. Runtime gameplay binding uses Attributes.

## Gameplay Model Names

Recommended examples:

- `Q1_Start`
- `Q1_Obj1_ExpeditionTerminal`
- `Q1_Obj2_MissionBriefing`
- `Q1_Obj3_LaunchPanel`
- `Q1_Complete`
- `Q8_Obj5_StarCoreRestore`
- `NPC_Proton_Guide`
- `Travel_CommandCenter_To_UniverseExplorer`

## Required Child Part

- `PromptPart`

If no `PromptPart` exists, a Model may use `PrimaryPart`. A direct `BasePart` gameplay object is also supported.

## Optional Children

- `Visual`
- `Label`
- `Decoration`
- `Highlight`
- `Collision`

## Folder Names

- `Gameplay`
- `Decor`
- `Lighting`
- `Blocking`
- `Background`
- `Props`

## Rules

- Runtime IDs remain English and stable.
- `DisplayName` can be Thai.
- Object names can be Thai or English if they remain readable to builders.
- Do not name decor like real quest objects unless it is clearly decorative.
- Do not put `InteractionId`, `QuestId`, `ObjectiveId`, or `RewardId` on decor.
