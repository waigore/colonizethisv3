# Map Data: Topology and Tile Maps

**SPEC/program** — Format and ownership of static map data (topology, tile maps) and the generate_map CLI. Game semantics: [SPEC/game/world-model.md](../game/world-model.md), [SPEC/game/map-topology.md](../game/map-topology.md). Tile map generation: [tile-map-generation.md](tile-map-generation.md).

---

## Topology format

**Region topology** is stored as a graph:

- **Nodes:** List of nodes with id, region id, and type (province | sea zone). Cross-region: nodes may belong to different regions.
- **Edges:** List of undirected edges (id1, id2). Semantics: P<->P (contiguous land), P<->S (province next to sea), optionally S<->S. Edges may reference nodes from different regions (cross-region adjacency).
- **Storage:** File per region or one world graph with region labels; format (e.g. JSON or YAML) is implementation-defined. Loaded at game creation; colonizethis_data owns loading and provides topology to logic and tools. When generating maps, topology is **inferred** from the tile map.
- **Province ids:** Topology and tile maps use **local** province ids (e.g. `p1`, `p2`). Game state (Province, Unit, orders, etc.) uses **prefixed** ids (`regionId|localId`). When resolving a province from game state, always use regionId + provinceId; never look up by province id alone. See [world-model.md](../game/world-model.md) (Province identity and lookup). **Map visualizers must always convert local ids from the tile map into full province ids before querying ownership or names.** Tile-map ids are an internal encoding only; the source of truth for ownership is the full province id stored in game state.

---

## Tile map format

**Per-region 2D grid (static per scenario).** Each cell: region id (province or sea zone), type (land/water), **terrain type** (for land), **resource** (optional; at most one). Resource must be allowed for that **region** and that **terrain type**; resource–region and resource–terrain rules live in colonizethis_data. Extraction level and road are **mutable** game state (keyed by region, province, tile), not part of the static tile map (or only as initial scenario state). Produced by tile-based map generation ([tile-map-generation.md](tile-map-generation.md)) or loaded from data. Not persisted in game save; static per map/scenario.

---

## Map generation tool (unified)

A single tool supports end-to-end map generation. **Place:** `tool/generate_map/`.

**Mode:** Generate map from province count (N) and continent count (C) via `--provinces` and `--continents`. Infer topology from the grid. Output graph description, map summary, tile map PNG, and **topology graph** (DOT file; PNG when Graphviz installed).

**Options:** `--provinces N` (default: 60), `--continents M` (default: 3; must be 2–4), `--region oldWorld|newWorld` (default: oldWorld), `--tiles-per-province N`, `--sea-fraction F`, `--interactive`, `--tile-map`, `--tile-map-image[=path]`, `--seed <n>`, `--world-state <path>`, `--join-continents` (default off), `--seed-before-assignment` (default off), `--skip-fill-lakes` (default off), `--continent-buffer N` (default 2).

**Topology graph visualization:** Export topology to Graphviz DOT format. Write `.dot` file; render PNG with Graphviz. If Graphviz not found or fails: warn user ("Graphviz not installed; run `brew install graphviz` to render topology graph"), write `.dot` only, continue. Show topology graph PNG alongside tile map PNG when both are produced.

- **Map-aligned layout:** When a tile map is available (e.g. during map generation), nodes are positioned to match their locations on the map. Centroids (average x, y of all tiles per region id) are computed from the tile map and emitted as `pos="x,y!"` in the DOT output. Grid coordinates are scaled to **points** (neato -n expects points; 72 points = 1 inch). Default scale: 12 points per grid cell so a typical map renders at readable size. Graphviz's **neato** layout engine (part of Graphviz) supports fixed positions via the `pos` attribute; the `!` suffix marks the position as fixed.
- **Rendering:** When positions are present, use `neato -n -Tpng` (the `-n` flag tells neato to use existing positions instead of computing layout). When positions are absent (e.g. topology-only export, no tile map), fall back to `dot -Tpng` for automatic layout.
- **Node labels:** When tile counts are available, each node label is `nodeId (tileCount)` — e.g. `p25 (33)` means province p25 has 33 tiles. The number in brackets is the tile count.
- **Node size:** Nodes use fixed dimensions (width=0.2, height=0.2 inches, fixedsize=true, fontsize=8) to avoid overlap in dense graphs.

**Run:** From repo root: `melos run generate_map -- [options]`.

### Tile map PNG export

When the tool (or colonizethis_data) exports a tile map as PNG:

- **Fill:** When terrain data is present, each cell is colored by **terrain type**. Sea zones use a single **deep blue**. Land cells use a fixed color per terrain (plains, forest, hills, mountain, swamp). When terrain data is absent, fill falls back to region-based coloring (one color per province/sea zone) for backward compatibility.
- **Borders:** Borders are drawn on edges between two cells that belong to different regions. **Land borders** (province–province and province–sea) are drawn in **black**. **Sea zone borders** (sea–sea, i.e. between two different sea zone ids) are drawn in **light blue** (e.g. RGB 173, 216, 230) so sea zone boundaries are visible. Legend text should indicate: black = land borders, light blue = sea zone borders.
- **Legend:** When terrain is present, the legend lists **terrain types** with a color swatch and label. When seed positions are provided, the image MAY draw continent seeds and land seeds with per-continent coloring.
- **Resources:** When resource data is present (`result.resourceGrid != null`), each land cell that has a resource displays a single **lowercase letter** at cell center. Legend letters: g Grain, m Meat, w Wool, h Horses, t Timber, i Iron, c Copper, n Tin, k Coal, s Sugar Cane, b Tobacco, u Cotton, f Furs, p Spices, v Silver, a Gold, e Gems, d Diamonds. Letters are drawn **last** on the map (after borders and seed markers) so they remain visible. See [resource-terrain-region-rules.md](../game/resource-terrain-region-rules.md). If more resources are added later, consider two-letter codes.
- **Land seeds:** Land seeds are drawn as **small circles** at cell centers, with a **black outline** (fill + outline), so they are clearly distinguishable from the square tile cells. Continent seeds remain the larger, distinct-style markers.
- **Region id on tiles:** Each tile (cell) MAY display its **region id** (e.g. p1, s2) as text on the map for identification. The id is drawn in **red** so it stands out from terrain and borders. When resources are present, resource letters are drawn at cell center and remain visible; region id placement (e.g. top-left of cell) should avoid obscuring resource letters where possible.
- **Tile size:** **Tile size** (pixels per cell, "cell size") is configurable so that tile details are easier to see. The default cell size is **24** pixels per tile (implementation may use a larger default than previously). The generate_map tool and colonizethis_map APIs accept an optional cell size parameter; when not specified, the default is used.

---

## Tile map visualizers (two, shared code)

Two visualizers exist; they share border drawing, legend layout, and swatch helpers.

### Base tile map visualizer

**Module:** `tile_map_visualization`. Renders `TileMapResult` + `MapTopology`. Fill by terrain or region. Legend: terrain types, regions, seeds, resources. No game state. Used by generate_map. Implemented in colonizethis_map.

### Game world state map visualizer

**Module:** `game_world_state_map_visualizer`. Extends base by adding ownership overlay, capital markers, and port markers. Input: `Game` + per-region tile maps and topology (or an `InitGameMapViewData` view model for tools). Reads `Province.ownerId` for ownership; `Player.capitalTile`, `MinorNation.capitalTile`, `Tribe.capitalTile` for capitals; `WorldState.portsByProvinceSeaboard` for port tile positions (value = tile key `regionId|provinceId|x|y`). Separate module; shares border drawing, legend layout, swatches.

- **Ownership colours (legibility):** One colour per faction, chosen by faction type.
  - **Great Powers:** Ownership colours are taken from **GDD 09 (Great Powers & Leaders)** default colour per **semantic GP id** (e.g. `england` red, `france` dark blue, `portugal` green). During game setup, orchestration maps each selected semantic id to a per-game `Player.id` (e.g. `gp1`, `gp2`…) and re-keys any GP colour overrides from semantic id → `Player.id`. The game-state map view model (`RegionMapViewData.factionColors`) is therefore always keyed by **runtime faction id** (`Player.id`, MinorNation id, Tribe id), never by semantic id.
  - When an optional override map (semantic GP id → RGB) is supplied—e.g. by ctdev from Init Game Config choices—setup converts it into a `Player.id` → RGB map and passes that to the map builder. If no override is supplied, GDD defaults per semantic id are looked up and then associated with the corresponding `Player.id`.
  - **Minor Nations:** Use a palette of grey shades.
  - **Tribes (New World):** Use a deterministic vibrant palette by index.
  - The base tile map visualizer and other region-by-id colouring continue to use the existing single `regionPalette`; only the game-state ownership overlay uses the type-based split. When building the map view from a **loaded game**, ctdev passes the game's `greatPowerColorOverride` (if any, keyed by `Player.id`) so ownership colours match the setup that was used when the game was created; when the save has no override, GDD default colours are used. The `Game` model may carry an optional `greatPowerColorOverride` (setup-time GP map colours) for display; when present it is used by map visualizers and ctdev, and when absent GDD defaults apply.
- **Capitals:** Distinct marker (e.g. gold circle) at capital tile; legend entry per faction.
- **Ports:** The map shows **port** locations. For each region, the visualizer draws a **distinct marker** at each port tile (e.g. filled diamond or small square in a different colour from capitals). The legend includes a line explaining ports. Capitals remain the gold circle; ports use a different shape/colour.

The ctdev debug app consumes `InitGameMapViewData` and offers a **view mode toggle**. In geographic mode, the legend includes a **compact glyph reference** (all 18 resource letters in fixed order) and **per-region resource count breakdown** (OW and NW; format `letter+count`, e.g. `OW: g12 m8 w5`, `NW: t8 s20 b5`). Hovering over the resource glyph lines shows the full letter→name legend in the right inspection panel.

