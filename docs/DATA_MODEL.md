# ANP Adventures - Data Model Specification

## Purpose

This document defines persistent and runtime data models for ANP Adventures. It is intended for Roblox Luau architecture planning and service contract design.

This document does not define quest content, puzzle design, dialogue, or story details.

## Data Ownership

Persistent player data is owned by `PlayerDataService` and stored with Roblox `DataStoreService`.

Other services may read or request mutations through service APIs, but they should not write directly to DataStore.

## Core Data Rules

- All progression must be persistent.
- Data must include a `SchemaVersion`.
- Data migrations must be explicit and repeatable.
- Runtime state must not be stored unless it affects progression after reconnect.
- Rewards must be idempotent so duplicate remote calls or retry behavior cannot duplicate grants.
- Quest, item, badge, zone, episode, and discovery IDs must come from definitions or config modules.

## Persistent Player Data

```text
PlayerData
  SchemaVersion
  Profile
  Progression
  Episodes
  Quests
  Inventory
  Discoveries
  Journal
  Lore
  Badges
  Zones
  Companion
  Settings
  Timestamps
```

### Profile

Stores account-level metadata for the save file.

```text
Profile
  UserId: number
  CreatedAt: number
  LastLoginAt: number
  TotalPlaytimeSeconds: number
```

### Progression

Stores Explorer Score and rank state.

```text
Progression
  ExplorerScore: number
  ExplorerRankId: string
  LifetimeExplorerScore: number
```

`ExplorerScore` is the active progression value. `LifetimeExplorerScore` may be used for analytics, rank history, or future systems that need total earned score.

Rank thresholds should come from `RankConfig`, not from service-local constants.

### Episodes

Stores episode-level unlock and completion state.

```text
Episodes
  ActiveEpisodeId: string?
  UnlockedEpisodeIds: map<string, boolean>
  CompletedEpisodeIds: map<string, boolean>
  EpisodeProgress: map<string, EpisodeProgress>
```

```text
EpisodeProgress
  StartedAt: number?
  CompletedAt: number?
  CompletedQuestCount: number
  TotalQuestCount: number
```

Episode state supports expansion by allowing new episode IDs to be added without changing the root save structure.

### Quests

Stores active, completed, and partially completed quest state.

```text
Quests
  ActiveQuestIds: array<string>
  CompletedQuestIds: map<string, boolean>
  QuestStates: map<string, QuestState>
```

```text
QuestState
  QuestId: string
  EpisodeId: string
  ZoneId: string?
  Status: "Inactive" | "Active" | "Completed"
  ObjectiveStates: map<string, ObjectiveState>
  StartedAt: number?
  CompletedAt: number?
  LastUpdatedAt: number?
  AssistedByCompanion: boolean
  CoopParticipantUserIds: array<number>
  RewardClaimIds: map<string, boolean>
```

```text
ObjectiveState
  ObjectiveId: string
  Progress: number
  RequiredProgress: number
  Completed: boolean
```

Quest definitions should define objective requirements. Saved objective state stores only the player's progress and completion state.

### Inventory

Stores player-owned items and reward objects.

```text
Inventory
  Items: map<string, InventoryItemState>
```

```text
InventoryItemState
  ItemId: string
  Quantity: number
  FirstCollectedAt: number?
  LastCollectedAt: number?
```

Inventory item categories should be defined in `InventoryConfig`.

Episode 1 fragment items are collectible achievement items. They must be retained after Star Core Segment assembly and must not be consumed:

- `item_ep01_fragment_universe`
- `item_ep01_fragment_earth`
- `item_ep01_fragment_theos`
- `item_ep01_fragment_rocket`
- `item_ep01_fragment_moon`

Star Core Segment items are persistent inventory items:

- `item_star_core_segment_01`
- `item_star_core_segment_02`
- `item_star_core_segment_03`
- `item_star_core_segment_04`
- `item_star_core_segment_05`

### Discoveries

Stores exploration and discovery progress.

```text
Discoveries
  FoundDiscoveryIds: map<string, boolean>
  ZoneDiscoveryProgress: map<string, ZoneDiscoveryProgress>
```

```text
ZoneDiscoveryProgress
  ZoneId: string
  FoundCount: number
  TotalKnownCount: number
  Completed: boolean
```

Discovery rewards must be granted through `RewardService` to avoid duplicate scoring.

### Journal

Stores persistent player journal unlocks.

```text
Journal
  UnlockedEntryIds: map<string, boolean>
  EntryStates: map<string, JournalEntryState>
```

```text
JournalEntryState
  JournalEntryId: string
  SourceType: string
  SourceId: string
  UnlockedAt: number
  ViewedAt: number?
```

Journal entries may be unlocked by discoveries, quest milestones, fragment collection, Star Core Segment restoration, or approved server-authored events.

