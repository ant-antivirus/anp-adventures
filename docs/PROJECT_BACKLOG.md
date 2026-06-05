# ANP Adventures - Project Backlog

## Scope

This backlog defines the technical development tasks for Episode 1: The Lost Star Core.

The backlog is based on the current project documentation, including the architecture, data model, service contracts, analytics contract, gameplay rules, world structure, and technical rules.

This document does not define gameplay content, quest story, puzzle solutions, dialogue, or educational lesson material.

## Priority Definitions

- `P0`: Required for MVP.
- `P1`: Important after MVP.
- `P2`: Nice to have.

## Complexity Definitions

- `Small`: Narrow task with limited dependencies and low integration risk.
- `Medium`: Requires service coordination, shared definitions, UI integration, or persistence awareness.
- `Large`: Cross-system task involving networking, persistence, validation, analytics, or broad QA.

## P0 - Required For MVP

| Task | Description | Dependencies | Estimated Complexity |
| --- | --- | --- | --- |
| Establish Roblox project structure | Create the agreed Roblox source layout for shared modules, server services, client controllers, UI, workspace zones, and server-only assets. | Architecture folder structure | Medium |
| Create shared ID and config modules | Define stable IDs and config modules for episodes, zones, characters, ranks, inventory, badges, rewards, remotes, attributes, companion support, and data keys. | Project structure | Medium |
| Create shared Luau type modules | Define shared type contracts for player data, quests, rewards, inventory, zones, discoveries, companion state, analytics context, and service results. | Shared ID and config modules | Medium |
| Build service bootstrap plan | Define server initialization order for data, progression, rewards, inventory, quests, discoveries, zones, companion, episodes, and analytics. | Project structure, shared type modules | Medium |
| Build client controller bootstrap plan | Define client controller startup order for UI, input, quests, inventory, progression, companion prompts, interactions, and zone state. | Project structure, shared type modules | Medium |
| Define remote communication map | Create the approved remote event and remote function surface for quest, inventory, progression, companion, interaction, zone, reward, and initial state sync. | Shared ID and config modules | Medium |
| Define remote validation policy | Specify server-side validation for payload shape, known IDs, request eligibility, cooldowns, rate limits, and impossible state transitions. | Remote communication map, service contracts | Medium |
| Define default player data | Specify the default persistent save shape for profile, progression, episodes, quests, inventory, discoveries, badges, zones, companion, settings, and timestamps. | Data model, shared type modules | Medium |
| Define DataStore lifecycle | Specify load, validate, migrate, cache, autosave, leave save, shutdown save, retry, dirty-state tracking, and release behavior. | Default player data, PlayerDataService contract | Large |
| Define schema migration process | Specify schema versioning, migration order, default filling, preservation of existing progress, and migration diagnostics. | Default player data, DataStore lifecycle | Medium |
| Define PlayerDataService MVP contract usage | Map all MVP services to controlled read and mutation access through `PlayerDataService`. | DataStore lifecycle, service contracts | Large |
| Define Episode 1 catalog package | Represent Episode 1 as a data-driven content package with episode ID, zone references, quest references, discovery references, reward references, and completion criteria. | Shared ID and config modules, EpisodeService contract | Medium |
| Define zone registry for Episode 1 | Define technical zone records for the Episode 1 zone list, including unlock state, spawn references, fast travel eligibility, and episode ownership. | Episode 1 catalog package, ZoneService contract | Medium |
| Define quest definition format | Specify quest definition fields for quest ID, episode ID, zone ID, objective IDs, prerequisites, reward references, solo completion metadata, and Proton assist declarations. | Episode 1 catalog package, QuestService contract | Large |
| Define quest state machine | Specify inactive, active, completed, objective progress, reward claim markers, timestamps, co-op participants, and companion-assisted metadata. | Quest definition format, data model | Large |
| Define quest validation rules | Require known quest IDs, valid objective IDs, satisfied prerequisites, server-authoritative progress, duplicate-safe completion, and solo-completable required objectives. | Quest definition format, quest state machine | Medium |
| Define RewardService grant pipeline | Specify duplicate-safe reward bundle grants for Explorer Score, inventory items, badges, zone unlocks, episode unlocks, and reward summaries. | RewardService contract, ProgressionService contract, InventoryService contract, ZoneService contract, EpisodeService contract | Large |
| Define Explorer Score progression | Specify score sources, rank thresholds, rank updates, score persistence, server-only score changes, and rank-change events. | ProgressionService contract, RewardService grant pipeline | Medium |
| Define inventory item model | Specify persistent item records, quantity handling, item categories, collection sources, item snapshots, and item delta events. | InventoryService contract, data model | Medium |
| Define badge award model | Specify internal badge state, Roblox badge mapping, duplicate prevention, and pending award retry rules. | Data model, RewardService grant pipeline | Medium |
| Define discovery tracking model | Specify discovery IDs, zone discovery progress, duplicate-safe discovery rewards, and server-side discovery validation. | DiscoveryService contract, RewardService grant pipeline, zone registry | Medium |
| Define interaction framework contract | Specify reusable interaction IDs, server validation, routing to quest/discovery/inventory/companion systems, cooldowns, and input-neutral prompts. | Remote validation policy, QuestService contract, DiscoveryService contract, CompanionService contract | Large |
| Define Proton Companion MVP support | Specify tutorial flags, hint history, solo assist history, fast travel guidance, context validation, and companion-assisted progress metadata. | CompanionService contract, quest definition format, data model | Large |
| Define solo-first validation checklist | Specify validation that every required quest and interaction can be completed solo and that any co-op-style required mechanic declares Proton support. | Quest validation rules, interaction framework contract, Proton Companion MVP support | Large |
| Define co-op participation model | Specify player participation tracking, party size metadata, teamwork bonus eligibility, shared credit rules, and non-required co-op advantages. | Quest state machine, RewardService grant pipeline, analytics contract | Medium |
| Define Episode 1 progression flow | Specify technical dependencies between episode start, zone unlocks, quest completion, rewards, inventory state, and episode completion. | Episode 1 catalog package, quest state machine, RewardService grant pipeline, ZoneService contract | Large |
| Define MVP UI architecture | Specify required UI surfaces for quest tracking, progression, inventory, reward feedback, companion prompts, zone travel, and save/load state. | Client controller bootstrap plan, service contracts | Large |
| Define input abstraction | Specify keyboard/mouse, touch, and gamepad input adapters for interaction prompts, UI navigation, companion prompts, and zone travel. | MVP UI architecture, client controller bootstrap plan | Medium |
| Define workspace organization rules | Specify technical organization for Episode 1 zones, spawn points, interaction points, server-owned assets, NPC assets, and replicated objects. | Project structure, zone registry | Medium |
| Define analytics MVP event wiring | Specify when MVP services emit session, quest, discovery, zone, episode, rank, companion, inventory, reward, funnel, and error events. | Analytics service contract, service contracts | Medium |
| Define analytics privacy validation | Specify that analytics records stable IDs and aggregate metrics only, never personal information, chat messages, private user content, or free-form player text. | Analytics service contract | Small |
| Define MVP QA checklist | Create test coverage expectations for save/load, quest progress, reward grants, Explorer Score, rank changes, inventory, discovery, zone travel, solo completion, co-op bonuses, Proton assist, and UI input modes. | All P0 architecture tasks | Large |
| Define definition validation tooling scope | Specify validation checks for duplicate IDs, missing references, invalid rewards, unreachable objectives, invalid episode references, and required co-op mechanics without Proton support. | Shared ID and config modules, quest definition format, RewardService grant pipeline, solo-first validation checklist | Medium |

