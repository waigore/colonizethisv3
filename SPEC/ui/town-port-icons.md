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
- **Style:** Colonial-era pixel art; development levels differ by **architectural complexity** (structure count, roof variety, spires/totems, walls/enclosures). Asset files stay 64×64; **on-map size** is paint-time scale (S10), not silhouette shrink in the PNG.
- **On-map level scale (S10):** Destination draw sides are **48 / 56 / 60 / 64** px for levels **1–4** (`TownIconCache.townIconDestinationSize`). L4 equals `townIconSize` (64); lower levels shrink. Assets remain 64×64; no regen for size. Ports stay at `portIconSize` (64). Capital gold ring stays **fixed** (does not scale with the town glyph).
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

**On-map size rule (S10):** Render destination side is level-scaled (**48 / 56 / 60 / 64**). Asset bbox / height-floor checks remain **art quality** gates only — they do **not** define on-map size.

| Level | Tier name | Mandatory visual elements | Dest. side |
|-------|-----------|----------------------------|------------|
| **1** | Hamlet | **2–3** ground structures; **zero** spires/towers/totems; simplest roofs | **48** |
| **2** | Village | **4–5** structures; **one** low central roof or bell-cote; **no** thin spire | **56** |
| **3** | Town | **6+** structures; **one** tower or spire; wall/market enclosure | **60** |
| **4** | City | **8+** structures; **2+** towers/spires/totems; grandest enclosure | **64** |

**Automatable proxy tests:**

- **Complexity (required):** For each style, opaque pixel count strictly increases **1 < 2 < 3 < 4**.
- **Asset bbox (S9c art quality):** For each style, level-1 vs level-4 bbox width/height/min-x/min-y and center offset differ by at most **6 px** on promoted production art.
- **Height floor (S9c art quality):** Level-1 `maxColumnHeight` ≥ **75%** of level-4 `maxColumnHeight`.
- **Render scale (S10):** `townIconDestinationSize(n+1) > townIconDestinationSize(n)` for n∈{1,2,3}; ports ignore the ladder.
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

- **Given** a province with `townDevelopmentLevel` **L** (1–4) and style **S** per style resolution, **when** the map renders the town tile in full visibility, **then** the glyph is `town_{S}_{L}` drawn at destination side **48 / 56 / 60 / 64** for L **1–4**.
- **Given** `townDevelopmentLevel` changes after turn resolution, **when** the map refreshes, **then** the matching level glyph renders at that level’s destination size without reload.
- **Given** a fogged town tile, **when** the map renders, **then** the icon shows the **true** level at that level’s scale (reduced opacity only).
- **Given** an unrevealed town tile, **when** the map renders, **then** **no** town icon is drawn.
- **Given** town glyphs for levels **1–4** of the same style, **when** compared side-by-side, **then** destination sides are strictly increasing **48 < 56 < 60 < 64**.
- **Given** a port glyph and a level-**3** town glyph, **when** both render, **then** the port draws at **64** px (`portIconSize`) and the town at **60** px.
- **Given** a capital town tile with gold ring, **when** the town glyph uses a level scale, **then** the gold ring radius stays at its current fixed size.
- **Given** each style, **when** opaque pixel counts are measured on levels 1–4, **then** counts strictly increase **1 < 2 < 3 < 4**.
- **Given** the three level-**1** legacy town PNGs at `ui_icon_com_town_{style}_1_legacy_64.png`, **when** loaded from the asset bundle, **then** file byte lengths match the pre-#3892 #3871 hamlets (`bed8a84a`) and decode as readable pixel-art (opaque count > 100 per icon).
- **Given** each style, **when** axis-aligned bounding boxes of opaque pixels are measured for promoted production levels **1** and **4**, **then** width, height, min-x, min-y, and center offset differ by at most **6 px** (art-quality gate; not on-map size).
- **Given** each style, **when** `maxColumnHeight` is measured on promoted production levels **1** and **4**, **then** level **1** is at least **75%** of level **4**.
- **Given** the app is built **without** `--dart-define=CT_LEGACY_TOWN_ICONS=true`, **when** the map renders level-**1** town glyphs, **then** the system uses promoted production `ui_icon_com_town_{style}_1_64.png` assets (still at 48 px destination).
- **Given** the app is built with `--dart-define=CT_LEGACY_TOWN_ICONS=true`, **when** the map renders level-**1** town glyphs, **then** the system loads legacy `ui_icon_com_town_{style}_1_legacy_64.png` assets at the same S10 level-1 destination size. Levels **2–4** always use production paths.

(Port placement, tap/hit-test, and event-bus ACs unchanged from prior spec — see GitHub #1361.)

---

## Fort map icons (Refs #4280)

When `worldFortLevel ≥ 1` and `mapVisibleFortLevel` is non-null (player-view gate), draw a **fort glyph** near the town tile at offset **(−14, −18)** px from town center, destination side **40** px. Assets: `ui_icon_com_fort_{1,2,3}_64.png`, cache ids `fort_1` … `fort_3`. Single colonial style family (v1). Tap opens province detail like town/port.

| Level | Name | Asset |
|-------|------|-------|
| 1 | Wood | `ui_icon_com_fort_1_64.png` |
| 2 | Stone | `ui_icon_com_fort_2_64.png` |
| 3 | Modern | `ui_icon_com_fort_3_64.png` |

**Visibility:** `mapVisibleFortLevel` is null when `worldFortLevel == 0`, when foreign and military intel is incomplete (`provincePanelShowsFullTileDerivedIntel`), or when the town tile is unrevealed (no glyph). Own provinces: true level when tile is not unrevealed (fog uses reduced opacity). Full-visibility / tool maps set `revealAllForts`.

Generator: `pytool/generate_fort_map_icons_64.py` (PIL; Pixflux prompts optional for art refresh).

---

## Implementation Notes

- `TownIconCache` loads all 16 town ids plus `port` (`kTownIconIds`). Level **1** honors `kCtLegacyTownIconsEnabled` (`CT_LEGACY_TOWN_ICONS`) via `legacyTownIconAssetPaths`; levels **2–4** always use production paths. `townIconDestinationSize` applies S10 paint-time sides **48 / 56 / 60 / 64**.
- `_paintTownIconAt` uses destination size for town glyphs; ports always use `portIconSize`. Capital ring paint stays fixed radius.
- `buildTownMarkers` populates `townDevelopmentLevel` and `townIconStyle` from province + game faction data.
- Province overlay Political section shows `Town development: {level}` (Refs #3870, `SPEC/ui/province-sea-zone-detail-overlay.md`).
