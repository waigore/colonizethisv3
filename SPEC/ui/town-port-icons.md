# Town and Port Icons — SPEC/ui/town-port-icons.md

**SPEC/ui** — Pixel art icons for towns and ports on the map widget. Renders **level- and style-aware town** icons at `province.townTileKey` and **port** icons at authoritative port tiles from `portsByProvinceSeaboard`. Town development level valid range is **1–4** (Refs #3870). Tapping either icon emits `OpenProvinceDetailPanelEvent` via the app event bus.

---

## Overview

Towns use **16** distinct 64×64 glyphs: **4 development levels × 3 architectural styles**. Port provinces render town + port glyphs. Port icon unchanged (`ui_icon_com_port.png`).

| Style | When |
|-------|------|
| `euro` | Great Power Old World, Minor Nation Old World, unowned Old World |
| `colonial` | Great Power New World, unowned New World |
| `tribal` | Tribe-owned (any region) |

Style resolution (`townIconStyleForProvince` in `colonizethis_map`):

1. If `ownerId` maps to **Tribe** → `tribal`
2. Else if `regionId == newWorld` and (`ownerId` is null/unowned **or** `ownerId` maps to **Great Power**) → `colonial`
3. Else → `euro`

---

## Asset Files

Pattern: `app/assets/icons/64/ui_icon_com_town_{style}_{level}_64.png`  
Cache id: `town_{style}_{level}` where `{style}` ∈ `euro` | `colonial` | `tribal`, `{level}` ∈ `1`–`4`.

| Example file | Cache id |
|--------------|----------|
| `ui_icon_com_town_euro_1_64.png` | `town_euro_1` |
| `ui_icon_com_town_colonial_3_64.png` | `town_colonial_3` |
| `ui_icon_com_town_tribal_4_64.png` | `town_tribal_4` |
| `ui_icon_com_port.png` | `port` |

Retired: `ui_icon_com_town_inland_64.png` / `town_inland_64`.

### Asset and Render Requirements

- **Format:** 64×64 PNG, RGBA transparent.
- **Style:** Colonial-era pixel art; level progression increases cluster size / silhouette height monotonically within each style set.
- **Fog:** Fogged town tiles render the **true** level glyph at reduced opacity; unrevealed tiles show **no** town icon.
- **Capital ring:** GP capital town tiles (always level 4) use level-4 glyph + gold ring; non-GP capitals use their **actual** level glyph + ring.

---

## View data (`TownMarkerView`)

| Field | Meaning |
|-------|--------|
| `townDevelopmentLevel` | Province level 1–4 for glyph selection |
| `townIconStyle` | `euro`, `colonial`, or `tribal` |
| (existing fields) | `x`, `y`, `provinceId`, `isPort`, `portIconX/Y`, … |

Map render resolves icon id via `TownIconCache.townIconIdForMarker(style, level)`.

---

## Acceptance Criteria (Given–When–Then)

- **Given** a province with `townDevelopmentLevel` **L** (1–4) and style **S** per style resolution, **when** the map renders the town tile in full visibility, **then** the glyph is `town_{S}_{L}`.
- **Given** `townDevelopmentLevel` changes after turn resolution, **when** the map refreshes, **then** the matching level glyph renders without reload.
- **Given** a fogged town tile, **when** the map renders, **then** the icon shows the **true** level (reduced opacity only).
- **Given** an unrevealed town tile, **when** the map renders, **then** **no** town icon is drawn.
- **Given** each style, **when** opaque pixel counts and `maxColumnHeight` are measured on levels 1–4, **then** both strictly increase **1 < 2 < 3 < 4**.

(Port placement, tap/hit-test, and event-bus ACs unchanged from prior spec — see GitHub #1361.)

---

## Implementation Notes

- `TownIconCache` loads all 16 town ids plus `port` (`kTownIconIds`).
- `buildTownMarkers` populates `townDevelopmentLevel` and `townIconStyle` from province + game faction data.
- Province overlay Political section shows `Town development: {level}` (Refs #3870, `SPEC/ui/province-sea-zone-detail-overlay.md`).
