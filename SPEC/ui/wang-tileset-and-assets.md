# Wang Tileset and Map Asset Pipeline

**SPEC/ui** — Wang tilesets and overlay assets for the Flame map viewer. Reduced edge set; forced palette; layer-isolated pipeline; spritesheet layout and consumer contract. See [tile-map-and-generation.md](../game/tile-map-and-generation.md), [resource-terrain-region-rules.md](../game/resource-terrain-region-rules.md). Tooling: [pytool-image-tools.md](pytool-image-tools.md).

---

## Scope

- **Tile size:** 64×64 pixels (canonical). Terrain from PixelLab may be generated at 32×32 (or 16×16) and upscaled to 64×64 in the pipeline.
- **Layers:** (1) Base terrain Wang tiles, (2) Resource overlay sprites, (3) Improvement overlay sprites (including roads). The map viewer composes them in order.
- **Resources and improvements:** Overlay sprites only (one sprite per resource type; improvement sprites for road connectivity and other improvements). No per-terrain×resource Wang multiplication.

---

## Reduced edge set

- **Edge types:** Two only — **water**, **land**.
- **Semantics:** Sea tiles use water edges; all land terrain types (plains, forest, hills, mountain, swamp, desert) use land edges. Land–land transitions (e.g. plains next to forest) are not distinguished at the edge; the tile interior may vary by terrain type for interior-only tiles.
- **Wang tiles needed:** Enough to cover (N,E,S,W) ∈ {water, land}⁴ that occur in the grid: water interior (water,water,water,water), land interior (land,land,land,land), and water–land transitions (e.g. land on N,E,S and water on W). Exact set is the minimal set of 4-tuples that can appear given the grid (e.g. 16-tile Wang set for 2 edge types, or a subset if some combinations are unused).

---

## Forced palette

All generated assets (terrain, resource overlays, improvement overlays) MUST use the same forced palette so that layers are visually consistent. The palette is the **single source of truth** for color; generation (PixelLab or other) MUST be constrained to it (e.g. via `color_image` / target palette).

**Palette (16 colors) — strategy / colonial era:**

| Index | Name          | Hex       | Use |
|-------|----------------|-----------|-----|
| 0     | water_dark     | `#1e3a5f` | Sea, deep water |
| 1     | water_mid      | `#2d5a87` | Water highlight |
| 2     | sand           | `#c4a574` | Coast, desert tint |
| 3     | grass_light    | `#7cb342` | Plains, grass |
| 4     | grass_dark     | `#558b2f` | Grass shadow |
| 5     | forest         | `#2e7d32` | Forest |
| 6     | forest_dark    | `#1b5e20` | Forest shadow |
| 7     | hill           | `#6d4c41` | Hills |
| 8     | hill_dark      | `#4e342e` | Hills shadow |
| 9     | mountain       | `#78909c` | Mountain |
| 10    | mountain_dark  | `#546e7a` | Mountain shadow |
| 11    | swamp          | `#5d4037` | Swamp |
| 12    | swamp_dark     | `#3e2723` | Swamp shadow |
| 13    | desert         | `#d7ccc8` | Desert |
| 14    | road           | `#5d4037` | Roads, paths (distinct from swamp in use) |
| 15    | accent         | `#ffb74d` | Resource/UI accent (e.g. gold, grain highlight) |

- **Asset:** The palette MUST be provided as a small image (e.g. 8×2 or 4×4 PNG) in the pipeline and passed as `color_image` (or equivalent) to PixelLab (or any generator) for terrain, resource, and improvement generation.
- **Location:** Palette image and a machine-readable table (e.g. JSON or Dart const) live in the asset pipeline config so each layer can be re-run with the same palette (e.g. `pytool/config/wang_palette.png`).

---

## Python tools and uv

Following [pytool-image-tools.md](pytool-image-tools.md):

