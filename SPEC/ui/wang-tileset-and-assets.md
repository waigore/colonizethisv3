# Wang Tileset and Map Asset Pipeline

**SPEC/ui** — Terrain tilesets and overlay assets for the Flame map viewer. Wang tilesets forL0/L1 transitions (sea, plains, desert); standalone overlay tiles forL2+ features. See [layered-terrain-rendering.md](layered-terrain-rendering.md) for rendering details.

---

## Scope

- **Tile size:** 64×64 pixels (canonical). Terrain from PixelLab may be generated at32×32 and upscaled in the pipeline.
- **Layered rendering:** Three-pass architecture (L0: Sea, L1: Plains/Desert, L2+: Features).
- **Resources and improvements:** Overlay sprites only (one sprite per resource type; improvement sprites for road connectivity and other improvements).

---

## Architecture Overview

### Layer Stack

| Layer | Content | Tile Type |
|-------|---------|-----------|
| L0 | Sea (base layer) | Wang tilesets for coastline |
| L1 | Plains, Desert (land base) | Wang tilesets for land transitions |
| L2+ | Forest, Hills, Mountain, Swamp (features) | Standalone overlay tiles |

### Transition Strategy

All L0/L1 tilesets use **Wang tilesets** with shared base tiles for visual consistency:
- `sea_plains` — Sea↔Plains coastline
- `sea_desert` — Sea↔Desert coastline  
- `plains_desert` — Plains↔Desert land border

Base tiles are chained across tilesets to ensure consistent appearance.

---

## Tileset Inventory

### Layer 0/1: Wang Tilesets

| Tileset ID | Lower Terrain | Upper Terrain | Transition Size | Status |
|------------|---------------|---------------|-----------------|--------|
| `sea_plains` | Deep sea | Grassland plains | 0.5 (half-tile beach) | ✅ Generated |
| `sea_desert` | Deep sea | Arid desert | 0.5 (half-tile coastal sand) | ✅ Generated |
| `plains_desert` | Grassland plains | Arid desert | 1.0 (full-tile gradient) | ✅ Generated |

### Layer2+: Feature Overlay Tiles

