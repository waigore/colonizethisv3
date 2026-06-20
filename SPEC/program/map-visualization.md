# Map Visualization: PNG Export and View Builders

**SPEC/program** — PNG export, color schemes, legends, border rendering. Data model: [map-data.md](map-data.md). Tile map generation: [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md). Province and tile identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Responsibility

Render tile maps and topology to PNG; provide view models for tools. Two visualizers share border drawing, legend layout, swatches.

---

## Cell-fill render pipeline

All PNG fill paths in `colonizethis_map` share a single cell-fill abstraction so the political (ownership), geographic (terrain), and base region/terrain renders differ **only by their colour strategy**, never by a copy-pasted nested fill loop (Refs #3574).

- **Per-cell primitive:** `fillCellRect` owns the `cellSize`×`cellSize` pixel-block geometry for one tile cell. Every fill path uses it so block bounds are identical across renders.
- **Grid fill:** `fillTileGridCells(image, height, width, cellSize, colorAt)` walks a 2D tile grid via the canonical row-major `TileMapGrid.forEachIndex` order and fills each cell with the RGB returned by the `colorAt(x, y)` strategy. Used by the base tile-map visualizer (terrain or region fill) and the game-world `Game`/topology ownership fill.
- **View-data fill:** `fillRegionViewCells(image, cells, cellSize, colorAt)` is the companion for pre-flattened `RegionMapViewData` cells, filling each via `colorAt(cell)`. Used by `renderInitGameMapToPngFromViewData` for both political and geographic modes.
- **Determinism:** Fill order is the same as the borders/markers drawn afterwards; the abstraction preserves byte-identical PNG output relative to the previous hand-rolled loops.

---

## Tile map PNG export

- **Fill:** Terrain present → color by terrain type. Sea = deep blue. Land = fixed color per terrain. No terrain → fallback to region-based coloring.
- **Borders:** Different regions → draw border. Land borders (P–P, P–S): black. Sea zone borders (S–S): light blue (e.g. RGB 173, 216, 230). Legend: black = land borders, light blue = sea zone borders.
- **Legend:** Terrain swatches and labels. Optional: seed positions (continent/land seeds). Resources: when `resourceGrid` present, land cells with resource show **lowercase letter** at center. Legend letters: g Grain, m Meat, w Wool, h Horses, t Timber, i Iron, c Copper, n Tin, k Coal, s Sugar Cane, b Tobacco, u Cotton, f Furs, p Spices, v Silver, a Gold, e Gems, d Diamonds.
- **Land seeds:** Small circles at cell centers, black outline.
- **Region id on tiles:** Optional; red text. Avoid obscuring resource letters.
- **Tile size:** Configurable (default 24 px/cell).

---

## Base tile map visualizer

**Module:** `tile_map_visualization`. Renders `TileMapResult` + `MapTopology`. Fill by terrain or region. Legend: terrain, regions, seeds, resources. No game state. Used by generate_map. Implemented in colonizethis_map.

---

## Game world state map visualizer

**Module:** `game_world_state_map_visualizer`. Extends base: ownership overlay, capital markers, port markers. Input: `Game` + tile maps and topology (or `InitGameMapViewData`). Ownership from `Province.ownerId`; capitals from `Player.capitalTile`, etc.; ports from `WorldState.portsByProvinceSeaboard` (value = tile key `regionId|provinceId|x|y`).

- **Ownership colours:** Per faction (GDD 09 for GPs; grey for minors; vibrant for tribes). Keys: runtime faction id (`Player.id`, etc.), not semantic id. `greatPowerColorOverride` when present (see below).
- **Capitals:** Gold circle. **Ports:** Distinct marker (e.g. diamond). Legend: capitals, ports.
- **View modes:** Political (ownership fill) vs geographic (terrain fill, resource glyphs). Same view model; toggle is UI-only.
- **PNG-from-view-data:** `renderInitGameMapToPngFromViewData` supports geographic mode param.
- **Geographic legend scope:** In geographic mode the game-world visualizer (view-data path) shows a **subset** of resources in both the map glyphs and the legend: Grain (g), Timber (t), Iron (i). This keeps the init-game and running-game map compact; the full resource legend (all letters per § Tile map PNG export) is provided by the base tile map visualizer (generate_map). Only g, t, i are drawn on the map and listed in the legend in this mode.

**greatPowerColorOverride source and flow**

- **Keys:** Runtime Great Power faction id (`Player.id`, e.g. `gp1`..`gpN`), **not** semantic id (`england`, …). Province `ownerId` and map tint lookups use these ids.
- **Data model:** `Game.greatPowerColorOverride` (see [world-model.md](../game/world-model.md)) stores an optional map **player id → [r,g,b]**. `createGameFromGeneratedMaps` seeds it from `GameSetupConfig.selectedGreatPowerIds` slot order × `greatPowerDefaultColorRgb` (GDD 09) so in-game tint matches nation-picker swatches. When null/empty (legacy saves), `factionOwnershipColorMap` falls back to `regionPalette` by sorted player id — hues may not match semantic GDD colours.
- **Init Game (ctdev):** The ctdev Init Game screen may pass semantic-keyed picks on `InitGameOptions.greatPowerColorOverride`; `runInitGame` maps them to runtime player ids and **merges** onto the seeded defaults, then persists the merged map on `Game` and passes tuple form into `buildInitGameMapViewData` (see [ctdev-app-init-map.md](ctdev-app-init-map.md), [init-game-tool.md](init-game-tool.md)).
- **Running game / load save (ctdev):** When ctdev loads a save, it reads `Game.greatPowerColorOverride` and converts it via `greatPowerColorOverrideFromGame` into the tuple map passed to `buildInitGameMapViewData` (see [ctdev-app.md](ctdev-app.md)).

---

## Map view model

`RegionMapViewData`: regionId, width, height, cellSize; per-cell `CellViewData` (x, y, regionCellId, isSea, terrainTypeId, resourceId, ownerFactionId, provinceDisplayName, improvementLevel, transportLevel, **`resourceExtractionUnits`**, **`resourceExtractionEffectiveUnits`**, **`resourceExtractionBlockedUnits`**); overlays (capitalMarkers, portMarkers, unitMarkers); factionColors, terrainColors; **`greatPowerFactionIds`** — set of runtime Great Power faction ids (`Game.players` ids) used by the app map to restrict the **province ownership** (GP land tint) layer to GP-held land only ([map-widget.md](../ui/map-widget.md) § Layer model).

`CellViewData.resourceExtractionUnits` semantics:

- Nullable integer for **land** cells only; `null` for sea cells.
- Value is the **human-player** per-tile extraction units used by map extraction throughput indicators.
- Value is derived from the same extraction pipeline branch as `computeExtraction` tile `effectiveCapped` (improvement, tech cap, path/tile transport cap, town-development branch rules), and excludes economy-wide aggregate-only lines not attributable to a tile.
- The map extraction indicator path does **not** include `Game.capitalTileGrainBonusPerTurn` (or equivalent aggregate-only adjustments).

`CellViewData.resourceExtractionEffectiveUnits` and `CellViewData.resourceExtractionBlockedUnits` semantics:

- Nullable integers for **land** cells only; `null` for sea cells.
- `resourceExtractionEffectiveUnits` is the subset effectively transported/connected to capital for the human player tile path.
- `resourceExtractionBlockedUnits` equals produced tile units that are blocked by transport/path bottlenecks for that same tile path.
- For a tile in scope, `resourceExtractionUnits = resourceExtractionEffectiveUnits + resourceExtractionBlockedUnits`.

For province-name overlays, `RegionMapViewData` may also carry province-level unit-presence data keyed by full province id:

- `provinceUnitPresenceByProvinceId[provinceId] = { civilianCount, regimentCount, shipCount, intelVisible }`
- Counts are non-negative integers representing class presence for the active player view.
- `intelVisible` indicates whether the active player is allowed to know class presence for that province under fog/intel rules.
- UI maps counts to icons using threshold `count > 0`; when `intelVisible = false`, UI renders no class icons for that province.
- Values are refreshed at turn start after turn resolution and player-view rebuild.

For interactive civilian map icons, `RegionMapViewData` may also carry tile-scoped player-civilian marker data:

- `civilianTileMarkers[] = { tileKey, x, y, localProvinceId, unitIds, unitTypes, representativeUnitType, stackCount }`.
- The view builder includes only civilians owned by human players (`Game.players.where(isHuman)`), and only when `Unit.tileKey` belongs to the current region.
- `unitIds` order is deterministic: icon-priority by unit type, then lexical `unit.id` tie-break. Icon priority is: `Builder > Engineer > Rail Builder > Explorer > Merchant > Spy`.
- `representativeUnitType` is the first `unitIds` entry’s type and drives single-icon rendering for mixed stacks.
- `stackCount` equals the number of included civilians on that tile and supports tile stack badges.
- This payload is view-only and does not mutate unit placement or save semantics.

For interactive **human fleet** map icons (ports and sea-zone centroids), `RegionMapViewData` carries `fleetTileMarkers[]` with `tileKey`, `x`, `y`, `locationScopeKey` (`port:…` / `sea:…`), `fleetIds`, `stackCount`, `renderGrayscale`, and `applyFleetRevealHalo` (display-only halo for draft naval moves). Built in `colonizethis_map` from game state, tile maps, topology, and draft orders; consumed by the Flame map and naval panel tile scope.

**Province-level political owner for label plates:** `provincePoliticalOwnerByPrefixedProvinceId[provinceId] = Province.ownerId` (nullable) for each land province in the region, populated from world state in `buildInitGameMapViewData`. The in-game map uses this map with per-cell `CellViewData.ownerFactionId` to choose a **GP-tinted** vs **neutral** semi-transparent name plate per [map-widget.md](../ui/map-widget.md) § Layer model (province names). This distinguishes Great Power–owned provinces from Minor/Tribe provinces where purchased tiles may assign a GP to individual cells.

**Sea zone display names for map labels:** `seaZoneDisplayNameByPrefixedId` — copy of `WorldState.seaZoneDisplayNameById` populated in `buildInitGameMapViewData` for each `RegionMapViewData`. Keys are prefixed sea zone ids (`regionId|localSeaZoneId`). The Flame map resolves label text per [map-widget.md](../ui/map-widget.md) § Province and sea zone names (fallback to local id when missing).

`InitGameMapViewData`: oldWorld, newWorld, metadata. `cellSize` = base logical px per map cell for Flame terrain/layout; for the shipped app init-game map it is taken from `assets/data/map_terrain_tilesets.json` (`map_cell_size_px`) via `MapTerrainConfig` so it matches Wang destination rects ([wang-tileset-and-assets.md](../ui/wang-tileset-and-assets.md) § App map runtime configuration). Zoom still scales the canvas in the parent; this is the unzoomed cell size.

---

## Tile visibility model (player view)

Tile visibility for the map widget and running-game tools (e.g. Widgetbook stories) is derived from **player view** and applied at the **tile key** level.

- **Enum:** `TileVisibility` with values:
  - `visible`: the tile is currently visible to the player this turn.
  - `fogged`: the tile has been revealed previously but is not currently visible; the last-known terrain/ownership is shown but visually muted.
  - `unrevealed`: the tile has never been seen; the tile is rendered as fully black.
- **Granularity:** Visibility is determined **per tile key** using the canonical tile key format `regionId|provinceId|x|y` (see [world-model-identity.md](../game/world-model-identity.md)).
- **View model field:** `CellViewData` carries a `TileVisibility visibility` field. When not explicitly set, tools treat the visibility as `visible` for backward compatibility.
- **Player-constrained vs full views:**
  - Full visibility views ignore `visibility` and treat all tiles as `visible`.
  - Player-constrained views honor `visibility` for each tile and render tiles accordingly.
- **Player selection:** When a tool renders a player-constrained view for a single player (e.g. Widgetbook map stories), it uses the **first player** in `Game.players` (`game.players.first`) as the source of `playerView`.

### Player view integration

- **Input:** `buildInitGameMapViewData` may accept a `playerView` argument (from `SPEC/program/player-view.md`) that exposes per-tile visibility keyed by tile key `regionId|provinceId|x|y`.
- **Mapping:** For each tile in the map grid, the view builder:
  - Computes the tile key for that cell (`regionId|provinceId|x|y`).
  - Looks up the tile key in `playerView` to obtain visibility.
  - Maps the player-view visibility to `TileVisibility.visible`, `TileVisibility.fogged`, or `TileVisibility.unrevealed`.
  - Stores the result on `CellViewData.visibility`.
- **Default behavior:** When `playerView` is `null` or does not contain an entry for a tile key, the builder sets `CellViewData.visibility` to `TileVisibility.visible`.
- **PNG export:** `renderInitGameMapToPngFromViewData` ignores `visibility` and always renders full-visibility maps; constrained exports are out of scope for this spec.

---

## Legend layout

Shared utilities (padding, line height, swatch size). Game-state visualizer adds: Ownership, Capitals.

---

## Multi-region rendering

`renderMultiRegionMapToPng(oldWorld, newWorld, options)`. OW left, NW right; labels; shared legend below. Used by init_game.

---

## Integration

Implemented in colonizethis_map. Consumed by generate_map, init_game, ctdev.

---

## Constraints

- Terrain palette fixed (same as base PNG).
- **Province and tile identity:** Ownership lookup, province names, unit markers, and tile keys follow [world-model-identity.md](../game/world-model-identity.md): use full province id (`regionId|localId`), tile key format `regionId|localId|x|y`; never look up by province id alone.

---

## Acceptance criteria

- **Base PNG export:** Base tile map visualizer (`tile_map_visualization`) renders `TileMapResult` + `MapTopology` to PNG: fill by terrain or region, borders (land black, sea-zone light blue), legend (terrain, regions, seeds, resources when present). No game state. Used by generate_map.
- **Game-world visualizer:** Game world state visualizer extends base with ownership overlay from `Province.ownerId`, capital markers from `Player.capitalTile`, port markers from `WorldState.portsByProvinceSeaboard`; input is `Game` + tile maps/topology or `InitGameMapViewData`. Province identity: full id (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md).
- **Ownership colours:** Faction colours per GDD 09 (GPs, minors grey, tribes vibrant); keys are runtime faction id; `greatPowerColorOverride` applied when present. Capitals: gold circle; ports: distinct marker; legend includes ownership, capitals, ports.
- **View model:** `RegionMapViewData` and `InitGameMapViewData` provide per-cell and overlay data; `renderInitGameMapToPngFromViewData` supports geographic mode param. View modes: political (ownership fill) vs geographic (terrain, resource glyphs); same view model, UI toggle. **Geographic legend:** In geographic mode the legend and map glyphs show only the subset g (Grain), t (Timber), i (Iron); full resource legend is in the base tile map visualizer.
- **Multi-region:** `renderMultiRegionMapToPng(oldWorld, newWorld, options)` renders OW left, NW right, shared legend below; used by init_game.
- **Given** a tile grid of `height` rows × `width` columns and a `colorAt(x, y)` strategy returning RGB, **when** `fillTileGridCells` renders the grid, **then** the System fills each cell `(x, y)` with the block `x1 = x*cellSize, y1 = y*cellSize, x2 = (x+1)*cellSize-1, y2 = (y+1)*cellSize-1` in row-major order, producing the same pixels as a hand-rolled nested `y`/`x` fill loop.
- **Given** a flattened list of `CellViewData` and a `colorAt(cell)` strategy returning RGB, **when** `fillRegionViewCells` renders the cells, **then** the System fills each cell at `(cell.x, cell.y)` using the shared `fillCellRect` block geometry, in list order.
- **Given** the political (ownership) and geographic (terrain) render paths, **when** either renders a region, **then** the System routes its cell fill through the shared cell-fill pipeline (`fillTileGridCells` / `fillRegionViewCells`) and the game-world visualizer contains no standalone ownership-fill nested loop duplicating the base fill logic.
- **Integration:** Implemented in colonizethis_map; consumed by generate_map, init_game, ctdev. Terrain palette and border/legend behaviour fixed as specified.
- **Given** a `Game` with tile maps, topology, and a `playerView` that exposes visibility per tile key `regionId|provinceId|x|y`, **when** `buildInitGameMapViewData` is invoked with that `playerView`, **then** each `CellViewData` in the resulting `InitGameMapViewData` has `visibility` set to `TileVisibility.visible`, `TileVisibility.fogged`, or `TileVisibility.unrevealed` according to the visibility entry for its tile key, defaulting to `TileVisibility.visible` when no entry exists.
- **Given** a `Game` with at least one player in `Game.players`, **when** a tool builds a player-constrained map view for that game using `buildInitGameMapViewData`, **then** the tool uses the first player (`game.players.first`) as the source of `playerView` and sets `CellViewData.visibility` based on that player’s view.
- **Given** an `InitGameMapViewData` whose `CellViewData.visibility` values are populated from a `playerView`, **when** a consumer requests a **full visibility** view, **then** the consumer renders all tiles as if they were `TileVisibility.visible`, regardless of stored `visibility` values.
- **Given** `renderInitGameMapToPng` renders a region where a land cell has local province id `L` and the owning province exists in `Game` with prefixed id `R|L` and non-empty `ownerId`, **when** the renderer resolves ownership color for that cell, **then** the renderer uses `R|L` (not `L`) for ownership lookup and fills the land cell with the owner faction color (not fallback grey).
- **Given** a player-constrained `RegionMapViewData` includes `provinceUnitPresenceByProvinceId` for province `P` with `intelVisible = true`, **when** UI consumers evaluate map label presence icons, **then** they treat each class as present iff its count (`civilianCount`, `regimentCount`, `shipCount`) is greater than zero.
- **Given** a player-constrained `RegionMapViewData` includes `provinceUnitPresenceByProvinceId` for province `P` with `intelVisible = false`, **when** UI consumers evaluate map label presence icons, **then** they treat all classes as not renderable for `P` regardless of stored counts.
- **Given** turn resolution completes and the game advances to a new turn, **when** the view builder produces the next turn's `RegionMapViewData`, **then** `provinceUnitPresenceByProvinceId` values are recomputed from post-resolution state and the active player's fog/intel constraints.
- **Given** a region has two or more human-player civilian units on the same tile and their types are mixed, **when** `buildInitGameMapViewData` builds `RegionMapViewData.civilianTileMarkers`, **then** the tile has one marker with `stackCount` equal to the number of units and `representativeUnitType` set by priority `Builder > Engineer > Rail Builder > Explorer > Merchant > Spy`.
- **Given** a region contains civilian units not owned by a human player, **when** `buildInitGameMapViewData` builds `RegionMapViewData.civilianTileMarkers`, **then** those non-player civilians are excluded from `civilianTileMarkers`.
- **Given** a human-player civilian has a `tileKey` whose region segment differs from the region currently being built, **when** `buildInitGameMapViewData` builds `RegionMapViewData.civilianTileMarkers`, **then** the builder excludes that civilian from that region’s marker list.
- **Given** a tile-map export where `TileMapResult.resourceGrid` has nullable entries, **when** `renderTileMapToPng` renders map glyphs, **then** the system draws resource letters only for non-null `Resource` entries and skips null entries without throwing.
- **Given** game-world geographic map rendering where `CellViewData.resourceId` may be null, empty, unknown, or outside the geographic subset, **when** `renderInitGameMapToPngFromViewData(geographicMode: true)` renders map glyphs, **then** the system draws letters only for resource ids mapped to the geographic subset (`grain`, `timber`, `iron`) and skips all other values without throwing.
- **Given** `buildInitGameMapViewData` builds a region for a game with human player id `H`, **when** a land tile `T` belongs to `H`’s connected extraction graph and has effective per-tile extraction `N` under the same rule branch as `computeExtraction` tile `effectiveCapped`, **then** `CellViewData.resourceExtractionUnits` for `T` is set to integer `N` where `N >= 0`.
- **Given** `Game.capitalTileGrainBonusPerTurn` is greater than zero, **when** `buildInitGameMapViewData` computes `CellViewData.resourceExtractionUnits`, **then** no tile’s `resourceExtractionUnits` includes any portion of that aggregate-only bonus.
- **Given** a `Game` whose `WorldState.seaZoneDisplayNameById` contains an entry for prefixed sea zone id `S`, **when** `buildInitGameMapViewData` builds a `RegionMapViewData` for the region in `S`, **then** `RegionMapViewData.seaZoneDisplayNameByPrefixedId[S]` equals `WorldState.seaZoneDisplayNameById[S]`.
