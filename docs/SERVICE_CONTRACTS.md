# ANP Adventures - Service Contracts

## Purpose

This document defines public service APIs for the Roblox Luau server architecture.

It specifies service responsibilities, public methods, events, inputs, outputs, and validation rules. It does not define implementation code, gameplay content, quest story, puzzle logic, dialogue, or zone-specific activity design.

## Global Contract Rules

- Services are server-authoritative.
- Clients request actions through remotes; services validate and decide outcomes.
- Persistent player state is owned by `PlayerDataService`.
- Rewards are granted only through `RewardService`.
- Explorer Score is modified only through `ProgressionService`, normally as part of a reward grant.
- Quest IDs, episode IDs, zone IDs, item IDs, discovery IDs, journal entry IDs, lore IDs, reward IDs, and companion assist IDs must come from definitions or config modules.
- Required progression must be solo-completable.
- Any required mechanic that benefits from co-op must declare Proton Companion support.
- Public methods return structured results instead of raw booleans when the caller needs diagnostics.

## Shared Result Shapes

### ServiceResult

Used by mutating methods.

Inputs: none.

Outputs:

- `Success`: whether the operation completed.
- `Code`: stable result code for logs and UI routing.
- `Message`: optional diagnostic text for development.
- `Data`: optional service-specific output.

Validation rules:

- `Code` must be stable and not depend on localized UI text.
- `Message` is diagnostic only and must not drive gameplay logic.

## Player Feedback UI Contract

Phase 6A UI consumes server-to-client `PlayerFeedbackEvent` payloads for display only.

Validation rules:

- `QuestTracker` payloads are built by the server.
- Client UI must not calculate quest progress.
- Client UI must not complete objectives, grant rewards, mutate inventory, or save/load data.
- No RemoteFunction is used for UI state.

## Skeleton World Presentation Contract

Phase 6B world presentation is decorative only. `SkeletonWorldBuilder` may create zone platforms, route strips, marker adornments, and simple landmarks, but it must preserve existing gameplay IDs, prompt binding, quest progression, rewards, save/load behavior, and server authority.

Decorative parts should not block prompts or player movement during Studio playtests, and the compact Q1-Q8 route must remain fast to traverse.

## Onboarding Contract

Phase 6C onboarding is server-owned and display-only. `OnboardingService` may send `Onboarding` payloads through `PlayerFeedbackEvent`, but it must not mutate quest, inventory, reward, episode, or save state.

The client may render welcome text, marker legend lines, Episode 1 goal text, and first quest hints. It must not request onboarding state, calculate progression, skip server rules, or save onboarding decisions.

## EP1 Content Lock Contract

Phase 6D locks Episode 1 runtime content for the MVP baseline. Definition modules must keep `ep01_lost_star_core`, Quest 001 through Quest 008, required objective totals, start/objective/complete interaction routes, final reward semantics, and active EP1 zones stable.

Validation rules:

- Quest 008 must keep five required objectives.
- `reward_ep01_main_008` must grant `item_star_core_segment_01` only for Star Core segment restoration.
- EP1 must not grant future Star Core segment items.
- Quest Tracker totals must use `RequiredObjectiveIds`.
- Save payloads must validate under `SaveSchema` v1 after full EP1 completion.
- No active EP2 gameplay content should be added to the EP1 MVP baseline.

## Localization Contract

Phase 6E localization is player-facing copy only.

Validation rules:

- Runtime IDs must not be translated.
- RemoteEvent payload field names must not be translated.
- SaveSchema field names must not be translated.
- Client UI may render Thai text but must remain display-only.
- Server services still own tracker, onboarding, hint, quest, reward, and episode payload values.

## Final QA Contract

Phase 6F is a verification layer only. It may add smoke tests and QA documentation, but it must not change locked EP1 IDs, reward semantics, save/load defaults, client authority, or active episode content.

Validation rules:

- EP1 remains the only active episode.
- Quest 008 remains five required objectives.
- Thai player-facing payloads keep stable English field names.
- Real DataStore remains disabled by default.
- Client UI remains display-only.

## Release Candidate Runtime Defaults Contract

Phase 6G audits release candidate defaults and startup diagnostics.

Validation rules:

- Startup health logs must be concise and must not include save payloads.
- `PersistenceMode` remains `Mock` by default.
- Real and production DataStore paths remain disabled unless explicitly configured for a separate pilot.
- Thai remains the default player-facing locale for EP1.
- RC smoke checks must not add gameplay features or new active episode content.

### PlayerRef

Used by all player-facing methods.

