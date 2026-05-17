# Pytool: Python image manipulation tools

**SPEC/ui** — Python scripts under `pytool/` for UI asset processing. Used to refine main-menu pixel-art assets (e.g. button contrast and wood grain) and to run the Wang tileset asset pipeline. Authority: [main-menu.md](main-menu.md) (pixel aesthetic, palette); [wang-tileset-and-assets.md](wang-tileset-and-assets.md) (tileset layers and tools).

---

## Location and environment

- **Path:** `pytool/` at repo root (sibling to `tool/`, `app/`).
- **Venv:** Use a venv **inside pytool**: create with `cd pytool && python -m venv .venv`, then `source .venv/bin/activate` and `pip install -r requirements.txt`. Run scripts from repo root or from `pytool/` (adjust paths accordingly). Alternatively use **uv**: from repo root run `cd pytool && uv sync`, then `uv run python script.py ...` (from within `pytool/`) or `uv run pytool/script.py ...` (from root). No `.venv_pixel` at repo root is required.
- **Tileset pipeline (uv):** For the Wang tileset pipeline (Layer 1–4), use **uv** as above. Layer 1–3 require **PIXELLAB_API_KEY**; Layer 4 (pack) does not. See [wang-tileset-and-assets.md](wang-tileset-and-assets.md).

---

## Scripts

### button_contrast_wood_pil.py

**Purpose:** Apply higher border/center contrast and randomised wood grain to a button PNG. Reads an image file and writes a new PNG. Tuned for the main-menu colonial wood palette (reddish-brown frame, warm inner wood, gold accents).

**Dependencies:** Pillow (see `pytool/requirements.txt`).

**Usage:**

```bash
python pytool/button_contrast_wood_pil.py <input.png> <output.png>
```

**Example:**

```bash
python pytool/button_contrast_wood_pil.py app/assets/images/ui_main_menu_button.png app/assets/images/ui_main_menu_button_processed.png
```

**Behaviour:** Pixel-based: darkens border pixels, lightens centre wood and adds ±12 RGB noise, leaves gold accents unchanged; uses fixed RNG seed (42) for reproducibility.

---

### button_nine_patch_proper.py

**Purpose:** Build a proper 48×48 (or 3×tile_size) nine-patch PNG from a wide button PNG for Flame's `NineTileBoxWidget`. Creates a nine-patch where corners keep detailed artwork, but edges and center use solid colors that stretch cleanly without deformation. See [buttons-nine-patch.md](buttons-nine-patch.md).

**Dependencies:** Pillow (see `pytool/requirements.txt`).

**Usage:**

```bash
python pytool/button_nine_patch_proper.py <input.png> <output.png> [tile_size]
```

**Example (from repo root):**

```bash
python pytool/button_nine_patch_proper.py app/assets/images/ui_main_menu_button.png app/assets/images/ui_button_nine_patch.png 16
```

**Example (from pytool dir):**

```bash
python button_nine_patch_proper.py ../app/assets/images/ui_main_menu_button.png ../app/assets/images/ui_button_nine_patch.png 16
```

**Behaviour:** Default `tile_size` is 16 (output 48×48). Source must be at least 3×tile_size wide and tile_size tall.

