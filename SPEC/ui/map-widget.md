# Map Widget (reusable)

**SPEC/ui** — Reusable 2D tile-map component for the Flutter app. Renders one region's map with a base tile layer and optional overlays; viewport sized to the widget; pan and zoom with fixed zoom levels and smooth zooming. Tap/click exposes province selection via callbacks. Implemented as a **Flame** component to support animation of individual tiles and other assets. Data and events align with shared packages and event systems (same as ctterm); this spec is for the app only.

---

## Responsibility

- Display a **full** region map (one region per widget instance).
- **Viewport:** The visible area is the widget's layout size. Map extent is the full 2D tile grid; user pans and zooms to see it.
- **Base layer:** Single 2D tile layer: terrain, resources, improvements, towns, capitals.
- **Overlays:** Political ownership (borders) as a **separate overlay** on top; user can toggle overlay visibility.
- **Interaction:** Pan; fixed zoom levels with smooth zooming; tap/click to select a province (callbacks; province details content TBD elsewhere). **Hover:** When the pointer is over a tile, a selector (e.g. a simple square) is shown on that tile with a subtle bouncing animation; the hovered tile's province (or sea zone) borders glow and use a subtle animation (e.g. pulse).
- **Animation:** Widget supports animation of individual tiles and other assets (e.g. highlights, build progress); Flame is the implementation fit.

---

## Layer model

| Layer | Content | Togglable |
|-------|---------|-----------|
| **Base (tile)** | Terrain, resources, improvements, towns, capitals. | Optional per-sublayer if needed; at minimum base is always on. |
| **Borders** | Province and sea-zone boundaries (topology edges P–P, P–S, S–S). | Yes. User can turn the borders layer on/off. |
| **Political** | Political borders (ownership differences between adjacent land provinces). Drawn on top of base and borders. | Yes. User can turn political overlay on/off. |
| **Province names** | Land province labels: `CellViewData.provinceDisplayName` (same string as the Political section in the province detail overlay), with fallback to local province id when missing. One label per land province per region. Position: centroid of that province’s **land** tiles in the region (tile centers averaged). **Not** drawn for sea zones. **Player-constrained visibility:** only tiles that are not `unrevealed` participate in the centroid and get a label; if no qualifying tiles, no label. **Screen space:** text and backing plate use roughly **constant logical pixel size** regardless of map zoom (inverse scale in world space). Style: short label on a semi-transparent rectangular plate; neighbor overlap is acceptable. Rendered after province/political border strokes and before capitals/ports. | Yes. Independent of borders and political overlay toggles. |

Data source for tiles and ownership: shared view model (e.g. `RegionMapViewData` / game + tile maps per [map-visualization.md](../program/map-visualization.md)). Province and tile identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Base layer display mode

The base (tile) layer can show terrain only, terrain plus resource icons, or terrain plus resource icons and improvement/road labels. The widget accepts an optional **base layer display mode**; when provided, the map draws the overlay according to that mode. When not provided (e.g. Widgetbook, debug stories), the widget uses **full** mode so all overlays are shown for backward compatibility.

| Mode | Terrain | Resource icon | Improvement/road (I0, R0, …) |
|------|---------|---------------|-------------------------------|
| **terrainOnly** | Yes | No | No |
| **terrainAndResources** | Yes | Yes (icon) | No |
| **terrainResourcesImprovements** | Yes | Yes (icon) | Yes |

Implementation: a single overlay pass draws per-cell icons and text; the mode controls which elements are included. Capitals, ports, and warp zone indicators are always drawn regardless of mode.

---

## Resource Icons

Resources are displayed as 32×32 pixel-art icons rendered on tiles, centered within the cell. Icons are drawn instead of the legacy single-letter glyphs (g, t, i, …).

### Asset Files

Resource icons are stored in `app/assets/icons/` with naming convention `ui_icon_com_<resource_id>.png`:

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

All icons are 32×32 PNG with RGBA transparency, colonial-era pixel art style matching `ui_main_menu_button.png`.

### Rendering

- **Icon size:** Resource icons are always 32×32 pixels, regardless of the tile cell size. Icons are never scaled up; they render at native 32×32 resolution.
- **Position:** Position depends on the tile cell size:
  - **For tiles ≤32px:** Icon is centered horizontally within the tile cell; vertically positioned in the lower half of the cell to avoid overlapping terrain features.
  - **For tiles >32px:** Icon is placed in the **bottom-left corner** of the tile cell (at x=0, y=tileSize-32). This ensures the icon remains visible and readable at native resolution without being obscured or requiring upscaling.