## P1 - Important After MVP

| Task | Description | Dependencies | Estimated Complexity |
| --- | --- | --- | --- |
| Add service diagnostics standards | Define structured diagnostics for service startup, data loading, save failures, reward rejections, remote validation failures, and quest progress rejection. | P0 service contracts, analytics event wiring | Medium |
| Add session recovery policy | Specify behavior for late data loads, failed data loads, save retries, reconnects during active progression, and partial service startup failures. | DataStore lifecycle, service diagnostics standards | Medium |
| Add anti-exploit hardening checklist | Expand validation expectations for impossible quest progress, interaction range checks, reward tampering, item grant tampering, and replayed remotes. | Remote validation policy, interaction framework contract, RewardService grant pipeline | Medium |
| Add reward bundle validator | Specify automated validation that reward bundles reference known score sources, items, badges, zones, episodes, discoveries, and valid source contexts. | Definition validation tooling scope, RewardService grant pipeline | Medium |
| Add quest replay policy | Specify whether completed quests support replay, whether replay grants rewards, and how replay state is separated from first-time completion state. | Quest state machine, RewardService grant pipeline | Medium |
| Add companion analytics detail | Expand analytics around hint frequency, repeated tutorial suppression, solo assist usage, and assisted completion outcomes. | Proton Companion MVP support, analytics event wiring | Small |
| Add funnel tracking definitions | Define MVP funnel IDs and steps for onboarding, episode progression, discovery engagement, and companion support. | Analytics service contract, Episode 1 progression flow | Medium |
| Add zone streaming plan | Specify technical grouping, loading boundaries, replicated object ownership, and performance rules for Episode 1 zones. | Workspace organization rules, zone registry | Medium |
| Add asset ownership standards | Define naming, storage, replication, and ownership rules for NPCs, quest objects, UI assets, zone templates, and collectible assets. | Workspace organization rules, project structure | Small |
| Add UI view model contracts | Define view model structures between client controllers and UI components for quest, progression, inventory, reward, companion, and zone screens. | MVP UI architecture, shared type modules | Medium |
| Add accessibility settings model | Specify settings for hints, dialogue speed, reduced motion, input preference, and persistence through player data. | Data model, MVP UI architecture, CompanionService contract | Medium |
| Add platform QA matrix | Define QA coverage for desktop, mobile, tablet, and gamepad input paths across core UI and interaction flows. | Input abstraction, MVP QA checklist | Medium |
| Add multiplayer edge case tests | Specify tests for player join/leave during active quest progress, shared reward eligibility, teamwork bonuses, and solo fallback after co-op interruption. | Co-op participation model, solo-first validation checklist | Medium |
| Add development debug view spec | Define a safe development-only player state viewer for progression, quests, inventory, discoveries, zones, companion state, and analytics session state. | PlayerDataService contract usage, analytics event wiring | Medium |
| Add local development workflow | Specify expected sync, validation, linting, test execution, and review flow once Roblox tooling is selected. | Project structure, definition validation tooling scope | Small |

