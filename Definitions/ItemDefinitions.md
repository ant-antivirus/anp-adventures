# Item Definitions

## Purpose

This document defines item records used by inventory, reward, quest, and episode completion validation.

## Item Record Schema

```text
ItemDefinition
  ItemId: string
  Category: string
  Stackable: boolean
  Persistent: boolean
  FragmentType: string?
  SegmentType: string?
```

## Episode 1 Fragment Items

| ItemId | Category | Stackable | Persistent | FragmentType | SegmentType |
| --- | --- | --- | --- | --- | --- |
| `item_ep01_fragment_universe` | EpisodeFragment | false | true | Universe | None |
| `item_ep01_fragment_earth` | EpisodeFragment | false | true | Earth | None |
| `item_ep01_fragment_theos` | EpisodeFragment | false | true | THEOS | None |
| `item_ep01_fragment_rocket` | EpisodeFragment | false | true | Rocket | None |
| `item_ep01_fragment_moon` | EpisodeFragment | false | true | Moon | None |

## Star Core Segment Items

| ItemId | Category | Stackable | Persistent | FragmentType | SegmentType |
| --- | --- | --- | --- | --- | --- |
| `item_star_core_segment_01` | StarCoreSegment | false | true | None | Segment01 |
| `item_star_core_segment_02` | StarCoreSegment | false | true | None | Segment02 |
| `item_star_core_segment_03` | StarCoreSegment | false | true | None | Segment03 |
| `item_star_core_segment_04` | StarCoreSegment | false | true | None | Segment04 |
| `item_star_core_segment_05` | StarCoreSegment | false | true | None | Segment05 |

## Item Rules

- Episode fragments are collectible achievement items and must not be consumed during assembly.
- Segment items are persistent inventory records keyed by `ItemId`.
- Future segment items must be added as new item definitions, not as root save fields.
