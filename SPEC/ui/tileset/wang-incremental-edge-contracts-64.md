# Incremental 64×64 Wang generation (algorithm)

**SPEC/ui/tileset** — **Part 1 of 2.** **Artifacts, naming, resume:** [wang-incremental-edge-contracts-64-artifacts.md](wang-incremental-edge-contracts-64-artifacts.md).

**Corner Wang** plains↔sea (`wang_index` 0–15, [plains-sea-wang-inpaint-64.md](plains-sea-wang-inpaint-64.md)). **Does not** read **`contracts_128/`** (batch pipeline archived under **`pytool/archive/`**).

---

## Generated set

**Primary:** **`state/incremental_state.json`** → **`completed_wang_indices`**. Only indices **with** an existing **`tiles/tile_{jj}.png`** count.

**Bootstrap:** If **`incremental_state.json`** is **missing**, use **all** **`tiles/tile_*.png`** present (same file filter). **`--init`** writes initial state (**`{0,15}`** after seeding bases).

**Seeds `tile_00` / `tile_15`:** Treated like any other completed index once listed in state (they are not API-generated but **are** in the set for matching).

**Layout / geometric neighbors** do **not** decide arms or center fills—only **signature match** within this set (excluding the target **`ii`**).

---

## Arms (64×64 edge contracts)

For target **T** (`wang_index` **`ii`**) and side **x** ∈ **{N,E,S,W}**:

- Let **Cx** = **T**’s two corner materials along **x** (see § signatures).
- **Arm x** is filled **iff** there exists **`jj`** in the generated set (**`jj ≠ ii`**) such that **`tile_{jj}.png`** exists and **`jj`’s edge `y`** equals **Cx**, where **`y`** is the **opposite** of **x** (**N↔S**, **E↔W**).
- **Lowest `jj`** wins. Paste **full** **`tile_{jj}.png`** into the arm slot.

If no such **`jj`**: arm **empty**, arm rectangle **white** on mask (inpaint).

---

## Center 16px fill bands (inside Wang cell)

For side **x** of **T**:

- **Band x** is filled **iff** there exists **`jj`** in the generated set (**`jj ≠ ii`**) with **`tile_{jj}.png`** such that **`jj`’s edge x** has the **same** corner pair as **T**’s edge **x** (same **label** **x**, not opposite).
- **Lowest `jj`** wins. Crop **`jj`’s** **x** edge (**16px** deep) into **T**’s center cell; **black** on mask (keep).

Then paste four **16×16** **anchors** from bases on top of the center. **White** inpaint = **32×32** interior (plus open arms). **Final** tile = **center 64×64** crop from API output.

---

## Edge signatures

**Vertical** (**w/e** of **T**): **`(N,S)`** from **(T.NW,T.SW)** or **(T.NE,T.SE)**. **Horizontal** (**n/s**): **`(W,E)`** from **(T.NW,T.NE)** or **(T.SW,T.SE)**. Encoded as **`P`/`S`** strings (e.g. **`SP`**).

**Match:** **B.west** ↔ donor **east** iff **`(B.NW,B.SW) = (donor.NE,donor.SE)`**. **No mirroring** v1.

---

## Reference layout and PNG

**`reference_layout.json`:** **4×4** **`wang_index`**. **`reference.png`:** paste completed tiles; **JSON** is authoritative for **which** index sits in **which** cell (used for **layout_row/col** in **meta** only under this algorithm). For a **legal** permutation where **every internal grid edge** matches **shared-corner** terrain, generate JSON (and optionally **`reference.png`**) with **`pytool/wang_reference_legal_layout_64.py`** — [wang-reference-legal-layout-64.md](wang-reference-legal-layout-64.md). **Changing** layout updates **meta** **`layout_row`/`layout_col`** for **new** runs only; existing **`meta_*.json`** is not rewritten automatically.

---

## Generation order

**Next tile:** Among missing **`tiles/tile_{ii}.png`**, maximize **`k`** = count of sides with a valid **arm** (§ Arms). **Tie:** **`donor_reuse_extra`** (distinct **`jj`** on arms vs sides), then **`ii`**, then **`(r,c)`**.

---

## API

**`POST /v2/inpaint-v3`**, **`crop_to_mask`:** **true** (default). **Description:** verbatim Wang § in [plains-sea-wang-inpaint-64.md](plains-sea-wang-inpaint-64.md). Optional **baked init** (**`init_guide`** merged raster as **`inpainting_image`**; **`--no-init-image`** uses bare **`composite`**) — [plains-sea-wang-inpaint-64.md](plains-sea-wang-inpaint-64.md) § **Init-style guidance**. **Tool:** [wang_incremental_64.py](../../../pytool/wang_incremental_64.py); index: [pytool-image-tools.md](../pytool-image-tools.md).

---

## Prior PoC

Archived: [wang_corner_anchor_inpaint_poc.py](../../../pytool/archive/wang_corner_anchor_inpaint_poc.py) (anchors only, no donor strips).