- **Visibility:** Icons are subject to the same visibility rules as terrain (visible/fogged/unrevealed). Fogged tiles render icons with reduced opacity; unrevealed tiles show nothing.

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
  - Outer layer: 3px wide, semi-transparent gold (`0xFFFFD700` at 30% alpha)
  - Inner layer: 1.5px wide, bright yellow (`0xFFFFEA00`)
- **Border Logic:** Edges are drawn where a warp sea zone tile is adjacent to a non-warp tile (different sea zone or land province), similar to province border rendering.
- **Layer:** Rendered after the base terrain and overlays (after ports, same layer as capitals).
- **Visibility:** Always visible regardless of `baseLayerDisplayMode` (same as capitals and ports).

The **in-game shell** (Empire overview) may overlay a cycle button that toggles this mode; see [empire-overview.md](empire-overview.md).

---

## Viewport, scale, pan, zoom

- **Viewport:** Exactly the size of the map widget in the layout. No intrinsic minimum; parent constrains the widget.
- **Scale:** Fixed scale at any time (e.g. 1 tile = N logical pixels). **Fixed zoom levels:** Only discrete zoom levels are allowed; no free-form scale.
- **Pan:** User can pan to move the visible region over the full map (drag or gesture). Map is larger than viewport when zoomed in; **dragging** on the map surface pans the camera.
- **Zoom:** Smooth zooming between fixed zoom levels (e.g. pinch or buttons or scroll wheel). Transition is smooth; final scale snaps to a zoom level. **Pinch gestures** (on touch devices) and **scroll wheel** input (on pointer devices) both change zoom level.
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

**Constructor / props (driven by parent):** **`selectedTileKey`** — full tile key for the **orange** selection outline (detail panel’s selected tile). **`secondaryHighlightTileKey`** — optional second outline (e.g. cyan) for list/locate; distinct from selection. Parents set these from shared state (e.g. Riverpod); the map does not read panel widgets.

Details of what “province details” shows are **not** defined in this spec; the screen that embeds the map defines that. The map widget reports taps via callbacks and paints outlines from passed-in keys.

---

## Province / sea zone detail panel (decoupling)

- **No cross-imports:** The Flame map component tree and `CtRegionMap` MUST NOT import `ProvinceSeaZoneDetailOverlay` or any province-panel-only module. The detail overlay MUST NOT import the Flame map game class.
- **Bridge:** In the app, **`mapProvincePanelProvider`** holds `overlayOpen`, `selectedTileKey`, `secondaryHighlightTileKey`. A **Consumer** host (e.g. game map canvas stack) wires `onMapTileTappedForDetail` → `reportMapTileTapped`, and passes `selectedTileKey` / `secondaryHighlightTileKey` from `ref.watch` into the map widget. Side and narrow panel slots are separate Consumers that read the same provider and build the overlay. This satisfies “Riverpod-only” wiring between map and panel; `AppEventBus` is optional for other concerns.
- **Behavior:** **Tap** drives detail selection and panel content. **Hover** drives the animated hover selector and province/sea glow only — it does **not** update the detail panel’s selected tile. Full rules: [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md).

---

## Work target selection mode

