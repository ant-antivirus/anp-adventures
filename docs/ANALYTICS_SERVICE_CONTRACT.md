# ANP Adventures - Analytics Service Contract

## Purpose

This document defines the architecture contract and public API specification for `AnalyticsService`.

ANP Adventures is a family-friendly Roblox adventure game. Analytics is used only to understand gameplay balance, progression flow, retention, funnels, and technical errors.

This document does not define implementation code, gameplay content, quest story, puzzle logic, dialogue, or analytics vendor configuration.

## Privacy Policy

Analytics must never store:

- Personal information.
- Player display names.
- Usernames.
- Chat messages.
- Private user content.
- Free-form player text.
- Precise real-world location.
- Contact information.
- Device identifiers outside Roblox-approved operational metadata.

Analytics may store:

- Roblox `UserId` only if required for retention analysis and only as a hashed or internal pseudonymous key.
- Stable content IDs such as quest IDs, episode IDs, zone IDs, discovery IDs, item IDs, reward IDs, rank IDs, hint IDs, and assist IDs.
- Server timestamps.
- Session duration.
- Aggregated gameplay metrics.
- Error codes and service names.
- Platform category such as desktop, mobile, gamepad, or unknown.

## Service Responsibilities

`AnalyticsService` owns technical event capture for product analysis and diagnostics.

Responsibilities:

- Track gameplay balancing signals.
- Track quest start, progress, and completion.
- Track discovery found events.
- Track zone entry and completion.
- Track episode start and completion.
- Track Explorer Rank changes.
- Track Proton Companion hint and solo assist usage.
- Track inventory item collection.
- Track reward grants.
- Track session start and session end.
- Track funnel step progress.
- Track service and validation errors.
- Sanitize all event payloads before recording.
- Enforce privacy rules before any event leaves the server.
- Provide service APIs for other server services to record analytics events.

Does not:

- Control gameplay outcomes.
- Gate player progression.
- Award rewards.
- Mutate player save data.
- Store personal information.
- Store chat messages.
- Store private user content.
- Trust arbitrary client-submitted analytics payloads.

## Public Methods

### `StartSession`

Inputs:

- `PlayerRef`.
- `SessionStartContext`.

Outputs:

- `AnalyticsResult.Data.SessionId`.
- `AnalyticsResult.Data.StartedAt`.

Validation rules:

- Player must exist and be connected.
- Session must not already be active for the same player.
- Context must be sanitized before storage.
- No username, display name, chat text, or private content may be included.

### `EndSession`

Inputs:

- `PlayerRef`.
- `EndReason`: leave, shutdown, disconnect, teleport, or error.
- `SessionEndContext`: optional.

Outputs:

- `AnalyticsResult.Data.SessionMetrics`.
- `AnalyticsResult.Data.EndedAt`.

Validation rules:

- Session must be active.
- Duration must be non-negative.
- End reason must be known.
- Final metrics must be sanitized.

### `TrackEvent`

Inputs:

- `PlayerRef`: optional for server-only events.
- `AnalyticsEvent`.

Outputs:

- `AnalyticsResult.Data.Accepted`.
- `AnalyticsResult.Data.EventId`.

Validation rules:

- Event type must be allowlisted.
- Event schema must match the event type.
- Event must include `AnalyticsContext`.
- Payload must not contain personal information, chat messages, private user content, or free-form player text.
- Unknown keys must be dropped or rejected according to validation mode.

### `TrackQuestStarted`

Inputs:

- `PlayerRef`.
- `QuestId`.
- `EpisodeId`.
- `ZoneId`: optional.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Quest ID must be known.
- Episode ID must be known.
- Zone ID must be known when supplied.
- Player session should be active.

### `TrackQuestProgressed`

Inputs:

- `PlayerRef`.
- `QuestId`.
- `ObjectiveId`.
- `ProgressValue`.
- `RequiredValue`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Quest ID and objective ID must be known.
- Progress values must be numeric and non-negative.
- Progress must not include player-entered text.

