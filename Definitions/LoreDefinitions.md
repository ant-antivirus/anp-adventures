# Lore Definitions

## Purpose

This document defines lore records for implementation. Lore text is separate from discovery IDs so localization and content edits do not change persistent progression.

## Lore Record Schema

```text
LoreDefinition
  LoreId: string
  DiscoveryId: string
  Topic: string
  RelatedConcepts: array<string>
```

## THEOS Lore Records

| LoreId | DiscoveryId | Topic | RelatedConcepts |
| --- | --- | --- | --- |
| `lore_ep01_theos_calibration_console` | `disc_ep01_theos_calibration_console` | Satellite calibration | `satellite_calibration`, `signal_processing`, `earth_observation` |
| `lore_ep01_theos_fragment` | `disc_ep01_theos_fragment` | THEOS Fragment | `theos_fragment`, `earth_observation`, `space_technology` |
| `lore_ep01_theos_satellite_history` | `disc_ep01_theos_satellite_history` | Thai satellite history | `thai_satellite`, `satellite_history`, `earth_observation` |
| `lore_ep01_theos_theos_1` | `disc_ep01_theos_theos_1` | THEOS-1 | `theos_1`, `thai_satellite`, `satellite_imagery` |
| `lore_ep01_theos_theos_2` | `disc_ep01_theos_theos_2` | THEOS-2 | `theos_2`, `thai_satellite`, `earth_observation` |
| `lore_ep01_theos_thailand_map` | `disc_ep01_theos_thailand_map` | Thai Earth observation | `thai_satellite`, `earth_observation`, `map_reading` |
| `lore_ep01_theos_satellite_imagery` | `disc_ep01_theos_satellite_imagery` | Satellite imagery | `satellite_imagery`, `earth_science`, `change_detection` |
| `lore_ep01_theos_disaster_monitoring` | `disc_ep01_theos_disaster_monitoring` | Flood monitoring | `flood_monitoring`, `disaster_monitoring`, `public_safety` |
| `lore_ep01_theos_agriculture_monitoring` | `disc_ep01_theos_agriculture_monitoring` | Agriculture monitoring | `agriculture_monitoring`, `food_systems`, `remote_sensing` |
| `lore_ep01_theos_water_resource_monitoring` | `disc_ep01_theos_water_resource_monitoring` | Water resource monitoring | `water_resources`, `earth_systems`, `remote_sensing` |
| `lore_ep01_theos_forest_monitoring` | `disc_ep01_theos_forest_monitoring` | Forest monitoring | `forest_monitoring`, `land_cover`, `earth_observation` |

## Lore Rules

- Every `LoreId` must reference one valid `DiscoveryId`.
- Lore summaries and localized text are content fields and should be kept outside player save data.
- Lore unlock state must persist through `PlayerDataService`.
