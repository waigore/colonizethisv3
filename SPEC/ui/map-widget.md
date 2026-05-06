# Map Widget (reusable)

**SPEC/ui** — Reusable 2D tile-map component for the Flutter app. Renders one region's map with a base tile layer and optional overlays; viewport sized to the widget; pan and zoom on a **fit-map baseline** with a unified **0.5×–8×** multiplier band (see § Viewport, scale, pan, zoom). Tap/click exposes province selection via callbacks. Implemented as a **Flame** component to support animation of individual tiles and other assets. Data and events align with shared packages and event systems; this spec is for the app only.

---

## Responsibility

- Display a **full** region map (one region per widget instance).
- **Viewport:** The visible area is the widget's layout size. Map extent is the full 2D tile grid; user pans and zooms to see it.
- **Base layer:** Terrain plus optional **base overlays** (resource icons, improvement labels, road/rail transport sprites) drawn in a fixed Z-order; towns, capitals, and warp markers per below.
- **Overlays:** Province boundary strokes, Great Power **province ownership** tint, and political (faction-difference) borders as **separate layers** on top; the in-game shell exposes independent toggles for boundaries vs ownership tint vs province names ([empire-overview.md](empire-overview.md)).
- **Interaction:** Pan; continuous zoom within the unified fit-relative band (§ Viewport, scale, pan, zoom); tap/click to select a province (callbacks; province details content TBD elsewhere). **Hover:** When the pointer is over a tile, a selector (e.g. a simple square) is shown on that tile with a subtle bouncing animation; the hovered tile's province (or sea zone) borders glow and use a subtle animation (e.g. pulse).
- **Animation:** Widget supports animation of individual tiles and other assets (e.g. highlights, build progress); Flame is the implementation fit.

### Region minimap camera sync

- **`CtRegionMap`** may report viewport changes via **`onViewportSnapshotChanged`** (`RegionMapViewportSnapshot`: `regionId`, `cellSizePx`, map world size, camera center, `zoom`, **`fitMapZoom`** (Flame viewfinder zoom at which the full map fits the current viewport), logical viewport width/height). Emitted when the camera changes size, zoom, or center; math matches `_CtRegionMapGame._clampCameraToMap` (same viewport-in-world as hover/tap conversion).
- **`GameRegionMinimap`** (in-game shell) must use the **same** logical cell size and world extent as **`CtRegionMap`** for that region: `mapWidthWorld` / `mapHeightWorld` = `region.width` × `cellSizePx` and `region.height` × `cellSizePx` with `cellSizePx == RegionMapViewData.cellSize`. If the minimap uses a different `cellSizePx` than the snapshot, the viewport indicator and tap/drag camera mapping will be wrong.
- The in-game shell may request camera moves using **`RequestRegionMapCameraCenterWorldEvent`**, **`RequestRegionMapCameraPanWorldDeltaEvent`**, and **`RequestRegionMapSetZoomMultiplierEvent`** on the shared **`AppEventBus`**; the map host applies them only when `event.regionId` matches the widget’s `RegionMapViewData.regionId`.

---

## Layer model

