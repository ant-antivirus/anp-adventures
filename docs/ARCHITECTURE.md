# ANP Adventures - Technical Architecture

## Purpose

This document defines the technical architecture for ANP Adventures as a Roblox Luau project. It focuses on reusable systems, service boundaries, client/server separation, persistent progression, Proton Companion support, and episode-based expansion.

This document does not define gameplay content, quest stories, puzzles, dialogue, or zone-specific activity design.

## Architecture Principles

- Use Luau and ModuleScripts for all reusable systems.
- Keep server authority over progression, rewards, inventory, quests, badges, discoveries, journal unlocks, lore unlocks, and save data.
- Keep clients responsible for input, UI, camera presentation, local feedback, and non-authoritative previews.
- Use a service pattern on the server and a controller pattern on the client.
- Store IDs in config and definition modules instead of hardcoding NPC names, quest IDs, item IDs, badge IDs, or zone IDs in logic.
- Build every quest and interaction as solo-completable first, with co-op as an advantage rather than a requirement.
- Provide Proton Companion support for solo players whenever a mechanic would otherwise benefit from another player.
- Support episode-based expansion without rewriting core services.

## Phase 4A Feedback UI

Phase 4A adds a minimal player-facing feedback layer. `PlayerFeedbackService` sends display-only payloads through one server-to-client `RemoteEvent` at `ReplicatedStorage/ANP_Remotes/PlayerFeedbackEvent`.

The client UI may show hints, blocked interaction reasons, quest start/completion messages, objective updates, reward messages, and episode completion messages. The client must not mutate quest, reward, discovery, inventory, or episode state.

## Phase 4B Object Behavior

Phase 4B adds lightweight object behavior metadata for interactions: `Station`, `CollectibleItem`, `DiscoveryObject`, `LockedObject`, and `QuestObject`.

Station objects stay in the world and can report already-used hints. Collectibles must not grant duplicate progress or rewards after collection. Discoveries remain readable but do not reward twice. Important locked objects may stay inspectable and explain why they are not usable yet through server-authored feedback.

## Phase 4C Quest Tracker

Phase 4C adds a minimal display-only quest tracker UI. `QuestTrackerService` builds server-owned tracker state and sends `QuestTracker` payloads through the existing `PlayerFeedbackEvent`.

The client renders quest title, current objective, progress text, and hint text only. It must not calculate quest progress, mutate quest state, claim rewards, or infer inventory state.

## Phase 4E MVP QA

Phase 4E adds full Episode 1 MVP regression coverage and compact, configurable developer labels for the skeleton test track. The compact track remains developer scaffolding only; IDs, progression logic, reward logic, and RemoteEvent payload contracts stay unchanged.

The project still has no persistence implementation at this MVP checkpoint. Server authority remains intact for quest, discovery, reward, inventory, tracker, and episode state.

## Phase 5A Save Readiness

Phase 5A adds a versioned save schema, server-side serialization and validation, mock in-memory persistence, and save/load round-trip smoke coverage. It does not enable real persistence, autosave, or client-driven save/load.

`SaveService` is the server-only facade. Future persistence adapters should sit behind that facade without changing quest, reward, discovery, inventory, or episode authority.

## Phase 5B DataStore Adapter

Phase 5B adds `DataStorePersistenceService` behind `SaveService`. Real persistence is disabled by default through `PersistenceConfig`, and Studio continues to use mock persistence unless explicitly configured.

Load/save lifecycle hooks, autosave, and shutdown flush are config-gated. If a real DataStore load fails, the session is marked unsafe to save by default so default data cannot overwrite an existing cloud save.

## Recommended Folder Structure