## P2 - Nice To Have

| Task | Description | Dependencies | Estimated Complexity |
| --- | --- | --- | --- |
| Add automated definition report | Specify a generated report for episode, zone, quest, reward, discovery, item, badge, companion, and validation status. | Definition validation tooling scope | Medium |
| Add live tuning configuration model | Specify a safe approach for tuning non-critical values without changing service logic or breaking server authority. | Shared config modules, anti-exploit hardening checklist | Large |
| Add localization architecture | Define text key strategy, locale lookup rules, fallback behavior, and separation between text content and technical IDs. | MVP UI architecture, UI view model contracts | Large |
| Add analytics dashboard requirements | Define dashboard needs for retention, funnels, quest completion, zone completion, score pacing, reward grants, companion usage, and error diagnostics. | Analytics event wiring, funnel tracking definitions | Large |
| Add richer companion personalization | Specify optional persisted preferences for hint frequency, tutorial behavior, and assist prompt timing without changing progression requirements. | Accessibility settings model, Proton Companion MVP support | Medium |
| Add content authoring templates | Define templates for future episode, zone, quest, reward, discovery, item, badge, and companion assist definitions. | Episode 1 catalog package, quest definition format, RewardService grant pipeline | Medium |
| Add performance budget document | Specify target budgets for memory, network events, UI responsiveness, zone object counts, analytics event volume, and server work per player. | Zone streaming plan, analytics event wiring | Medium |
| Add automated save migration tests | Specify fixture-based tests for older save shapes migrating into the current player data schema. | Schema migration process, session recovery policy | Large |
| Add automated remote validation tests | Specify tests for malformed payloads, unknown IDs, replayed requests, rate limits, impossible progress, and reward tampering attempts. | Remote validation policy, anti-exploit hardening checklist | Large |
| Add future episode readiness checklist | Define expansion readiness checks to ensure new episodes can be added through definitions without service rewrites. | Episode 1 catalog package, content authoring templates, definition validation tooling scope | Medium |

## MVP Exit Criteria

- Episode 1 is represented as a data-driven episode package.
- All required progression is server-authoritative.
- All progression persists through `DataStoreService`.
- Explorer Score and Explorer Rank save and restore correctly.
- Quest state, inventory, discoveries, badges, zones, companion state, and episode progress save and restore correctly.
- Rewards are granted only through `RewardService`.
- Reward grants are duplicate-safe.
- Every required quest and required interaction is solo-completable.
- Any co-op-benefiting required mechanic declares Proton Companion support.
- UI architecture supports mobile, gamepad, and PC.
- Analytics records only stable IDs and aggregate metrics, never personal information, chat, or private user content.
- Definition validation catches duplicate IDs, missing references, invalid rewards, invalid episode references, and required co-op mechanics without Proton support.

