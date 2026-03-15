# Wang Tileset and Map Asset Pipeline

**SPEC/ui** — Terrain tilesets and overlay assets for the Flame map viewer. Simplified architecture: only sea coastline uses Wang tilesets; all other terrain uses standalone tiles. See [layered-terrain-rendering.md](layered-terrain-rendering.md) for rendering details.

---

## Scope

- **Tile size:** 64×64 pixels (canonical). Terrain from PixelLab may be generated at32×32 and upscaled in the pipeline.
- **Layered rendering:** Two-pass architecture (Layer 0: Sea, Layer 1: Plains, Layer 2: Features as standalone tiles).
- **Resources and improvements:** Overlay sprites only (one sprite per resource type; improvement sprites for road connectivity and other improvements).

---

## Tileset Inventory

### Layer 0: Sea Coastline

| Tileset ID | Description | Status |
|------------|-------------|--------|
| `sea_beach` | Sea→Beach coastline (Wang tileset) | ✅ Generated |

### Layer 1: Plains Base

| Tile ID | Description | Status |
|---------|-------------|--------|
| `tile_plains_interior` | Plains standalone tile | ✅ Generated |

### Layer 2: Terrain Features (Standalone Tiles)

| Tile ID | Description | Status |
|---------|-------------|--------|
| `tile_desert_standalone` | Desert dunes overlay | ✅ Generated |
| `tile_forest_standalone` | Forest with trees overlay | ✅ Generated |
| `tile_hills_standalone` | Rolling hills overlay | ✅ Generated |
| `tile_mountain_standalone` | Rocky mountain overlay | ✅ Generated |
| `tile_swamp_standalone` | Murky swamp overlay | ✅ Generated |

---

## Forced Palette

All generated assets MUST use the same forced palette for visual consistency.

**Palette (16 colors) — strategy / colonial era:**

| Index | Name | Hex | Use |
|-------|------|-----|-----|
| 0 | water_dark | `#1e3a5f` | Sea, deep water |
| 1 | water_mid | `#2d5a87` | Water highlight |
| 2 | sand | `#c4a574` | Coast, beach |
| 3 | grass_light | `#7cb342` | Plains base |
| 4 | grass_dark | `#558b2f` | Grass shadow |
| 5 | forest | `#2e7d32` | Forest |
| 6 | forest_dark | `#1b5e20` | Forest shadow |
| 7 | hill | `#6d4c41` | Hills |
| 8 | hill_dark | `#4e342e` | Hills shadow |
| 9 | mountain | `#78909c` | Mountain |
| 10 | mountain_dark | `#546e7a` | Mountain shadow |
| 11 | swamp | `#3d4a3f` | Swamp |
| 12 | swamp_dark | `#2a332a` | Swamp shadow |
| 13 | desert | `#d7ccc8` | Desert |
| 14 | road | `#6b5344` | Roads, paths |
| 15 | accent | `#ffb74d` | Resource/UI accent |

---

## Python Tools

Following [pytool-image-tools.md](pytool-image-tools.md):

- **Location:** `pytool/` at repo root
- **Dependency management:** Use **uv**
- **API authentication:** Every PixelLab API request MUST use the **PIXELLAB_API_KEY** environment variable

---

## Asset Generation

### Sea Coastline Tileset

Use PixelLab `create_topdown_tileset`:
- `lower_description`: "deep blue ocean water with dark waves"
- `upper_description`: "light brown sandy beach with visible grain texture"
- `transition_description`: "sandy yellow-beige beach with foam where water meets sand"
- `tile_size`: 32×32 (upscale to 64×64)
- `transition_size`: 0.5

### Standalone Feature Tiles

Use PixelLab `create_map_object`:
- `width`: 64, `height`: 64
- `view`: "high top-down"
- `background_image`: transparent (default)
- Descriptions:
  - Desert: "sandy desert dunes with orange-tan sand, warm desert colors"
  - Forest: "dense forest with visible round tree canopies, multiple shades of green"
  - Hills: "rolling hills with gentle slopes, light brown earth tones, subtle shadows"
  - Mountain: "rocky mountain peak with gray stone, white snow cap on top"
  - Swamp: "murky swamp with brownish-green shallow water, scattered lily pads"

---

## Map Viewer Contract

- **Input:** Asset directory with `tileset_sea_beach.png/json`, `tile_plains_interior.png`, and feature standalone tiles.
- **Per cell (i, j):**
  1. **Sea:** Ifsea, use Wang tileset for coastline or solid sea color.
  2. **Plains:** Draw plains tile or solid color.
  3. **Feature:** If terrain is desert/forest/hills/mountain/swamp, draw standalone tile over plains.

---

## Acceptance Criteria

- Given the forced palette and tileset config, when generating `sea_beach`, then it produces a 16-tile Wang tileset for coastline transitions.
- Given standalone tile descriptions, when generating feature tiles, then each produces a 64×64 PNG with transparent background.
- Given a map cell with sea, when rendering, then the coastline Wang tileset is used correctly.
- Given a map cell with feature terrain, when rendering, then plains is drawn first, then the feature standalone tile on top.