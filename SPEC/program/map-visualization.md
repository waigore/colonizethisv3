# Map Visualization: PNG Export and View Builders

**SPEC/program** — PNG export, color schemes, legends, border rendering. Data model: [map-data.md](map-data.md). Tile map generation: [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md).

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

- **Ownership colours:** Per faction (GDD 09 for GPs; grey for minors; vibrant for tribes). Keys: runtime faction id (`Player.id`, etc.), not semantic id. `greatPowerColorOverride` when present.
- **Capitals:** Gold circle. **Ports:** Distinct marker (e.g. diamond). Legend: capitals, ports.
- **View modes:** Political (ownership fill) vs geographic (terrain fill, resource glyphs). Same view model; toggle is UI-only.
- **PNG-from-view-data:** `renderInitGameMapToPngFromViewData` supports geographic mode param.

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

- Terrain palette fixed (same as base PNG). Ownership lookup uses full province id (`regionId|localId`).
