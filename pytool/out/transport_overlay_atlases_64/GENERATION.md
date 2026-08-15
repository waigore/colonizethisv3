# Transport overlay candidate atlases (Refs #1819)

Candidate-only PixelLab pipeline output. Shipped UI atlases under
`app/assets/images/terrain/tilesets/` were not written.

## Commands

From repository root, with `PIXELLAB_API_KEY` set:

```bash
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family both --init-seed
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family both --resume
uv run --directory pytool python generate_transport_overlay_tiles_64.py --family both --rebuild-atlas
```

Default `--out-dir` is this folder. `--rebuild-atlas` does not call the API.

## PixelLab

- Pixflux (`POST /v2/create-image-pixflux`) for each family's 64×64 straight seed
- inpaint-v3 (`POST /v2/inpaint-v3`) for masks `1..15` (mask `0` is transparent)
- Shared N/E/S/W edge contracts; interiors inpainted; contract edges reinforced
- Rail seed corridor extended to tile edges so N↔S / E↔W joins lock

## Intermediates

Per-mask tiles and contracts live under `pytool/out/transport_edge_contracts_64/`
(gitignored). Resume state: `pytool/out/transport_edge_contracts_64/state.json`.

## Validation

```bash
python3 pytool/test_transport_overlay_candidate_seams.py
cd app && flutter test test/transport_overlay_assets_test.dart \
  test/transport_overlay_tileset_cache_test.dart \
  test/transport_overlay_mask_test.dart \
  test/transport_overlay_render_policy_test.dart \
  test/transport_overlay_visual_sanity_test.dart
```

QA composites in this folder: `qa_{road,rail}_{straight_ns,straight_ew,corner,tee,cross,path}.png`.
