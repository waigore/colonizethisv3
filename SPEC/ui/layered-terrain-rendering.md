# Layered Terrain Rendering

**SPEC/ui** — Layered terrain rendering architecture. L0: Sea (Wang tilesets for coastline). L1: Plains and Desert (Wang tilesets for land borders). L2+: Features (standalone overlay tiles).

---

## Terminology

- **Standalone tile**: A terrain tile with no adjacency-based transitions. Drawn centered in the cell with internal details.
- **Wang tileset**: A set of tiles that encode corner-based terrain transitions. Each tile has four corners (NW, NE, SW, SE), each marked as "lower" or "upper" terrain.
- **Base tile**: The pure interior tile for a terrain type, generated as part of a Wang tileset and reused for chaining.

---

## Layer Architecture

The map renderer draws terrain in **three passes**:

### Layer0: Sea (Base Layer)

- **Purpose**: Draws sea tiles as the foundation.
- **Content**: Deep ocean water with Wang transitions for coastline.
- **Transitions**:
  - Sea↔Plains coastline (beach/sandy shore)
  - Sea↔Desert coastline (coastal sand)
- **Tilesets**: 
  - `sea_plains` — Wang tileset with sea (lower) and plains (upper)
  - `sea_desert` — Wang tileset with sea (lower) and desert (upper)

### Layer 1: Land Base (Plains and Desert)

- **Purpose**: Draws plains or desert as the base land layer.
- **Content**: Grassland plains or arid desert.
- **Transitions**: Plains↔Desert border (gradual desertification edge).
- **Tilesets**:
  - `plains_desert` — Wang tileset with plains (lower) and desert (upper)
- **Mechanism**: When a cell is desert, it clips the plains layer, and desert is drawn instead. The plains↔desert transition is handled by the `plains_desert` Wang tileset.
- **Plains resource variants (L1)**: For **interior** plains cells only, the renderer selects standalone overlay assets with **RGBA transparency** (transparent “background” around the resource-specific art):
  - `resourceId = grain` → `tile_plains_grain`
  - `resourceId = meat` → `tile_plains_meat`
  - `resourceId = horses` → `tile_plains_horses`
  - **Draw order:** L1 **first** draws the **same canonical interior plains** Wang upper-base tile used for a non-resource interior plains cell (`sea_plains` atlas), **then** draws the selected `tile_plains_*` image with normal alpha blending (`srcOver`). Transparent pixels in the overlay must reveal that plains base—not the empty canvas (which would read as black).
  - Any other `resourceId` (or null) keeps a single draw of the canonical plains base tile (no overlay variant).
  - Desert never uses these plains variant keys.

### Layer 2+: Terrain Features (Overlay)

- **Purpose**: Draws feature overlays on top of land base.
- **Terrain types**: Hardwood forest, Scrub forest, Hills, Mountain, Swamp.
- **Rendering**: Each feature cell draws its land base first (plains or desert, determined by L1), then overlays the feature standalone tile.
- **Overlay tile IDs**:
  - `tile_hardwoodForest` — Default hardwood forest overlay
  - `tile_hardwoodForestTimber` — Hardwood forest overlay variant for timber resource tiles
  - `tile_scrubForest` — Default scrub forest overlay
  - `tile_scrubForestTimber` — Scrub forest overlay variant for timber resource tiles
  - `tile_hills` — Default hills overlay
  - `tile_hills_mine` — Hills overlay variant for mine-case tiles
  - `tile_hills_wool` — Hills overlay variant for wool resource tiles
  - `tile_mountain` — Default mountain overlay
  - `tile_swamp` — Default swamp overlay