Inputs:

- `Player`: Roblox `Player` instance.

Validation rules:

- Player must exist.
- Player must still be connected unless the method explicitly supports leave/shutdown save.
- Player data must be loaded before progression, quest, inventory, discovery, zone, companion, or episode mutations.

### SourceContext

Used for auditability and duplicate-safe grants.

Inputs:

- `SourceType`: source category such as quest, discovery, zone, companion, or admin tooling.
- `SourceId`: stable source ID.
- `RequestId`: optional idempotency key for repeat-safe operations.
- `ActorUserIds`: optional participating player UserIds.

Validation rules:

- `SourceType` must be known.
- `SourceId` must be a stable definition ID when tied to content.
- `RequestId` must be reused for retries of the same operation and must not be reused for unrelated operations.

## PlayerDataService

### Responsibilities

- Own in-memory player data sessions.
- Support server-side save payload apply/read hooks for persistence services.
- Create default player data for new players.
- Validate loaded data.
- Apply schema migrations.
- Own the in-memory session copy of player data.
- Provide controlled read and mutation APIs.
- Future phases may save on autosave interval, player leave, and server shutdown.
- Prevent unrelated services from writing directly to persistence adapters.

### Public Methods

#### `LoadPlayerData`

Inputs:

- `PlayerRef`.

Outputs:

- `ServiceResult.Data.PlayerDataSnapshot`.
- `ServiceResult.Data.WasCreated`.
- `ServiceResult.Data.WasMigrated`.

Validation rules:

- Must reject duplicate load attempts for the same connected player.
- Must validate `UserId`.
- Must validate loaded schema before exposing data to other services.
- Must apply migrations before returning success.

#### `ReleasePlayerData`

Inputs:

- `PlayerRef`.
- `Reason`: player leaving, shutdown, or administrative release.

Outputs:

- `ServiceResult.Data.Saved`.
- `ServiceResult.Data.SaveAttemptCount`.

Validation rules:

- Must only release loaded player data.
- Must attempt final save unless data is explicitly marked read-only or failed to load.
- Must prevent further mutations after release begins.

#### `GetSnapshot`

Inputs:

- `PlayerRef`.
- `Path`: optional data section path such as progression, quests, inventory, zones, or companion.

Outputs:

- Immutable snapshot of requested player data.

Validation rules:

- Must only return data for loaded players.
- Must not return a mutable reference to the live session table.
- Must reject unknown paths.

#### `Mutate`

Inputs:

- `PlayerRef`.
- `MutationName`: stable name for audit logs.
- `SourceContext`.
- `MutationRequest`: structured mutation payload.

Outputs:

- `ServiceResult.Data.Changed`.
- `ServiceResult.Data.UpdatedSnapshot`: optional changed section snapshot.

Validation rules:

- Must only mutate loaded, unreleased player data.
- Must validate the mutation is allowed for the calling service.
- Must keep data schema valid after mutation.
- Must mark dirty state when data changes.

#### `SaveNow`

Inputs:

- `PlayerRef`.
- `Reason`: manual, autosave, player leave, shutdown, or recovery.

Outputs:

- `ServiceResult.Data.Saved`.
- `ServiceResult.Data.LastSavedAt`.

Validation rules:

- Must only save loaded player data.
- Must serialize valid data only.
- Must apply retry policy for transient DataStore failures.

Phase 5B note: Real save calls are routed through `SaveService` and are disabled by default unless `PersistenceConfig` enables lifecycle persistence.

Phase 5C note: `PersistenceConfig.Validate` must reject unsafe DataStore mode combinations before live lifecycle hooks are used.

Phase 5D note: Studio pilot lifecycle save/load must respect canary UserId gating and production mode must require explicit confirmation.

## SaveService

### Responsibilities

- Build server-owned save payloads.
- Validate save payloads before persistence or apply.
- Route saves to mock or DataStore adapters based on `PersistenceConfig`.
- Keep client code out of save/load decisions.
- Block saves after real DataStore load failure by default.
- Track server-only persistence session diagnostics for load/save attempts, result codes, timestamps, default-data use, and blocked-save reasons.
- Skip real persistence for non-canary Studio pilot players by default.

### Public Methods

#### `BuildSave`

Inputs:

- `PlayerRef`.

Outputs:

- Validated save payload.

#### `SavePlayer`

Inputs:

- `PlayerRef`.

Outputs:

- Save result from the active adapter.

Validation rules:

- Must build and validate payload before adapter write.
- Must not save after failed real persistence load unless config explicitly allows it.