### `TrackQuestCompleted`

Inputs:

- `PlayerRef`.
- `QuestId`.
- `EpisodeId`.
- `ZoneId`: optional.
- `CompletionContext`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Quest ID and episode ID must be known.
- Completion context must use allowed fields only.
- Solo, co-op, and Proton-assisted metadata may be included as booleans or counts.

### `TrackDiscoveryFound`

Inputs:

- `PlayerRef`.
- `DiscoveryId`.
- `ZoneId`.
- `EpisodeId`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Discovery ID, zone ID, and episode ID must be known.
- Discovery event must not include screenshots, chat, or private content.

### `TrackZoneEntered`

Inputs:

- `PlayerRef`.
- `ZoneId`.
- `EpisodeId`.
- `TravelMode`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Zone ID and episode ID must be known.
- Travel mode must be one of the approved zone travel modes.

### `TrackZoneCompleted`

Inputs:

- `PlayerRef`.
- `ZoneId`.
- `EpisodeId`.
- `ZoneCompletionContext`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Zone ID and episode ID must be known.
- Completion context must contain aggregate values only.

### `TrackEpisodeStarted`

Inputs:

- `PlayerRef`.
- `EpisodeId`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Episode ID must be known.
- Session should be active.

### `TrackEpisodeCompleted`

Inputs:

- `PlayerRef`.
- `EpisodeId`.
- `EpisodeCompletionContext`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Episode ID must be known.
- Completion context must be derived from authoritative services.
- Completion cannot be based only on client input.

### `TrackExplorerRankChanged`

Inputs:

- `PlayerRef`.
- `PreviousRankId`.
- `NewRankId`.
- `ExplorerScore`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Rank IDs must be known.
- Explorer Score must be numeric and non-negative.
- Event should be emitted by `ProgressionService`.

### `TrackCompanionHintRequested`

Inputs:

- `PlayerRef`.
- `HintId`.
- `HintContextType`.
- `HintContextId`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Hint ID must be known.
- Hint context type must be known.
- Hint context ID must refer to a known quest, objective, zone, interaction, or general support context.
- Hint payload text must not be stored.

### `TrackCompanionSoloAssistActivated`

Inputs:

- `PlayerRef`.
- `AssistId`.
- `AssistContextType`.
- `AssistContextId`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Assist ID must be known.
- Assist context must be known.
- Event should be emitted by `CompanionService`.
- Assist output text or private player content must not be stored.

### `TrackInventoryItemCollected`

Inputs:

- `PlayerRef`.
- `ItemId`.
- `Quantity`.
- `SourceContext`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Item ID must be known.
- Quantity must be positive.
- Source context must be server-approved.

### `TrackRewardGranted`

Inputs:

- `PlayerRef`.
- `RewardBundleId`: optional for inline server rewards.
- `RewardSummary`.
- `SourceContext`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Reward IDs must be known when supplied.
- Reward summary must contain aggregate grant data only.
- Reward event should be emitted by `RewardService`.
- Client-provided reward values are invalid.

### `TrackError`

Inputs:

- `ErrorTrackingEvent`.
- `AnalyticsContext`: optional.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Error code must be stable.
- Service name must be known.
- Stack traces, if captured in development, must be sanitized before analytics storage.
- No player names, chat text, private content, or raw payloads may be stored.

### `TrackFunnelStep`

Inputs:

- `PlayerRef`.
- `FunnelEvent`.
- `AnalyticsContext`.

Outputs:

- `AnalyticsResult`.

Validation rules:

- Funnel ID must be known.
- Step ID must be known for the funnel.
- Step order must be numeric and non-negative.
- Funnel payload must contain stable IDs and aggregate metrics only.

## Event Contracts

All event names must be stable strings.

Supported analytics events:

- `SessionStarted`
- `SessionEnded`
- `QuestStarted`
- `QuestProgressed`
- `QuestCompleted`
- `DiscoveryFound`
- `ZoneEntered`
- `ZoneCompleted`
- `EpisodeStarted`
- `EpisodeCompleted`
- `ExplorerRankChanged`
- `CompanionHintRequested`
- `CompanionSoloAssistActivated`
- `InventoryItemCollected`
- `RewardGranted`
- `FunnelStepReached`
- `ErrorRecorded`

Event routing rules:

- Gameplay services emit analytics through `AnalyticsService` public methods.
- `AnalyticsService` validates and sanitizes payloads.
- `AnalyticsService` may buffer events for reliable delivery.
- Analytics failure must not block gameplay progression.
- Analytics failure may be logged through diagnostics.

## Data Schemas

### AnalyticsResult

```text
AnalyticsResult
  Success: boolean
  Code: string
  Message: string?
  Data: map?
```

Validation rules:

- `Code` must be stable.
- `Message` must be diagnostic only.
- Analytics failures must not expose private data.

### AnalyticsEvent

```text
AnalyticsEvent
  EventId: string
  EventType: string
  Version: number
  OccurredAt: number
  PlayerKey: string?
  SessionId: string?
  Context: AnalyticsContext
  Payload: map
```

Field rules:

- `EventId` is a generated unique event key.
- `EventType` must be allowlisted.
- `Version` supports schema evolution.
- `OccurredAt` uses server time.
- `PlayerKey` must be pseudonymous and must not be a username or display name.
- `SessionId` must be generated by the server.
- `Payload` must match the event-specific schema.

### AnalyticsContext

```text
AnalyticsContext
  PlaceId: number
  JobId: string
  ServerStartedAt: number?
  SessionId: string?
  PlayerKey: string?
  EpisodeId: string?
  ZoneId: string?
  QuestId: string?
  PlatformCategory: "Desktop" | "Mobile" | "Gamepad" | "Unknown"
  PlayMode: "Solo" | "Coop" | "Unknown"
  PartySize: number?
  IsProtonAssisted: boolean?
  SourceService: string
  SourceType: string?
  SourceId: string?
```

Validation rules:

- `SourceService` must be known.
- Stable IDs must resolve when supplied.
- `PartySize` must be between 1 and 8 when supplied.
- `PlatformCategory` must not store exact device identifiers.
- `PlayerKey` must be pseudonymous.

### SessionMetrics

```text
SessionMetrics
  SessionId: string
  PlayerKey: string
  StartedAt: number
  EndedAt: number?
  DurationSeconds: number
  StartingEpisodeId: string?
  EndingEpisodeId: string?
  StartingZoneId: string?
  EndingZoneId: string?
  QuestsStarted: number
  QuestsCompleted: number
  DiscoveriesFound: number
  ZonesEntered: number
  ZonesCompleted: number
  RewardsGranted: number
  ItemsCollected: number
  HintsRequested: number
  SoloAssistsActivated: number
  ExplorerScoreEarned: number
  RankChanges: number
  ErrorCount: number
```

Validation rules:

- Counts must be non-negative.
- Duration must be non-negative.
- IDs must be stable content IDs.
- Metrics must not include player-entered text.

### Quest Analytics Payloads

```text
QuestStartedPayload
  QuestId: string
  EpisodeId: string
  ZoneId: string?
  StartedAt: number
```

```text
QuestProgressedPayload
  QuestId: string
  ObjectiveId: string
  ProgressValue: number
  RequiredValue: number
  Completed: boolean
```

```text
QuestCompletedPayload
  QuestId: string
  EpisodeId: string
  ZoneId: string?
  DurationSeconds: number?
  CompletedSolo: boolean
  CompletedCoop: boolean
  PartySize: number
  AssistedByProton: boolean
  RewardBundleId: string?
```

### Discovery Analytics Payload

```text
DiscoveryFoundPayload
  DiscoveryId: string
  ZoneId: string
  EpisodeId: string
  RewardBundleId: string?
```

### Zone Analytics Payloads