| Layer | Content | Togglable |
|-------|---------|-----------|
| **Base (tile)** | Terrain; optional resource icons; optional improvement labels (`I{n}`); optional road/rail transport sprite overlay (cardinal mask `0..15` from `roadLevel` land connectivity); towns; capitals. Town/port icon behavior (including render sizes and glyph policy) follows [town-port-icons.md](town-port-icons.md). **Player-constrained visibility:** capital markers and town/port icons on a cell are omitted when that cell’s `CellViewData.visibility` is `unrevealed` (fog parity; does not apply in full visibility mode). | Base terrain always on; resource and label sublayers controlled by [Base layer display mode](#base-layer-display-mode). |
| **Province overlay** | Province and sea-zone **boundary strokes** only (topology edges P–P, P–S, S–S). **Land–sea edges:** strokes are drawn **inset into the land cell** (toward land from the nominal grid line between tiles) so the coastline reads as an outline around seaboard land; land–land and sea–sea edges stay on the grid line. Stroke width is **2 logical px** in world space at baseline cell scale (2× legacy 1 px). **Player-constrained visibility:** draw a unit edge between two adjacent cells only if **at least one** cell is not `unrevealed` (same rule for land and sea cells). **Full visibility mode:** draw all topology edges regardless of `CellViewData.visibility`. | Yes. In-game toggle **Show province overlay** ([empire-overview.md](empire-overview.md)). When off, boundary strokes are not drawn; other layers follow their own toggles. |
| **Province ownership (GP tint)** | **Great Power land ownership tint:** for each **land** cell whose `ownerFactionId` is a Great Power (runtime id in `RegionMapViewData.greatPowerFactionIds`), draw a **semi-transparent** fill in that faction’s colour from `factionColors` at **fixed alpha 0.5** (`BlendMode.srcOver`). **Not** drawn for sea cells, unowned land, Minor Nations, or Tribes. **Player-constrained visibility:** tint is **not** drawn on `unrevealed` tiles; **`visible` and `fogged`** tiles use the same tint rules (no extra suppression for fogged). **Full visibility mode:** all GP-owned land cells qualify when the layer is on. Tint is painted **after** the terrain pass (sea, land base, transport sprites when enabled, L1 interior plains resource decals, L2 feature terrain overlays) and **before** resource icons and improvement labels. | Yes. In-game toggle **Show province ownership** ([empire-overview.md](empire-overview.md)), independent of boundary strokes. When off, no GP tint is drawn. |
| **Political** | Political borders (ownership differences between adjacent land provinces). Stroke width **4 logical px** in world space (2× legacy 2 px). **Player-constrained visibility:** same edge rule as the province overlay — draw the segment only if at least one of the two adjacent land cells is not `unrevealed`. **Full visibility mode:** no gating. Drawn on top of base and province overlay strokes when both are enabled. | Yes. User can turn political overlay on/off. |
| **Human fleet markers** | One icon per distinct human naval **location scope** (port or sea zone) on the region map. **In port:** anchored at the **same sea drawable cell** as the harbor icon (`TownMarkerView.portIconX` / `portIconY`), computed from `portsByProvinceSeaboard` per [town-port-icons.md](town-port-icons.md) (strict sea-only placement). **At sea:** anchored at the **sea-zone centroid** from the tile map. Icon: `ui_icon_map_fleet.png`. **Stack badge** when multiple fleets share the scope. **Grayscale** when every fleet at the marker has a pending naval move/mission draft; **Chebyshev ≤2 terrain “reveal” halo** (painting only; no stored fog change) when any fleet there has a pending naval **move** draft. **Tap** (before civilian markers when overlapping) emits **`OpenNavalUnitsPanelEvent`** with `locationScopeKey`, optional `initialSelectedFleetId`, and `tileScopeTileKey` for panel chrome. **Draft projection** (human naval move drafts in the app shell) must use the same harbor sea cell as map construction: `colonizethis_map` `harborDrawableSeaTileKeyForPortProvince` for in-port positions and **dock** destinations — not province town tile keys (`tileKeyForProvinceLocation`). | No separate toggle; follows map visibility and draft projection from `RegionMapViewData.fleetTileMarkers`. |
| **Province and sea zone names** | **Land (province) labels:** `CellViewData.provinceDisplayName` (same string as the Political section in the province detail overlay), with fallback to local province id when missing. One label per land province per region. Centroid: average of **land** tile centers. **Sea zone labels:** one per local sea zone in the region topology; text from `RegionMapViewData.seaZoneDisplayNameByPrefixedId['regionId|localSeaZoneId']` with fallback to the local sea zone id (same resolution as app `sea_zone_name_resolver`). Centroid tile: `round(mean x)`, `round(mean y)` over all grid cells for that zone (same anchor as fleet markers). **Warp sea-zone prefix icon:** when the local sea-zone id appears in `RegionMapViewData.warpMarkers`, render `ui_icon_map_warp_zone.png` inside the same sea label plate immediately to the **left** of text (`[icon][gap][text]`), using the same rendered icon size and text-icon gap constants as province label rows; non-warp sea zones render text-only labels. **Shared toggle:** in-game **Show province names** (`showProvinceNamesLayer`); **no** separate toggle for sea zone names. **Player-constrained visibility (sea):** draw a sea zone label only if the **centroid cell** is not `TileVisibility.unrevealed` under the same rules as terrain for the map, including fleet move-draft reveal halo (`_visibilityForTerrain` / Chebyshev ≤2). Other sea cells in the zone need not be revealed. Warp icon visibility is identical to sea-label visibility (same centroid predicate and toggle gating). **Sea plate style:** fill **RGB (173, 216, 230)** at **alpha 0.55**; text **black** (`#000000`). **Sea placement:** default **above** the centroid so the plate does **not** overlap the centroid cell (fleet icon cell); if that would clip the **top** of the map, place **below** the centroid instead; then apply **minimal** horizontal/vertical nudge so the **entire** plate stays inside the region world rect — no clipping. **Long names:** no ellipsis; render the full string (overlap with neighbors acceptable), including warp labels. Land province label rules (GP-tinted vs neutral plate, capital icon, presence row, ellipsize exceptions) are unchanged — see § Sea zone name plates and § Province label unit presence icons. Rendered after province/political border strokes; **sea zone name plates** are painted immediately **after** land province name plates and **before** capitals/towns/warp/civilian/fleet markers. | Yes. **Show province names** only; independent of province overlay, province ownership tint, and political overlay toggles. |

Data source for tiles and ownership: shared view model (e.g. `RegionMapViewData` / game + tile maps per [map-visualization.md](../program/map-visualization.md)). Province and tile identity: [world-model-identity.md](../game/world-model-identity.md).

### Sea zone name plates

Detailed behavior for sea zone labels (toggle gating, visibility, style, placement) is summarized in the **Province and sea zone names** layer row above. **Inverse zoom** for constant on-screen size matches land province names: scale factor `1.0 / cameraZoom.clamp(0.25, 4.0)` in world space.

**Bounds algorithm (normative summary):** Let `cellSize` be `RegionMapViewData.cellSize`, map world size `W = width × cellSize`, `H = height × cellSize`. Let the centroid cell be `(cx, cy)` in grid indices. In world space, plate half-extents are `(bw·invZ/2, bh·invZ/2)` where `bw`, `bh` are the label plate’s width and height in logical pixels (text + padding) and `invZ` is the inverse zoom factor above. Prefer vertical placement **above** the centroid cell (plate does not intersect the centroid cell’s world rectangle). If the plate would extend above `y = 0`, use **below** the centroid cell instead. Clamp/nudge the plate center so the axis-aligned plate rectangle lies entirely in `[0, W] × [0, H]`. If clamping introduces overlap with the centroid cell, nudge toward the alternate vertical side and re-clamp as needed.

### Province label unit presence icons

Province-name overlays on the main app map may render decorative unit-presence icons for three classes:

- **Civilian presence:** any civilian unit in the province (definitions from [civilian-units.md](../game/civilian-units.md)).
- **Regiment presence:** any land military regiment in the province (definitions from [military-units.md](../game/military-units.md)).
- **Ship presence:** any ship/fleet presence associated with the province context used by map labels (definitions from [ships-and-naval.md](../game/ships-and-naval.md)).

Asset and style contract:

- 64x64 full-color pixel-art PNG icons in `app/assets/icons/64/`.
- Distinct visual identity:
  - civilian: person with 16th-century hat
  - regiment: tent
  - ship: frigate
- Suggested filenames for the map-label row:
  - `ui_icon_map_presence_civilian.png`
  - `ui_icon_map_presence_regiment.png`
  - `ui_icon_map_presence_ship.png`
- Pixel style must match existing app icon style and palette conventions.

Render and data rules:

- **Presence threshold:** for each class, render the icon iff the class count in that province is `> 0`.
- **Ordering:** icon row order is always civilian → regiment → ship.
- **Scope:** applies to player-owned provinces and other-faction provinces.
- **Fog/intel gate:** if current player intel does not permit knowledge of class presence in that province, render no class icons for that province (even if hidden world state has units there).
- **Layout:** default is inline with the province name; when horizontal space is insufficient, wrap the icons to a second line below the province name while keeping class order.
- **Interaction:** icons are decorative only (no counts, no direct command actions).
- **Semantics:** map widget may expose semantic labels/tooltips describing class presence for accessibility, but icon-level semantics are optional because these indicators are decorative and non-interactive.
- **Refresh cadence:** label icon data is recomputed at turn start after turn resolution.

### Province label capital icon

Province-name overlays on the main app map render a decorative capital icon for capital provinces:

- **Scope:** applies to all faction types with capitals represented in `RegionMapViewData.capitalMarkers` (Great Powers, Minor Nations, Tribes).
- **Asset:** 64x64 full-color PNG in `app/assets/icons/64/ui_icon_map_capital_star.png` generated via PixelLab.
- **Visual contract:** icon is recognizable as a gold five-point star in the project’s pixel-art style; transparent background.
- **Placement:** icon appears immediately to the **left** of the province name text inside the same label plate.
- **Layout guarantee:** for capital labels, both the star icon and full province name remain visible (no ellipsis or truncation that hides either). Increased overlap with nearby labels is acceptable.
- **Interaction:** decorative only; no click/tap behavior.

### Base overlay paint order (Z-order, bottom → top)

Within the Flame map render pipeline, **tile stack** (first paint group) is built bottom → top as:

1. **Sea and land terrain base** (Wang coast/interior, desert transitions, bare L1 plains interior upper-base, etc.). **Does not** include full-cell **L1 interior plains resource decals** (`tile_plains_grain`, `tile_plains_meat`, `tile_plains_horses`); those are step 3 so they stack above transport.
2. **Road/rail transport sprites** when the base-layer mode includes roads and `roadLevel > 0` on **land** only: cardinal mask bits (**N=1, E=2, S=4, W=8**) from neighboring **land** cells with `roadLevel > 0`; road family for levels 1/2, rail family for level 4. Transport sits **above** bare land/plains interior base passes and **below** L1 plains resource-linked decals and L2 feature terrain overlays so corridor art reads on open terrain while resource pasture art and feature art remain on top.
3. **L1 interior plains resource-linked terrain decals** — full-cell standalone `tile_plains_grain` / `tile_plains_meat` / `tile_plains_horses` from `landInteriorPlainsVariantTileKey` / `terrainVariantTileKey`, **excluding** plains↔desert Wang transition cells (same gating as the land-base pass). Painted **after** step 2 and **before** step 4.
4. **L2 feature terrain overlays** (forest/mountains/hills/swamp standalone tiles where applicable).

Then **base overlays** (second group), still bottom → top:

5. **Great Power province ownership tint** (when that layer is enabled).
6. **Resource icons** (when the base-layer mode includes resources).
7. **Improvement labels** `I{n}` (when the mode includes improvements and `n > 0`).

Then province boundary strokes (when enabled), hover glow, political borders, province names, **sea zone names**, capitals, towns/ports, warp indicators, civilian markers, fleet markers, then selection/hover chrome — unchanged except as noted elsewhere in this spec.

**Label placement:** Improvement label at the **top-left** of the tile cell (small inset from top and left edges). **Do not** draw `I0`; draw only when improvement level is **greater than zero**. `R{n}` text labels are removed once transport sprite overlays are enabled.

Implementation: `_paintTiles` covers steps 1–4; `_paintGreatPowerLandOwnershipTint` and `_paintOverlay` cover steps 5–7 so Z-order matches this spec (see `SPEC/program/map-region-map-render.md`).

---

## Base layer display mode

The widget accepts an optional **base layer display mode** enumerating terrain, resource icons, improvement labels, and road/rail transport sprites. When `baseLayerDisplayMode` is **omitted** (e.g. some Widgetbook stories), the widget uses **terrain + resources + improvements + roads** (full detail) for backward compatibility.

| Mode | Terrain | Resource icon | Improvement `I{n}` (n > 0) | Road/rail transport sprite (`roadLevel` > 0) |
|------|---------|---------------|----------------------------|---------------------------|
| **terrainOnly** | Yes | No | No | No |
| **terrainAndResources** | Yes | Yes | No | No |
| **terrainAndResourcesImprovementLabels** | Yes | Yes | Yes | No |
| **terrainAndResourcesImprovementsRoads** | Yes | Yes | Yes | Yes |

**Constraint:** Any mode that shows road/rail transport sprites **must** also show improvement labels (the enum satisfies this: roads exist only in `terrainAndResourcesImprovementsRoads`).

**Base layer display mode** does not hide capitals, town/port icons, or warp zone indicators when switching among terrain vs resources vs labels — those markers are independent of `terrainOnly` / `terrainAndResources` / etc.

**Player-constrained visibility** (fog of war) is separate: **capital markers** and **town/port icons** use the **host cell’s** `CellViewData.visibility` and are **not** drawn when that cell is `unrevealed`, so they do not leak positions in unknown territory. **Warp zone** glow borders are still drawn regardless of `baseLayerDisplayMode`; in player-constrained mode, each warp glow edge segment follows the same edge-gating predicate as province/political borders (draw only if at least one adjacent cell is not `unrevealed`).

---

## Resource Icons

Resources use **64×64** pixel-art **source** assets (`app/assets/icons/64/`). On the map they are drawn **scaled to a marker**—**one quarter of the tile’s linear size** in world/cell space—**anchored to the bottom-left** of the cell, so terrain stays visible at native zoom (e.g. **16×16** drawn when `cellSize == 64`). The painted width/height is **never larger** than the asset (64); when `cellSize / 4` would exceed 64, the display size **caps at 64** (scale down only, never upscale beyond native asset resolution). Icons replace the legacy single-letter glyphs (g, t, i, …).

### Map tile icon inventory (64 policy)

The following map-rendered icon families are governed by the 64×64 tile icon policy and are loaded from `app/assets/icons/64/`:

| Family | Files |
|---|---|
| Town / port | `ui_icon_com_town_inland_64.png`, `ui_icon_com_port.png` |
| Resource tile icons | `ui_icon_com_<resource_id>.png` (all `kResourceIconIds`) |
| Civilian tile markers | `ui_icon_civ_builder.png`, `ui_icon_civ_engineer.png`, `ui_icon_civ_rail_builder.png`, `ui_icon_civ_explorer.png`, `ui_icon_civ_merchant.png`, `ui_icon_civ_spy.png` |
| Province label row icons | `ui_icon_map_capital_star.png`, `ui_icon_map_presence_civilian.png`, `ui_icon_map_presence_regiment.png`, `ui_icon_map_presence_ship.png`, `ui_icon_map_warp_zone.png` |

Non-map UI glyphs remain outside this map tile inventory and use their own UI contracts.

### Asset Files

Resource icons are stored in `app/assets/icons/64/` with naming convention `ui_icon_com_<resource_id>.png`:

| Resource ID | Icon File | Resource ID | Icon File |
|-------------|-----------|-------------|-----------|
| grain | ui_icon_com_grain.png | meat | ui_icon_com_meat.png |
| timber | ui_icon_com_timber.png | iron | ui_icon_com_iron.png |
| wool | ui_icon_com_wool.png | cotton | ui_icon_com_cotton.png |
| coal | ui_icon_com_coal.png | sugar_cane | ui_icon_com_sugar_cane.png |
| tobacco | ui_icon_com_tobacco.png | furs | ui_icon_com_furs.png |
| copper | ui_icon_com_copper.png | tin | ui_icon_com_tin.png |
| horses | ui_icon_com_horses.png | lumber | ui_icon_com_lumber.png |
| cast_iron | ui_icon_com_cast_iron.png | fabric | ui_icon_com_fabric.png |
| refined_sugar | ui_icon_com_refined_sugar.png | cigars | ui_icon_com_cigars.png |
| fur_hats | ui_icon_com_fur_hats.png | steel | ui_icon_com_steel.png |
| paper | ui_icon_com_paper.png | bronze | ui_icon_com_bronze.png |
| gold | ui_icon_com_gold.png | silver | ui_icon_com_silver.png |
| gems | ui_icon_com_gems.png | diamonds | ui_icon_com_diamonds.png |
| spices | ui_icon_com_spices.png | | |

All icons are 64×64 PNG with RGBA transparency, colonial-era pixel art style matching `ui_main_menu_button.png`.

### Rendering

- **Asset vs display:** Source samples are always the full **64×64** PNG. The **destination** `Rect` uses edge length `displaySize = min(cellSize / 4, 64)` (same width and height). `drawImageRect` maps the full source rect to that destination (downscale when `displaySize &lt; 64`; at `displaySize == 64` the marker matches native asset pixel density for that cell scale).
- **Position:** **Bottom-left** anchor in tile/world coordinates: `iconX = tileLeft`, `iconY = tileTop + cellSize - displaySize` (with `tileLeft` / `tileTop` and `cellSize` in the same space). The marker fits within the cell horizontally and vertically (width and height ≤ `cellSize` given the cap above).
- **Transport overlap:** When the base-layer mode draws **road/rail transport** on a **land** cell (`roadLevel > 0`, same gating as the transport overlay pass) and a resource icon is drawn on that cell, the renderer **does not** draw a separate filled “readability” mat or rounded plate in icon space. **Paint order** is normative: transport is in the tile pass; the resource glyph is `drawImageRect` in the overlay pass **above** transport. Transparent pixels in the commodity icon may therefore reveal corridor pixels underneath; that is acceptable. **Fog / tint:** On fogged tiles, the resource icon uses the same fog modulation rules as other resource icons (see **Visibility** below); there is **no** icon-local filled plate workaround — the cell continues to follow the map’s normal GP tint and visibility pipeline for the tile as a whole.
- **Visibility:** Icons are subject to the same visibility rules as terrain (visible/fogged/unrevealed). Fogged tiles render icons with reduced opacity; unrevealed tiles show nothing.

#### Acceptance criteria (resource vs transport readability)

- Given the region map uses `terrainAndResourcesImprovementsRoads` and a **land** cell has `roadLevel > 0` and a **non-null** resource id that passes resource visibility rules  
- When the map finishes painting that cell’s base overlays  
- Then the renderer does **not** draw a filled rounded rectangle or other opaque/semi-opaque backdrop in the resource icon’s destination rect **before** `drawImageRect` solely because transport is enabled, and the composed pixels for at least one fixture cell (e.g. plains + road + grain, and a second fixture such as plains + road + horses) are **pixel-regression covered** in automated tests (golden or equivalent).

- Given the region map uses `terrainAndResourcesImprovementLabels` and a **land** cell has `roadLevel > 0` and a **non-null** resource id that passes resource visibility rules  
- When the map pipeline evaluates whether the base-layer mode includes road/rail transport sprites  
- Then that mode does **not** include road/rail transport sprites in the active base-layer contract (per [Base layer display mode](#base-layer-display-mode)), so corridor sprites are not painted in the tile pass for this concern (negative control that co-road+resource stacking is scoped to the roads display mode).

### Per-tile extraction throughput indicators

When resource icons are visible, the map may render extraction throughput indicators for the same tile:

- **Scope:** Indicators encode per-tile extraction throughput for the **human player’s owned tiles only** using `CellViewData.resourceExtractionEffectiveUnits` and `CellViewData.resourceExtractionBlockedUnits` (fallback: `resourceExtractionUnits` as all-effective when split fields are absent).
- **Count rule:** Draw exactly `E` effective **extraction discs** and `B` blocked **extraction discs** where `E = resourceExtractionEffectiveUnits` and `B = resourceExtractionBlockedUnits`. Draw none when `E + B <= 0`.
- **Economic alignment:** `E` and `B` follow the tile-level extraction branch used by `computeExtraction` tile `effectiveCapped` vs transport-limited blocked units, excluding aggregate-only adjustments (for example `Game.capitalTileGrainBonusPerTurn`).
- **Placement:** Indicators are anchored to the painted resource icon `Rect` and rendered immediately to the right in a horizontal left-to-right stack with overlap.
- **Visual:** Each indicator is a **filled disc** (circle inscribed in the indicator square), not a second copy of the commodity resource bitmap. **Transport semantics (colors):** effective discs (units that count as **effectively transported** toward the capital per `CellViewData.resourceExtractionEffectiveUnits`) use a fixed **gold** fill `Color(0xFFFFD700)` (same accent gold as map warp/selection constants in `region_map_component_shared.dart`). Blocked discs (transport/path-limited slots per `resourceExtractionBlockedUnits`) use a fixed **brown** fill `Color(0xFF5C4033)`. This matches program paint order language (“extraction discs”) in `SPEC/program/map-region-map-render.md`. Optional commodity-hue reference output from `tool/generate_resource_icon_disc_palette.dart` is **not** used for on-map extraction disc fills.
- **Size:** Indicator square edge length is `>=` resource icon display edge length for that tile (slightly larger by default, capped at source-asset native 64 px); the painted disc is inscribed in that square.
- **Base-layer gating:** Indicators are rendered only when resource icons are rendered (`baseLayerDisplayMode != terrainOnly`).
- **Icon visibility gating:** If resource icon visibility/prospecting rules suppress the icon on a tile, indicators are also suppressed on that tile.
- **Fog parity:** On `TileVisibility.fogged`, indicators use the same fog modulation treatment as resource icons.

---

## Civilian Marker Icons

Interactive civilian tile markers use per-type color icon assets in `assets/icons/64/`:

- `ui_icon_civ_builder.png`
- `ui_icon_civ_engineer.png`
- `ui_icon_civ_rail_builder.png`
- `ui_icon_civ_explorer.png`
- `ui_icon_civ_merchant.png`
- `ui_icon_civ_spy.png`

All assets are 64×64 PNG with transparency. The map draws these icons tile-sized in world space so marker occupancy scales with zoom. Assigned-state rendering is achieved by applying a grayscale color filter at paint time, not by loading separate grayscale runtime assets.

### PixelLab generation prompts (this slice)

- Generator: `pixellab-generate_image_pixflux`
- Shared settings: `width=64`, `height=64`, `no_background=true`, `outline='single color outline'`, `shading='medium shading'`, `detail='medium detail'`
- Color prompts:
  - `pixel art builder civilian with hammer and tool belt, full body, colonial era style, readable 64x64 unit marker icon`
  - `pixel art engineer civilian with wrench and measuring tools, full body, colonial era style, readable 64x64 unit marker icon`
  - `pixel art rail builder civilian with pickaxe and rail spike hammer, full body, colonial era style, readable 64x64 unit marker icon`
  - `pixel art explorer civilian with compass and satchel, full body, colonial era style, readable 64x64 unit marker icon`
  - `pixel art trader merchant civilian holding visible coin pouch and ledger, full body, colonial era clothing, readable 64x64 unit marker icon`
  - `pixel art spy civilian cloaked with dagger and covert posture, full body, colonial era style, readable 64x64 unit marker icon`
- Grayscale assets:
  - Runtime assigned-state rendering is paint-time grayscale filtering of color icons.
  - Compatibility `_gray` files are generated from approved color icons via deterministic grayscale conversion.

---

## Warp Zone Indicators

Warp zones are sea zones that link to sea zones in other regions (Old World ↔ New World). The map widget renders a **glowing yellow border** around each warp sea zone to make cross-region connections visible.

### Data Source

Warp zone indicators are provided via `RegionMapViewData.warpMarkers` (list of `WarpMarkerView`). Each marker contains:
- `x`, `y`: Tile coordinates (representative tile of the warp sea zone)
- `seaZoneId`: The sea zone identifier
- `otherRegionId`: The connected region ID
- `otherSeaZoneId`: The connected sea zone ID on the other region

### Rendering

- **Style:** Glowing yellow border drawn around the perimeter of all tiles belonging to a warp sea zone.
- **Glow Effect:** Two-layer border:
  - Outer layer: 6px wide, semi-transparent gold (`0xFFFFD700` at 30% alpha)
  - Inner layer: 3px wide, bright yellow (`0xFFFFEA00`)
- **Border Logic:** Edges are drawn where a warp sea zone tile is adjacent to a non-warp tile (different sea zone or land province), similar to province border rendering.
- **Layer:** Rendered after the base terrain and overlays (after ports, same layer as capitals).
- **Visibility:** Always visible regardless of `baseLayerDisplayMode` (independent of terrain vs resource vs label modes). In **full** visibility mode, warp glow ignores `CellViewData.visibility`. In **player-constrained** visibility mode, each warp glow segment is drawn only when at least one of the two adjacent cells on that unit edge is not `unrevealed` (same predicate as province/political border strokes).

The **in-game shell** (Empire overview) may overlay a cycle button that toggles this mode; see [empire-overview.md](empire-overview.md).

---

## Viewport, scale, pan, zoom

- **Viewport:** Exactly the size of the map widget in the layout. No intrinsic minimum; parent constrains the widget.
- **Fit-map baseline (`z_fit`):** For the active region and current logical viewport size, `z_fit = min(viewportWidth / mapWidthWorld, viewportHeight / mapHeightWorld)` (same world units as the Flame map). At camera zoom `z_fit`, the entire region map is visible (tight fit on the limiting axis). When the map is smaller than the viewport in world space, `z_fit` is the zoom that fills the viewport with that map extent (centering applies per `_clampCameraToMap`).
- **Fit-relative multiplier:** `m = zoom / z_fit` where `zoom` is the Flame viewfinder zoom. User-facing **percent = 100 × m** (display range **50%–800%** corresponds to **`m ∈ [0.5, 8]`**). **100% = fit the full map** in the current viewport.
- **Unified clamp:** **Pinch**, **scroll wheel**, **keyboard zoom shortcuts**, and the **in-game minimap zoom slider** all use the **same** limits on **`m`**: **`[0.5, 8]`** (no separate clamps per input). Effective camera zoom is **`m × z_fit`** after clamping **`m`**.
- **Pan:** User can pan to move the visible region over the full map (drag or gesture). Map is larger than viewport when zoomed in; **dragging** on the map surface pans the camera.
- **Zoom:** **Continuous** zoom within the band above; scroll, pinch, keys, and shell slider update **`m`** smoothly. **`z_fit`** is recomputed when the widget resizes or the displayed region changes; the implementation preserves `m` across viewport resize and **across `regionId` switches** for the same map host. On region switch, the host reapplies the current global `m` to the new region and clamps effective zoom to the region's allowable range.
- **Full map:** The component always has the full region map in memory/logic; viewport is a window over it.

---

## Callbacks (contract)

The map widget exposes callbacks so the parent (e.g. Empire overview) can react; it does not define province-detail content.

| Callback | Purpose |
|----------|---------|
| **onProvinceSelected** | Invoked when the user taps/clicks a province (e.g. with prefixed province id). Province details (what to show, where) are defined by the parent/screen; the map widget only reports selection. |
| **onMapTileTappedForDetail** | Optional. Invoked when the user **taps/clicks** a tile for the **province/sea zone detail** flow with full tile key `regionId|provinceId|x|y`. The **embedding shell** (not the reusable map) connects this to shared UI state (e.g. Riverpod `mapProvincePanelProvider`). The map widget does **not** import the detail overlay. See [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md). |
| **onRegionViewChanged** | Optional: viewport or zoom level changed (e.g. for syncing with sidebar or URL). |
| **onProvinceHovered** | Optional: invoked when hover enters or leaves a province (prefixed province id, or null when leaving). Enables e.g. tooltips. |
| **onTileSelected** | Optional. When the map is in **work target selection mode** (see below), invoked when the user taps/clicks a tile with the tile key `regionId|provinceId|x|y`. Used by the Civilian Units panel assign flow. |
| **validTileKeys** | Optional. When non-null and non-empty, the map is in work target selection mode: tiles whose key is in this set are drawn with a **subtle glow** (e.g. soft overlay or outline) so the user sees which tiles are valid targets. Tap on a valid tile invokes **onTileSelected** with that tile key; tap on an invalid tile or empty area does not invoke onTileSelected (parent may treat as cancel/back-out). |
| **onCivilianTileTapped** | Optional. Invoked when the user taps/clicks a tile with a player-owned civilian marker (`RegionMapViewData.civilianTileMarkers`) while **not** in work target selection mode. Reports the civilian marker tile key so the shell can open tile-scoped civilian UI. |
| **onCivilianTileSelectionCleared** | Optional. Invoked when a civilian tile marker is selected and the user taps a non-civilian map tile while **not** in work target selection mode. Lets the shell clear civilian marker selection state. |

**Constructor / props (driven by parent):** **`selectedTileKey`** — full tile key for the **orange** selection outline (detail panel’s selected tile; stroke **6 logical px** world space, 2× legacy 3 px). **`secondaryHighlightTileKey`** — optional second outline (e.g. cyan) for list/locate (**5 logical px**, 2× legacy 2.5 px); distinct from selection. Parents set these from shared state (e.g. Riverpod); the map does not read panel widgets.

**Civilian map marker slice:** The map may render tile-scoped player civilian markers from `RegionMapViewData.civilianTileMarkers` as tile-sized overlays with deterministic representative type and stack badge. Marker visuals use PixelLab icon assets (color for idle, grayscale for assigned), while marker z-order, tile occupancy, tap hit-testing precedence, and selected-marker blink behavior remain part of the reusable map contract.

Details of what “province details” shows are **not** defined in this spec; the screen that embeds the map defines that. The map widget reports taps via callbacks and paints outlines from passed-in keys.

---

## Province / sea zone detail panel (decoupling)

- **No cross-imports:** The Flame map component tree and `CtRegionMap` MUST NOT import `ProvinceSeaZoneDetailOverlay` or any province-panel-only module. The detail overlay MUST NOT import the Flame map game class.
- **Bridge:** In the app, **`mapProvincePanelProvider`** holds `overlayOpen`, `selectedTileKey`, `secondaryHighlightTileKey`. A **Consumer** host (e.g. game map canvas stack) wires `onMapTileTappedForDetail` → `reportMapTileTapped`, and passes `selectedTileKey` / `secondaryHighlightTileKey` from `ref.watch` into the map widget. Side and narrow panel slots are separate Consumers that read the same provider and build the overlay. This satisfies “Riverpod-only” wiring between map and panel; `AppEventBus` is optional for other concerns.
- **Behavior:** **Tap** drives detail selection and panel content. **Hover** drives the animated hover selector and province/sea glow only — it does **not** update the detail panel’s selected tile. Full rules: [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md).

---

## Work target selection mode

- **When** the parent supplies **validTileKeys** (set or list of tile keys in format `regionId|provinceId|x|y`) and **onTileSelected**, the map is in **work target selection mode**.
- **Caching:** The parent computes valid tile keys **once** when entering selection mode (e.g., using `getValidWorkOrderTileKeysWithVisibility` or similar validation). The cached set is **global for the active selection session** (may include keys from multiple regions), is passed to the map widget unchanged, and is not overwritten by region-scoped subsets when tabs change. The map widget does NOT recompute valid tiles on each frame or hover.
- **Orange cursor:** When in work target selection mode, the hover selector (the square outline that follows the pointer/tap) changes from white to **orange** (`Color(0xFFFFAA00)`) to visually indicate selection mode is active.
- **Flashing yellow selectors:** Every tile whose key is in **validTileKeys** (and belongs to the currently displayed region) is rendered with a **flashing yellow border/outline** (stroke **5 logical px** world space, 2× legacy 2.5 px) that pulses (opacity oscillates, e.g. 0.4 to 0.8) to clearly indicate valid targets. The border should be visible and distinct from terrain but not overpower game visuals.
- **Empty valid tiles:** When **validTileKeys** is provided but empty (no valid targets for this unit/order), no tiles are highlighted. Tapping any tile invokes **onWorkTargetSelectionCancelled** to allow the user to back out of selection mode.
- **Hover behavior:** During work target selection mode, hover events update the cursor position and tile highlighting normally (via **onTileHovered**). Hover does NOT trigger selection or cancellation; only explicit tap/click does.
- **Selection:** Tap/click on a tile in **validTileKeys** invokes **onTileSelected** with that tile's key, **commits the order**, and **exits selection mode** (clearing the yellow selectors and restoring the normal white cursor).
- **Clicking non-selectable tiles:** Tap/click on a tile not in **validTileKeys** or on empty area is a **no-op** for selection state (selection mode remains active; no cancel callback).
- **Selection prompt overlay:** When in work target selection mode, a **top-centered Flutter overlay banner** appears with exact copy **"Select a tile, or click cancel"** and a prominent clickable **`cancel`** control. Activating `cancel` invokes **onWorkTargetSelectionCancelled** and exits selection mode without committing.
- **Unified cancel routes:** The selection cancellation path is shared across: prompt **`cancel`**, desktop/macOS **Esc** while selection mode is active, and any left-rail icon tap (left-rail actions still execute after cancellation).
- **Interaction lock while active:** While selection mode is active, map interactions other than valid tile selection and region switching are suppressed (e.g., province/tile detail taps, civilian/fleet marker panel interactions).
- **Region:** Valid tile keys may reference the other region; only tiles in the **currently displayed region** are highlighted. Region tab switch behavior is render-time filtering only: the same global cached set drives highlights before and after a tab change. See [civilian-units-panel.md](civilian-units-panel.md).

---

## Hover

- **Selector:** When the pointer hovers over a tile, the widget shows a selector on that tile (e.g. a simple square outline). Stroke **4 logical px** world space (2× legacy 2 px). The selector has a **subtle bouncing animation** (e.g. scale or position) so it is clearly visible and responsive.
- **Province border highlight:** The province (or sea zone) that contains the hovered tile is highlighted: its border segments **glow** (stroke **6 logical px** world space, 2× legacy 3 px) and use a **subtle animation** (e.g. opacity or stroke pulse). Land–sea glow segments use the same **coastal inset** as the province overlay. This applies to both land provinces and sea zones. In **player-constrained** mode, each glow segment is drawn only where the same predicate as the province overlay applies (at least one adjacent cell of that edge is not `unrevealed`); segments between two `unrevealed` cells are not shown.
- **Optional callback:** The widget may expose **onProvinceHovered**(prefixed province id, or null when hover leaves) so the parent can show tooltips or other feedback.
- **Tap-as-hover on touch (map visuals only):** On touch-only/mobile viewports where pointer hover is not available, **tapping a tile** drives the same **hover** visuals and **onTileHovered** / **onProvinceHovered** as pointer hover (selector + province glow). The **province/sea zone detail panel** does **not** use hover or tap-as-hover for its Tile section — only **onMapTileTappedForDetail** (and provider state) updates that panel.

---

## Visibility modes (full vs player-constrained)

The map widget supports two visibility modes that determine how each tile is rendered:

- **Full visibility mode:**
  - Ignores per-tile visibility and renders all tiles as fully visible.
  - Renders all tiles as fully visible (no per-tile visibility masking).
- **Player-constrained visibility mode:**
  - Uses per-tile visibility from the **player view** (see [player-view.md](../program/player-view.md)) to decide how each tile is drawn.
  - Visibility is specified per tile key `regionId|provinceId|x|y` and carried via `CellViewData.visibility` (see [map-visualization.md](../program/map-visualization.md)).
  - When the widget renders a player-constrained view in Widgetbook, it uses the **first player** (`game.players.first`) from the initialized demo game as the source of `playerView`.

### Tile rendering semantics per visibility

When the widget is in **full visibility mode**, it renders the base layer per the selected base-layer mode (terrain, resource icons, improvement labels, and optional road/rail transport sprites) plus capitals, province/sea and political borders (ungated), etc., and does not consider visibility for masking or boundary gating.

When the widget is in **player-constrained visibility mode**, it maps `CellViewData.visibility` to rendering and interaction as follows:

- **`visible`:** The tile is rendered unmodified (full terrain color, resource icons, improvement labels, and optional transport sprites per base-layer mode, and borders).
- **`fogged`:** The tile is rendered with the same content as `visible` but visually muted:
  - The base terrain color is blended towards a **darker gray or black** with a consistent, moderate darkening (e.g. ~40% toward black / 40% overlay) so fogged tiles are noticeably darker than fully visible tiles but remain readable.
  - Resource icons, improvement labels, and transport sprites remain readable but appear on the muted background.
- **`unrevealed`:** The tile is rendered as a solid black square:
  - No terrain color or icons/labels are shown.
  - **Capital markers and town/port icons** anchored on that cell are not drawn (same strategic hiding as resources on unrevealed tiles).
  - **Province/sea topology strokes and political strokes:** an edge between two adjacent cells is drawn only if **at least one** of the two cells is not `unrevealed` (land and sea use the same rule). Thus a region that is entirely unknown shows **no** interior province mesh; a partially revealed province shows only edges touching at least one non-`unrevealed` tile.

Hover, selection, and overlay behavior:

- Hover selector and province-border glow only apply to tiles that are not `unrevealed`.
- Province selection callbacks (`onProvinceSelected`, `onProvinceHovered`) **are invoked** for taps/clicks on tiles whose visibility is `visible`, `fogged`, or `unrevealed`; it is the responsibility of the overlay (see `SPEC/ui/province-sea-zone-detail-overlay.md`) to obfuscate data for fully unrevealed provinces/tiles.
- On touch devices, tapping a tile that is not `unrevealed` also updates the **hover selector** and hover callbacks as in the Hover section. The **detail overlay** stays in sync only when the shell also handles **onMapTileTappedForDetail** / provider selection — not via hover callbacks alone.

---

## Animation

- The widget **supports** animation of individual tiles and other assets (e.g. tile highlight, building animation, unit pulse).
- Implementation uses **Flame** so that per-tile and per-asset animations can be driven by game events or timers without blocking the UI. Animation API (e.g. “play tile animation at tileKey”) is implementation-defined; this spec only requires that the component is built so such animation is feasible.

---

## Layout and reuse

- **Reusable:** The map widget is a single reusable component. It is used by the Empire overview screen (one instance per region when a region is active). It may be reused elsewhere (e.g. debug or other screens) with the same contract.
- **Widgetbook debug mode:** The Map Widget “Debug mode” stories in Widgetbook use a map from the real map generator and an initialized game (default config); see app `debug_init_game` and map widget directories.
- **One region per instance:** Each widget instance displays one region's map (e.g. Old World or New World). Region id (or equivalent) is a parameter; data is supplied for that region only.
- **Desktop and mobile:** Same component; parent controls size. On mobile, one region per map with region switching via tabs (see [empire-overview.md](empire-overview.md)).

---

## Terrain Tileset Rendering

The map widget renders terrain using **Wang tilesets** for seamless terrain transitions. Each tileset is a 4×4 grid (16 tiles) that covers all corner combinations for transitions between two terrain types.

For L1 **interior** plains cells, the renderer may apply resource-specific plains terrain variants selected by terrain/resource id. Assets `tile_plains_grain`, `tile_plains_meat`, and `tile_plains_horses` use **transparent regions** around the drawn resource detail; the renderer **must** draw the **canonical interior plains** base (same `sea_plains` upper-base tile as non-resource interior plains) **before** compositing the variant PNG so transparency shows grass, not the blank canvas.

Variant keys:
- `tile_plains_grain` for `resourceId = grain`
- `tile_plains_meat` for `resourceId = meat`
- `tile_plains_horses` for `resourceId = horses`

These variants apply only to plains cells (not desert) and do not alter desert rendering rules.

### Runtime configuration (Flutter app)

- **Source of truth:** `app/assets/data/map_terrain_tilesets.json` (bundled under `assets/data/` in `pubspec.yaml`). See [wang-tileset-and-assets.md](wang-tileset-and-assets.md) § App map runtime configuration for the full schema and validation rules.
- **`map_cell_size_px`:** Logical size in pixels of each map cell in Flame (`RegionMapViewData.cellSize`, `CtRegionMap` / `RegionMapComponent` layout). Init-game map view data uses this value so the grid matches Wang draw destinations.
- **`wang_tilesets`:** Per–terrain-pair entries `sea_plains`, `sea_desert`, `plains_desert`. Each supplies `spec_json` and `atlas_png` asset paths and `tile_px` (atlas tile edge length). `tile_px` must match `tile_size` in that JSON. Tilesets may use different atlas sizes and `tile_px` values; the renderer maps each tile’s `bounding_box` in atlas space into one `cellSize`×`cellSize` screen cell (so a 32×32 atlas tile scales up when `map_cell_size_px` is 64).
- **Startup:** `MapTerrainConfig.ensureLoaded()` runs before map terrain load (app `main`; tests use `flutter_test_config.dart`). Swapping which PNG/JSON the app uses is a **config + asset** change only when paths and `tile_px` stay consistent with the files.

### Tileset Structure

- **Atlas:** PNG sheet; layout is defined by per-tile `bounding_box` in the JSON (PixelLab-style), not assumed row-major.
- **Metadata:** JSON with corner mappings (NW, NE, SW, SE → "upper" or "lower" terrain), `tile_size`, and `bounding_box` per tile.
- **Map grid vs atlas tile:** `map_cell_size_px` is the on-screen cell; `tile_px` is the source tile extent in the atlas for that tileset.

### Terrain Priority (Layer Order)

Terrains are assigned priority values for corner determination:

| Priority | Terrain Type | Notes |
|----------|--------------|-------|
| 0 | Sea | Base layer (ocean) |
| 1 | Plains | Default land terrain |
| 2 | Forest | Transitional layer |
| 2 | Hills | Transitional layer |
| 2 | Mountain | Transitional layer |
| 2 | Swamp | Transitional layer |
| 2 | Desert | New World only |

### Wang Tiling Algorithm

For each map cell (x, y):

1. **Build terrain vertex grid:** Create (width+1)×(height+1) grid of terrain priorities
2. **Sample 4 corners:** For cell (x, y), sample vertices at (x, y), (x+1, y), (x, y+1), (x+1, y+1)
3. **Determine corner values:** Each corner = max terrain priority among 4adjacent cells
4. **Select tileset:** Based on highest and second-highest terrain priorities in corners
5. **Find matching tile:** Look up tile by corner configuration (16 possible combinations)
6. **Draw tile:** Extract from tileset PNG using bounding box from metadata

### Tileset Chain

Tilesets are chained for visual consistency. All land terrain tilesets use the same "plains" base tile:

1. **Sea → Beach:** Coastline transitions
2. **Beach → Plains:** Coastal grass transitions
3. **Plains → Forest:** Forest edges
4. **Plains → Hills:** Hill transitions
5. **Plains → Mountain:** Mountain edges
6. **Plains → Swamp:** Swamp transitions
7. **Plains → Desert:** Desert edges (New World only)

### Asset files (implemented Wang tilesets)

The **three** L0/L1 Wang atlases used by the Flame map are whichever paths appear under `wang_tilesets` in `map_terrain_tilesets.json` (typically under `assets/images/terrain/tilesets/`). Additional transition tilesets (e.g. beach, plains↔forest) remain **pipeline / future** unless wired the same way; see [wang-tileset-and-assets.md](wang-tileset-and-assets.md).

### Visibility Integration

When rendering in **player-constrained visibility mode**:
- **visible tiles:** Render full tileset tiles
- **fogged tiles:** Apply a moderate black overlay to tile (e.g. 40% opacity) so fogged areas stay readable
- **unrevealed tiles:** Render solid black (no tile)

### Fallback Behavior

If a tileset fails to load, the widget falls back to solid color rendering using `RegionMapViewData.terrainColors` for backward compatibility.

Required plains resource variant assets (`tile_plains_grain.png`, `tile_plains_meat.png`, `tile_plains_horses.png`) are fail-fast assets: missing/decode failures in terrain asset initialization are treated as errors, not best-effort skips.

---

## Acceptance criteria

- **Given** bundled `assets/data/map_terrain_tilesets.json` with valid `map_cell_size_px`, required `wang_tilesets` keys, and asset paths whose JSON `tile_size` matches each entry’s `tile_px`, **when** the init-game map builds view data and loads terrain, **then** `RegionMapViewData.cellSize` equals `map_cell_size_px` and all three Wang atlases load without falling back to `terrainColors` for those transitions.
- **Given** a tile with `terrainType = plains` and `resourceId = grain`, **when** the map renders the terrain layer, **then** it selects plains terrain variant `tile_plains_grain` for that tile.
- **Given** a tile with `terrainType = plains` and `resourceId = meat`, **when** the map renders the terrain layer, **then** it selects plains terrain variant `tile_plains_meat` for that tile.
- **Given** a tile with `terrainType = plains` and `resourceId = horses`, **when** the map renders the terrain layer, **then** it selects plains terrain variant `tile_plains_horses` for that tile.
- **Given** an **interior** plains tile with `resourceId` in `{grain, meat, horses}`, **when** the map renders the L1 terrain layer, **then** it draws the canonical interior plains base and composites the selected `tile_plains_*` on top so pixels transparent in the PNG show the same plains base as neighboring non-resource plains (no spurious solid black from an undrawn background).
- **Given** a tile with `terrainType = desert` and any `resourceId`, **when** the map renders the terrain layer, **then** it does not select a plains terrain variant.
- **Given** terrain asset initialization and one required plains variant PNG is missing or fails decode, **when** map terrain assets are loaded, **then** initialization fails with an error instead of silently skipping that asset.
- **Given** only a change to `map_terrain_tilesets.json` (paths, `tile_px`, and/or `map_cell_size_px`) plus matching atlas/JSON assets declared in `pubspec.yaml`, **when** the app runs, **then** the map uses the new files and cell size without Dart code edits (same loader contract).
- **Given** a map widget with a region's data and visibility mode **full**, **when** the widget is laid out, **then** the viewport matches the widget size and shows terrain, optional resource icons, optional improvement labels, optional road/rail transport sprites (per base-layer mode), and markers (capitals, town/port icons, warp) at the current zoom level without fog gating.
- **Given** visibility mode **player-constrained** and a **capital marker** whose coordinates fall on a cell with `CellViewData.visibility` `unrevealed`, **when** the map renders, **then** that capital marker is not drawn; **when** that cell’s visibility becomes `visible` or `fogged`, **then** the capital marker is drawn again.
- **Given** visibility mode **player-constrained** and a **town or port icon** on a cell that is `unrevealed`, **when** the map renders, **then** that icon is not drawn (unchanged rule; capital markers follow the same predicate).
- **Given** the Great Power tint layer and a base-layer mode that includes resource icons and/or improvement labels and/or transport sprites, **when** the map renders a qualifying land tile, **then** the stack from bottom to top is: terrain base → transport sprites (if mode includes roads and level > 0) → L2 feature terrain overlays (when present) → GP tint (if on) → resource icons (if mode includes resources) → improvement labels (if mode includes improvements and level > 0) → later overlays per § Layer model.
- **Given** the province overlay is enabled and visibility mode is **full**, **when** the map renders province and sea-zone boundaries, **then** all topology edges are drawn (no gating by `CellViewData.visibility`), land↔sea-zone edges use a subtle/fainter stroke (instead of a solid black line), and other province/sea-zone borders are rendered subtly (not solid black).
- **Given** the province overlay is enabled and visibility mode is **player-constrained**, **when** two adjacent cells are both `unrevealed`, **then** no province/sea-zone topology stroke is drawn on the unit edge between them.
- **Given** the province overlay is enabled and visibility mode is **player-constrained**, **when** two adjacent cells belong to different provinces or sea zones and at least one cell is not `unrevealed`, **then** the topology stroke for that edge is drawn (stroke color rules unchanged: land↔sea subtle, etc.).
- **Given** the province overlay is enabled and visibility mode is **player-constrained**, **when** every tile in a connected land or sea zone is `unrevealed`, **then** no strokes are drawn for edges whose **both** endpoints are cells in that all-unknown area (interior mesh hidden).
- **Given** the province ownership (GP tint) layer is enabled and a land tile’s `ownerFactionId` is a Great Power (present in `RegionMapViewData.greatPowerFactionIds`) and the tile is not `unrevealed` when in player-constrained visibility mode, **when** the map renders that tile, **then** a semi-transparent tint of that faction’s `factionColors` entry at **alpha 0.5** is drawn over the completed terrain pass (including transport sprites and L2 feature overlays when drawn) but under resource icons and improvement labels.
- **Given** the province ownership layer is enabled, **when** the map renders a land tile owned by a Minor Nation or Tribe, **then** no Great Power ownership tint is drawn on that tile (political borders may still apply per political overlay).
- **Given** the province ownership layer is enabled, **when** the map renders a **sea** tile, **then** no Great Power ownership tint is drawn on that tile.
- **Given** the province ownership layer is enabled and visibility mode is player-constrained, **when** the map renders a tile whose `CellViewData.visibility` is `unrevealed`, **then** no Great Power ownership tint is drawn on that tile (the tile remains black per base visibility rules).
- **Given** the province ownership layer is enabled and visibility mode is player-constrained, **when** the map renders a tile whose visibility is `fogged` and the tile is GP-owned land, **then** the Great Power ownership tint is applied (same eligibility as `visible` GP land; fogging uses existing base-layer muting only).
- **Given** the province overlay (boundaries) is disabled, **when** the map renders the region, **then** province and sea-zone boundary strokes are not drawn, while hover selectors, hover glows, warp zone indicators, Great Power ownership tint (if its layer is enabled), and (if enabled) province name labels remain visible per their toggles; **capitals** and **town/port icons** still follow `CellViewData.visibility` in player-constrained mode (omitted on `unrevealed` cells).
- **Given** the province ownership layer is disabled, **when** the map renders the region, **then** no Great Power ownership tint is drawn, while boundary strokes (if the province overlay is enabled) and other layers follow their toggles.
- **Given** the province names layer is enabled, **when** the map renders land provinces, **then** each land province has at most one label at the centroid of its land tiles (subject to visibility rules above), using `provinceDisplayName` with local-id fallback, on a semi-transparent plate, with roughly constant on-screen size across zoom levels.
- **Given** the province names layer is enabled and a province town marker tile equals the province centroid-derived anchor tile, **when** the map renders that province label, **then** the label plate is placed using sea-zone-equivalent fallback semantics so it avoids overlap with that town tile when feasible.
- **Given** the province names layer is enabled and a province label that must avoid its centroid town tile would clip the map top when placed above, **when** the map renders, **then** the label uses below placement and still avoids overlap with the avoided town tile when feasible.
- **Given** the province names layer is enabled and a province label that must avoid its centroid town tile is near map edges, **when** the map renders, **then** the full plate remains inside region world bounds with no clipping.
- **Given** the province names layer is enabled and no perfect non-overlap placement exists for a province label that must avoid its centroid town tile, **when** the map renders, **then** placement uses the nearest valid in-bounds fallback.
- **Given** the province names layer is enabled and province `P` has province-level owner a Great Power (in `greatPowerFactionIds`) and every qualifying land cell for `P`’s label has `ownerFactionId` equal to that owner with a defined `factionColors` entry, **when** the map renders the label for `P`, **then** the name plate fill uses that GP’s RGB at **alpha 0.55** (tinted semi-transparent plate).
- **Given** the province names layer is enabled and province `P` has province-level owner a Minor Nation or Tribe (not in `greatPowerFactionIds`), **when** the map renders the label for `P`, **then** the name plate uses the **neutral** semi-transparent dark plate (even if some land tiles in `P` are owned by a GP due to purchase).
- **Given** the province names layer is enabled and the province ownership (GP land tint) layer is disabled, **when** the map renders a province that qualifies for a GP-tinted name plate, **then** the name plate is still GP-tinted (no dependency on the ownership tint toggle).
- **Given** the province names layer is enabled and a land province is the active capital province of any faction represented in `RegionMapViewData.capitalMarkers`, **when** the map renders the province label, **then** the UI layer draws `ui_icon_map_capital_star.png` immediately to the left of the province name.
- **Given** the province names layer is enabled and a land province is not the active capital province of any faction, **when** the map renders the province label, **then** the UI layer does not draw the capital star icon for that label.
- **Given** the province names layer is enabled and a capital province label is rendered, **when** label layout is computed, **then** the full province name text and capital star icon are both visible and neither is ellipsized or clipped.
- **Given** the province names layer is enabled and province `P` has civilian presence count greater than zero and player intel permits class-presence knowledge for `P`, **when** the map renders the province name label for `P`, **then** the province label includes the civilian presence icon.
- **Given** the province names layer is enabled and province `P` has regiment presence count greater than zero and player intel permits class-presence knowledge for `P`, **when** the map renders the province name label for `P`, **then** the province label includes the regiment presence icon.
- **Given** the province names layer is enabled and province `P` has ship presence count greater than zero and player intel permits class-presence knowledge for `P`, **when** the map renders the province name label for `P`, **then** the province label includes the ship presence icon.
- **Given** a province name label where one or more class presence counts are zero for province `P`, **when** the map renders that label, **then** the map does not render icons for zero-count classes.
- **Given** a province name label where two or more class icons are shown, **when** the map renders those icons, **then** the icons are ordered left-to-right as civilian, regiment, ship.
- **Given** the map cannot fit province name text and class icons on one line at the label position, **when** label layout is computed, **then** the map renders icons on a second line under the province name while preserving class order.
- **Given** player-constrained visibility/intel for province `P` does not expose class-presence knowledge to the current player, **when** the map renders `P`'s province name label, **then** no class presence icons are shown for `P`.
- **Given** turn resolution has completed and a new turn starts, **when** map label view data is refreshed, **then** class-presence icons are recomputed from the post-resolution province unit-presence state.
- **Given** `assets/icons/64/ui_icon_map_capital_star.png` is generated for the map label capital indicator, **when** asset checks run, **then** the icon passes: (a) human visual review confirming a recognizable gold star silhouette at map-label render scale and (b) deterministic checks confirming dominant yellow/gold hue and a non-rectangular opaque pixel cluster.
- **Given** the province names layer is disabled, **when** the map renders, **then** no province name labels and no sea zone name plates are drawn.
- **Given** the province names layer is enabled and a sea zone’s **centroid cell** is not `TileVisibility.unrevealed` under the map’s terrain visibility rules (including fleet move-draft reveal halo where applicable), **when** the map renders that region, **then** that sea zone’s **full** display name appears on a semi-transparent plate with fill **RGB (173, 216, 230)** at **alpha 0.55** and **black** text, using `RegionMapViewData.seaZoneDisplayNameByPrefixedId['regionId|localSeaZoneId']` with fallback to the local sea zone id when the map entry is missing.
- **Given** the province names layer is enabled and a sea zone’s **centroid cell** is `TileVisibility.unrevealed`, **when** the map renders, **then** no name plate is drawn for that sea zone.
- **Given** the province names layer is enabled and a sea zone has a fleet marker on its centroid tile, **when** the map renders, **then** the sea zone name plate does not overlap the centroid cell’s world rectangle (default placement **above**; **below** when **above** would clip the top of the map), and the full plate remains inside the region bounds after minimal nudge.
- **Given** the province names layer is enabled and a sea zone’s centroid lies on the **top** grid row (or any case where **above** placement would clip the map top), **when** the map renders, **then** the plate is placed **below** the centroid, still not overlapping the centroid cell, and the entire plate lies within the region world bounds.
- **Given** the province names layer is enabled and any sea zone label is rendered at a supported zoom level, **when** the map paints that label, **then** the entire sea zone name plate rectangle lies within the region’s world bounds (`0`–`width×cellSize`, `0`–`height×cellSize`) with no partial clipping.
- **Given** the province names layer is enabled and `RegionMapViewData.seaZoneDisplayNameByPrefixedId` supplies an unexpectedly long display string for a sea zone, **when** the map renders that label, **then** the UI shows the **complete** text with **no** ellipsis.
- **Given** the province names layer is enabled and a sea zone local id is present in `RegionMapViewData.warpMarkers`, **when** the sea label renders, **then** the label plate shows `ui_icon_map_warp_zone.png` to the left of the text in the same row with the standard label text-icon gap.
- **Given** the province names layer is enabled and a sea zone local id is not present in `RegionMapViewData.warpMarkers`, **when** the sea label renders, **then** no warp prefix icon is shown.
- **Given** the province names layer is disabled or the sea-zone centroid is `TileVisibility.unrevealed`, **when** the map renders, **then** neither sea-zone text nor the warp prefix icon is shown.
- **Given** a warp sea zone where the sea label is shown, **when** the map renders, **then** the existing yellow warp border glow remains unchanged and visible in its normal layer.
- **Given** the province names layer is enabled and the province overlay (boundaries) is disabled, **when** the map renders, **then** province name labels are still drawn (no dependency on the province overlay).
- **Given** the province names layer is enabled and the province ownership layer is disabled, **when** the map renders, **then** province name labels are still drawn (no dependency on the ownership tint).
- **Given** the political overlay is enabled while the province overlay is enabled and visibility mode is **player-constrained**, **when** two adjacent land tiles belong to different owning factions and **both** tiles are `unrevealed`, **then** no political border stroke is drawn between them.
- **Given** the political overlay is enabled while the province overlay is enabled and visibility mode is **player-constrained**, **when** two adjacent land tiles belong to different owning factions and at least one tile is not `unrevealed`, **then** a thicker political border stroke is drawn between them on top of the province/sea-zone boundary stroke when that topology edge is drawn.
- **Given** the political overlay is enabled while the province overlay is enabled and visibility mode is **full**, **when** two adjacent land tiles belong to different owning factions, **then** a thicker political border stroke is drawn between them regardless of `CellViewData.visibility`.
- **Given** the political overlay is disabled, **when** the map renders adjacent land tiles with different owning factions, **then** no political border stroke is drawn between them regardless of the province overlay setting.
- **When** the user pans, **then** the visible portion of the map updates; the full map remains pannable within the fixed scale.
- **When** the user zooms via scroll, pinch, keyboard, or shell slider, **then** the fit-relative multiplier `m` stays within **[0.5, 8]** and camera zoom equals **`m × z_fit`** after each update.
- **Given** the player changes fit-relative zoom multiplier `m` on one region map instance and then switches to another region in the same map host, **when** the new region is rendered, **then** the host reapplies the same `m` and computes effective camera zoom as `clamp(m, 0.5, 8) × z_fit(activeRegion)` without resetting `m` to 1.0.
- **Given** the reapplied global `m` would produce a camera state outside active-region camera bounds, **when** the map host updates the region, **then** the map clamps the resulting camera position and effective zoom using the same clamping rules as normal zoom/pan updates and remains interactive without errors.
- **When** the user taps/clicks a province, **then** the widget invokes the provided province-selection callback with an identifier (e.g. prefixed province id); the widget does not render province details itself.
- **When** the user hovers over a tile, **then** a selector (e.g. simple square) is shown on that tile with a subtle bouncing animation.
- **When** the user hovers over a tile that is not `unrevealed`, **then** the borders of that tile's province (or sea zone) glow and have a subtle animation, and each glowing segment follows the same visibility predicate as province topology strokes in player-constrained mode; when hover leaves, the highlight is removed.
- **Given** a touch/mobile viewport where pointer hover is not available, **when** the user taps a non-`unrevealed` tile, **then** the widget updates the hover selector and province-border glow and invokes hover-related callbacks as if the tile were hovered; **when** the host wires **onMapTileTappedForDetail**, **then** that callback also runs for the detail panel flow (provider), independent of hover.
- **Given** the component is implemented with Flame, **then** it is possible to drive per-tile or per-asset animations from external events or timers.
- **Given** the Widgetbook map widget story is configured with an initialized game whose `Game.players` list is non-empty, **when** the user enables player-constrained visibility mode in the story controls, **then** the widget builds its map view using the first player's (`game.players.first`) player view and applies per-tile visibility from that view.
- **Given** a map widget with `CellViewData.visibility` populated and the visibility mode set to **full**, **when** the widget renders tiles, **then** tiles whose visibility is `visible`, `fogged`, or `unrevealed` are all drawn as fully visible (no gray or black masking is applied based on visibility), and province/sea and political boundary strokes are not suppressed by visibility.
- **Given** a map widget with `CellViewData.visibility` populated and the visibility mode set to **player-constrained**, **when** the widget renders a tile whose visibility is `visible`, **then** the tile is drawn identically to the current base behavior (full terrain color and overlays).
- **Given** a map widget with `CellViewData.visibility` populated and the visibility mode set to **player-constrained**, **when** the widget renders a tile whose visibility is `fogged`, **then** the tile is drawn with the same terrain and overlays as `visible` tiles but with a consistent gray/opacity effect applied so the tile appears muted.
- **Given** a map widget with `CellViewData.visibility` populated and the visibility mode set to **player-constrained**, **when** the widget renders a tile whose visibility is `unrevealed`, **then** the tile area is drawn as solid black, no terrain or resource icons or improvement labels or transport sprites are shown, and hover callbacks are not fired for that tile while tap/click selection still invokes province-selection callbacks.

- **Given** the map widget is in work target selection mode (non-null **validTileKeys** and **onTileSelected** provided), **when** the widget renders a tile whose key is in **validTileKeys** and in the current region, **then** that tile is drawn with a flashing yellow border (opacity oscillates between ~0.4 and ~0.8). When the user taps a tile in **validTileKeys**, **then** the widget invokes **onTileSelected** with that tile key, commits the order (via parent), and exits selection mode (clears yellow selectors, restores white cursor). When the user taps a tile not in **validTileKeys** or empty area, **then** selection mode remains active and no cancel callback is fired.
- **Given** the map widget is in work target selection mode with **validTileKeys** provided but empty, **when** the user taps any tile, **then** the widget remains in selection mode and does not auto-cancel from that tap.
- **Given** the map widget is in work target selection mode, **when** the pointer hovers over tiles, **then** the hover selector is rendered with an **orange** outline (`Color(0xFFFFAA00`)) and hover events update the tile position via **onTileHovered**; hover does NOT trigger selection or cancellation.
- **Given** the map widget is in work target selection mode, **when** the user taps a tile in **validTileKeys** or taps outside valid tiles, **then** the widget invokes **onTileSelected** only for valid tiles; hover gestures remain purely visual and invalid/empty taps do not commit or cancel.
- **Given** the map widget is in work target selection mode, **when** the map renders, **then** a top-centered overlay appears with exact text **"Select a tile, or click cancel"** and a prominent clickable **`cancel`** control. Clicking `cancel` invokes **onWorkTargetSelectionCancelled** and exits selection mode.
- **Given** `RegionMapViewData.civilianTileMarkers` contains a marker for tile `T` and the map is not in work target selection mode, **when** the map renders tile `T`, **then** it draws one tile-sized civilian marker with a stack badge when `stackCount > 1`.
- **Given** the user assigns a civilian work order in the current turn and that unit has a pending draft `WorkOrder` with target tile key `T`, **when** the map renders before turn resolution, **then** the civilian marker projection includes that unit at tile `T` in the same turn (using the current draft order), instead of waiting for post-resolution unit movement.
- **Given** map markers and Civilian Units panel rows are shown in the same turn, **when** a civilian has pending or assigned work, **then** each surface derives location from one shared projected-location rule (pending target tile, else assigned tile, else standing tile) so display and locate targets stay aligned.
- **Given** a pending or assigned civilian marker tile `T` is currently `TileVisibility.fogged` for the active player, **when** the map renders in player-constrained mode, **then** tiles within Chebyshev distance <= 2 of `T` are painted as visible for display only (civilian reveal halo), and stored visibility remains unchanged.
- **Given** a civilian marker tile `T` is the same tile as a capital marker tile, **when** the map renders both markers, **then** the civilian marker is painted above the capital marker and any civilian stack badge remains legible.
- **Given** `RegionMapViewData.civilianTileMarkers` contains a marker for tile `T` with representative unit type `U` and `representativeIsAssigned = false`, **when** the map renders tile `T`, **then** the UI layer draws `assets/icons/64/ui_icon_civ_<slug(U)>.png` mapped by unit type.
- **Given** `RegionMapViewData.civilianTileMarkers` contains a marker for tile `T` with representative unit type `U` and `representativeIsAssigned = true`, **when** the map renders tile `T`, **then** the UI layer draws `assets/icons/64/ui_icon_civ_<slug(U)>.png` mapped by unit type and applies grayscale via paint-time color filtering.
- **Given** a selected civilian marker tile key and a map frame render, **when** the selected marker is painted, **then** only that marker (including its badge) uses blink modulation; unselected civilian markers remain steady.
- **Given** a civilian assignment flow completes and the previously selected civilian marker tile key differs from the newly assigned marker tile, **when** the shell exits work-target selection mode, **then** the shell clears the stale selected marker key so only an actively selected marker can blink.
- **Given** the map is not in work target selection mode and tile `T` contains a civilian marker, **when** the user taps tile `T`, **then** `onCivilianTileTapped` is invoked and default province/tile-detail tap handling for that tap is suppressed.
- **Given** a civilian marker is selected and the map is not in work target selection mode, **when** the user taps a non-civilian tile, **then** `onCivilianTileSelectionCleared` is invoked and regular map detail/province tap handling still runs.
- **Given** the map widget is given **base layer display mode** `terrainOnly`, **when** the widget renders the base layer, **then** terrain is drawn and no resource icons or improvement labels or transport sprites are drawn on tiles; capitals, town/port icons, and warp indicators are drawn subject to [base layer display mode](#base-layer-display-mode) (always, for mode switching) and, in player-constrained mode, capital/town/port markers additionally respect per-cell visibility as above.
- **Given** the map widget is given **base layer display mode** `terrainAndResources`, **when** the widget renders the base layer, **then** terrain and resource icons (64×64 source assets, on-map quarter-cell/capped display per § Resource Icons) are drawn per cell where present, and no improvement labels or transport sprites are drawn.
- **Given** the map widget is given **base layer display mode** `terrainAndResourcesImprovementLabels`, **when** the widget renders the base layer, **then** terrain and resource icons are drawn, and improvement labels `I{n}` are drawn only when `improvementLevel > 0` (top-left of cell); no transport sprites are drawn.
- **Given** the map widget is given **base layer display mode** `terrainAndResourcesImprovementsRoads`, **when** the widget renders the base layer, **then** terrain and resource icons are drawn, improvement labels when `improvementLevel > 0`, and road/rail transport sprites when `roadLevel > 0` with cardinal bitmask auto-tiling (`N=1, E=2, S=4, W=8`) on land cells only.
- **Given** the map widget omits **base layer display mode** (null), **when** the widget renders the base layer, **then** behavior matches `terrainAndResourcesImprovementsRoads` (full detail).
- **Given** the map widget uses a mode that draws improvements and/or transport sprites, **when** a tile has `improvementLevel == 0` or `roadLevel == 0`, **then** no `I0` label is drawn and no transport sprite is drawn for that tile.
- **Given** a map widget rendering a tile with a resource, **when** the base layer display mode includes resources, **then** the resource icon matching the resource ID is loaded from `assets/icons/64/ui_icon_com_<resource_id>.png` from the full **64×64** source and painted into the on-map **display** rect (quarter `cellSize`, capped at 64; never upscaled beyond native asset size). **Loading failures** (missing file, decode error) must propagate: `ResourceIconCache` does not swallow per-icon errors; a failed load aborts cache initialization so the problem surfaces immediately.
- **Given** a map widget rendering a tile with a resource, **when** the base layer display mode includes resources, **then** the resource icon uses **bottom-left placement** with `displaySize = min(cellSize / 4, 64)`: `iconX = tileLeft`, `iconY = tileTop + cellSize - displaySize` in tile coordinates; extraction throughput indicators remain anchored to that painted `Rect` and stack to the right.
- **Given** `baseLayerDisplayMode` is `terrainOnly`, **when** the map renders tiles, **then** the UI layer draws no extraction throughput indicators on any tile.
- **Given** a land tile renders a resource icon and `CellViewData.resourceExtractionEffectiveUnits = E >= 0` and `CellViewData.resourceExtractionBlockedUnits = B >= 0`, **when** the map renders that tile, **then** the UI layer draws exactly `E` effective **extraction discs** (gold `0xFFFFD700`) and `B` blocked **extraction discs** (brown `0xFF5C4033`) immediately to the right of the resource icon in a left-to-right overlapping stack, each disc visually distinct from the commodity resource sprite.
- **Given** `CellViewData.resourceExtractionEffectiveUnits + CellViewData.resourceExtractionBlockedUnits` is `0` or both values are `null`, **when** the map renders that tile, **then** the UI layer draws no extraction indicators on that tile.
- **Given** resource icon visibility/prospecting rules suppress a tile’s resource icon, **when** the map renders that tile, **then** the UI layer draws no extraction indicators on that tile.
- **Given** a fogged tile (`TileVisibility.fogged`) with a visible resource icon and extraction indicators, **when** the map renders the icon and indicators, **then** the indicators use the same fog modulation as the icon on that tile.
- **Given** extraction indicators are rendered for a tile, **when** indicator layout is computed, **then** each indicator square edge length is greater than or equal to the resource icon display edge length for that tile and the stack advances left-to-right with overlap.
- **Given** a tile renders extraction throughput indicators, **when** the overlay pass paints them, **then** the implementation does not reuse the commodity `Image`/`drawImageRect` path used for the base resource glyph for indicator slots (disc paint path is regression-covered; e.g. golden or dedicated paint helper test).
- **Given** a map widget with `RegionMapViewData.warpMarkers` populated (non-empty), **when** the widget renders the map, **then** a glowing yellow border is drawn around each warp sea zone; warp zone indicators are rendered regardless of `baseLayerDisplayMode`.
- **Given** a map widget in **player-constrained** visibility mode with `RegionMapViewData.warpMarkers` populated, **when** a warp perimeter unit edge has adjacent cells where both visibilities are `unrevealed`, **then** no warp glow segment is drawn on that edge.
- **Given** a map widget in **player-constrained** visibility mode with `RegionMapViewData.warpMarkers` populated, **when** a warp perimeter unit edge has adjacent cells where at least one visibility is `visible` or `fogged`, **then** the warp glow segment is drawn on that edge.
- **Given** a map widget in **full** visibility mode with `RegionMapViewData.warpMarkers` populated, **when** the widget renders warp perimeter edges, **then** warp glow segments are drawn regardless of `CellViewData.visibility` values.
- **Given** a map widget with `RegionMapViewData.warpMarkers` populated, **when** the user hovers over a warp zone sea zone tile, **then** the province border glow is shown (same as any other sea zone).
- **Given** the human player has a pending naval move draft from a fleet in `oldWorld` to a sea zone in `newWorld` and the new-world destination tile is currently `TileVisibility.unrevealed`, **when** the New World map region renders in player-constrained mode, **then** the UI layer renders a projected fleet marker at the destination sea-zone centroid tile before turn resolution.
- **Given** the human player has a pending cross-region naval move draft for fleet `F`, **when** map markers render in both the source and destination regions during draft preview, **then** the UI layer renders `F` at the projected destination region marker only and does not render `F` concurrently at the source-region marker location.
- **Given** a projected fleet marker exists due to a pending cross-region naval move draft, **when** the map renders in player-constrained mode, **then** terrain tiles within Chebyshev distance <= 2 of the projected marker tile are drawn as visible for display only, and stored fog state is unchanged.
- **Given** a pending cross-region naval move draft for fleet `F` is removed before turn resolution, **when** map markers render again, **then** the projected destination-region marker for `F` is removed and `F` is rendered at its current in-world location with no residual draft projection.
- **Given** a projected cross-region fleet marker is tapped and that marker’s fleet has `fleet.regionId` different from the destination region id, **when** the map emits `OpenNavalUnitsPanelEvent`, **then** the event uses a destination-normalized `locationScopeKey` and the Naval Units panel opens with rows scoped to that projected destination location.

---

## Integration

- **Data:** Uses shared view models and game state (e.g. `RegionMapViewData`, Game, topology, tile maps). See [map-visualization.md](../program/map-visualization.md), [player-view.md](../program/player-view.md) for visibility when needed. `RegionMapViewData` / `CellViewData` are the source of truth for what is rendered; the map widget does not perform its own world simulation.
- **Flame/Flutter:** Flame for the map canvas and animations; Flutter for shell and overlays. Per [repo-and-packages.md](../program/repo-and-packages.md): Flame owns game canvas and in-game pixel-art UI; communicate via state and callbacks. The reusable map widget is exposed to Flutter as a `CtRegionMap`-style wrapper that embeds a Flame `GameWidget` and internal Flame game/component tree. Province detail UI is wired only through **Riverpod** (or bus) at the shell — see **Province / sea zone detail panel** above and [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md).
- **Catalog:** Once implemented, register in app widget catalog (e.g. CtRegionMap or similar; category: game/map, Flame component).