- **Selection API note**: Terrain variant key selection is shared across L1 and L2+ terrain rendering so plains, forest, and hills variants follow one deterministic selector.
- **Asset note (issue #3573)**: Hardwood forest loads the renamed dense-canopy art `tile_hardwood_forest.png` / `tile_hardwood_forest_timber.png` (formerly `tile_forest.png` / `tile_forest_timber.png`). Scrub forest loads its own distinct sparse art `tile_scrub_forest.png` / `tile_scrub_forest_timber.png` (sparser, lighter foliage with more bare ground than hardwood). All four standalone keys are registered and selected independently, so any refreshed art (e.g. a future PixelLab pass) can drop in by replacing the PNG with no code change.

---

## Rendering Algorithm

### Pass 0: Draw Sea Layer (L0)

```dart
for each cell:
  if cell.isSea:
    if cell has no land neighbors:
      draw solid sea color
    else:
      // Determine which coastline tileset to use
      if all land neighbors are plains:
        corners = compute which corners have plains
        tile = sea_plains_tileset.findTile(corners)
      else if all land neighbors are desert:
        corners = compute which corners have desert
        tile = sea_desert_tileset.findTile(corners)
      else:
        // Mixed neighbors: use predominant neighbor type or default
        corners = compute mixed corners
        tile = sea_plains_tileset.findTile(corners) // default
      draw tile
```

### Pass 1: Draw Land Base (L1)

```dart
for each cell:
  if not cell.isSea:
    if cell.terrainType == plains:
      draw plains tile or solid plains color
    else if cell.terrainType == desert:
      draw desert tile or solid desert color

// For plains↔desert borders:
for each cell:
  if cell.terrainType == plains and has desert neighbors:
    corners = compute which corners have desert
    tile = plains_desert_tileset.findTile(corners)
    draw tile
  else if cell.terrainType == desert and has plains neighbors:
    corners = compute which corners have plains
    tile = plains_desert_tileset.findTile(corners)
    draw tile
```

### Pass 2: Draw Terrain Features (L2+)

```dart
for each cell:
  if not cell.isSea and cell.terrainType is feature (forest/hills/mountain/swamp):
    // Determine base land (plains or desert from L1)
    base_land = getBaseLand(cell) // plains or desert
    draw base_land tile first
    standalone_tile = getStandaloneTile(cell.terrainType)
    draw standalone_tile over the base
```

---

## Asset Requirements

### Layer 0/1 (Wang Tilesets)

| Tileset ID | Lower | Upper | Description |
|------------|-------|-------|-------------|
| `sea_plains` | Sea | Plains | Coastline with beach transition |
| `sea_desert` | Sea | Desert | Coastline with coastal sand |
| `plains_desert` | Plains | Desert | Land border with gradual transition |

### Layer 2+ (Standalone Tiles)

| Tile ID | Description |
|---------|-------------|
| `tile_hardwoodForest` | Default dense hardwood forest canopy overlay on land base |
| `tile_hardwoodForestTimber` | Hardwood forest overlay variant for `resourceId = timber` |
| `tile_scrubForest` | Default sparse scrub forest overlay on land base |
| `tile_scrubForestTimber` | Scrub forest overlay variant for `resourceId = timber` |
| `tile_hills` | Default rolling hills overlay on land base |
| `tile_hills_mine` | Hills overlay variant for mine-case tiles |
| `tile_hills_wool` | Hills overlay variant for `resourceId = wool` |
| `tile_mountain` | Rocky mountain overlay on land base |
| `tile_swamp` | Murky swamp overlay on land base |
| `tile_plains_grain` | Plains terrain variant for `resourceId = grain` |
| `tile_plains_meat` | Plains terrain variant for `resourceId = meat` |
| `tile_plains_horses` | Plains terrain variant for `resourceId = horses` |

---

## Implementation Notes

### TerrainType Classification

```dart
// Layer 0 (Sea)
bool isSea(TerrainType t) => t == TerrainType.sea;

// Layer 1 (Land Base)
bool isLandBase(TerrainType t) =>
    t == TerrainType.plains ||
    t == TerrainType.desert;

// Layer 2+ (Features)
bool isFeature(TerrainType t) =>
    t == TerrainType.hardwoodForest ||
    t == TerrainType.scrubForest ||
    t == TerrainType.hills ||
    t == TerrainType.mountain ||
    t == TerrainType.swamp;
```

### Tileset Cache

The `TerrainTilesetCache` loads:
- `sea_plains` Wang tileset (L0→L1)
- `sea_desert` Wang tileset (L0→L1)
- `plains_desert` Wang tileset (L1 internal)
- Feature standalone tiles (L2+): hardwood forest (+timber), scrub forest (+timber), hills (+mine/+wool), mountain, swamp, plus plains resource variants

### Terrain Colors (Fallback)

When tiles are not loaded, use solid colors:

| Terrain | RGB |
|---------|-----|
| Sea | `(30, 58, 95)` dark blue |
| Plains | `(124, 179, 66)` grass green |
| Desert | `(215, 204, 200)` beige |
| Hardwood forest | `(46, 125, 50)` dark green |
| Scrub forest | `(124, 179, 66)` light sparse green |
| Hills | `(109, 76, 65)` brown |
| Mountain | `(120, 144, 156)` gray |
| Swamp | `(61, 74, 63)` grey-green |

---

## Flutter app: Wang asset selection

The **logic** (which tileset applies per corner pattern) is fixed by terrain type. The **files** and **map cell size** for the three Wang tilesets are selected via `assets/data/map_terrain_tilesets.json` — see [wang-tileset-and-assets.md](wang-tileset-and-assets.md) § App map runtime configuration and [map-widget.md](map-widget.md) § Terrain tileset rendering.

---

## Acceptance Criteria

- Given bundled `map_terrain_tilesets.json` with valid paths for `sea_plains`, `sea_desert`, and `plains_desert`, when the Flame map draws L0/L1, then those configured atlases are used (not hardcoded filenames in layer logic).
- Given a sea cell with no land neighbors, when rendering, then solid sea color is drawn.
- Given a sea cell adjacent to plains, when rendering, then the `sea_plains` Wang tileset is used.
- Given a sea cell adjacent to desert, when rendering, then the `sea_desert` Wang tileset is used.
- Given a plains cell adjacent to desert, when rendering, then the `plains_desert` Wang tileset is used.
- Given a desert cell adjacent to plains, when rendering, then the `plains_desert` Wang tileset is used.
- Given a feature cell (forest/hills/mountain/swamp), when rendering, then the appropriate land base (plains or desert) is drawn first, then the selected feature overlay tile on top.
- Given a fogged feature cell (forest/hills/mountain/swamp), when rendering completes, then fog attenuation is applied exactly once for that tile (single-pass), matching the intended fog darkness level used for other fogged land tiles.
- Given a plains tile with `resourceId = grain`, when rendering L1, then the renderer selects `tile_plains_grain` for that tile.
- Given a plains tile with `resourceId = meat`, when rendering L1, then the renderer selects `tile_plains_meat` for that tile.
- Given a plains tile with `resourceId = horses`, when rendering L1, then the renderer selects `tile_plains_horses` for that tile.
- Given an **interior** plains cell with `resourceId` in `{grain, meat, horses}`, when rendering L1, then the renderer draws the canonical interior plains base, then the corresponding `tile_plains_*` overlay so transparent overlay pixels show plains grass (not an empty/black canvas).
- Given an **interior** plains cell with `resourceId` in `{grain, meat, horses}` and player-constrained **fogged** visibility, when rendering L1 completes, then fog attenuation for that cell matches other interior plains land-base tiles (no unintended double-darkening from separate base vs overlay passes).
- Given a plains tile with `resourceId` not in `{grain, meat, horses}` (or null), when rendering L1, then the renderer keeps the canonical plains base tile.
- Given a desert tile with any `resourceId`, when rendering L1, then the renderer does not select any plains resource variant tile key.
- Given a hardwood forest tile with `resourceId = timber`, when rendering L2+, then the renderer selects `tile_hardwoodForestTimber`; otherwise for hardwood forest it selects `tile_hardwoodForest`.
- Given a scrub forest tile with `resourceId = timber`, when rendering L2+, then the renderer selects `tile_scrubForestTimber`; otherwise for scrub forest it selects `tile_scrubForest`.
- Given a hills tile where `improvementLevel > 0` and the `resourceId` is a mineral resource, when rendering L2+, then the renderer selects `tile_hills_mine`; otherwise if `resourceId = wool`, then it selects `tile_hills_wool`; otherwise it selects `tile_hills`.
- Given terrain asset loading and any required plains variant PNG (`tile_plains_grain`, `tile_plains_meat`, `tile_plains_horses`) is missing or fails decode, when map terrain assets initialize, then initialization fails fast with an error instead of silently skipping that variant.
- Given fog-of-war visibility, when rendering, then appropriate darkening is applied to obscured cells.

---

## See Also

- [wang-tileset-and-assets.md](wang-tileset-and-assets.md) — Tileset generation pipeline and palette
- [map-widget.md](map-widget.md) — Map widget contract