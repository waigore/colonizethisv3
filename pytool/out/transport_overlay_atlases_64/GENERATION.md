# Transport overlay candidate atlases (Refs #1819)

Candidate source folder and promotion staging area. Shipped UI atlases are promoted
from here via `pytool/restyle_transport_overlay_candidates.py --promote-only`.

## 2026-08-29 terrain-palette restyle + PO promotion

`PIXELLAB_API_KEY` was not available in the agent environment. Candidates were
restyled with the procedural terrain-palette pipeline instead of Pixflux/inpaint.

### Generate candidates

```bash
python3 pytool/restyle_transport_overlay_candidates.py
```

### Promote into shipped player paths (PO-approved 2026-08-29)

```bash
python3 pytool/restyle_transport_overlay_candidates.py --promote-only
```

Copies byte-identical PNGs to:

- `app/assets/images/terrain/tilesets/tileset_transport_{road,rail}_64.png` (default theme)
- `app/assets/themes/sepia/images/terrain/tilesets/tileset_transport_{road,rail}_64.png`
- `widgetbook_host/assets/transport_overlay_candidates/`

JSON sidecars and `map_terrain_tilesets.json` paths are unchanged.

### Method

1. Sample muted land tones from `app/assets/images/terrain/tilesets/tileset_sea_plains_v2_64.png`.
2. Build deterministic straight seeds (road: olive-brown stipple; rail: grey bed, steel rails, brown ties).
3. Derive locked N/E/S/W edge contracts and compose masks `0..15` via
   `generate_transport_overlay_tiles_64.py` (contract compositor only — no per-mask independent images).
4. Rebuild 4×4 atlases and QA composites into this folder.

Intermediates: `pytool/out/transport_edge_contracts_64/{road,rail}/` (gitignored).

### PixelLab (future regeneration)

When `PIXELLAB_API_KEY` is set, prefer the Pixflux + inpaint-v3 workflow with the
updated terrain-aligned prompts in `generate_transport_overlay_tiles_64.py`:

```bash
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family both --init-seed
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family both --resume
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family both --rebuild-atlas
python3 pytool/restyle_transport_overlay_candidates.py --promote-only
```

## Validation

```bash
python3 pytool/test_transport_overlay_candidate_seams.py
cd app && flutter test test/transport_overlay_assets_test.dart \
  test/transport_overlay_tileset_cache_test.dart \
  test/transport_overlay_mask_test.dart \
  test/transport_overlay_render_policy_test.dart \
  test/transport_overlay_visual_sanity_test.dart \
  test/widgetbook_transport_overlay_candidates_test.dart
```

QA composites in this folder: `qa_{road,rail}_{straight_ns,straight_ew,corner,tee,cross,path}.png`.