#### `LoadPlayer`

Inputs:

- `PlayerRef`.

Outputs:

- Load/apply result from the active adapter.

Validation rules:

- Must validate payload before applying.
- Missing save keeps default data.
- Real load failure marks the session unsafe for later save by default.

#### `IsLoaded`

Inputs:

- `PlayerRef`.

Outputs:

- `boolean`.

Validation rules:

- Must return false for released or failed-load players.

### Events

#### `PlayerDataLoaded`

Payload:

- `Player`.
- `PlayerDataSnapshot`.
- `WasCreated`.
- `WasMigrated`.

#### `PlayerDataChanged`

Payload:

- `Player`.
- `ChangedPath`.
- `UpdatedSnapshot`.
- `SourceContext`.

#### `PlayerDataSaved`

Payload:

- `Player`.
- `Reason`.
- `LastSavedAt`.

#### `PlayerDataSaveFailed`

Payload:

- `Player`.
- `Reason`.
- `ErrorCode`.
- `AttemptCount`.

## QuestService

### Responsibilities

- Own quest lifecycle state.
- Start, progress, and complete quests.
- Validate objective progress.
- Persist quest state through `PlayerDataService`.
- Request quest rewards through `RewardService`.
- Record solo, co-op, and Proton-assisted metadata.
- Emit quest state updates to clients.

### Public Methods

#### `CanStartQuest`

Inputs:

- `PlayerRef`.
- `QuestId`.

Outputs:

- `ServiceResult.Data.CanStart`.
- `ServiceResult.Data.Blockers`.

Validation rules:

- Quest ID must exist.
- Episode must be unlocked.
- Required zone must be unlocked when applicable.
- Quest must not already be completed unless replay is explicitly supported.
- Prerequisites must be satisfied.

#### `StartQuest`

Inputs:

- `PlayerRef`.
- `QuestId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.QuestState`.

Validation rules:

- Must pass `CanStartQuest`.
- Must initialize objective state from quest definition.
- Must not duplicate active quest entries.
- Must persist through `PlayerDataService`.

#### `GetQuestState`

Inputs:

- `PlayerRef`.
- `QuestId`: optional. If omitted, return all relevant quest states.

Outputs:

- Quest state snapshot or collection of quest state snapshots.

Validation rules:

- Player data must be loaded.
- Quest ID must exist when supplied.

#### `ApplyObjectiveProgress`

Inputs:

- `PlayerRef`.
- `QuestId`.
- `ObjectiveId`.
- `Amount`.
- `SourceContext`.
- `ProgressMetadata`: optional solo, co-op, companion, zone, or interaction context.

Outputs:

- `ServiceResult.Data.QuestState`.
- `ServiceResult.Data.ObjectiveCompleted`.
- `ServiceResult.Data.QuestCompleted`.

Validation rules:

- Quest must be active.
- Objective ID must exist in the quest definition.
- Amount must be positive and within configured limits.
- Progress source must be allowed for the objective.
- Required co-op-style objectives must have valid Proton solo support.
- Client-submitted completion must not be trusted without server-side validation.

#### `CompleteQuest`

Inputs:

- `PlayerRef`.
- `QuestId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.QuestState`.
- `ServiceResult.Data.RewardResult`.

Validation rules:

- Quest must be active.
- Required objectives must be complete.
- Completion must be idempotent.
- Reward grant must go through `RewardService`.
- Completion metadata must record solo, co-op, and companion participation where applicable.

#### `AbandonQuest`

Inputs:

- `PlayerRef`.
- `QuestId`.
- `Reason`.

Outputs:

- `ServiceResult.Data.QuestState`.

Validation rules:

- Quest must be active.
- Required main progression quests may reject abandon if the design requires persistent availability.
- Abandon must not remove completed rewards.

### Events

#### `QuestStarted`

Payload:

- `Player`.
- `QuestId`.
- `QuestState`.

#### `QuestProgressChanged`

Payload:

- `Player`.
- `QuestId`.
- `ObjectiveId`.
- `QuestState`.
- `SourceContext`.

#### `QuestCompleted`

Payload:

- `Player`.
- `QuestId`.
- `QuestState`.
- `RewardResult`.

#### `QuestBlocked`

Payload:

- `Player`.
- `QuestId`.
- `Blockers`.

## ProgressionService

### Responsibilities

- Own Explorer Score and Explorer Rank state.
- Apply server-approved score changes.
- Calculate rank from `RankConfig`.
- Persist progression through `PlayerDataService`.
- Emit progression updates to clients.

