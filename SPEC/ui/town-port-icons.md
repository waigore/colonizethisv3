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
| `ui_icon_com_town_{style}_1_candidate_64.png` | `town_{style}_1` when `CT_NEW_TOWN_ICONS=true` only |

Retired: `ui_icon_com_town_inland_64.png` / `town_inland_64`.

### Asset and Render Requirements

- **Format:** 64×64 PNG, RGBA transparent.
- **Style:** Colonial-era pixel art; development levels differ by **architectural complexity** (structure count, roof variety, spires/totems, walls/enclosures) — **not** by shrinking the overall silhouette.
- **On-map size parity:** All four levels target the same **48×48 px inner box** centered in the 64×64 canvas (8 px margin). Level **1** must appear **as large on the map** as levels 2–4 and other 64×64 map markers (port, resources). **Current gap (S9a):** Level-1 PNGs are the pre-#3892 #3871 hamlets (commit `bed8a84a`); they do not yet meet size parity — **S9b** closes the gap after product-owner visual review.
- **S9b preview gate:** Compile-time flag `CT_NEW_TOWN_ICONS` (`defaultValue: false` in `app/lib/config/ct_new_town_icons.dart`). When **false**, level-1 map glyphs load production `ui_icon_com_town_{style}_1_64.png`. When **true**, level-1 glyphs load **candidate** `ui_icon_com_town_{style}_1_candidate_64.png` for local/ctdev preview only; levels 2–4 unchanged. **No PR to `dev`** until PO on-map screenshots with the flag **true** approve the candidates.
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
- **Size parity (S9b target):** For each style, level-1 vs level-4 bbox width/height/min-x/min-y and center offset differ by at most **2 px**. Automatable tests are **skipped until S9b** after S9a revert of level-1 PNGs.
- **Height floor (S9b target):** Level-1 `maxColumnHeight` ≥ **75%** of level-4 `maxColumnHeight` (prevents tiny silhouettes). Automatable tests are **skipped until S9b**.
- **Removed:** Strict `maxColumnHeight(1) < maxColumnHeight(2) < …` — height must **not** be the primary differentiation axis.

**S9b candidate art (preview only, `CT_NEW_TOWN_ICONS=true`):** Triple-cluster spread from S9a-reverted level-1 hamlets — nearest-neighbor upscale of the production L1 opaque crop, placed left/center/right within the level-4 opaque bounding box, plus sparse corner grass to align bbox edges. Target opaque count below level 2 while matching level-4 footprint (±2 px). PixelLab inpaint/Bitforge preferred when available; programmatic spread is the fallback.

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
- **Given** level-**1** and level-**4** town glyphs of the same style rendered at 64×64 on the map, **when** a player views them side-by-side, **then** level **1** appears **the same map scale** as level **4** (not noticeably smaller or distant). *(S9b; known gap after S9a revert.)*
- **Given** each style, **when** opaque pixel counts are measured on levels 1–4, **then** counts strictly increase **1 < 2 < 3 < 4**.
- **Given** the three level-**1** town PNGs after **S9a**, **when** loaded from the asset bundle, **then** file byte lengths match the pre-#3892 #3871 hamlets (`bed8a84a`) and decode as readable pixel-art (opaque count > 100 per icon).
- **Given** each style, **when** axis-aligned bounding boxes of opaque pixels are measured for levels **1** and **4**, **then** width, height, min-x, min-y, and center offset differ by at most **2 px** (size parity). *(S9b; tests skipped until S9b.)*
- **Given** each style, **when** `maxColumnHeight` is measured on levels **1** and **4**, **then** level **1** is at least **75%** of level **4** (prevents tiny silhouettes). *(S9b; tests skipped until S9b.)*

(Port placement, tap/hit-test, and event-bus ACs unchanged from prior spec — see GitHub #1361.)

---

## Implementation Notes

- `TownIconCache` loads all 16 town ids plus `port` (`kTownIconIds`). Level-1 asset file names resolve through `TownIconCache.townIconAssetFileName` (production vs `_candidate_64` when `CT_NEW_TOWN_ICONS=true`).
- `buildTownMarkers` populates `townDevelopmentLevel` and `townIconStyle` from province + game faction data.
- Province overlay Political section shows `Town development: {level}` (Refs #3870, `SPEC/ui/province-sea-zone-detail-overlay.md`).
- **S9b workflow:** iterate on `feat/issue-3870-s9b-new-town-icons` (or successor branch) → run app/ctdev with `--dart-define=CT_NEW_TOWN_ICONS=true` → PO on-map screenshot review → promotion PR swaps approved candidates into default `_1_64` paths and removes the flag.
