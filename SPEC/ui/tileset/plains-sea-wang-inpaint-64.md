# 64×64 plains↔sea Wang tiles (inpainted land–sea)

**SPEC/ui/tileset** — **Two-terrain corner Wang** (same class as existing `sea_plains` tilesets): **16** tiles, one per assignment of **plains vs sea** at the **four cell corners**. Land–sea transitions use **async** `POST /v2/inpaint-v3` on **composites + masks** (see [base-tiles-64.md](base-tiles-64.md) for base fills); default prompts emphasize **rocky coast** with a **normal** land–ocean boundary (**no** cliffs / sheer drops). **Runtime contract** matches `WangTile` / `WangTileset.findTile` in `app/lib/features/game/flame/tilesets/terrain_tileset.dart`.

---

## Why 16 tiles

With **two** corner colors (**lower** = sea, **upper** = plains for tileset `sea_plains`), each tile must match **four** boolean corners → **2⁴ = 16** combinations. This is the standard **minimal** corner Wang set (4×4 atlas).

---

## Corner index and metadata (for code)

**Semantic:** `upper` = plains, `lower` = sea (same as PixelLab Wang JSON today).

**Booleans for `findTile`:** `nw, ne, sw, se` — **`true` = upper (plains)**, **`false` = lower (sea)**.

**Packed index `wang_index` (0–15), bit order NW → NE → SW → SE:**

`wang_index = (nw ? 8 : 0) | (ne ? 4 : 0) | (sw ? 2 : 0) | (se ? 1 : 0)`

**JSON per tile (unchanged shape):**

```json
{
  "id": "sea_plains_inpaint_wang_12",
  "corners": { "NW": "lower", "NE": "upper", "SW": "lower", "SE": "upper" },
  "bounding_box": { "x": 192, "y": 64, "width": 64, "height": 64 }
}
```

**Optional fields** (manifest or `tileset_data` sibling): `wang_index`, `terrain_pair: ["sea","plains"]`, `generator: "inpaint-v3"` for tooling; **loader may ignore** extras if `WangTile.fromJson` stays strict—either extend the Dart model later or strip before parse.

**4×4 atlas layout (row-major, `wang_index` = row×4 + col):**

| Row | Col 0 | Col 1 | Col 2 | Col 3 |
|-----|-------|-------|-------|-------|
| 0 | 0–3 | | | |
| 1 | 4–7 | | | |
| 2 | 8–11 | | | |
| 3 | 12–15 | | | |

`bounding_box.x = (wang_index % 4) * 64`, `bounding_box.y = (wang_index ~/ 4) * 64` for a **256×256** sheet.

**Incremental run `reference.png`:** A **permutation** of the same **16** indices with **pairwise corner-consistent** internal edges is **optional** for preview — [wang-reference-legal-layout-64.md](wang-reference-legal-layout-64.md) (`pytool/wang_reference_legal_layout_64.py`). **Atlas row-major** above does **not** imply adjacent cells match.

---

## Production path: incremental Wang

| | |
|--|--|
| **Tool** | `pytool/wang_incremental_64.py` |
| **Algorithm + artifacts** | [wang-incremental-edge-contracts-64.md](wang-incremental-edge-contracts-64.md), [wang-incremental-edge-contracts-64-artifacts.md](wang-incremental-edge-contracts-64-artifacts.md) |
| **API** | `POST /v2/inpaint-v3` → poll `GET /v2/background-jobs/{job_id}` |

**Canvas:** **192×192** cross; **64×64** center cell; **donor** arms and **16px** center-edge fills from the **generated** tile set (**no** `contracts_128/`). **`crop_to_mask`:** **true** so inpainting respects mask geometry.

### Verbatim inpaint `description` (default in `wang_incremental_64.py`)

Tuned to reduce **harsh mask boundaries**: gradual blend into kept pixels (hue, value, grain); **masked interior** stays **one continuous scene** with arms, **16px** center bands, and **anchor** corners (**same** land/sea story—**no** contradictory central motif).