### Lore

Stores persistent lore unlocks.

```text
Lore
  UnlockedLoreIds: map<string, boolean>
  LoreStates: map<string, LoreEntryState>
```

```text
LoreEntryState
  LoreId: string
  DiscoveryId: string?
  SourceType: string
  SourceId: string
  UnlockedAt: number
  ViewedAt: number?
```

Lore entries should reference stable discovery IDs or milestone IDs. Lore text should remain in definitions, not player save data.

### Badges

Stores internal badge state and Roblox badge award retry state.

```text
Badges
  AwardedBadgeIds: map<string, boolean>
  PendingRobloxBadgeAwards: array<string>
```

Internal badge IDs should map to Roblox badge asset IDs through `BadgeConfig`.

### Zones

Stores zone unlocks, travel state, and last known location.

```text
Zones
  UnlockedZoneIds: map<string, boolean>
  FastTravelUnlockedZoneIds: map<string, boolean>
  LastZoneId: string?
  LastSpawnPointId: string?
```

Zone access rules should be checked by `ZoneService`.

### Companion

Stores persistent Proton Companion support state.

```text
Companion
  TutorialFlags: map<string, boolean>
  HintHistory: map<string, CompanionHintState>
  SoloAssistHistory: map<string, CompanionAssistState>
```

```text
CompanionHintState
  HintId: string
  FirstShownAt: number
  TimesShown: number
```

```text
CompanionAssistState
  AssistId: string
  FirstUsedAt: number
  TimesUsed: number
```

Persistent companion state prevents repeated tutorial spam and supports analytics around solo assistance.

### Settings

Stores player preferences.

```text
Settings
  InputMode: "Auto" | "KeyboardMouse" | "Gamepad" | "Touch"
  HintsEnabled: boolean
  DialogueSpeed: number
  ReducedMotion: boolean
```

Client-side input detection may be runtime-only, but saved settings should persist when a player chooses a preference.

### Timestamps

Stores save-level timing metadata.

```text
Timestamps
  CreatedAt: number
  LastSavedAt: number
  LastLoadedAt: number
```

## Runtime Session Data

Runtime session data should live in service memory and should be rebuilt when a player rejoins.

Examples:

- Active interaction cooldowns.
- Current prompt visibility.
- Temporary co-op group state.
- Loaded character references.
- Remote request rate limits.
- Pending UI notifications.
- Session-only analytics events.

## Reward Data

Rewards should be represented as server-side reward bundles.

```text
RewardBundle
  RewardBundleId: string
  ExplorerScore: number?
  Items: array<ItemGrant>
  Badges: array<string>
  ZoneUnlocks: array<string>
  EpisodeUnlocks: array<string>
  DiscoveryCredit: array<string>
  JournalUnlocks: array<string>
  LoreUnlocks: array<string>
```

```text
ItemGrant
  ItemId: string
  Quantity: number
```

Reward bundles must be granted through `RewardService`. Services should not directly mutate score, inventory, badges, or unlocks.

## Explorer Score Model

Explorer Score is the primary progression value.

Score sources should be defined in reward definitions, such as:

- Discovery rewards.
- Exploration rewards.
- Puzzle completion rewards.
- Quest completion rewards.
- Teamwork bonuses.
- Hidden secret rewards.

Services should pass a reward bundle or reward source ID to `RewardService`; they should not calculate arbitrary client-provided score values.

## Solo And Co-op Metadata

Quest and interaction state should record whether progress was:

- Completed solo.
- Assisted by Proton Companion.
- Completed with co-op participants.

This metadata supports balancing, diagnostics, and future tuning while preserving the rule that solo players can progress.

## DataStore Strategy

Recommended save key:

```text
Player_<UserId>
```

Recommended save behavior:

- Load on player join.
- Validate against current schema.
- Apply migrations if needed.
- Keep an in-memory session copy.
- Autosave at a fixed interval.
- Save on player leave.
- Save during server shutdown.
- Retry transient failures with backoff.

DataStore writes must avoid partial updates from multiple services. `PlayerDataService` should be the only service that writes the full player profile.

## Migration Strategy

Every migration should:

- Check the current `SchemaVersion`.
- Add missing fields with defaults.
- Preserve existing player progress.
- Avoid deleting unknown future fields unless explicitly required.
- Increment `SchemaVersion` only after the migration step succeeds.

## Definition Data Versus Save Data

Definition data describes available content.

Save data describes player state within that content.

Definitions include:

- Episode definitions.
- Quest definitions.
- Objective definitions.
- Reward definitions.
- Item definitions.
- Discovery definitions.
- Journal definitions.
- Lore definitions.
- Badge definitions.
- Zone definitions.

Save data should reference definition IDs and store state, not duplicate full definitions.