- **When** the parent supplies **validTileKeys** (set or list of tile keys in format `regionId|provinceId|x|y`) and **onTileSelected**, the map is in **work target selection mode**.
- **Caching:** The parent computes valid tile keys **once** when entering selection mode (e.g., using `getValidWorkOrderTileKeysWithVisibility` or similar validation). The set is cached and passed to the map widget; the map widget does NOT recompute valid tiles on each frame or hover.
- **Orange cursor:** When in work target selection mode, the hover selector (the square outline that follows the pointer/tap) changes from white to **orange** (`Color(0xFFFFAA00)`) to visually indicate selection mode is active.
- **Flashing yellow selectors:** Every tile whose key is in **validTileKeys** (and belongs to the currently displayed region) is rendered with a **flashing yellow border/outline** that pulses (opacity oscillates, e.g. 0.4 to 0.8) to clearly indicate valid targets. The border should be visible and distinct from terrain but not overpower game visuals.
- **Empty valid tiles:** When **validTileKeys** is provided but empty (no valid targets for this unit/order), no tiles are highlighted. Tapping any tile invokes **onWorkTargetSelectionCancelled** to allow the user to back out of selection mode.
- **Hover behavior:** During work target selection mode, hover events update the cursor position and tile highlighting normally (via **onTileHovered**). Hover does NOT trigger selection or cancellation; only explicit tap/click does.
- **Selection:** Tap/click on a tile in **validTileKeys** invokes **onTileSelected** with that tile's key, **commits the order**, and **exits selection mode** (clearing the yellow selectors and restoring the normal white cursor).
- **Cancel on click outside:** Tap/click on a tile not in **validTileKeys** or on empty area **exits selection mode without committing** and invokes **onWorkTargetSelectionCancelled**.
- **Cancel button:** A **cancel button** with a **cross icon (×)** is overlaid on the map (e.g., top-right corner or similar visible position) when in work target selection mode. Clicking the cancel button **exits selection mode** and invokes **onWorkTargetSelectionCancelled** without committing any order. The cancel button is rendered on top of the map (Flutter overlay, not Flame canvas) so it remains visible alongside the tile selection visuals.
- **Region:** Valid tile keys may reference the other region; only tiles in the **currently displayed region** are highlighted. When the user switches region tab, the overlay shows valid tiles for that region. See [civilian-units-panel.md](civilian-units-panel.md).

---

## Hover

- **Selector:** When the pointer hovers over a tile, the widget shows a selector on that tile (e.g. a simple square outline). The selector has a **subtle bouncing animation** (e.g. scale or position) so it is clearly visible and responsive.
- **Province border highlight:** The province (or sea zone) that contains the hovered tile is highlighted: its borders **glow** and use a **subtle animation** (e.g. opacity or stroke pulse). This applies to both land provinces and sea zones.
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

When the widget is in **full visibility mode**, it renders the base layer exactly as today (terrain, resources, improvements, roads, capitals, borders) and does not consider visibility.

When the widget is in **player-constrained visibility mode**, it maps `CellViewData.visibility` to rendering and interaction as follows:

- **`visible`:** The tile is rendered unmodified (full terrain color, resource icons, improvement/road labels, and borders).
- **`fogged`:** The tile is rendered with the same content as `visible` but visually muted:
  - The base terrain color is blended towards a **darker gray or black** with a consistent, moderate darkening (e.g. ~40% toward black / 40% overlay) so fogged tiles are noticeably darker than fully visible tiles but remain readable.
  - Resource icons and improvement/road labels remain readable but appear on the muted background.
- **`unrevealed`:** The tile is rendered as a solid black square:
  - No terrain color or icons/labels are shown.
  - Province and faction borders for unrevealed tiles are not emphasized; border behavior at the edge between revealed/fogged and unrevealed tiles is implementation-defined and may be omitted for unrevealed areas.

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

### Tileset Structure

- **Format:** Each tileset is a 128×128 PNG (4×4 grid of 32×32 tiles)
- **Metadata:** JSON file with corner mappings (NW, NE, SW, SE → "upper" or "lower" terrain)
- **Tile Size:** 32×32 pixels per tile (configurable via `cellSize` in view data)

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

### Asset Files

Tilesets are stored in `assets/images/terrain/`:
- `tileset_sea_beach.png` / `.json`
- `tileset_beach_plains.png` / `.json`
- `tileset_plains_forest.png` / `.json`
- `tileset_plains_hills.png` / `.json`
- `tileset_plains_mountain.png` / `.json`
- `tileset_plains_swamp.png` / `.json`
- `tileset_plains_desert.png` / `.json`

### Visibility Integration

When rendering in **player-constrained visibility mode**:
- **visible tiles:** Render full tileset tiles
- **fogged tiles:** Apply a moderate black overlay to tile (e.g. 40% opacity) so fogged areas stay readable
- **unrevealed tiles:** Render solid black (no tile)

### Fallback Behavior

If a tileset fails to load, the widget falls back to solid color rendering using `RegionMapViewData.terrainColors` for backward compatibility.

---

## Acceptance criteria