```text
src/
  ReplicatedStorage/
    Shared/
      Config/
        GameConfig.lua
        EpisodeConfig.lua
        ZoneConfig.lua
        CharacterConfig.lua
        RankConfig.lua
        BadgeConfig.lua
        InventoryConfig.lua
        CompanionConfig.lua
        JournalConfig.lua
      Constants/
        RemoteNames.lua
        AttributeNames.lua
        DataKeys.lua
      Types/
        PlayerDataTypes.lua
        QuestTypes.lua
        RewardTypes.lua
        InventoryTypes.lua
        JournalTypes.lua
        ServiceTypes.lua
      Util/
        Signal.lua
        Maid.lua
        TableUtil.lua
      Definitions/
        Episodes/
        Quests/
        Rewards/
        Interactions/
        Discoveries/
        Lore/
        Journal/
    Remotes/
      QuestRemotes/
      InventoryRemotes/
      ProgressionRemotes/
      CompanionRemotes/
      JournalRemotes/
      InteractionRemotes/

  ServerScriptService/
    Server/
      Bootstrap.server.lua
      Services/
        PlayerDataService.lua
        QuestService.lua
        ProgressionService.lua
        RewardService.lua
        InventoryService.lua
        BadgeService.lua
        DiscoveryService.lua
        ZoneService.lua
        CompanionService.lua
        JournalService.lua
        LoreService.lua
        InteractionService.lua
        MultiplayerService.lua
        EpisodeService.lua
        AnalyticsService.lua
      Data/
        DataStoreConfig.lua
        DataMigrationService.lua
        DefaultPlayerData.lua
      Validators/
        RemoteValidator.lua
        QuestValidator.lua
        RewardValidator.lua
        DefinitionValidator.lua

  StarterPlayer/
    StarterPlayerScripts/
      Client/
        Bootstrap.client.lua
        Controllers/
          UIController.lua
          QuestController.lua
          InventoryController.lua
          ProgressionController.lua
          CompanionController.lua
          JournalController.lua
          InteractionController.lua
          ZoneController.lua
          InputController.lua
        UI/
          Screens/
          Components/
          ViewModels/
        Input/
          KeyboardMouseInput.lua
          GamepadInput.lua
          TouchInput.lua

  StarterGui/
    ANPInterface/

  Workspace/
    Zones/
    InteractionPoints/
    SpawnPoints/

  ServerStorage/
    Assets/
      NPCs/
      QuestObjects/
      ZoneTemplates/
```

## Runtime Layers

### Shared Layer

The shared layer contains definitions, configs, constants, types, and utility modules used by both client and server.

Shared modules must be deterministic and side-effect light. They should not mutate live player state, call DataStoreService, award rewards, or trust client input.

### Server Layer

The server layer owns all authoritative game state. Services are initialized by `Bootstrap.server.lua`, then communicate through direct service APIs and controlled events.

Server services must validate every client request before mutating player data or world state.

### Client Layer

The client layer owns presentation. Controllers are initialized by `Bootstrap.client.lua` and subscribe to server state through remotes.

Client controllers may cache server snapshots for UI responsiveness, but the server remains the source of truth.

## Server Authority Model

The client may request:

- Starting or advancing a quest.
- Interacting with a world object.
- Claiming a visible collectible.
- Requesting a Proton hint.
- Viewing an unlocked journal or lore entry.
- Requesting travel to an unlocked destination.
- Updating local settings.

The server must decide:

- Whether the player is allowed to perform the action.
- Whether quest objective progress changes.
- Whether rewards are granted.
- Whether Explorer Score changes.
- Whether inventory or badge state changes.
- Whether journal or lore entries unlock.
- Whether the request counts as solo, co-op, or companion-assisted progress.
- Whether persistent data should be saved.

## Solo First, Co-op Better

All quest, interaction, and reward systems must support the following rule:

Solo players can complete required progression without another human player.

Co-op may provide:

- Faster completion.
- Optional teamwork bonuses.
- Shared discovery credit when appropriate.
- More convenient interaction flows.
- Social feedback and celebration.

Co-op must not provide:

- Required-only progression gates.
- Required-only quest completion conditions.
- Required-only rewards that block main progression.
- Mechanics that Proton Companion cannot assist with for solo play.

## Proton Companion Architecture

Proton Companion is a technical support system, not a hardcoded quest workaround.

The companion system must expose reusable capabilities:

- Tutorial prompts.
- Contextual hints.
- Solo assist hooks.
- Fast travel guidance.
- Objective reminder support.
- Recovery prompts when a player is stuck.

Quest and interaction definitions should declare companion support requirements, such as:

- Whether Proton can provide a hint.
- Whether Proton can simulate a second-player assist.
- Whether Proton can activate a solo fallback path.
- Whether companion assistance should be recorded in quest state.