```text
ZoneEnteredPayload
  ZoneId: string
  EpisodeId: string
  TravelMode: string
  PreviousZoneId: string?
```

```text
ZoneCompletedPayload
  ZoneId: string
  EpisodeId: string
  DurationSeconds: number?
  DiscoveryCompletionPercent: number?
  RequiredQuestCount: number?
  CompletedQuestCount: number?
```

### Episode Analytics Payloads

```text
EpisodeStartedPayload
  EpisodeId: string
  StartedAt: number
```

```text
EpisodeCompletedPayload
  EpisodeId: string
  DurationSeconds: number?
  QuestCompletionPercent: number
  DiscoveryCompletionPercent: number?
  AssistedByProtonCount: number
  CoopCompletionCount: number
```

### Progression Analytics Payload

```text
ExplorerRankChangedPayload
  PreviousRankId: string
  NewRankId: string
  ExplorerScore: number
```

### Companion Analytics Payloads

```text
CompanionHintRequestedPayload
  HintId: string
  HintContextType: string
  HintContextId: string
  EpisodeId: string?
  ZoneId: string?
  QuestId: string?
```

```text
CompanionSoloAssistActivatedPayload
  AssistId: string
  AssistContextType: string
  AssistContextId: string
  EpisodeId: string?
  ZoneId: string?
  QuestId: string?
```

### Inventory Analytics Payload

```text
InventoryItemCollectedPayload
  ItemId: string
  Quantity: number
  SourceType: string
  SourceId: string
```

### Reward Analytics Payload

```text
RewardGrantedPayload
  RewardBundleId: string?
  SourceType: string
  SourceId: string
  ExplorerScoreGranted: number
  ItemGrantCount: number
  BadgeGrantCount: number
  ZoneUnlockCount: number
  EpisodeUnlockCount: number
  SkippedDuplicateCount: number
```

## Funnel Tracking Model

Funnel tracking measures player progress through known technical steps. Funnels use stable IDs and aggregate metrics only.

```text
FunnelEvent
  FunnelId: string
  StepId: string
  StepIndex: number
  EpisodeId: string?
  ZoneId: string?
  QuestId: string?
  StartedAt: number?
  ReachedAt: number
  DurationFromPreviousStepSeconds: number?
  DurationFromFunnelStartSeconds: number?
  WasCompleted: boolean
```

Recommended MVP funnels:

- `NewPlayerOnboarding`: session started, first zone entered, first quest started, first quest completed, first reward granted.
- `EpisodeProgression`: episode started, required zone entered, required quest completed, episode completed.
- `DiscoveryEngagement`: zone entered, discovery found, zone discovery progress changed, zone completed.
- `CompanionSupport`: hint requested, solo assist activated, related quest progressed, related quest completed.

Validation rules:

- Funnel ID must be allowlisted.
- Step ID must be allowlisted for the funnel.
- Step index must match the configured funnel order.
- Funnel data must not contain player names, chat, or private content.

## Error Tracking Model

Error tracking records technical diagnostics without storing sensitive payloads.

```text
ErrorTrackingEvent
  ErrorId: string
  ErrorCode: string
  Severity: "Info" | "Warning" | "Error" | "Critical"
  SourceService: string
  SourceMethod: string?
  OccurredAt: number
  PlayerKey: string?
  SessionId: string?
  EpisodeId: string?
  ZoneId: string?
  QuestId: string?
  RequestId: string?
  RetryCount: number?
  SanitizedDetails: map?
```

Allowed error categories:

- `DataStoreLoadFailed`
- `DataStoreSaveFailed`
- `RemoteValidationFailed`
- `DefinitionValidationFailed`
- `RewardGrantRejected`
- `QuestProgressRejected`
- `DiscoveryRejected`
- `ZoneTravelRejected`
- `CompanionAssistRejected`
- `AnalyticsDeliveryFailed`
- `ServiceStartupFailed`

Validation rules:

- `ErrorCode` must be stable.
- `Severity` must be allowlisted.
- `SourceService` must be known.
- `SanitizedDetails` must not contain raw remote payloads, chat, usernames, display names, or private user content.
- Stack traces are development-only unless sanitized and approved.
- Error tracking must not block gameplay except where the source service already blocks the invalid operation.

## Validation Rules

General event validation:

- Event type must be allowlisted.
- Event version must be supported.
- Event payload must match the schema for the event type.
- Stable IDs must resolve against definitions when applicable.
- Numeric values must be finite and within expected ranges.
- Party size must be between 1 and 8 when supplied.
- Durations and counts must be non-negative.
- Client-submitted analytics must be treated as untrusted.
- Unknown fields must be rejected or stripped before persistence.

Privacy validation:

- Reject any field named or shaped like username, display name, chat, message, email, phone, address, or free-form private content.
- Reject unbounded strings unless they are stable IDs, enum values, or known error codes.
- Do not store player-entered text.
- Do not store raw remote payloads.
- Do not store private user-generated content.

Reliability validation:

- Analytics recording must be non-blocking for gameplay.
- Analytics failures should emit sanitized error diagnostics.
- Duplicate events should be tolerated through `EventId`, `SessionId`, and source context.
- Events may be buffered, sampled, or dropped according to operational policy, but privacy validation must always run first.

## Cross-Service Integrations

### PlayerDataService

Analytics usage:

- Emits `SessionStarted` after player data is loaded and the session is ready.
- Emits `SessionEnded` during player release or shutdown.
- Emits error events for load, migration, save, and release failures.

Rules:

- Analytics must not write to player save data.
- Analytics must not store full player data snapshots.

### QuestService

Analytics usage:

- Emits `QuestStarted` after a quest starts.
- Emits `QuestProgressed` after objective progress is accepted.
- Emits `QuestCompleted` after quest completion is validated.
- Emits funnel steps for onboarding and episode progression.

Rules:

- Quest analytics must use stable quest and objective IDs.
- Quest analytics must not include dialogue, player chat, or private content.

### ProgressionService

Analytics usage:

- Emits `ExplorerRankChanged` when a player's rank changes.
- May include score delta context through reward analytics.

Rules:

- Explorer Score must be server-authoritative.
- Rank IDs must come from rank config.

### RewardService

Analytics usage:

- Emits `RewardGranted` after a reward grant succeeds.
- Emits error tracking for rejected or invalid reward grants.

Rules:

- Reward values must come from server-approved reward definitions or server-authored inline rewards.
- Analytics must record aggregate reward summaries, not raw mutable reward payloads.

### InventoryService

Analytics usage:

- Emits `InventoryItemCollected` when items are added from approved reward or collection flows.

Rules:

- Item IDs must come from inventory definitions.
- Quantity must be numeric and positive.

### DiscoveryService

Analytics usage:

- Emits `DiscoveryFound` when a discovery is recorded.
- Emits funnel steps for discovery engagement.

Rules:

- Discovery claims must already be server-validated.
- Discovery analytics must not include screenshots or private content.

### ZoneService

Analytics usage:

- Emits `ZoneEntered` after travel is completed.
- Emits `ZoneCompleted` when zone completion criteria are met.
- Emits error tracking for rejected travel requests when useful for diagnostics.

Rules:

- Zone IDs must come from zone definitions.
- Travel mode must be allowlisted.

### CompanionService

Analytics usage:

- Emits `CompanionHintRequested` after a valid hint request.
- Emits `CompanionSoloAssistActivated` after Proton solo assist activates.
- Emits funnel steps for companion support analysis.

Rules:

- Hint text must not be stored.
- Assist output text must not be stored.
- Companion analytics must record IDs and context only.

### EpisodeService

Analytics usage:

- Emits `EpisodeStarted` when an episode becomes active for a player.
- Emits `EpisodeCompleted` when episode completion is validated.
- Emits funnel steps for episode progression.

Rules:

- Episode IDs must come from episode definitions.
- Episode completion analytics must be derived from authoritative service state.

