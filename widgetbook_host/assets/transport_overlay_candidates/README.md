# Transport overlay candidate atlases (Widgetbook)

Review copies of road/rail atlases for issue #1819.

- **Source of truth:** `pytool/out/transport_overlay_atlases_64/` (see `GENERATION.md` there).
- **PO promotion (2026-08-29):** Shipped default + sepia theme atlases now use the same
  PNG bytes as this folder. Widgetbook **shipped vs candidate** stories show identical art.
- Mask layout matches the shipped JSON sidecars (4×4 × 64px, masks `0..15`).

Refresh after regenerating candidates:

```bash
python3 pytool/restyle_transport_overlay_candidates.py --promote-only
```