- **Corners (4 tiles):** Keep detailed artwork from source (don't stretch)
- **Horizontal edges (2 tiles):** Solid color extracted from edge region (stretches horizontally)
- **Vertical edges (2 tiles):** Solid color extracted from edge region (stretches vertically)
- **Center (1 tile):** Solid color extracted from center region (stretches in both directions)

This avoids deformation when buttons are scaled to different sizes.

---

### button_contrast_wood.py

**Purpose:** Same contrast/wood logic as above, but works on **pixel JSON** (e.g. exported from an external editor or pipeline) instead of a PNG. Reads JSON from stdin or a file; writes JSON to stdout or a file. Useful when the pipeline is JSON → tool → PNG elsewhere.

**Dependencies:** None (stdlib only).

**Usage:**

```bash
# stdin → stdout
python pytool/button_contrast_wood.py

# file in → stdout
python pytool/button_contrast_wood.py pixels.json

# file in → file out
python pytool/button_contrast_wood.py pixels.json pixels_out.json
```

**Input format:** JSON object with a `"pixels"` array, or a bare array of pixel objects. Each pixel: `{"x": int, "y": int, "color": "#RRGGBB" or "#RRGGBBAA"}`.

**Output format:** `{"pixels": [ ... ]}` with the same structure and modified `color` values.

---

## When to use

- **PIL script:** Use when you have a PNG (e.g. `ui_main_menu_button.png`) and want a quick in-repo pass to increase frame/centre contrast and wood texture without leaving the repo.
- **JSON script:** Use when your pipeline produces or consumes pixel JSON and you want the same effect in that pipeline.

Both scripts share the same colour logic (border, centre wood, gold, dark outline) and seed for reproducible output.

---

### generate_base_tiles_64_async.py

**Purpose:** Generate **64×64** standalone base fill tiles (plains, sea, desert) via PixelLab **async** `POST /v2/generate-image-v2`, polling `GET /v2/background-jobs/{job_id}`. Complements 32×32 Wang `tileset_terrain.py`. MCP tool, REST steps, and **verbatim prompts**: [base-tiles-64.md](tileset/base-tiles-64.md).

**Dependencies:** `requests`, `Pillow` (see `pytool/pyproject.toml`).

**Usage (repo root):**

```bash
export PIXELLAB_API_KEY=…
uv run --directory pytool python pytool/generate_base_tiles_64_async.py \
  --out-dir app/assets/images/terrain/base_64 \
  --poll-interval 12 \
  --max-polls 150
```

Optional: `--only plains,sea` to regenerate a subset.

**Behaviour:** Submits one background job per tile; logs each poll; decodes completed payload (PNG or raw RGBA → PNG). See the wang spec for Cursor MCP path (`mcp_pixellab_generate_image_pixflux`) when not using this script.

---

### fix_base_tile_edge_seams.py

**Purpose:** Remove a bad **1px** outer row/column (e.g. black) by copying the **adjacent interior** line — no blur, full RGBA. Default edges **`south,east`**. Used on checked-in **`sea_base_64.png`** per [base-tiles-64.md](tileset/base-tiles-64.md).

**Dependencies:** Pillow.

**Usage (repo root):**

```bash
uv run --with pillow python pytool/fix_base_tile_edge_seams.py \
  app/assets/images/terrain/base_64/sea_base_64.png --in-place
# Optional: --edges north,south,east,west  -o out.png
```

---

### Archived: batch Wang + seam PoC (`pytool/archive/`)

Historical scripts (**not** used for new work): **`inpaint_plains_sea_composite_async.py`** (128×64 seam PoC), **`generate_sea_plains_wang_inpaint_64.py`** (**`contracts_128/`**, strips/cross compositing), **`wang_corner_anchor_inpaint_poc.py`**. See **`pytool/archive/README.md`** and [plains-sea-wang-inpaint-64.md](tileset/plains-sea-wang-inpaint-64.md) § archived batch pipeline.

---

### wang_incremental_64.py

**Purpose:** **Incremental** **64×64** corner-Wang plains↔sea tiles: **192×192** **cross**. **Generated set** = **`state/incremental_state.json`** ∩ existing **`tile_*.png`** (or all tiles on disk if no state). **Arms:** **`tile_{jj}`** only if **`jj`**’s **opposite** edge matches target’s side signature. **Center 16px bands:** **`tile_{jj}`** only if **`jj`**’s **same** edge matches. Else **open** + **inpaint** (**no** `contracts_128/`). **`POST /v2/inpaint-v3`** + poll; **center-crop** **64×64**. **Order:** **`k`**, **`donor_reuse_extra`**, **`wang_index`**, cell. **Seeds** **0**/**15**. **Second pass:** **`--refine-center-island II`** — **64×64** canvas, **white mask** on inner **32×32** only (outer **16px** fixed); default text stresses **continuity** with that ring (same land/sea reading inward); **`meta.center_island_refine`**. **Optional grayscale API mask feather** (`WANG_MASK_FEATHER_PX`, **`mask_feather_px`** in **`meta`**) — see [plains-sea-wang-inpaint-64.md](tileset/plains-sea-wang-inpaint-64.md). Spec: [wang-incremental-edge-contracts-64.md](tileset/wang-incremental-edge-contracts-64.md), [wang-incremental-edge-contracts-64-artifacts.md](tileset/wang-incremental-edge-contracts-64-artifacts.md), [plains-sea-wang-inpaint-64.md](tileset/plains-sea-wang-inpaint-64.md).

**Dependencies:** `requests`, `Pillow` (`pytool/requirements.txt`).

**Usage (repo root):**

```bash
export PIXELLAB_API_KEY=…
# Default --run-dir: app/assets/images/terrain/base_64/wang_incremental
python3 pytool/wang_incremental_64.py --init --max-tiles 1
python3 pytool/wang_incremental_64.py --max-tiles 4
python3 pytool/wang_incremental_64.py --only 14 --max-tiles 1
python3 pytool/wang_incremental_64.py --dry-run --max-tiles 16
python3 pytool/wang_incremental_64.py --refine-center-island 6 -v
# Override run root:
python3 pytool/wang_incremental_64.py --run-dir /path/to/other_run --init
```

**Flags:** `--init`, `--plains`, `--sea`, `--description` (applies to **every** tile that run **or** to **`--refine-center-island`** when set; disables built-in per-index overrides for normal generation), `--dry-run`, `--poll-interval`, `--max-polls`, `--max-tiles`, `--only`, `--no-crop-to-mask`, `--init-image-strength`, `--no-init-image`, `--save-strips` (writes **`edges/arm_*.png`**), `--no-resume`, `--refine-center-island II`, `-v` / `--verbose`. Built-in **`description`** overrides for specific **`wang_index`** values (when **`--description`** omitted): see [plains-sea-wang-inpaint-64.md](tileset/plains-sea-wang-inpaint-64.md).

**Outputs:** **`tiles/`**, **`intermediate/`**, **`meta/`**, **`state/edge_index.json`**, **`state/incremental_state.json`**, updated **`reference.png`** cells.

---

### Transport overlay atlas production contract (road/rail)

**Purpose:** Define the reproducible asset contract for road/rail transport atlases used by region map bitmask rendering (`roadLevel` based, masks `0..15`).

**Families:**

- `tileset_transport_road_64` (road levels `1/2`)
- `tileset_transport_rail_64` (road level `4`)

**Generation pattern:**

1. Start from a shared **64x64** straight reference tile using a centered **14px** transport corridor.
2. Build cardinal edge contracts (`N`, `E`, `S`, `W`) and combine to produce masks `0..15` (bits: `N=1`, `E=2`, `S=4`, `W=8`).
3. Use the same incremental inpaint/composite style as Wang tooling where style blending is required (`POST /v2/inpaint-v3`); use Pillow compositing helpers for deterministic assembly/cropping.
4. Pack each family to a 16-tile atlas and emit matching JSON (`tile_size=64x64`, one tile entry per mask id).

**Required validation before commit:**

- All masks `0..15` exist for both families.
- Every tile `bounding_box` is unique, 64px grid-aligned, and inside atlas dimensions.
- `app/assets/data/map_terrain_tilesets.json` includes `transport_tilesets.road` and `transport_tilesets.rail` entries pointing to the emitted atlas/spec files.
- Atlas PNGs contain substantive rendered content (not near-empty placeholders): each 256x256 transport atlas must have at least 2,500 non-transparent pixels.
- App tests covering transport contract pass (`flutter test test/transport_overlay_assets_test.dart` and `flutter test test/transport_overlay_tileset_cache_test.dart`).
- Visual sanity test passes (`flutter test test/transport_overlay_visual_sanity_test.dart`).

This contract is normative for issue #1775 transport overlays and future atlas refreshes.

**Resumable generation workflow (`pytool/generate_transport_overlay_tiles_64.py`):**

1. Initialize family contracts from Pixflux (once per family, or when reseeding style):

```bash
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family road --init-seed
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family rail --init-seed
```

2. Generate masks one-by-one (`inpaint-v3` heavy step), with resume safety:

```bash
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family road --mask 1 --resume
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family road --mask 2 --resume
# ...continue through mask 15, repeat for --family rail
```

3. Rebuild atlas PNG after all `tile_mask_00..15.png` exist for that family:

```bash
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family road --rebuild-atlas
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family rail --rebuild-atlas
```

4. Resume point for handoff: `pytool/out/transport_edge_contracts_64/state.json` stores completed masks by family and is authoritative for `--resume`.

---

### wang_reference_legal_layout_64.py

**Purpose:** Compute a **4×4** **`reference_layout.json`** that places each **`wang_index` 0–15** once so **every internal edge** satisfies **shared-corner** rules (horizontal: **`A.NE==B.NW`**, **`A.SE==B.SW`**; vertical: **`A.SW==B.NW`**, **`A.SE==B.NE`**). **Corner bits** match [plains-sea-wang-inpaint-64.md](tileset/plains-sea-wang-inpaint-64.md). **Backtracking** + **forward checking**; **`--seed`** shuffles candidate order. Spec: [wang-reference-legal-layout-64.md](tileset/wang-reference-legal-layout-64.md).

**Dependencies:** stdlib only; **`--update-reference`** needs **Pillow**.

**Usage (repo root):**

```bash
python3 pytool/wang_reference_legal_layout_64.py --run-dir app/assets/images/terrain/base_64/wang_incremental
python3 pytool/wang_reference_legal_layout_64.py --output /tmp/legal_ref.json --seed 7
python3 pytool/wang_reference_legal_layout_64.py --run-dir …/wang_incremental --update-reference
```

**Flags:** **`--run-dir`**, **`--output`**, **`--seed`**, **`--no-forward-checking`**, **`--update-reference`**, **`-v`**.

**Exit codes:** **0** success; **2** UNSAT (no layout); **3** internal validation failure.

**Tests:** `python3 pytool/test_wang_reference_legal_layout_64.py`

---

### preview_wang_tile_in_cross_composite.py

**Purpose:** Paste **`tile_XX.png`** into the center of its **192×192** cross composite for transition QA. **Incremental** (**default `--out-dir`): reads **`intermediate/composite_XX.png`** and **`tiles/tile_XX.png`**. **Legacy batch** tree: **`intermediate/cross/composite_XX.png`** and **`out/tile_XX.png`**. If **`--no-synthesize-composite`** is **not** set and no composite exists, optionally **synthesizes** from **`contracts_128/`** via **`pytool/archive/generate_sea_plains_wang_inpaint_64.py`** (requires contract PNGs on disk).

**Dependencies:** Pillow; synthesis loads the **archived** generator by file path.

```bash
uv run --with pillow python pytool/preview_wang_tile_in_cross_composite.py --wang-index 1
uv run --with pillow python pytool/preview_wang_tile_in_cross_composite.py --all
# Optional: --out-dir app/assets/images/terrain/base_64/wang_incremental
# -o path/to/out.png  (single index only); --no-synthesize-composite
```

Default **`--out-dir`**: **`app/.../wang_incremental`**. Default output: **`intermediate/preview_tile_XX_in_cross.png`** (incremental) or **`intermediate/cross/...`** (batch layout).

---

### pack_sea_plains_wang_tileset_64.py

**Purpose:** **`pack`:** Build a **256×256** atlas + JSON from **`tileset_sea_plains.json`** and **`tile_00.png`…`tile_15.png`**. Default **`--tiles-dir`**:**`app/.../wang_incremental/tiles`**; default outputs **`tileset_sea_plains_incremental_64.png`** + **`.json`** (parallel to app **`tileset_sea_plains`**, not a replacement). **`preview`:** raster coastline from committed **`TileMapResult`** JSON + atlas (same corner rules as app sea pass). Spec: [plains-sea-wang-inpaint-64.md](tileset/plains-sea-wang-inpaint-64.md), `SPEC/program/map-data.md`.

**Usage (from `pytool/`):**

```bash
uv run python pack_sea_plains_wang_tileset_64.py pack
# Override tiles or outputs (e.g. archived batch tree):
uv run python pack_sea_plains_wang_tileset_64.py pack --tiles-dir /path/to/tiles --out-png … --out-json …
# From repo root: emit TileMapResult JSON, then preview
dart run melos run generate_map -- --provinces 28 --continents 2 --seed 100 --write-tile-map-json=/tmp/tm.json
uv run python pack_sea_plains_wang_tileset_64.py preview --tile-map-json /tmp/tm.json --out-png ../app/assets/images/terrain/tilesets/map.png
```

**Flags:** **`pack`:** `--ref-json`, `--tiles-dir`, `--out-png`, `--out-json`. **`preview`:** `--tile-map-json`, `--tileset-png`, `--out-png`, `--cell-size` (multiple of 64).

**Quality gate:** `python3 pytool/test_wang_incremental_assets_and_preview.py` (committed tiles, atlas, **`_tile_map_incremental_preview_seed100.json`** + preview run).