```text
pixel art high-detail top-down orthographic strategy map terrain seamlessly extend grassland plains and open sea from kept corners and edges into the masked region blend gradually across the boundary over several pixels matching local hue value and grain avoid abrupt color steps bright rims or sharp cutoffs natural shoreline where land meets sea match palette texture and pixel-scale detail of kept areas no visible seam the masked interior is the same tile as the kept frame only continue what arms sixteen-pixel center bands and anchor corners already show same land versus sea story palette grain and scale at the mask edge do not invent a different biome lighting or focal theme in the center that contradicts those pixels
```

**Per-`wang_index` overrides** (when **`--description`** is **not** passed): **4** (mostly sea), **11** (mostly plains), **14** (east/southeast sea continuity)—see `WANG_INDEX_INPAINT_DESCRIPTION_OVERRIDES` in `wang_incremental_64.py`.

### Inpaint-v3 **init-style guidance**

**`POST /v2/inpaint-v3`** does **not** accept **`init_image`** in the JSON body (**422**). Guidance is **baked** into **`intermediate/init_guide_{ii}.png`** as **`inpainting_image`**; **`composite_{ii}.png`** is arms-only QA. **`--no-init-image`** sends the bare **`composite`**.

**How the guide is built:** For each **white** mask pixel: opaque RGB from **plains**/**sea** base colours (tile centre sample)—**center 64×64** bilinear Wang-corner blend; each **arm** edge **lerp**; then **`alpha_composite`** the real **composite** on top.

**API mask feather (optional):** **`WANG_MASK_FEATHER_PX`** is **empty**; trial **4px** feather caused **inpaint-v3** failures—grayscale masks **off** until API behaviour is confirmed.

**CLI:** **`--init-image-strength`** default **450**—stored in **`meta`** only; **not** sent on the wire for v3.

---

## Parallel packed tileset + map preview (checked in)

| Path | Role |
|------|------|
| `app/assets/.../wang_incremental/tiles/tile_{ii}.png` | Canonical **16** tiles |
| `app/assets/.../tilesets/tileset_sea_plains_incremental_64.png` + `.json` | **`pack_sea_plains_wang_tileset_64.py pack`** (`--tiles-dir` → `wang_incremental/tiles`) |
| `app/assets/.../tilesets/_tile_map_incremental_preview_seed100.json` | Golden **`TileMapResult`** (e.g. `generate_map --write-tile-map-json`) |
| `app/assets/.../tilesets/map_preview_sea_plains_incremental_64_seed100.png` | **`pack … preview`** coastline raster |

**Runtime (Flutter app):** Sea↔plains (and the other L0/L1 Wang pairs) load from paths in **`assets/data/map_terrain_tilesets.json`** — default `sea_plains` points at the upscaled **`tileset_sea_plains_v2_64`** atlas/JSON unless you change that config. **`tileset_sea_plains_incremental_64`** remains an alternate packed set for tooling/previews (`pack_sea_plains_wang_tileset_64.py`, `preview-app`), not a separate hardcoded app path.

---

## Cross preview QA

**`pytool/preview_wang_tile_in_cross_composite.py`** pastes **`tile_{ii}.png`** onto **`intermediate/composite_{ii}.png`** (incremental layout). If only **`intermediate/cross/composite_{ii}.png`** exists (old batch tree), that path is used. **Synthesis** from **`contracts_128/`** requires **`pytool/archive/generate_sea_plains_wang_inpaint_64.py`** and a checkout that still has contract PNGs.

---

## Archived batch pipeline

**`pytool/archive/`** holds the former **`contracts_128/`** batch generator (**`generate_sea_plains_wang_inpaint_64.py`**), **corner-anchor PoC**, and **beach seam** script. **Do not use for new work**; incremental **`wang_incremental_64.py`** is authoritative.

---

## Related

- [base-tiles-64.md](base-tiles-64.md)
- [wang-tileset-and-assets.md](../wang-tileset-and-assets.md)
- [pytool-image-tools.md](../pytool-image-tools.md)
