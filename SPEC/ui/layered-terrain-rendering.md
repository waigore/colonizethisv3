# Layered Terrain Rendering

**SPEC/ui** — Layered terrain rendering architecture. L0: Sea (Wang). L1: Plains and Desert (Wang for plains↔desert; plains also uses plains↔L2 Wang at feature edges). L2+: Features — **plains↔L2 Wang** for configured pairs (forest, mountains, …) when the pattern matches; **standalone** for islands and for L2 types without a Wang pair yet (hills, swamp).

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

- **Purpose**: Draws plains or desert as the base land layer, including transitions into L2 where the cell is **plains** and touches an L2.
- **Content**: Grassland plains or arid desert.
- **Transitions**: Plains↔Desert (`plains_desert`); **plains↔forest** (`plains_forest`); **plains↔mountains** (`plains_mountains`); future `plains_<l2>` keys same pattern.
- **Tilesets**:
  - `plains_desert` — plains (lower) / desert (upper)
  - `plains_forest`, `plains_mountains` — plains (lower) / that L2 (upper)
- **Mechanism**: Desert vs plains interior uses sea-coast–style land base tiles; plains↔desert uses its Wang pass. **Plains** cells adjacent to an L2 use the dominant-L2 rule and wedge corners (see [map-widget.md](map-widget.md) § Wang tiling).

### Layer 2+: Terrain Features (Overlay / full-cell Wang)

- **Purpose**: Renders forest, hills, mountain, swamp.
- **Forest / mountain (when Wang applies)**: Feature pass draws a **full-cell** `plains_forest` or `plains_mountains` tile; land-base pass **omits** the plains interior for that cell when the wedge pattern is non-island and `findTile` succeeds.
- **Forest / mountain (island or missing tile)**: Land base draws interior plains (or desert flow); feature pass draws **standalone** sprite.
- **Hills / swamp**: Land base + **standalone** only until a plains↔L2 Wang is wired.
- **Standalone tiles** (asset ids): `forest_standalone`, `hills_standalone`, `mountain_standalone`, `swamp_standalone`.

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

Order of evaluation per land cell (see implementation in `region_map_component.dart`):

1. Unrevealed → black rect.
2. Plains↔desert Wang when the existing corner predicate matches.
3. **Plains** only: if 8-neighbors contain forest/mountain, pick **dominant L2** (count, tie → forest); if any wedge has that L2, draw `plains_forest` or `plains_mountains` Wang.
4. **Forest/mountain**: if non-island Wang will draw in pass 2, **skip** interior base here.
5. Else: interior land tile from `sea_plains` or `sea_desert` upper base (plains vs desert).

### Pass 2: Draw Terrain Features (L2+)

```dart
for each land cell with feature terrain:
  if forest or mountain and plains↔L2 Wang applies (wedges + findTile):
    draw full-cell Wang tile
  else:
    draw standalone overlay (land base already drawn in pass 1)
```

---

## Asset Requirements

### Layer 0/1 (Wang Tilesets)

| Tileset ID | Lower | Upper | Description |
|------------|-------|-------|-------------|
| `sea_plains` | Sea | Plains | Coastline with beach transition |
| `sea_desert` | Sea | Desert | Coastline with coastal sand |
| `plains_desert` | Plains | Desert | Land border with gradual transition |
| `plains_forest` | Plains | Forest | L2 meets plains; 64×64 canonical |
| `plains_mountains` | Plains | Mountain | Same |

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
- `sea_plains`, `sea_desert`, `plains_desert` Wang tilesets
- `plains_forest`, `plains_mountains` Wang tilesets (required keys in config)
- Feature standalone tiles (L2+), best-effort

### Terrain Colors (Fallback / tooling)

Solid colors may be used when tilesets are unavailable (e.g. tests or debug). The **shipping** app path requires Wang assets to load for configured keys:

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

## Flutter app: Wang asset selection

The **logic** (which tileset applies per corner pattern) is implemented in the Flame map component. The **files** and **map cell size** for all Wang tilesets (L0/L1 plus `plains_forest`, `plains_mountains`, …) are selected via `assets/data/map_terrain_tilesets.json` — see [wang-tileset-and-assets.md](wang-tileset-and-assets.md) § App map runtime configuration and [map-widget.md](map-widget.md) § Terrain tileset rendering.

---

## Acceptance Criteria

- Given bundled `map_terrain_tilesets.json` with valid paths for `sea_plains`, `sea_desert`, `plains_desert`, `plains_forest`, and `plains_mountains`, when the Flame map loads, then those configured atlases are used (not hardcoded filenames in layer logic).
- Given a sea cell with no land neighbors, when rendering, then solid sea color is drawn.
- Given a sea cell adjacent to plains, when rendering, then the `sea_plains` Wang tileset is used.
- Given a sea cell adjacent to desert, when rendering, then the `sea_desert` Wang tileset is used.
- Given a plains cell adjacent to desert, when rendering, then the `plains_desert` Wang tileset is used.
- Given a desert cell adjacent to plains, when rendering, then the `plains_desert` Wang tileset is used.
- Given a forest or mountain cell with a matching plains↔L2 Wang pattern, when rendering, then the Wang tile covers the full cell (no separate plains fill in pass 1 for that cell).
- Given a forest or mountain **island** cell (no same-L2 in any wedge), when rendering, then the land base is drawn in pass 1 and the standalone feature tile is drawn in pass 2.
- Given a hills or swamp cell, when rendering, then the land base is drawn first and the standalone feature tile on top until a plains↔L2 Wang exists for that type.
- Given fog-of-war visibility, when rendering, then appropriate darkening is applied to obscured cells.

---

## See Also

- [wang-tileset-and-assets.md](wang-tileset-and-assets.md) — Tileset generation pipeline and palette
- [map-widget.md](map-widget.md) — Map widget contract