### Public Methods

#### `GetProgression`

Inputs:

- `PlayerRef`.

Outputs:

- `ProgressionSnapshot`.

Validation rules:

- Player data must be loaded.

#### `AddExplorerScore`

Inputs:

- `PlayerRef`.
- `Amount`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.PreviousScore`.
- `ServiceResult.Data.NewScore`.
- `ServiceResult.Data.PreviousRankId`.
- `ServiceResult.Data.NewRankId`.
- `ServiceResult.Data.RankChanged`.

Validation rules:

- Amount must be positive.
- Amount must come from a server-approved reward or administrative source.
- Score source must be auditable through `SourceContext`.
- Rank must be calculated from config, not hardcoded thresholds inside the service.

#### `SetExplorerScore`

Inputs:

- `PlayerRef`.
- `Amount`.
- `SourceContext`.

Outputs:

- Updated progression result.

Validation rules:

- Reserved for migration, recovery, or authorized tooling.
- Must reject normal client-driven use.
- Amount must be non-negative.

#### `GetRankForScore`

Inputs:

- `ExplorerScore`.

Outputs:

- `RankId`.
- `RankDefinition`.

Validation rules:

- Score must be non-negative.
- Rank config must contain a valid matching range.

### Events

#### `ExplorerScoreChanged`

Payload:

- `Player`.
- `PreviousScore`.
- `NewScore`.
- `SourceContext`.

#### `ExplorerRankChanged`

Payload:

- `Player`.
- `PreviousRankId`.
- `NewRankId`.
- `ExplorerScore`.

## RewardService

### Responsibilities

- Own central reward grants.
- Resolve reward bundle definitions.
- Validate reward references.
- Prevent duplicate reward claims.
- Grant Explorer Score through `ProgressionService`.
- Grant items through `InventoryService`.
- Grant discoveries through `DiscoveryService` only when appropriate.
- Grant zone and episode unlocks through `ZoneService` and `EpisodeService`.
- Return a complete reward grant summary.

### Public Methods

#### `CanGrantRewardBundle`

Inputs:

- `PlayerRef`.
- `RewardBundleId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.CanGrant`.
- `ServiceResult.Data.Blockers`.
- `ServiceResult.Data.RewardPreview`.

Validation rules:

- Reward bundle ID must exist.
- Referenced item, badge, zone, episode, and discovery IDs must exist.
- Source must be eligible to grant the bundle.
- Duplicate grant rules must be checked.

#### `GrantRewardBundle`

Inputs:

- `PlayerRef`.
- `RewardBundleId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.GrantedExplorerScore`.
- `ServiceResult.Data.GrantedItems`.
- `ServiceResult.Data.GrantedBadges`.
- `ServiceResult.Data.UnlockedZones`.
- `ServiceResult.Data.UnlockedEpisodes`.
- `ServiceResult.Data.SkippedDuplicates`.

Validation rules:

- Must pass `CanGrantRewardBundle`.
- Must be idempotent for the same source and request.
- Must not accept client-provided reward amounts.
- Must delegate each grant type to the responsible service.
- Must persist reward claim markers through `PlayerDataService`.

#### `GrantInlineReward`

Inputs:

- `PlayerRef`.
- `RewardPayload`.
- `SourceContext`.

Outputs:

- Reward grant summary.

Validation rules:

- Reserved for server-authored dynamic rewards.
- Payload must be validated against the same rules as reward bundles.
- Client-provided inline rewards are invalid.

#### `GetRewardHistory`

Inputs:

- `PlayerRef`.
- `SourceId`: optional.

Outputs:

- Reward claim history snapshot.

Validation rules:

- Player data must be loaded.
- Source filter must be a valid stable ID when provided.

### Events

#### `RewardGranted`

Payload:

- `Player`.
- `RewardBundleId`.
- `RewardSummary`.
- `SourceContext`.

#### `RewardRejected`

Payload:

- `Player`.
- `RewardBundleId`.
- `ReasonCode`.
- `SourceContext`.

## InventoryService

### Responsibilities

- Own persistent inventory item state.
- Add items from server-approved reward grants.
- Remove or consume items for server-approved actions.
- Validate item IDs against inventory definitions.
- Emit inventory snapshots and item delta events.

### Public Methods

#### `GetInventory`

Inputs:

- `PlayerRef`.
- `Category`: optional item category filter.

Outputs:

- Inventory snapshot.

Validation rules:

- Player data must be loaded.
- Category must be known when supplied.

#### `GetItemQuantity`

Inputs:

- `PlayerRef`.
- `ItemId`.

Outputs:

- `number`.

Validation rules:

- Item ID must exist.
- Player data must be loaded.

#### `AddItem`

Inputs:

- `PlayerRef`.
- `ItemId`.
- `Quantity`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.ItemState`.
- `ServiceResult.Data.PreviousQuantity`.
- `ServiceResult.Data.NewQuantity`.