- **Location:** Python tools for the tileset pipeline live under **pytool/** at repo root (sibling to `tool/`, `app/`). Scripts: `pytool/tileset_terrain.py`, `pytool/tileset_resources.py`, `pytool/tileset_improvements.py`, `pytool/tileset_pack.py`.
- **Dependency management:** Use **uv**. From repo root: create/sync env with `uv sync` (with `pytool/pyproject.toml`) or `uv venv` and `uv pip install -r pytool/requirements.txt`. Run scripts with `uv run pytool/tileset_terrain.py ...` so the correct env is used. Minimal deps: `requests` for HTTP, `Pillow` for image upscale/pack.
- **API authentication:** Every PixelLab API request MUST use the **PIXELLAB_API_KEY** environment variable. Tools MUST read `PIXELLAB_API_KEY` from the environment. If unset, tools MUST fail with a clear error (e.g. "PIXELLAB_API_KEY is not set"). Send as header: `Authorization: Bearer <value>`.
- **Run from repo root:** After `cd pytool && uv sync`, run e.g. `uv run python tileset_terrain.py --out ../out/1_terrain --palette config/wang_palette.png --seed 42`. Paths in arguments are relative to the current working directory (pytool or repo root).

---

## Layer 1: Terrain (Wang tiles)

**Purpose:** Generate base terrain Wang tiles (reduced edge set: water, land). Output: 64×64 tiles and manifest.

**Detailed steps:**

1. **Create tileset via PixelLab API (no MCP).** The PixelLab MCP (user-pixellab) does not expose create_tileset; use **PixelLab API v2**.
   - **Endpoint:** `POST https://api.pixellab.ai/v2/tilesets` (or `POST /create-tileset`). Returns 202 with `job_id` (or similar); poll until complete.
   - **Request body (exact parameters):**
     - `lower_description`: `"deep ocean water, top-down view, pixel art strategy game terrain"`
     - `upper_description`: `"grass and earth land, top-down view, pixel art strategy game terrain"`
     - `transition_description`: (optional) `"sandy coast, beach, top-down"`
     - `tile_size`: `{ "width": 32, "height": 32 }` (API only allows 16 or 32)
     - `view`: `"high top-down"`
     - `transition_size`: `0.25` or `0.5`
     - `color_image`: base64 of the forced-palette image (from pipeline config)
     - `seed`: fixed integer for reproducibility (e.g. 42)
     - Optional if supported: `text_guidance_scale`, `outline`, `shading`, `detail`
   - **Auth:** `Authorization: Bearer <PIXELLAB_API_KEY>` (from environment).
2. **Poll:** `GET /background-jobs/{job_id}` or `GET /tilesets/{tileset_id}` until status indicates complete; then download tile images.
3. **Upscale:** Resize all tiles to 64×64 (nearest-neighbour) and write to `1_terrain/tiles/` with stable filenames (e.g. by Wang id: `water_water_water_water.png`, `land_land_water_land.png`).
4. **Manifest:** Write `1_terrain/manifest.json`: map tile id → filename (or x,y if packed into a single image).

**Python tool:** `pytool/tileset_terrain.py`. Calls PixelLab API v2 POST /tilesets, polls until done, downloads tiles, upscales to 64×64, writes `1_terrain/tiles/` and `1_terrain/manifest.json`. **Requires PIXELLAB_API_KEY.**

**Usage (example):**

```bash
uv run pytool/tileset_terrain.py --out out/1_terrain --palette pytool/config/wang_palette.png --seed 42
```

**Config:** Seed, output dir, PixelLab API base URL (default `https://api.pixellab.ai/v2`), palette image path.

**Optional fallback:** If the API is unavailable, generate individual Wang tiles via MCP `generate_image_pixflux` with exact prompts per (N,E,S,W) 4-tuple. Note: MCP Pixflux does not expose `color_image` in the tool schema—for strict palette use the API.

---

## Layer 2: Resource overlays

**Purpose:** One overlay sprite per resource type. Drawn centered on the terrain tile. No Wang multiplication.

**Detailed steps:**

1. For each resource id from [resource-terrain-region-rules.md](../game/resource-terrain-region-rules.md), generate one overlay.
   - **Tool (MCP):** Use **MCP** `generate_image_pixflux` when palette is not strictly required: `description` = per-resource prompt (see table), `width` = 32 or 48, `height` = 32 or 48, `no_background` = true, `outline` = `"selective outline"`, `shading` = `"basic shading"`, `detail` = `"medium detail"`, `save_to_file` = `2_resources/tiles/{resourceId}.png`.
   - **Tool (API, strict palette):** Use PixelLab API `POST /create-image-pixflux` (or v2 equivalent) with same prompts; request body includes `color_image` (palette image base64), `image_size` 32 or 48. **Requires PIXELLAB_API_KEY.**
2. Write `2_resources/manifest.json`: resource id → asset path or rect (x, y, w, h).

**Resource prompts (one per resource):**

| Resource id  | Prompt (short) |
|--------------|----------------|
| grain        | pixel art grain wheat icon, top-down view, strategy game resource |
| meat         | pixel art meat livestock icon, top-down view, strategy game resource |
| wool         | pixel art wool sheep icon, top-down view, strategy game resource |
| horses       | pixel art horses icon, top-down view, strategy game resource |
| timber       | pixel art wood timber icon, top-down view, strategy game resource |
| iron         | pixel art iron ore icon, top-down view, strategy game resource |
| copper       | pixel art copper ore icon, top-down view, strategy game resource |
| tin          | pixel art tin ore icon, top-down view, strategy game resource |
| coal         | pixel art coal mineral icon, top-down view, strategy game resource |
| sugarCane    | pixel art sugar cane icon, top-down view, strategy game resource |
| tobacco      | pixel art tobacco plant icon, top-down view, strategy game resource |
| cotton       | pixel art cotton plant icon, top-down view, strategy game resource |
| furs         | pixel art furs pelts icon, top-down view, strategy game resource |
| spices       | pixel art spices icon, top-down view, strategy game resource |
| silver       | pixel art silver ore icon, top-down view, strategy game resource |
| gold         | pixel art gold ore icon, top-down view, strategy game resource |
| gems         | pixel art gems precious stones icon, top-down view, strategy game resource |
| diamonds     | pixel art diamonds icon, top-down view, strategy game resource |

**Python tool:** `pytool/tileset_resources.py`. For each resource id, POST create-image-pixflux with description, color_image (palette), image_size; save to `2_resources/tiles/{id}.png`; write manifest. **Requires PIXELLAB_API_KEY.**

**Usage (example):**

```bash
uv run pytool/tileset_resources.py --out out/2_resources --palette pytool/config/wang_palette.png --size 48
```

**Config:** Resource list source (canonical list above or colonizethis_data), output dir, sprite size (32 or 48).

---

## Layer 3: Improvement overlays

**Purpose:** Road overlays (connectivity-based) and other improvement sprites (e.g. extraction). Roads MUST connect across tile boundaries via center-band constraint.

**Roads:** Roads MUST connect across tile boundaries. Transitions are constrained to the **center** of each tile edge: road segments lie along the **middle** of the tile (e.g. a band through the tile center, from edge midpoint to edge midpoint). Overlay sprites: one per connectivity pattern (which edges have road: N, S, E, W). Each overlay is 64×64; road is drawn only in the central band (e.g. middle 16–24 px along the relevant axis) so that when two tiles are adjacent, the road lines meet at the tile boundary.

**Detailed steps:**

1. **Road overlays:** 16 connectivity patterns: none, N, S, E, W, NS, EW, NE, ES, SW, WN, NSE, SEW, EWN, WNS, NSEW.
   - **Tool (MCP):** `generate_image_pixflux`: description e.g. `"pixel art top-down road segment, gravel path, only in center of tile, 64x64, strategy game map, [direction list]"`, width 64, height 64, no_background true; save_to_file `3_improvements/tiles/road_{pattern}.png`.
   - **Tool (API):** Same prompts; POST create-image-pixflux with color_image; **Requires PIXELLAB_API_KEY.**
2. **Other improvements:** One sprite per type (e.g. extraction level 1, 2, 3; or a single "mine" icon). Description e.g. "pixel art mine extraction icon, top-down, strategy game"; size 32 or 48; no_background true.
3. Write `3_improvements/manifest.json`: improvement tile id → path or rect (e.g. `road_NS`, `road_NSEW`, `extraction_1`).

**Python tool:** `pytool/tileset_improvements.py`. Generate road overlays (16 patterns) and other improvement sprites via PixelLab API with color_image; save to `3_improvements/tiles/`; write manifest. **Requires PIXELLAB_API_KEY.**

**Usage (example):**

```bash
uv run pytool/tileset_improvements.py --out out/3_improvements --palette pytool/config/wang_palette.png
```

**Config:** Road pattern list (16 above), improvement types (from game rules), output dir.

---

## Layer 4: Spritesheet and manifest (pack)

**Purpose:** Pack Layer 1–3 outputs into a single spritesheet per layer and one combined manifest for the map viewer. No generation; pure packing.

**Steps:** Read `1_terrain/`, `2_resources/`, `3_improvements/` manifests and tiles; pack in row-major order into `terrain.png`, `resources.png`, `improvements.png`; write combined `manifest.json` with `tile_size_px`, `layers.terrain`, `layers.resources`, `layers.improvements` (tile id → x, y [, w, h]).

**Python tool:** `pytool/tileset_pack.py`. No API calls; reads `out/1_terrain`, `out/2_resources`, `out/3_improvements` and writes `out/4_spritesheet/`. Does **not** require PIXELLAB_API_KEY.

**Usage (example):**

```bash
uv run pytool/tileset_pack.py --out out/4_spritesheet --terrain out/1_terrain --resources out/2_resources --improvements out/3_improvements
```

---

## Spritesheet and manifest structure

**Directory layout (per run):**

```
out/
  1_terrain/
    tiles/           # 64×64 PNGs, one per Wang tile id
    manifest.json
  2_resources/
    tiles/           # one image per resource id
    manifest.json
  3_improvements/
    tiles/           # road + other improvement sprites
    manifest.json
  4_spritesheet/
    terrain.png
    resources.png
    improvements.png
    manifest.json    # Single manifest for the viewer
```

**Manifest format (4_spritesheet/manifest.json):**

- `tile_size_px`: 64 (logical tile size for the map grid).
- `layers`: Object with keys `terrain`, `resources`, `improvements`.
  - **terrain:** `image`: `"terrain.png"`. `tiles`: Object mapping **tile id** (string) to `{ "x", "y" }` (top-left pixel in spritesheet). Tile id = Wang 4-tuple encoding, e.g. `"water_water_water_water"` or `"land_land_water_land"` (N_E_S_W).
  - **resources:** `image`: `"resources.png"`. `tiles`: Object mapping **resource id** (e.g. `"grain"`, `"timber"`) to `{ "x", "y", "w", "h" }` (optional; default 64×64 or centered subrect).
  - **improvements:** `image`: `"improvements.png"`. `tiles`: Object mapping **improvement tile id** (e.g. `"road_N"`, `"road_NS"`, `"road_NSEW"`, `"extraction_1"`) to `{ "x", "y", "w", "h" }`.

**Spritesheet packing:** Tiles placed in row-major order; manifest gives exact (x,y) so the viewer can use integer tile size (64) or variable rects.

---

## Map viewer contract

- **Input:** Path to `4_spritesheet/` (or equivalent): `terrain.png`, `resources.png`, `improvements.png`, and `manifest.json`.
- **Per cell (i, j):**
  1. **Terrain:** From grid data, determine terrain type and neighbour terrain (N,E,S,W). Map to reduced edge set (water/land). Look up Wang tile id from (N,E,S,W). Draw terrain tile from `terrain.png` at (x, y) using manifest `layers.terrain.tiles[tile_id]`.
  2. **Resource:** If cell has a resource, look up `layers.resources.tiles[resourceId]` and draw that sprite centered (or at manifest-defined offset) on the cell.
  3. **Improvements:** If cell has road, compute connectivity (which of N,S,E,W have road). Look up corresponding road overlay id (e.g. `road_NS`). Draw from `improvements.png` using `layers.improvements.tiles[id]`. Other improvements similarly.
- **Layer order:** Draw terrain first, then resources, then improvements. All at the same logical tile size (64×64).
- **Reload:** Replacing any of the three PNGs or the manifest and reloading is sufficient to update that layer; pipeline layers 1–3 are independent so only the changed layer and Layer 4 pack need re-run.

---

## Pipeline layer isolation

- **Layer 1:** Inputs = palette image, terrain/tileset config (descriptions, seed, PixelLab params). Outputs = `1_terrain/tiles/*.png` + `1_terrain/manifest.json`. No dependency on 2 or 3.
- **Layer 2:** Inputs = palette image, resource list, config. Outputs = `2_resources/tiles/*` + `2_resources/manifest.json`. No dependency on 1 or 3.
- **Layer 3:** Inputs = palette image, improvement definitions (road connectivity set, etc.), config. Outputs = `3_improvements/tiles/*` + `3_improvements/manifest.json`. No dependency on 1 or 2.
- **Layer 4 (pack):** Inputs = outputs of 1, 2, 3 (or existing dirs). Outputs = `4_spritesheet/*.png` + `4_spritesheet/manifest.json`. Can re-run whenever 1, 2, or 3 change; no generation, only packing and manifest merge.

---

## Acceptance criteria

- Given the forced palette and Layer 1 config, when the pipeline runs Layer 1, then it produces 64×64 terrain tiles (upscaling from API size if needed) and a manifest mapping Wang tile ids to tile images.
- Given the forced palette and resource list, when the pipeline runs Layer 2, then it produces one overlay asset per resource and a manifest mapping resource id to sprite.
- Given the forced palette and road connectivity set, when the pipeline runs Layer 3, then it produces road overlay sprites that use only the central band of each tile edge for connections, plus a manifest.
- Given 1_terrain, 2_resources, and 3_improvements (or existing outputs), when the pipeline runs Layer 4, then it produces terrain.png, resources.png, improvements.png and a single manifest.json that the map viewer can load to draw terrain, then resources, then improvements per cell.
- Given the manifest and spritesheets from Layer 4, when the map viewer renders a cell with terrain, optional resource, and optional road, then it draws the correct Wang terrain tile, then the resource overlay (if any), then the road overlay (if any), with roads aligning at tile boundaries via the center-edge constraint.
