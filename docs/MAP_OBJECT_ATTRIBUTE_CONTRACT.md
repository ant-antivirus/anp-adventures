# Map Object Attribute Contract

Manual map gameplay objects bind to server systems through Roblox attributes. Runtime IDs remain English and stable. Thai text is allowed for display-only fields.

## Common Required Attributes

Every gameplay object with an interaction must define:

- `InteractionId`: string
- `ZoneId`: string
- `ObjectType`: string

The object itself, or a child named `PromptPart`, must include a `BasePart` or `Attachment` for prompt attachment.

## QuestStart

Required:

- `InteractionId`
- `ZoneId`
- `ObjectType = "QuestStart"`
- `QuestId`

## QuestObjective

Required:

- `InteractionId`
- `ZoneId`
- `ObjectType = "QuestObjective"`
- `QuestId`
- `ObjectiveId`

## QuestComplete

Required:

- `InteractionId`
- `ZoneId`
- `ObjectType = "QuestComplete"`
- `QuestId`

## Discovery

Required:

- `InteractionId`
- `ZoneId`
- `ObjectType = "Discovery"`

Recommended when available:

- `DiscoveryId`

## ZoneTravel

Required:

- `InteractionId`
- `ZoneId`
- `ObjectType = "ZoneTravel"`

Recommended when available:

- `TargetZoneId`

## NPCGuide

Required:

- `InteractionId`
- `ZoneId`
- `ObjectType = "NPCGuide"`

Recommended when available:

- `CharacterId`

## Optional Display Attributes

These attributes are display-only and must not drive gameplay logic:

- `DisplayName`
- `PromptText`
- `PromptPartName`
- `IsDecorative = false`

## Decor Restrictions

Objects under `Decor` folders must not define:

- `InteractionId`
- `QuestId`
- `ObjectiveId`
- `RewardId`

Decor may use Thai names and visual labels, but server gameplay binding is reserved for objects under `Gameplay`.
