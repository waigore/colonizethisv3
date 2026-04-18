# 64×64 standalone base terrain tiles

**SPEC/ui/tileset** — Full-tile **64×64** textures for plains, sea, and desert (seamless tiling as a generation goal). Derives from [wang-tileset-and-assets.md](../wang-tileset-and-assets.md) (canonical tile size, palette). The Wang **tileset** API is **32×32** only (`POST /v2/tilesets`); these assets use **single-image** generation at 64×64.

---

## Output (Flutter app assets)

| File | Terrain |
|------|---------|
| `app/assets/images/terrain/base_64/plains_base_64.png` | Plains |
| `app/assets/images/terrain/base_64/sea_base_64.png` | Sea |

**Sea tile edge fix:** The shipped **sea** PNG was post-processed with **`pytool/fix_base_tile_edge_seams.py`** (default **`south,east`**) so the **south** and **east** outer lines match the adjacent interior row/column — removes a **1px black** generator seam on those edges without changing the rest of the tile.
| `app/assets/images/terrain/base_64/desert_base_64.png` | Desert |

---

## Cursor PixelLab MCP (single tile, synchronous)

Use when generating one tile interactively in Cursor. The MCP tool maps to Pixflux **create image** (HTTP **200**, synchronous).

| | |
|--|--|
| **MCP tool** | `mcp_pixellab_generate_image_pixflux` |
| **REST equivalent** | `POST /v2/create-image-pixflux` |
| **Parameters** | `description`: verbatim prompts below; `width`: **64**; `height`: **64**; `no_background`: **false** (opaque ground/water). Optional Pixflux fields (`outline`, `shading`, `detail`, `text_guidance_scale`, `view`) unset unless a future pass standardises them. |
| **Output** | `save_to_file`: absolute path; parent directory must exist. |

---

## Authoritative batch regeneration (async Pro + polling)

Checked-in PNGs from the script path use **async** Pro image generation.

| Step | REST |
|------|------|
| Submit | `POST /v2/generate-image-v2` |
| Status / result | `GET /v2/background-jobs/{job_id}` until `status` is `completed` |

**Script:** `pytool/generate_base_tiles_64_async.py` — default poll interval **12 s**; per-tile JSON body: `description` (below), `image_size`: `{"width": 64, "height": 64}`, `no_background`: **false**. Requires `PIXELLAB_API_KEY`. See [pytool-image-tools.md](../pytool-image-tools.md).

**Post-decode:** Job payloads may be **raw RGBA** (`64×64×4` bytes). The script encodes **PNG** via Pillow.

**Parity:** `generate-image-v2` (Pro, async) and `create-image-pixflux` (MCP) differ; for closest match to script-produced assets, run `generate_base_tiles_64_async.py`. For MCP iteration, use `mcp_pixellab_generate_image_pixflux` with the **same description strings**.

---

## Verbatim `description` prompts

Use exactly as MCP `description` or REST JSON `description`.

**plains**

```text
single 64 by 64 pixel art grassland plains ground tile, high top-down orthographic map view, seamless tileable texture: left edge must match right edge and top edge must match bottom edge when repeated in a grid, subtle grass and soil variation, no trees rocks buildings units, colonial era strategy game terrain base only
```

**sea**

```text
single 64 by 64 pixel art deep sea water surface tile, high top-down orthographic, seamless tileable: all four edges wrap continuously when tiled, gentle wave pattern, no land no boats, open ocean fill only, strategy game water base
```

**desert**

```text
single 64 by 64 pixel art arid desert sand ground tile, high top-down orthographic, seamless tileable texture with matching edges for grid tiling, fine dune ripples and grit, no plants structures, strategy game desert terrain base only
```

---

## Beach seam inpaint (archived PoC)

Early **128×64** seam **`inpaint-v3`** experiment: **`pytool/archive/inpaint_plains_sea_composite_async.py`**. **Production** sea↔plains corners use **incremental Wang** — [plains-sea-wang-inpaint-64.md](plains-sea-wang-inpaint-64.md).

**Verbatim inpaint `description`** (historical reference):

```text
pixel art beach shoreline wet sand shallow water sea foam blending grassland plains on the left into open deep ocean on the right high top-down orthographic colonial strategy map terrain no buildings no units
```