Validation rules:

- Item ID must exist.
- Quantity must be positive.
- Source must be server-approved, normally `RewardService`.
- Stack limits, if defined, must be enforced.

#### `ConsumeItem`

Inputs:

- `PlayerRef`.
- `ItemId`.
- `Quantity`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.ItemState`.
- `ServiceResult.Data.PreviousQuantity`.
- `ServiceResult.Data.NewQuantity`.

Validation rules:

- Item ID must exist.
- Quantity must be positive.
- Player must own at least the requested quantity.
- Source must be server-approved.

#### `HasItem`

Inputs:

- `PlayerRef`.
- `ItemId`.
- `Quantity`: optional minimum quantity.

Outputs:

- `boolean`.

Validation rules:

- Item ID must exist.
- Quantity defaults to one and must be positive.

### Events

#### `InventoryChanged`

Payload:

- `Player`.
- `ItemId`.
- `PreviousQuantity`.
- `NewQuantity`.
- `SourceContext`.

#### `ItemAdded`

Payload:

- `Player`.
- `ItemId`.
- `QuantityAdded`.
- `ItemState`.

#### `ItemConsumed`

Payload:

- `Player`.
- `ItemId`.
- `QuantityConsumed`.
- `ItemState`.

## DiscoveryService

### Responsibilities

- Own persistent discovery state.
- Validate discovery claims.
- Track zone discovery progress.
- Prevent duplicate discovery rewards.
- Request discovery rewards through `RewardService`.
- Emit discovery updates to clients.

### Public Methods

#### `CanRecordDiscovery`

Inputs:

- `PlayerRef`.
- `DiscoveryId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.CanRecord`.
- `ServiceResult.Data.AlreadyDiscovered`.
- `ServiceResult.Data.Blockers`.

Validation rules:

- Discovery ID must exist.
- Associated episode and zone must be valid.
- Required zone must be unlocked.
- Source must be valid for the discovery.
- If player position is part of validation, proximity must be checked server-side.

#### `RecordDiscovery`

Inputs:

- `PlayerRef`.
- `DiscoveryId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.DiscoveryState`.
- `ServiceResult.Data.ZoneDiscoveryProgress`.
- `ServiceResult.Data.RewardResult`.

Validation rules:

- Must pass `CanRecordDiscovery`.
- Must be idempotent for already recorded discoveries.
- Must persist state through `PlayerDataService`.
- Reward grants must go through `RewardService`.

#### `GetDiscoveryState`

Inputs:

- `PlayerRef`.
- `DiscoveryId`: optional.

Outputs:

- Discovery state snapshot or collection.

Validation rules:

- Player data must be loaded.
- Discovery ID must exist when supplied.

#### `GetZoneDiscoveryProgress`

Inputs:

- `PlayerRef`.
- `ZoneId`.

Outputs:

- Zone discovery progress snapshot.

Validation rules:

- Zone ID must exist.
- Player data must be loaded.

### Events

#### `DiscoveryRecorded`

Payload:

- `Player`.
- `DiscoveryId`.
- `ZoneId`.
- `RewardResult`.

#### `ZoneDiscoveryProgressChanged`

Payload:

- `Player`.
- `ZoneId`.
- `FoundCount`.
- `TotalKnownCount`.
- `Completed`.

## ZoneService

### Responsibilities

- Own zone unlock state.
- Validate zone access and travel.
- Track last zone and spawn point.
- Manage fast travel eligibility.
- Expose zone state to other services and clients.

### Public Methods

#### `GetZoneState`

Inputs:

- `PlayerRef`.

Outputs:

- Zone state snapshot.

Validation rules:

- Player data must be loaded.

#### `IsZoneUnlocked`

Inputs:

- `PlayerRef`.
- `ZoneId`.

Outputs:

- `boolean`.

Validation rules:

- Zone ID must exist.
- Player data must be loaded.

#### `UnlockZone`

Inputs:

- `PlayerRef`.
- `ZoneId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.ZoneState`.
- `ServiceResult.Data.WasAlreadyUnlocked`.

Validation rules:

- Zone ID must exist.
- Source must be server-approved, normally `RewardService` or episode initialization.
- Episode containing the zone must be unlocked.
- Operation must be idempotent.

#### `CanTravelToZone`

Inputs:

- `PlayerRef`.
- `ZoneId`.
- `TravelMode`: spawn, portal, fast travel, checkpoint, or administrative.

Outputs:

- `ServiceResult.Data.CanTravel`.
- `ServiceResult.Data.Blockers`.
- `ServiceResult.Data.SpawnPointId`.

Validation rules:

- Zone ID must exist.
- Zone must be unlocked unless travel mode is administrative.
- Fast travel must be unlocked for fast travel requests.
- Travel mode must be known.

#### `TravelToZone`

Inputs:

- `PlayerRef`.
- `ZoneId`.
- `TravelMode`.
- `SpawnPointId`: optional.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.ZoneId`.
- `ServiceResult.Data.SpawnPointId`.
- `ServiceResult.Data.ZoneState`.

