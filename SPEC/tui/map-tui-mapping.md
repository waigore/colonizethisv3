# Map TUI mapping

**SPEC/tui** — Ctterm’s mapping from map/PlayerView data to terminal display. Base data comes from [SPEC/program/map-visualization.md](../program/map-visualization.md) and [SPEC/program/player-view.md](../program/player-view.md); ctterm is a consumer and defines only the terminal representation.

---

## Responsibility

- Define how terrain, province ownership, capitals, ports, visibility, and other map data are rendered in the terminal (characters, symbols, colors/styles).
- Single place for implementors to extend or change the TUI map look without touching game logic.

---

## Data source

- **Base layer data:** Same as map-visualization and player-view: tile keys (`regionId|localId|x|y`), terrain, resources, province ownership, capitals, ports, visibility (fog, revealed, fully visible).
- **No logic here:** This doc describes only the **display mapping**. Province identity and visibility rules are in world-model-identity and player-view.

---

## Implemented mapping

### Terrain → Character

| Terrain | Character | Description |
|---------|-----------|-------------|
| Sea (no terrain) | `~` | Water |
| Plains | `.` | Flat land |
| Forest | `♣` | Tree/forest |
| Hills | `^` | Elevated land |
| Mountain | `▲` | High peaks |
| Swamp | `≈` | Marshland |
| Desert | `▒` | Sandy arid |

### Resources → Character

Resources are rendered using single-character glyphs so that the **Resources** map layer and mini-maps can show both terrain and resource at a glance. The authoritative mapping lives in `ctterm/lib/map_tui_mapping.dart` (`resourceToChar`), and the ctterm map legend must list **all** of these glyphs explicitly so any symbol on the map can be decoded without guessing.

| Resource    | Character | Notes              |
|------------|-----------|--------------------|
| Grain      | `g`       | Grain / cereals    |
| Meat       | `m`       | Livestock / meat   |
| Wool       | `w`       | Wool               |
| Horses     | `h`       | Horses             |
| Timber     | `t`       | Timber / lumber    |
| Iron       | `i`       | Iron ore           |
| Copper     | `c`       | Copper ore         |
| Tin        | `n`       | Tin                |
| Coal       | `k`       | Coal               |
| Sugar cane | `s`       | Sugar cane         |
| Tobacco    | `b`       | Tobacco            |
| Cotton     | `u`       | Cotton             |
| Furs       | `f`       | Furs               |
| Spices     | `p`       | Spices             |
| Silver     | `v`       | Silver             |
| Gold       | `G`       | Gold               |
| Gems       | `e`       | Gems               |
| Diamonds   | `d`       | Diamonds           |

### Province ownership → Character (political layer)

The **political** map layer in ctterm uses **exactly one character per tile** so that the viewport shape is identical across all layers (terrain, political, resources, units). Ownership glyphs are **precomputed once per game** in the core model and persisted in the save (`Game.politicalGlyphByPlayerId`, keyed by player/faction id). Ctterm and other UIs **only read** this mapping; they do not recompute glyphs ad hoc.

Glyph rules:

- **Great Powers (GPs)** — one unique **uppercase letter A–Z** per GP:
  - Start from the GP’s `Player.displayName` (e.g. `England`, `France`).
  - Take the first letter (uppercased). If already used by another GP, scan the rest of the name left-to-right for an unused A–Z.
  - If no unique letter exists in the name, pick any remaining unused A–Z.
- **Minor Nations & Tribes** — single-character **digits then lowercase letters**:
  - Order all non-GP owners deterministically (e.g. by id).
  - Assign glyphs `1`, `2`, … up to `9`, then `a`, `b`, `c`, … for additional owners.
- **Unclaimed/Wilderness** — always `·` (dot).

The **Resources** and **Units** layers continue to use their own single-character glyphs per tile (see tables above and implementation in `map_tui_mapping.dart`). Full-width ASCII map renderers that are not constrained by the ctterm viewport (e.g. debug maps) may append separate capital/port markers while keeping the base ownership glyph single-character.

### Special markers

| Feature | Character | Position |
|---------|-----------|----------|
| Capital | `*` | Appended to province, e.g., `F*` |
| Port | `¶` | Appended to province, e.g., `F¶` |
| Town | `#` | Shown in tile details |

### Visibility states

| State | Representation |
|-------|----------------|
| Fully visible | Normal character, full color |
| Revealed (seen but fogged) | Dimmed/italic style, partial info |
| Fogged (not currently visible) | Gray color, `?` prefix, limited info |
| Unexplored | Space character (empty) |

### Implementation

The mapping is implemented in `ctterm/lib/map_tui_mapping.dart`:
- `terrainToChar(TerrainType?)` - converts terrain to character
- `resourceToChar(Resource?)` - converts resources to character using the table above
- `ownerToChar(String? ownerId, PlayerType? playerType)` - converts owner to character
- `getTileDisplay(String tileKey, TileMapResult tileMap, Province? province, String? ownerId, bool isVisible)` - assembles full tile display
- `renderRegionMap(TileMapResult tileMap, Map<String, Province> provincesById, Map<String, String> playerVisibility, bool showTerrain, bool showOwnership)` - renders complete ASCII map
- `renderRegionMapViewport(regionId, tileMap, ..., offsetX, offsetY, viewportWidth, viewportHeight, layer, unitSymbolByTileKey?)` - renders a viewport for the in-game shell map grid; **layer** is `MapGridLayer` (terrain, political, resources, units)
- `MapGridLayer` enum; `makeFullTileKey(regionId, localId, x, y)` for full tile keys per world-model-identity

Mini-map views (such as the Development screen’s context panel) may apply **additional color-layering** on top of these glyphs for selection context (for example, bright color for the highlighted tile, normal color for tiles in the same province, dim/gray for tiles in other provinces) without changing the underlying character mapping.

### Color palette (terminal)

| Element | Color |
|---------|-------|
| Sea | Blue |
| Plains | Green |
| Forest | Dark green |
| Hills | Brown |
| Mountain | Gray |
| Swamp | Cyan |
| Desert | Yellow |
| Fog | Gray |
| Capital | Gold |
| Port | Magenta |
| Resource glyphs | Default foreground; disambiguated via legend text for Resources layer |
| Improved resource tiles | Green tint on glyph when `improvementLevel > 0` and the tile is at least revealed; character mapping is unchanged |

---

## Cross-references

- [ctterm.md](ctterm.md) §2 Map (ASCII/Unicode art), §5 Development setup
- [SPEC/program/map-visualization.md](../program/map-visualization.md) — data contract
- [SPEC/game/world-model-identity.md](../game/world-model-identity.md) — province/tile keys