- **Political view:** fill tiles by faction ownership using `ownerFactionId` and `factionColors`; capitals and ports are overlaid as markers.
- **Geographic view:** fill tiles by **terrain type** (and draw resource glyphs) using `terrainTypeId` / `resourceId`; ownership is shown only via overlays (capitals/ports or optional outlines). Both modes use the same underlying view model; the toggle is a **UI-only concern** in ctdev.

Implemented in colonizethis_map; consumed by init_game tool and the ctdev debug app (via the shared map view model).

- **PNG-from-view-data:** `renderInitGameMapToPngFromViewData` supports an optional **geographic mode** parameter. When true, land is filled by terrain using `terrainColors` and per-tile resource glyphs (g/t/i) are drawn at cell centres; when false, current behaviour (ownership fill only). Legend in geographic mode lists terrain swatches and resource letters (e.g. "g Grain", "t Timber", "i Iron").

### Map view model for tools

For tools that need richer, renderer-agnostic access to map and ownership data (PNG export, ctdev debug app), colonizethis_map exposes a lightweight view model. The logical `cellSize` in these view models is the base pixel size used for PNG export (e.g. 24px per tile); UI tools such as ctdev are free to apply their own additional scale factor so that maps fit typical viewports while keeping tiles readable.

- `RegionMapViewData`:
  - `regionId` (`oldWorld` or `newWorld`).
  - `width`, `height` (grid in cells) and `cellSize` (logical tile size).
  - Per-cell data (`CellViewData`):
    - `x`, `y`.
    - `regionCellId` — **local** province/sea-zone id from the tile map (e.g. `p12`, `s3`). This id is used for drawing borders and matching the topology, but is **never** used directly to look up ownership in game state.
    - `isSea`.
    - optional `terrainTypeId`, optional `terrainType` (for renderers; lookup by terrain type, not string id).
    - optional `resourceId`.
    - optional `ownerFactionId` — owning faction id for the province that this cell belongs to. This is computed by first converting `regionCellId` + `regionId` into a **full province id** (`regionId|regionCellId`) and then looking up `Province.ownerId` using that full id. When `Province.ownerId` is null/empty, `ownerFactionId` is null and political view falls back to a neutral colour.
    - optional `provinceDisplayName` — assigned province display name for land provinces (e.g. "Wessex", "London"); derived by resolving full province id (`regionId|regionCellId`) into a `Province` and reading `displayName`.
    - optional `improvementLevel` (0–4, from `WorldState.tileState.improvementByTile`; tile key format `regionId|provinceId|x|y`).
    - optional `roadLevel` (0/1/2/4, from `tileState.roadLevelByTile`).
  - Overlays:
    - `capitalMarkers`: faction id, display name, x, y.
    - `portMarkers`: tile position plus province/sea-zone ids (derived from `portsByProvinceSeaboard`).
    - `unitMarkers`: province-level markers for units/armies. The builder chooses **one representative tile per province** by scanning the tile map and mapping the **full** province id (`regionId|localId`) to the first land tile it encounters for that province. When building markers, it looks up units by `Unit.provinceId` (full id) in this map. This guarantees that unit markers continue to work even when the same local id (e.g. `p1`) exists in multiple regions.
  - Legend/palette:
    - `factionColors`: faction id → RGB.
    - `terrainColors`: terrain type → RGB (when terrain is present). Must use the **same terrain palette** as the base tile map PNG (fixed RGB per `TerrainType`). For geographic rendering, lookup is by **terrain type** (enum), not by string id.
- `InitGameMapViewData`:
  - `oldWorld` and `newWorld` `RegionMapViewData` instances.
  - Optional metadata: RNG seed and a short `GameSetupConfig` summary string.

`runInitGame` builds an `InitGameMapViewData` instance alongside the combined PNG. Both the PNG renderer and the ctdev Flutter dev app consume this view model instead of re-deriving map overlays from scratch.

### Legend layout abstraction

Shared legend layout utilities (padding, line height, swatch size) used by both visualizers. Game-state visualizer adds sections: **Ownership** (faction id → color), **Capitals** (marker + "Capital of gp1", etc.).

---

## Multi-region rendering

Renderer supports composing two maps (Old World + New World) side by side. Layout: OW left, NW right; labels "Old World" / "New World"; shared legend below. Generation (which returns `TileMapResult` per region) is decoupled from rendering; composition step combines two single-region renders. API: `renderMultiRegionMapToPng(oldWorld, newWorld, options)` or equivalent. Orchestration in colonizethis_map. Used by init_game for combined OW+NW output.

---

## Tile-based map generation

Implemented in colonizethis_map. Algorithm and contract: [tile-map-generation.md](tile-map-generation.md). Game-side semantics: [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md). **Grid size** derived from N, C, target tiles per province, sea fraction. Input: province count (N), continent count (C), region id, map params. Output: per-region tile map (2D grid) and inferred MapTopology.