Validation rules:

- Must pass `CanTravelToZone`.
- Spawn point must exist and belong to the target zone.
- Last zone and spawn point must be persisted when appropriate.

#### `UnlockFastTravel`

Inputs:

- `PlayerRef`.
- `ZoneId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.ZoneState`.
- `ServiceResult.Data.WasAlreadyUnlocked`.

Validation rules:

- Zone ID must exist.
- Zone must be unlocked before fast travel is unlocked.
- Source must be server-approved.

### Events

#### `ZoneUnlocked`

Payload:

- `Player`.
- `ZoneId`.
- `SourceContext`.

#### `ZoneTravelStarted`

Payload:

- `Player`.
- `ZoneId`.
- `TravelMode`.

#### `ZoneTravelCompleted`

Payload:

- `Player`.
- `ZoneId`.
- `SpawnPointId`.

#### `FastTravelUnlocked`

Payload:

- `Player`.
- `ZoneId`.
- `SourceContext`.

## CompanionService

### Responsibilities

- Own Proton Companion support state.
- Provide tutorial, hint, fast travel, and solo assist APIs.
- Persist tutorial flags, hint history, and solo assist history.
- Validate companion support declared by quest and interaction definitions.
- Record companion-assisted progress metadata.

### Public Methods

#### `GetCompanionState`

Inputs:

- `PlayerRef`.

Outputs:

- Companion state snapshot.

Validation rules:

- Player data must be loaded.

#### `CanShowTutorial`

Inputs:

- `PlayerRef`.
- `TutorialId`.

Outputs:

- `ServiceResult.Data.CanShow`.
- `ServiceResult.Data.AlreadyShown`.

Validation rules:

- Tutorial ID must exist.
- Player settings must allow tutorial or hint presentation where applicable.

#### `MarkTutorialShown`

Inputs:

- `PlayerRef`.
- `TutorialId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.CompanionState`.

Validation rules:

- Tutorial ID must exist.
- Operation must be idempotent.
- State must persist through `PlayerDataService`.

#### `RequestHint`

Inputs:

- `PlayerRef`.
- `HintContextType`: quest, objective, zone, interaction, or general.
- `HintContextId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.HintId`.
- `ServiceResult.Data.HintPayload`.
- `ServiceResult.Data.CompanionState`.

Validation rules:

- Hint context type must be known.
- Hint context ID must exist.
- Player must be eligible to see the hint.
- Player hint settings must allow hints unless this is a required accessibility or recovery prompt.
- Hint history must be updated without spamming repeated prompts.

#### `CanUseSoloAssist`

Inputs:

- `PlayerRef`.
- `AssistId`.
- `AssistContext`.

Outputs:

- `ServiceResult.Data.CanAssist`.
- `ServiceResult.Data.Blockers`.

Validation rules:

- Assist ID must exist.
- Assist context must reference a known quest, objective, interaction, or zone.
- Assist must be declared in the relevant definition.
- Player must be solo or otherwise eligible for companion assistance.
- Assist must not bypass server quest validation.

#### `ActivateSoloAssist`

Inputs:

- `PlayerRef`.
- `AssistId`.
- `AssistContext`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.AssistResult`.
- `ServiceResult.Data.CompanionState`.

Validation rules:

- Must pass `CanUseSoloAssist`.
- Must persist assist history.
- Must notify `QuestService` or the relevant service to record companion-assisted metadata.
- Must not grant rewards directly.

#### `GetFastTravelGuidance`

Inputs:

- `PlayerRef`.
- `ZoneId`.

Outputs:

- `ServiceResult.Data.GuidanceAvailable`.
- `ServiceResult.Data.GuidancePayload`.

Validation rules:

- Zone ID must exist.
- Guidance must reflect `ZoneService` travel eligibility.
- Guidance must not unlock travel by itself.

### Events

#### `TutorialShown`

Payload:

- `Player`.
- `TutorialId`.
- `SourceContext`.

#### `HintProvided`

Payload:

- `Player`.
- `HintId`.
- `HintContextType`.
- `HintContextId`.

#### `SoloAssistActivated`

Payload:

- `Player`.
- `AssistId`.
- `AssistContext`.
- `SourceContext`.

#### `CompanionStateChanged`

Payload:

- `Player`.
- `CompanionState`.
- `ChangedPath`.

## EpisodeService

### Responsibilities

- Own episode catalog access.
- Validate episode definitions.
- Track episode unlock and completion state.
- Expose episode metadata to other services.
- Support future episode expansion without changing core service contracts.

### Public Methods

#### `GetEpisodeDefinition`

Inputs:

- `EpisodeId`.

Outputs:

- Episode definition snapshot.

Validation rules:

- Episode ID must exist.
- Returned definition must not be mutable by callers.

#### `GetEpisodeCatalog`

Inputs:

- none.

Outputs:

- Collection of episode definition snapshots.

Validation rules:

- Catalog must contain unique episode IDs.
- Catalog references must be validated during service startup.

#### `GetPlayerEpisodeState`

Inputs:

- `PlayerRef`.
- `EpisodeId`: optional.

Outputs:

- Episode state snapshot or collection.

Validation rules:

- Player data must be loaded.
- Episode ID must exist when supplied.

#### `IsEpisodeUnlocked`

Inputs:

- `PlayerRef`.
- `EpisodeId`.

Outputs:

- `boolean`.

Validation rules:

- Episode ID must exist.
- Player data must be loaded.

#### `UnlockEpisode`

Inputs:

- `PlayerRef`.
- `EpisodeId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.EpisodeState`.
- `ServiceResult.Data.WasAlreadyUnlocked`.

Validation rules:

- Episode ID must exist.
- Source must be server-approved, normally initial profile setup, reward grant, or administrative tooling.
- Prerequisites must be satisfied unless source is administrative.
- Operation must be idempotent.

#### `SetActiveEpisode`

Inputs:

- `PlayerRef`.
- `EpisodeId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.ActiveEpisodeId`.
- `ServiceResult.Data.EpisodeState`.

Validation rules:

- Episode ID must exist.
- Episode must be unlocked.
- Player data must be loaded.

#### `UpdateEpisodeProgress`

Inputs:

- `PlayerRef`.
- `EpisodeId`.
- `ProgressPatch`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.EpisodeProgress`.
- `ServiceResult.Data.Completed`.

Validation rules:

- Episode ID must exist.
- Progress patch must contain allowed fields only.
- Quest completion counts must be derived from authoritative quest state when possible.
- Completion must not be set from client input.

#### `CompleteEpisode`

Inputs:

- `PlayerRef`.
- `EpisodeId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.EpisodeState`.
- `ServiceResult.Data.CompletedAt`.

Validation rules:

- Episode ID must exist.
- Episode must be unlocked.
- Required episode completion criteria must be satisfied.
- Completion must be idempotent.
- Any completion reward must be granted through `RewardService`.

### Events

#### `EpisodeUnlocked`

Payload:

- `Player`.
- `EpisodeId`.
- `SourceContext`.

#### `ActiveEpisodeChanged`

Payload:

- `Player`.
- `PreviousEpisodeId`.
- `NewEpisodeId`.

#### `EpisodeProgressChanged`

Payload:

- `Player`.
- `EpisodeId`.
- `EpisodeProgress`.
- `SourceContext`.

#### `EpisodeCompleted`

Payload:

- `Player`.
- `EpisodeId`.
- `CompletedAt`.
- `SourceContext`.

## JournalService

### Responsibilities

- Own persistent journal unlock state.
- Unlock journal entries from approved server sources.
- Mark unlocked journal entries as viewed.
- Expose journal state snapshots to clients.
- Validate journal entry IDs against journal definitions.
- Coordinate with `DiscoveryService`, `LoreService`, `QuestService`, `InventoryService`, and `EpisodeService` for milestone-based entries.

### Public Methods

#### `GetJournalState`

Inputs:

- `PlayerRef`.
- `JournalEntryId`: optional.

Outputs:

- Journal state snapshot or one journal entry state.

Validation rules:

- Player data must be loaded.
- Journal entry ID must exist when supplied.