- **Given** a map widget with a region's data, **when** the widget is laid out, **then** the viewport matches the widget size and shows the base tile layer (terrain, resources, improvements, towns, capitals) at the current zoom level.
- **Given** the borders layer is enabled, **when** the map renders province and sea-zone boundaries, **then** land↔sea-zone edges use a subtle/fainter stroke (instead of a solid black line) and other province/sea-zone borders are rendered subtly (not solid black).
- **Given** the borders layer is disabled, **when** the map renders the region, **then** province and sea-zone boundary strokes are not drawn while hover selectors, hover glows, capitals, ports, warp zone indicators, and (if enabled) province name labels remain visible.
- **Given** the province names layer is enabled, **when** the map renders land provinces, **then** each land province has at most one label at the centroid of its land tiles (subject to visibility rules above), using `provinceDisplayName` with local-id fallback, on a semi-transparent plate, with roughly constant on-screen size across zoom levels.
- **Given** the province names layer is disabled, **when** the map renders, **then** no province name labels are drawn.
- **Given** the province names layer is enabled and the borders layer is disabled, **when** the map renders, **then** province name labels are still drawn (no dependency on borders).
- **Given** the political overlay is enabled while the borders layer is enabled, **when** two adjacent land tiles belong to different owning factions, **then** a thicker political border stroke is drawn between them on top of the province/sea-zone boundary stroke.
- **Given** the political overlay is disabled, **when** the map renders adjacent land tiles with different owning factions, **then** no political border stroke is drawn between them regardless of the borders layer setting.
- **When** the user pans, **then** the visible portion of the map updates; the full map remains pannable within the fixed scale.
- **When** the user zooms, **then** only fixed zoom levels are used and zooming is smooth between levels.
- **When** the user taps/clicks a province, **then** the widget invokes the provided province-selection callback with an identifier (e.g. prefixed province id); the widget does not render province details itself.
- **When** the user hovers over a tile, **then** a selector (e.g. simple square) is shown on that tile with a subtle bouncing animation.
- **When** the user hovers over a tile, **then** the borders of that tile's province (or sea zone) glow and have a subtle animation; when hover leaves, the highlight is removed.
- **Given** a touch/mobile viewport where pointer hover is not available, **when** the user taps a non-`unrevealed` tile, **then** the widget updates the hover selector and province-border glow and invokes hover-related callbacks as if the tile were hovered; **when** the host wires **onMapTileTappedForDetail**, **then** that callback also runs for the detail panel flow (provider), independent of hover.
- **Given** the component is implemented with Flame, **then** it is possible to drive per-tile or per-asset animations from external events or timers.
- **Given** the Widgetbook map widget story is configured with an initialized game whose `Game.players` list is non-empty, **when** the user enables player-constrained visibility mode in the story controls, **then** the widget builds its map view using the first player's (`game.players.first`) player view and applies per-tile visibility from that view.
- **Given** a map widget with `CellViewData.visibility` populated and the visibility mode set to **full**, **when** the widget renders tiles, **then** tiles whose visibility is `visible`, `fogged`, or `unrevealed` are all drawn as fully visible (no gray or black masking is applied based on visibility).
- **Given** a map widget with `CellViewData.visibility` populated and the visibility mode set to **player-constrained**, **when** the widget renders a tile whose visibility is `visible`, **then** the tile is drawn identically to the current base behavior (full terrain color and overlays).
- **Given** a map widget with `CellViewData.visibility` populated and the visibility mode set to **player-constrained**, **when** the widget renders a tile whose visibility is `fogged`, **then** the tile is drawn with the same terrain and overlays as `visible` tiles but with a consistent gray/opacity effect applied so the tile appears muted.
- **Given** a map widget with `CellViewData.visibility` populated and the visibility mode set to **player-constrained**, **when** the widget renders a tile whose visibility is `unrevealed`, **then** the tile area is drawn as solid black, no terrain or resource icons/improvement/road labels are shown, and hover callbacks are not fired for that tile while tap/click selection still invokes province-selection callbacks.

