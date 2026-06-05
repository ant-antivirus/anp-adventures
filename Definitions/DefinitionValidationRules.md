# Definition Validation Rules

## Purpose

This document defines validation requirements for ANP Adventures content definitions before packaging and runtime loading.

## Duplicate ID Validation

- Reject duplicate `EpisodeId` values.
- Reject duplicate `ZoneId` values.
- Reject duplicate `QuestId` and `ObjectiveId` values.
- Reject duplicate `RewardBundleId` values.
- Reject duplicate `DiscoveryId` values.
- Reject duplicate `ItemId` values.
- Reject duplicate `JournalEntryId` values.
- Reject duplicate `LoreId` values.
- Reject duplicate companion assist IDs when companion definitions are implemented.

## Broken Reference Validation

- Every quest `EpisodeId` must resolve to an episode definition.
- Every quest `ZoneId` must resolve to a zone definition in the same episode.
- Every episode `QuestId` must resolve to a quest definition.
- Every episode `ZoneId` must resolve to a zone definition.
- Every reward referenced by a quest, discovery, or episode must resolve to a reward definition.
- Every item referenced by a reward or completion requirement must resolve to an item definition.
- Every badge referenced by a reward must resolve to badge config.
- Every journal unlock referenced by a reward or discovery must resolve to a journal definition.
- Every lore unlock referenced by a reward or discovery must resolve to a lore definition.

## Missing Reward Validation

- Every main quest must define at least one main reward bundle.
- Every optional objective with Explorer Score must define or reference a duplicate-safe reward bundle.
- Every teamwork bonus must define a duplicate-safe reward bundle and must not unlock required progression.
- Every discovery with standalone Explorer Score must define a reward bundle or explicitly declare that its score is included in a quest reward bundle.

## Missing Lore Reference Validation

- Every lore definition must reference one valid discovery.
- Every THEOS lore entry listed in `docs/QUEST_BIBLE.md` must exist in `Definitions/LoreDefinitions.md`.
- Lore unlock rewards must not reference missing discoveries.

## Missing Journal Reference Validation

- Every `JournalUnlocks[]` reference in reward definitions must resolve.
- Every `JournalUnlockIds[]` reference in discovery definitions must resolve.
- Journal unlock source IDs must resolve against their declared source type.

## Missing Discovery Reference Validation

- Every zone `DiscoveryRequirements` entry must resolve to a discovery definition.
- Every discovery `ZoneId` must resolve to a zone definition.
- Every lore `DiscoveryId` must resolve to a discovery definition.

## Invalid Reward Reference Validation

- Reward `Items[]` must reference known item IDs and positive quantities.
- Reward `ExplorerScore` must be numeric and non-negative.
- Reward `UnlockZones[]` must reference known zone IDs.
- Reward `UnlockEpisodes[]` must reference known episode IDs.
- Reward `DuplicatePolicy` must be present and specific enough for idempotent grants.
- Rewards must not consume Episode 1 fragment items.

## Invalid Zone Reference Validation

- Zone `EpisodeId` must resolve to an episode.
- Zone unlock rules must reference known quests, rewards, or default setup rules.
- Zone spawn point IDs must be stable strings and unique within the zone.
- Fast travel eligibility must not unlock a zone by itself.

## Invalid Episode Reference Validation

- Episode completion requirements must reference known quests, items, or milestones.
- Episode reward bundles must resolve.
- Episode completion must not require future episode segment items.
- Future episodes must add definitions and keyed progress entries without root save schema changes.

## Solo And Companion Validation

- Every required quest objective must be solo-completable.
- Any required mechanic that benefits from co-op must list a Proton companion assist.
- Companion assists must not grant missing fragments, rewards, badges, journal entries, lore entries, or score directly.