#### `UnlockJournalEntry`

Inputs:

- `PlayerRef`.
- `JournalEntryId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.JournalEntryState`.
- `ServiceResult.Data.WasAlreadyUnlocked`.

Validation rules:

- Journal entry ID must exist.
- Source must be server-approved.
- Operation must be idempotent.
- Unlock must persist through `PlayerDataService`.
- Client-submitted unlock claims are invalid.

#### `MarkJournalEntryViewed`

Inputs:

- `PlayerRef`.
- `JournalEntryId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.JournalEntryState`.

Validation rules:

- Journal entry ID must exist.
- Entry must already be unlocked.
- Viewing state may be requested by the client but must only update known unlocked entries.

### Events

#### `JournalEntryUnlocked`

Payload:

- `Player`.
- `JournalEntryId`.
- `SourceContext`.

#### `JournalEntryViewed`

Payload:

- `Player`.
- `JournalEntryId`.
- `SourceContext`.

## LoreService

### Responsibilities

- Own persistent lore unlock state.
- Unlock lore entries from discoveries and approved server milestones.
- Mark unlocked lore entries as viewed.
- Validate lore IDs against lore definitions.
- Ensure lore entries reference valid discoveries or milestone sources.
- Expose lore state snapshots to clients.

### Public Methods

#### `GetLoreState`

Inputs:

- `PlayerRef`.
- `LoreId`: optional.

Outputs:

- Lore state snapshot or one lore entry state.

Validation rules:

- Player data must be loaded.
- Lore ID must exist when supplied.

#### `UnlockLoreEntry`

Inputs:

- `PlayerRef`.
- `LoreId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.LoreEntryState`.
- `ServiceResult.Data.WasAlreadyUnlocked`.

Validation rules:

- Lore ID must exist.
- Source must be server-approved.
- If the lore entry is discovery-linked, the referenced discovery ID must exist.
- Operation must be idempotent.
- Unlock must persist through `PlayerDataService`.
- Client-submitted unlock claims are invalid.

#### `MarkLoreEntryViewed`

Inputs:

- `PlayerRef`.
- `LoreId`.
- `SourceContext`.

Outputs:

- `ServiceResult.Data.LoreEntryState`.

Validation rules:

- Lore ID must exist.
- Entry must already be unlocked.
- Viewing state may be requested by the client but must only update known unlocked entries.

### Events

#### `LoreEntryUnlocked`

Payload:

- `Player`.
- `LoreId`.
- `SourceContext`.

#### `LoreEntryViewed`

Payload:

- `Player`.
- `LoreId`.
- `SourceContext`.

## Required Cross-Service Validation

### Quest Completion To Reward Grant

Required flow:

1. `QuestService` validates objective completion.
2. `QuestService` calls `RewardService` with a quest source context.
3. `RewardService` validates reward eligibility and duplicate state.
4. `RewardService` delegates score, item, zone, and episode changes to owning services.
5. `PlayerDataService` persists the resulting state mutations.

Validation rules:

- Quest completion cannot directly mutate Explorer Score or inventory.
- Reward bundle IDs must be defined.
- Duplicate quest completion cannot duplicate rewards.

### Discovery To Reward Grant

Required flow:

1. `DiscoveryService` validates the discovery claim.
2. `DiscoveryService` records discovery state.
3. `DiscoveryService` unlocks configured journal or lore entries through `JournalService` or `LoreService`.
4. `DiscoveryService` calls `RewardService` with a discovery source context.
5. `RewardService` grants configured rewards.

Validation rules:

- Discovery claims must be server-validatable.
- Already discovered IDs must not grant duplicate score or items.
- Journal and lore unlocks must be idempotent and persistent.

### Solo Assist To Quest Progress

Required flow:

1. `QuestService` or another system identifies a solo assist need.
2. `CompanionService` validates assist eligibility.
3. `CompanionService` activates Proton assist.
4. `QuestService` records companion-assisted metadata when progress changes.

Validation rules:

- Proton assist must be declared in the relevant definition.
- Proton assist cannot bypass quest completion validation.
- Required co-op-style mechanics must have a valid solo assist path.

### Episode Expansion

Required flow:

1. `EpisodeService` loads episode definitions.
2. Definitions reference quests, zones, discoveries, and rewards by stable IDs.
3. Services consume episode definitions without hardcoding episode content.
4. Player save data stores episode progress by episode ID.

Validation rules:

- New episodes must not require root save schema changes unless a migration is explicitly defined.
- Episode references must resolve before the episode is considered valid.