- **Given** the map widget is in work target selection mode (non-null **validTileKeys** and **onTileSelected** provided), **when** the widget renders a tile whose key is in **validTileKeys** and in the current region, **then** that tile is drawn with a flashing yellow border (opacity oscillates between ~0.4 and ~0.8). When the user taps a tile in **validTileKeys**, **then** the widget invokes **onTileSelected** with that tile key, commits the order (via parent), and exits selection mode (clears yellow selectors, restores white cursor). When the user taps a tile not in **validTileKeys** or empty area, **then** the widget invokes **onWorkTargetSelectionCancelled** and exits selection mode.
- **Given** the map widget is in work target selection mode with **validTileKeys** provided but empty, **when** the user taps any tile, **then** the widget invokes **onWorkTargetSelectionCancelled** to allow the user to back out of selection mode.
- **Given** the map widget is in work target selection mode, **when** the pointer hovers over tiles, **then** the hover selector is rendered with an **orange** outline (`Color(0xFFFFAA00`)) and hover events update the tile position via **onTileHovered**; hover does NOT trigger selection or cancellation.
- **Given** the map widget is in work target selection mode, **when** the user taps a tile in **validTileKeys** or taps outside valid tiles, **then** the widget invokes **onTileSelected** (for valid tiles) or **onWorkTargetSelectionCancelled** (for invalid/empty), respectively; hover gestures remain purely visual during selection mode and do not commit or cancel.
- **Given** the map widget is in work target selection mode, **when** the map renders, **then** a cancel button with a cross icon (×) is overlaid on the map (Flutter overlay) in a visible position (e.g., top-right corner). Clicking the cancel button invokes **onWorkTargetSelectionCancelled** and exits selection mode.
- **Given** the map widget is given **base layer display mode** `terrainOnly`, **when** the widget renders the base layer, **then** terrain (and capitals, ports) is drawn and no resource icons or improvement/road labels are drawn on tiles.
- **Given** the map widget is given **base layer display mode** `terrainAndResources`, **when** the widget renders the base layer, **then** terrain and resource icons (32×32 pixel art) are drawn per cell where present, and improvement/road labels (I0, R0, …) are not drawn.
- **Given** the map widget is given **base layer display mode** `terrainResourcesImprovements` (or the parameter is omitted), **when** the widget renders the base layer, **then** terrain, resource icons, and improvement/road labels are all drawn per cell where present.
- **Given** a map widget rendering a tile with a resource, **when** the base layer display mode includes resources, **then** the resource icon matching the resource ID is loaded from `assets/icons/ui_icon_com_<resource_id>.png` and rendered at native 32×32 resolution (never upscaled). **Loading failures** (missing file, decode error) must propagate: `ResourceIconCache` does not swallow per-icon errors; a failed load aborts cache initialization so the problem surfaces immediately.
- **Given** a map widget rendering a tile with a resource on a **32px or smaller cell**, **when** the base layer display mode includes resources, **then** the resource icon is centered horizontally and positioned in the lower half of the cell.
- **Given** a map widget rendering a tile with a resource on a **larger than 32px cell** (e.g. 64px), **when** the base layer display mode includes resources, **then** the resource icon is positioned in the **bottom-left corner** of the tile (x=0, y=tileSize-32) at native 32×32 resolution.
- **Given** a map widget with `RegionMapViewData.warpMarkers` populated (non-empty), **when** the widget renders the map, **then** a glowing yellow border is drawn around each warp sea zone; warp zone indicators are rendered regardless of `baseLayerDisplayMode`.
- **Given** a map widget with `RegionMapViewData.warpMarkers` populated, **when** the user hovers over a warp zone sea zone tile, **then** the province border glow is shown (same as any other sea zone).

---

## Integration

- **Data:** Uses shared view models and game state (e.g. `RegionMapViewData`, Game, topology, tile maps). See [map-visualization.md](../program/map-visualization.md), [player-view.md](../program/player-view.md) for visibility when needed. `RegionMapViewData` / `CellViewData` are the source of truth for what is rendered; the map widget does not perform its own world simulation.
- **Flame/Flutter:** Flame for the map canvas and animations; Flutter for shell and overlays. Per [repo-and-packages.md](../program/repo-and-packages.md): Flame owns game canvas and in-game pixel-art UI; communicate via state and callbacks. The reusable map widget is exposed to Flutter as a `CtRegionMap`-style wrapper that embeds a Flame `GameWidget` and internal Flame game/component tree. Province detail UI is wired only through **Riverpod** (or bus) at the shell — see **Province / sea zone detail panel** above and [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md).
- **Catalog:** Once implemented, register in app widget catalog (e.g. CtRegionMap or similar; category: game/map, Flame component).
