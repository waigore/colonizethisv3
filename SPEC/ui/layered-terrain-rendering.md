# Layered Terrain Rendering

**SPEC/ui** — Simplified terrain rendering architecture. Sea uses Wang tilesets for coastline transitions; plains is the base land layer; all other terrain types (desert, forest, hills, mountain, swamp) use standalone tiles drawn over plains.

---

## Terminology

- **Standalone tile**: A terrain tile with no adjacency-based transitions. Drawn centered in the cell with internal details.
- **Wang tileset**: A set of tiles that encode corner-based terrain transitions. Each tile has four corners (NW, NE, SW, SE), each marked as "lower" or "upper" terrain.
- **Coastline tileset**: Wang tileset for sea→land transitions (beach edge).

---

## Layer Architecture

The map renderer draws terrain in **two passes**:

### Layer 0: Sea (Base)

- **Purpose**: Draws sea tiles as the foundation.
- **Content**: Deep ocean water with Wang transitions for coastline.
- **Transitions**: Sea→Land edge tiles (beach/sandy shore).
- **Tileset**: `sea_beach` — Wang tileset where "upper" = beach/land, "lower" = sea.

### Layer 1: Land Base (Plains Only)

- **Purpose**: Draws plains as the base land layer.
- **Content**: Grassland/plains terrain.
- **Transitions**: Sea coastline handled in Layer 0.
- **Tile**: `plains_interior` — Standalone tile for plains (used near coastline).

### Layer 2: Terrain Features (All Other Terrain)

- **Purpose**: Draws all other terrain types on top of plains.
- **Terrain types**: Desert, Forest, Hills, Mountain, Swamp.
- **Rendering**: Each cell draws its base (plains) first (from Layer 1), then overlays the feature standalone tile.
- **Standalone tiles**: Each terrain type has one standalone tile asset:
  - `desert_standalone` — Sandy desert dunes
  - `forest_standalone` — Dense forest with trees
  - `hills_standalone` — Rolling hills
  - `mountain_standalone` — Rocky mountain peak
  - `swamp_standalone` — Murky swamp

---

## Rendering Algorithm

### Pass 0: Draw Sea Layer

```dart
for each cell:
  if cell.isSea:
    if cell has no land neighbors:
      draw solid sea color
    else:
      // Use Wang tileset for coastline
      corners = compute which corners have land
      tile = sea_beach_tileset.findTile(corners)
      draw tile
```

### Pass 1: Draw Land Base (Plains)

```dart
for each cell:
  if not cell.isSea:
    draw plains tile or solid plains color
```

### Pass 2: Draw Terrain Features

```dart
for each cell:
  if not cell.isSea and cell.terrainType is feature (desert/forest/hills/mountain/swamp):
    standalone_tile = getStandaloneTile(cell.terrainType)
    draw standalone_tile over the plains base
```

---

## Asset Requirements

### Layer 0 (Sea)

| Tileset ID | Description | Wang Corners |
|------------|-------------|--------------|
| `sea_beach` | Sea→Beach coastline | Corners=land vs sea |

### Layer 1 (Plains)

| Tile ID | Description |
|---------|-------------|
| `plains_interior` | Plains tile for coastline areas |

### Layer 2 (Features)

| Tile ID | Description |
|---------|-------------|
| `desert_standalone` | Sandy desert dunes, overlay on plains |
| `forest_standalone` | Dense forest with tree canopies, overlay on plains |
| `hills_standalone` | Rolling hills, overlay on plains |
| `mountain_standalone` | Rocky mountain peak, overlay on plains |
| `swamp_standalone` | Murky swamp, overlay on plains |

---

## Implementation Notes

### TerrainType Classification

```dart
// Layer 1 (Land Base)
bool isLandBase(TerrainType t) => t == TerrainType.plains;

// Layer 2 (Features)
bool isFeature(TerrainType t) =>
    t == TerrainType.desert ||
    t == TerrainType.forest ||
    t == TerrainType.hills ||
    t == TerrainType.mountain ||
    t == TerrainType.swamp;
```

### Tileset Cache

The `TerrainTilesetCache` loads only:
- `sea_beach` Wang tileset (Layer 0)
- `plains_interior` standalone tile (Layer 1)
- Five feature standalone tiles (Layer 2)

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
- Given a sea cell with land neighbors, when rendering, then the `sea_beach` Wang tileset is used with correct corner values.
- Given a plains cell, when rendering, then plains tile or solid plains color is drawn.
- Given a feature cell (desert/forest/hills/mountain/swamp), when rendering, then plains is drawn first, then the feature standalone tile is drawn on top.
- Given fog-of-war visibility, when rendering, then appropriate darkening is applied to obscured cells.

---

## See Also

- [wang-tileset-and-assets.md](wang-tileset-and-assets.md) — Tileset generation pipeline and palette
- [map-widget.md](map-widget.md) — Map widget contract