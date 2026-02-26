# Map Visualization: PNG Export and View Builders

**SPEC/program** — PNG export, color schemes, legends, border rendering. Data model: [map-data.md](map-data.md). Tile map generation: [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md). Province and tile identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Responsibility

Render tile maps and topology to PNG; provide view models for tools. Two visualizers share border drawing, legend layout, swatches.

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

- **Data model:** `Game.greatPowerColorOverride` (see [world-model.md](../game/world-model.md)) stores an optional map of GP semantic ids → RGB triples; when present, all map visualizers use it instead of GDD default GP colours.
- **Init Game (ctdev):** The ctdev Init Game screen lets the user pick GP colours; selections are stored on `InitGameOptions.greatPowerColorOverride` and passed to `runInitGame` (see [ctdev-app-init-map.md](ctdev-app-init-map.md) and [init-game-tool.md](init-game-tool.md)). The init-game orchestrator persists this on `Game.greatPowerColorOverride` and passes a tuple-form override into `buildInitGameMapViewData`, which then feeds `game_world_state_map_visualizer`.
- **Running game / load save (ctdev):** When ctdev loads a save, it reads `Game.greatPowerColorOverride` and converts it via `greatPowerColorOverrideFromGame` into the tuple map passed to `buildInitGameMapViewData` for both Init Game Map Debug and Running Game map views (see [ctdev-app.md](ctdev-app.md)).
- **CLI behaviour:** CLI tools that call init-game without a ctdev front-end do not set `greatPowerColorOverride`; the visualizer sees `null` and falls back to the GDD default GP palette.

---

## Map view model

`RegionMapViewData`: regionId, width, height, cellSize; per-cell `CellViewData` (x, y, regionCellId, isSea, terrainTypeId, resourceId, ownerFactionId, provinceDisplayName, improvementLevel, transportLevel); overlays (capitalMarkers, portMarkers, unitMarkers); factionColors, terrainColors. `InitGameMapViewData`: oldWorld, newWorld, metadata. `cellSize` = base px per tile; UI may scale.

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
- **Integration:** Implemented in colonizethis_map; consumed by generate_map, init_game, ctdev. Terrain palette and border/legend behaviour fixed as specified.
