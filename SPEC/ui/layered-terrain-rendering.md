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

### Layer 2+: Terrain Features (Overlay)

- **Purpose**: Draws feature overlays on top of land base.
- **Terrain types**: Forest, Hills, Mountain, Swamp.
- **Rendering**: Each feature cell draws its land base first (plains or desert, determined by L1), then overlays the feature standalone tile.
- **Standalone tiles**:
  - `forest_standalone` — Dense forest with trees
  - `hills_standalone` — Rolling hills
  - `mountain_standalone` — Rocky mountain peak
  - `swamp_standalone` — Murky swamp

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
| `forest_standalone` | Dense forest with tree canopies, overlay on land base |
| `hills_standalone` | Rolling hills, overlay on land base |
| `mountain_standalone` | Rocky mountain peak, overlay on land base |
| `swamp_standalone` | Murky swamp, overlay on land base |

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
    t == TerrainType.forest ||
    t == TerrainType.hills ||
    t == TerrainType.mountain ||
    t == TerrainType.swamp;
```

### Tileset Cache

The `TerrainTilesetCache` loads:
- `sea_plains` Wang tileset (L0→L1)
- `sea_desert` Wang tileset (L0→L1)
- `plains_desert` Wang tileset (L1 internal)
- Four feature standalone tiles (L2+)

### Terrain Colors (Fallback)

When tiles are not loaded, use solid colors:

| Terrain | RGB |
|---------|-----|
| Sea | `(30, 58, 95)` dark blue |
| Plains | `(124, 179, 66)` grass green |
| Desert | `(215, 204, 200)` beige |
| Forest | `(46, 125, 50)` dark green |
| Hills | `(109, 76, 65)` brown |
| Mountain | `(120, 144, 156)` gray |
| Swamp | `(61, 74, 63)` grey-green |

---

## Acceptance Criteria

- Given a sea cell with no land neighbors, when rendering, then solid sea color is drawn.
- Given a sea cell adjacent to plains, when rendering, then the `sea_plains` Wang tileset is used.
- Given a sea cell adjacent to desert, when rendering, then the `sea_desert` Wang tileset is used.
- Given a plains cell adjacent to desert, when rendering, then the `plains_desert` Wang tileset is used.
- Given a desert cell adjacent to plains, when rendering, then the `plains_desert` Wang tileset is used.
- Given a feature cell (forest/hills/mountain/swamp), when rendering, then the appropriate land base (plains or desert) is drawn first, then the feature standalone tile on top.
- Given fog-of-war visibility, when rendering, then appropriate darkening is applied to obscured cells.

---

## See Also

- [wang-tileset-and-assets.md](wang-tileset-and-assets.md) — Tileset generation pipeline and palette
- [map-widget.md](map-widget.md) — Map widget contract