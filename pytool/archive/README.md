# Archived Python Wang / seam tooling

Scripts kept for historical reference and optional replay of the **batch** plains↔sea Wang pipeline (**`contracts_128/`**, strip/cross compositing). **Active** work uses **`pytool/wang_incremental_64.py`** and specs under **`SPEC/ui/tileset/`**.

| Script | Role |
|--------|------|
| `generate_sea_plains_wang_inpaint_64.py` | Batch 16-tile generator (contracts + cross). |
| `inpaint_plains_sea_composite_async.py` | 128×64 seam inpaint PoC. |
| `wang_corner_anchor_inpaint_poc.py` | Corner-anchor inpaint PoC. |

See **`SPEC/ui/tileset/plains-sea-wang-inpaint-64.md`** (archived batch section).