The `CompanionService` should not contain episode-specific puzzle logic. It should route requests to definition-driven assist behaviors.

## Episode-Based Expansion

Episode content must be data-driven where practical. New episodes should add definitions and assets without changing core services.

Each episode should define:

- Episode ID.
- Zone IDs.
- Quest definition IDs.
- Discovery IDs.
- Journal entry IDs.
- Lore entry IDs.
- Reward references.
- Badge references.
- Required progression dependencies.

Core systems should treat episodes as loaded content packages. `EpisodeService` is responsible for resolving the active episode catalog and exposing episode metadata to other services.

## Content ID Policy

IDs must be stable strings defined in config or definition modules.

Examples of ID categories:

- `EpisodeId`
- `ZoneId`
- `QuestId`
- `ObjectiveId`
- `CharacterId`
- `ItemId`
- `DiscoveryId`
- `JournalEntryId`
- `LoreId`
- `BadgeId`
- `RewardBundleId`
- `InteractionId`

Logic should reference IDs through modules, not inline string literals scattered through services.

## Remote Communication Policy

Remote names must be defined in `RemoteNames.lua`.

Remote payloads must be validated by the server before use. Validation should check:

- Expected payload shape.
- Referenced IDs exist.
- Player has required unlock state.
- Request rate is reasonable.
- Request is possible from current player state.
- Reward claims are server-derived, not client-derived.

The client should receive state snapshots and deltas, not direct write access to state.

## Persistence Policy

All progression must persist through Roblox `DataStoreService`.

Persistent systems include:

- Explorer Score.
- Explorer Rank.
- Quest completion.
- Objective progress where needed.
- Inventory.
- Discoveries.
- Journal unlocks.
- Lore unlocks.
- Badge state.
- Zone unlocks.
- Episode completion.
- Player settings.

Runtime-only systems include:

- Temporary prompts.
- Current UI screen.
- Local input mode detection.
- Non-persistent interaction cooldowns.
- Active session caches.

Phase 5C adds a controlled persistence pilot layer. `PersistenceMode` defaults to `Mock`; `StudioDataStorePilot` uses a separate pilot DataStore name and must be explicitly allowed by config. Production DataStore mode is rejected unless `AllowProductionDataStore` is enabled. Normal Studio runs should not make real cloud calls.

Phase 5D adds canary-gated pilot execution. Studio pilot load/save only runs for configured `PilotCanaryUserIds` by default, and production mode requires explicit confirmation before it is valid.

## Journal And Lore Architecture

Journal and lore content are definition-driven systems.

Journal definitions describe player-facing records such as discoveries, episode notes, fragment records, Star Core Segment records, and educational summaries.

Lore definitions describe structured world-building and educational entries connected to discoveries. Lore text must be separate from discovery IDs so localization and content edits do not change persistent progression data.

Journal and lore unlocks must be persistent. They may be triggered by:

- `DiscoveryService` when a discovery is recorded.
- `LoreService` when a lore entry is unlocked by an approved server source.
- `JournalService` when episode, quest, fragment, or Star Core Segment milestones are reached.

Journal and lore unlocks must not be granted from client-trusted state.

## Bootstrap Order

Recommended server startup order:

1. Load shared configs, constants, and definitions.
2. Validate definitions.
3. Create remotes.
4. Initialize persistent services.
5. Initialize progression, inventory, reward, badge, journal, and lore services.
6. Initialize quest, discovery, zone, companion, interaction, multiplayer, and episode services.
7. Bind player lifecycle.
8. Load player data on join.
9. Send initial state snapshots to clients.

Recommended client startup order:

1. Load shared configs, constants, and types.
2. Initialize input adapters.
3. Initialize UI shell.
4. Initialize controllers.
5. Request initial state from server.
6. Subscribe to server state updates.

## Validation And Tooling

The project should include validation scripts or test utilities for:

- Missing IDs.
- Duplicate IDs.
- Quest definitions with unreachable objectives.
- Required multiplayer mechanics without Proton solo support.
- Rewards that reference unknown item, score, badge, or unlock IDs.
- Journal or lore entries that reference unknown discoveries, quests, episodes, or items.
- Episode definitions that reference missing zones or quests.
- Data schema migration coverage.
