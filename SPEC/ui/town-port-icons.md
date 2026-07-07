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
| `ui_icon_com_town_{style}_1_legacy_64.png` | `town_{style}_1` (S9c rollback only; `CT_LEGACY_TOWN_ICONS=true`) |
| `ui_icon_com_town_colonial_3_64.png` | `town_colonial_3` |
| `ui_icon_com_town_tribal_4_64.png` | `town_tribal_4` |
| `ui_icon_com_port.png` | `port` |

Retired: `ui_icon_com_town_inland_64.png` / `town_inland_64`.

### Asset and Render Requirements

- **Format:** 64×64 PNG, RGBA transparent.
- **Style:** Colonial-era pixel art; development levels differ by **architectural complexity** (structure count, roof variety, spires/totems, walls/enclosures) — **not** by shrinking the overall silhouette.
- **On-map size parity:** All four levels target the same **48×48 px inner box** centered in the 64×64 canvas (8 px margin). Level **1** must appear **as large on the map** as levels 2–4 and other 64×64 map markers (port, resources). **S9c (merged):** PO-approved S9b level-1 candidates are promoted to default production paths; retired S9a hamlets live at `_legacy_64` paths for rollback.
- **S9c legacy fallback flag:** `CT_LEGACY_TOWN_ICONS` compile-time dart define (`defaultValue: false`). When **false** (default), `TownIconCache` loads promoted production `ui_icon_com_town_{style}_1_64.png` for level **1** and canonical paths for levels **2–4**. When **true**, level **1** only loads `ui_icon_com_town_{style}_1_legacy_64.png` (retired S9a hamlets). Config: `app/lib/config/ct_legacy_town_icons.dart`.
- **S9b candidate art (completed):** Regenerated with PixelLab **Pixflux** using the verbatim prompt table below (Refs #3870). PO-approved level-1 candidates promoted to production in S9c; `_candidate_64` paths removed.

### PixelLab prompts (Pixflux — S9b candidates)

Shared negative: `blurry, anti-aliased, smooth gradient, photorealistic, circular background, text label, modern buildings, tiny distant buildings, small cluster in center with large empty margins, black lines only, outline only, wireframe, sprite sheet`

**European (`euro`) — base:** `16th century European settlement pixel art, stone and timber houses, steep roofs, centered on transparent background, fills the icon frame`

| Level | Description append |
|-------|-------------------|
| 1 | `, hamlet with 2-3 simple cottages spread across the full frame, same map scale as larger towns, no church tower, no spire, low flat roofs only, filled roofs and walls not outlines` |
| 2 | `, small village with 4 houses and one low church roof, one bell-cote, modest detail, no tall spire` |
| 3 | `, walled market town with 6 buildings and one church tower, medium spire, denser cluster` |
| 4 | `, grand European city with 8 buildings and two church spires, tallest spire dominates, dense medieval city cluster` |

**Colonial (`colonial`) — base:** `17th century American colonial settlement pixel art, wooden buildings, centered on transparent background, fills the icon frame`

| Level | Description append |
|-------|-------------------|
| 1 | `, frontier hamlet with 2-3 log cabins spread across the full frame, same map scale as larger settlements, no bell tower, no steeple, filled roofs and walls not outlines` |
| 2 | `, village with 4 wooden houses and a small meeting hall, one low roof peak, no tall steeple` |
| 3 | `, colonial town with 6 buildings, palisade segment, one church steeple, denser` |
| 4 | `, large colonial city with 8 buildings, two steeples, grand plaza, tallest steeple dominates` |

**Tribal (`tribal`) — base:** `indigenous American woodland settlement pixel art, longhouses and totems, centered on transparent background, fills the icon frame`

| Level | Description append |
|-------|-------------------|
| 1 | `, camp with 2-3 lodges spread across the full frame, same map scale as larger settlements, no totem pole, filled roofs and walls not outlines` |
| 2 | `, village with 4 lodges and one small ceremonial structure, modest roof detail, no tall totem` |
| 3 | `, tribal town with 6 lodges, one tall totem pole, enclosed gathering area` |
| 4 | `, large tribal settlement with 8 lodges, two tall totem poles, grand ceremonial center, tallest totem dominates` |

**Pixflux parameters (all):** `width: 64`, `height: 64`, `no_background: true`, `text_guidance_scale: 8`. Generator: `pytool/generate_town_l1_candidates_64.py` (`--level` repeatable; requires `PIXELLAB_API_KEY`).
- **Fog:** Fogged town tiles render the **true** level glyph at reduced opacity; unrevealed tiles show **no** town icon.
- **Capital ring:** GP capital town tiles (always level 4) use level-4 glyph + gold ring; non-GP capitals use their **actual** level glyph + ring.

### Visual progression (complexity-only tier ladder)

All styles: centered cluster, transparent background, no circular badge, colonial 16th/17th c. pixel art, single-color black outline, medium shading.

**On-map size rule:** The axis-aligned bounding box of opaque pixels for level **1** must be within **±2 px** of level **4** on each axis (width, height, min-x, min-y) and center offset for the same style.

| Level | Tier name | Mandatory visual elements |
|-------|-----------|----------------------------|
| **1** | Hamlet | **2–3** ground structures spread across the full 48×48 inner box; **zero** spires/towers/totems; simplest roof shapes; **same silhouette extent** as levels 2–4 |
| **2** | Village | **4–5** structures; **one** low central roof or bell-cote; **no** thin spire |
| **3** | Town | **6+** structures; **one** tower or spire; visible wall segment or market enclosure |
| **4** | City | **8+** structures; **2+** towers/spires/totems; grandest enclosure |

**Automatable proxy tests:**

- **Complexity (required):** For each style, opaque pixel count strictly increases **1 < 2 < 3 < 4**.
- **Size parity (S9c):** For each style, level-1 vs level-4 bbox width/height/min-x/min-y and center offset differ by at most **6 px** on promoted production art (PO-approved S9b candidates; Pixflux bbox variance).
- **Height floor (S9c):** Level-1 `maxColumnHeight` ≥ **75%** of level-4 `maxColumnHeight` (prevents tiny silhouettes). Automatable tests run against promoted production level-1 PNGs.
- **Removed:** Strict `maxColumnHeight(1) < maxColumnHeight(2) < …` — height must **not** be the primary differentiation axis.

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
- **Given** level-**1** and level-**4** town glyphs of the same style rendered at 64×64 on the map, **when** a player views them side-by-side, **then** level **1** appears **the same map scale** as level **4** (not noticeably smaller or distant). *(S9c promoted art.)*
- **Given** each style, **when** opaque pixel counts are measured on levels 1–4, **then** counts strictly increase **1 < 2 < 3 < 4**.
- **Given** the three level-**1** legacy town PNGs at `ui_icon_com_town_{style}_1_legacy_64.png`, **when** loaded from the asset bundle, **then** file byte lengths match the pre-#3892 #3871 hamlets (`bed8a84a`) and decode as readable pixel-art (opaque count > 100 per icon).
- **Given** each style, **when** axis-aligned bounding boxes of opaque pixels are measured for promoted production levels **1** and **4**, **then** width, height, min-x, min-y, and center offset differ by at most **6 px** (size parity on PO-approved S9c art).
- **Given** each style, **when** `maxColumnHeight` is measured on promoted production levels **1** and **4**, **then** level **1** is at least **75%** of level **4** (prevents tiny silhouettes).
- **Given** the app is built **without** `--dart-define=CT_LEGACY_TOWN_ICONS=true`, **when** the map renders level-**1** town glyphs, **then** the system uses promoted production `ui_icon_com_town_{style}_1_64.png` assets.
- **Given** the app is built with `--dart-define=CT_LEGACY_TOWN_ICONS=true`, **when** the map renders level-**1** town glyphs, **then** the system loads legacy `ui_icon_com_town_{style}_1_legacy_64.png` assets. Levels **2–4** always use production paths.

(Port placement, tap/hit-test, and event-bus ACs unchanged from prior spec — see GitHub #1361.)

---

## Implementation Notes

- `TownIconCache` loads all 16 town ids plus `port` (`kTownIconIds`). Level **1** honors `kCtLegacyTownIconsEnabled` (`CT_LEGACY_TOWN_ICONS`) via `legacyTownIconAssetPaths`; levels **2–4** always use production paths.
- `buildTownMarkers` populates `townDevelopmentLevel` and `townIconStyle` from province + game faction data.
- Province overlay Political section shows `Town development: {level}` (Refs #3870, `SPEC/ui/province-sea-zone-detail-overlay.md`).