| Tile ID | Description | Status |
|---------|-------------|--------|
| `tile_hardwood_forest` | Dense hardwood forest default overlay | ✅ Generated (renamed from `tile_forest`, forest v2 art) |
| `tile_hardwood_forest_timber` | Hardwood forest overlay for timber tiles | ✅ Generated (renamed from `tile_forest_timber`) |
| `tile_scrub_forest` | Sparse scrub forest default overlay | ✅ Generated (distinct sparse/lighter variant, #3573 R8) |
| `tile_scrub_forest_timber` | Scrub forest overlay for timber tiles | ✅ Generated (distinct sparse/lighter variant, #3573 R8) |
| `tile_hills` | Rolling hills default overlay | ✅ Generated (from hills v2 art) |
| `tile_hills_mine` | Hills overlay for mine-case tiles | ✅ Generated |
| `tile_hills_wool` | Hills overlay for wool tiles | ✅ Generated |
| `tile_mountain` | Rocky mountain default overlay | ✅ Generated (from mountain v2 art) |
| `tile_swamp` | Murky swamp default overlay | ✅ Generated |

**Note:** Desert is now a L1 terrain (not L2), so no desert L2 standalone overlay asset is used.

---

### Transport Overlay Atlases (Road/Rail)

The region map transport overlay uses two dedicated **64x64** atlases with **16 cardinal masks** (`0..15`) each:

- `tileset_transport_road_64` for `roadLevel` **1/2**
- `tileset_transport_rail_64` for `roadLevel` **4**

Both families share geometry and mask indexing:

- Bit 0 = **North**
- Bit 1 = **East**
- Bit 2 = **South**
- Bit 3 = **West**
- Mask = sum of active bits (`0..15`)

Runtime selection policy is documented in [map-widget.md](map-widget.md) and implemented in app transport overlay render policy helpers.

**Atlas contract (both families):**

- `tile_size`: `64x64`
- Exactly 16 tile entries, one per mask id `0..15`
- Each entry has a `bounding_box` aligned to 64px grid
- All `bounding_box` rectangles are unique and within atlas bounds
- Paths are declared in `app/assets/data/map_terrain_tilesets.json` under `transport_tilesets.road` and `transport_tilesets.rail`

Transport overlays are land-only visual overlays and do not add sea extensions or explicit road/rail transition art in this slice.

---

## Base Tile Chain Strategy

To ensure visual consistency, tilesets must share base tiles:

```
1. Generate sea_plains → gives sea_base_tile_id + plains_base_tile_id
2. Generate sea_desert using sea_base_tile_id → gives desert_base_tile_id  
3. Generate plains_desert using plains_base_tile_id + desert_base_tile_id
```

This ensures:
- Sea looks identical in sea_plains and sea_desert tilesets
- Plains looks identical in sea_plains and plains_desert tilesets
- Desert looks identical in sea_desert and plains_desert tilesets

### Generated Tilesets (PixelLab IDs)

| Tileset | PixelLab ID | Base Tiles |
|---------|-------------|------------|
| `sea_plains` | `8a879ea0-6fc3-42cc-8e72-b7f28ea3c990` | Sea: `4b30f53d-fd6e-40b7-bf10-b7684204afce`, Plains: `45a72bd6-87b4-4727-96b7-a7a3e7d639f2` |
| `sea_desert` | `65c6100b-7d47-4045-9e75-b9795dcd2fef` | Sea: `4b30f53d-fd6e-40b7-bf10-b7684204afce` (shared), Desert: `89f1e778-4fcd-4f66-9caf-916e92665650` |
| `plains_desert` | `b9aae241-1fcb-4983-a5fa-ed3cee78b346` | Plains: `45a72bd6-87b4-4727-96b7-a7a3e7d639f2` (shared), Desert: `89f1e778-4fcd-4f66-9caf-916e92665650` (shared) |

**Shared Base Tile IDs:**
- Sea: `4b30f53d-fd6e-40b7-bf10-b7684204afce`
- Plains: `45a72bd6-87b4-4727-96b7-a7a3e7d639f2`
- Desert: `89f1e778-4fcd-4f66-9caf-916e92665650`

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

### Wang Tileset Parameters

**Common settings for all L0/L1 tilesets:**
- `tile_size`: {"width": 32, "height": 32} (upscale to 64×64 in pipeline)
- `view`: "high top-down"
- `outline`: "selective outline"
- `shading`: "basic shading"
- `detail`: "medium detail"

**Per-tileset descriptions:**

#### sea_plains (Sea → Plains Coastline)
```python
create_topdown_tileset(
    lower_description="deep blue ocean water with dark waves, strategy game pixel art",
    upper_description="lush green grassland plains, strategy game pixel art",
    transition_description="sandy yellow-beige beach with foam where water meets sand",
    transition_size=0.5,
)
```

#### sea_desert (Sea → Desert Coastline)
```python
create_topdown_tileset(
    lower_description="deep blue ocean water with dark waves, strategy game pixel art",
    upper_description="arid desert sand dunes with beige-tan color, strategy game pixel art",
    transition_description="wet sand with scattered rocks where water meets desert",
    transition_size=0.5,
)
```

#### plains_desert (Plains → Desert Border)
```python
create_topdown_tileset(
    lower_description="lush green grassland plains, strategy game pixel art",
    upper_description="arid desert sand dunes with beige-tan color, strategy game pixel art",
    transition_description="patchy dry grass and cracked earth transitioning to sand",
    transition_size=1.0,
)
```

### Feature Overlay Tiles

Use PixelLab `create_map_object`:
- `width`: 64, `height`: 64
- `view`: "high top-down"
- Descriptions:
  - Forest: "dense forest with visible round tree canopies, multiple shades of green"
  - Hills: "rolling hills with gentle slopes, light brown earth tones, subtle shadows"
  - Mountain: "rocky mountain peak with gray stone, white snow cap on top"
  - Swamp: "murky swamp with brownish-green shallow water, scattered lily pads"

---

## 64×64 standalone base fill tiles

Native **64×64** plains/sea/desert fill tiles (not Wang tileset API). **MCP tool** (`mcp_pixellab_generate_image_pixflux`), **async REST** (`generate-image-v2` + `background-jobs`), **verbatim prompts**, and `pytool/generate_base_tiles_64_async.py`: [base-tiles-64.md](tileset/base-tiles-64.md).

**64×64 inpainted plains↔sea corner Wang (16 tiles),** `inpaint-v3` + composite/mask plan + `wang_index` metadata: [plains-sea-wang-inpaint-64.md](tileset/plains-sea-wang-inpaint-64.md).

---

## Map Viewer Contract

- **Input:** Asset directory with Wang tilesets and feature overlay tiles.
- **Per cell (i, j):**
  1. **Sea (L0):** If sea, use Wang tileset for coastline transitions.
  2. **Land Base (L1):** Draw plains or desert tile, using Wang tileset for plains↔desert borders.
  3. **Feature (L2+):** If terrain has feature, draw standalone tile over land base.

---

## App map runtime configuration (Flutter)

**Goal:** Choose Wang atlas paths, per-tileset atlas `tile_px`, and map grid `cellSize` without editing Dart.

| Item | Detail |
|------|--------|
| **JSON asset** | `app/assets/data/map_terrain_tilesets.json` |
| **Bundle** | `flutter.assets` includes `assets/data/` |
| **Dart API** | `MapTerrainConfig.ensureLoaded()` then `MapTerrainConfig.instance` (`app/lib/config/map_terrain_config.dart`) |
| **When loaded** | Before `TerrainTilesetCache` / map use: app `main.dart`; tests via `app/test/flutter_test_config.dart` |

**Schema (informal):**

- `map_cell_size_px` (int ≥ 1): logical pixels per map cell for Flame (`InitGameMapViewData` / `RegionMapViewData.cellSize`).
- `wang_tilesets` (object): must contain exactly these keys: `sea_plains`, `sea_desert`, `plains_desert`.
- Each Wang entry: `spec_json` (String, asset path to PixelLab-style JSON), `atlas_png` (String), `tile_px` (int ≥ 1). Loader requires `tile_px` to equal both `tile_size.width` and `tile_size.height` in that JSON.
- `transport_tilesets` (object): must contain exactly `road` and `rail`.
- Each transport entry: `spec_json` (String), `atlas_png` (String), `tile_px` (int ≥ 1) with `tile_px == 64` and exactly 16 tiles mapping mask ids `0..15`.
- **PNG vs metadata:** Every tile’s `bounding_box` must lie within the decoded PNG. If `tileset_image.dimensions` disagrees with the PNG size, the app may log a warning but still load when bboxes are valid.

**Rendering note:** Source rects use JSON `bounding_box`; destination is always one map cell of size `map_cell_size_px`, so mixed `tile_px` across tilesets (e.g. 64 sea/plains atlas, 32 desert atlases) is supported.

---

## Acceptance Criteria

- Given the forced palette and tileset config, when generating `sea_plains`, then it produces a 16-tile Wang tileset with consistent sea and plains base tiles.
- Given the `sea_plains` base tiles, when generating `sea_desert` with `lower_base_tile_id`, then sea tiles match visually across both tilesets.
- Given the `sea_plains` and `sea_desert` base tiles, when generating `plains_desert`, then plains and desert tiles match visually across all three tilesets.
- Given a map cell with sea adjacent to plains, when rendering, then the `sea_plains` Wang tileset is used with correct corner values.
- Given a map cell with sea adjacent to desert, when rendering, then the `sea_desert` Wang tileset is used.
- Given a map cell with plains adjacent to desert, when rendering, then the `plains_desert` Wang tileset is used.
- Given a feature cell (forest/hills/mountain/swamp), when rendering, then the appropriate land base is drawn first, then the feature overlay tile on top.
- Given valid bundled `map_terrain_tilesets.json` and referenced atlases, when the Flutter map loads Wang tilesets, then `sea_plains`, `sea_desert`, and `plains_desert` all resolve from the configured paths and the map grid uses `map_cell_size_px`.
- Given valid transport atlases and JSON contracts, when the Flutter map loads transport tilesets, then both `road` and `rail` resolve from `transport_tilesets` and each provides all masks `0..15`.
- Given a transport tile family atlas contract, when validated by tests, then each mask rectangle is unique, 64px-grid aligned, and inside atlas bounds.
