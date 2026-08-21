# Transport overlay candidate atlases (Widgetbook-only)

Review copies of PixelLab-generated road/rail atlases for issue #1819.

- **Source of truth:** `pytool/out/transport_overlay_atlases_64/` (see `GENERATION.md` there).
- **Do not** wire these into `map_terrain_tilesets.json` or overwrite
  `app/assets/images/terrain/tilesets/tileset_transport_{road,rail}_64.png`.
- Mask layout matches the shipped JSON sidecars (4×4 × 64px, masks `0..15`).

Refresh after regenerating candidates:

```bash
cp pytool/out/transport_overlay_atlases_64/tileset_transport_{road,rail}_64.png \
  widgetbook_host/assets/transport_overlay_candidates/
```
