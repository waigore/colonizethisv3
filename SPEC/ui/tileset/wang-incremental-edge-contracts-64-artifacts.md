# Incremental 64×64 Wang generation (artifacts & resume)

**SPEC/ui/tileset** — **Part 2 of 2.** **Algorithm:** [wang-incremental-edge-contracts-64.md](wang-incremental-edge-contracts-64.md).

---

## Directory layout (`<run-dir>`)

**Repo default `<run-dir>`:** **`app/assets/images/terrain/base_64/wang_incremental`** (`pytool/wang_incremental_64.py` **`--run-dir`** default).

**`ii` / `jj`:** zero-padded **`wang_index`** `00`–`15`.

```
<run-dir>/
  reference_layout.json
  reference.png
  tiles/tile_{ii}.png
  intermediate/composite_{ii}.png
  intermediate/mask_{ii}.png
  intermediate/init_guide_{ii}.png   # optional: merged guide = inpainting_image when init on
  intermediate/anchors_{ii}.png
  meta/meta_{ii}.json
  edges/strip_{jj}_{side}_{sig}.png    # optional export
  state/incremental_state.json
  state/edge_index.json
```

**`reference_layout.json`:** **4×4** **`wang_index`** permutation. **Atlas row-major** (**`wang_index` = row×4+col**) is used for **UV packing** in [plains-sea-wang-inpaint-64.md](plains-sea-wang-inpaint-64.md) and does **not** guarantee **neighbor** corner agreement. For a **legal** layout (all **internal** edges **corner-consistent**), use **`pytool/wang_reference_legal_layout_64.py`** — [wang-reference-legal-layout-64.md](wang-reference-legal-layout-64.md).

**`tiles/tile_{ii}.png`:** **Canonical** final Wang tile. **Hetero arms / center fills:** **`tile_{jj}`** only per Part 1 (**generated set** + **opposite-edge** match for arms, **same-edge** match for center bands). Else **open** arm. **Reference** **`meta_{ii}.json`**.

**Homogeneous seed (tool default):** Missing **`tile_00`** / **`tile_15`** → copy bases. They enter **`incremental_state.json`** on **`--init`** (or when completed on disk if no state file). To re-seed after base changes, delete those PNGs and rerun.

**`intermediate/`:** **`composite_{ii}`** = **192×192** cross (**donor** arms = real **`tile_{jj}`**; **open** arms = empty/transparent); **`mask_{ii}`** = PixelLab **L**: **white** only in the **center 64×64** interior (minus **16×16** anchor corners and minus **same-edge** center strips), **not** in open **arm** slots — so **inpaint-v3** focuses on the **central** region; **`init_guide_{ii}`** = **192×192** merged guide submitted as **`inpainting_image`** when init enabled (see [plains-sea-wang-inpaint-64.md](plains-sea-wang-inpaint-64.md)); **`anchors_{ii}`** = **64×64** anchors-only (QA).

---

## Optional `edges/arm_*.png`

**Naming:** **`arm_{ii}_{side}_{sig}_tile_{jj}.png`** when an **arm** donor **`jj`** exists (Part 1). **`--save-strips`** (flag name retained).

**Optional** (debug / review). **Open** sides are not exported.

---

## `meta/meta_{ii}.json` (minimum)

**`wang_index`**, **`layout_row`**, **`layout_col`**, **`k`** (count of **filled arms**), **`donors`** (**`edge_contract_donors`**: **`jj`** or **`null`** per side), **`arm_sources`** (**`tile_{jj}`** or **`open_edge:no_opposite_match_sig_*`**), **`arms_inpaint_open`**, **`api_canvas`**, **`tool_version`**, **`signatures`**, **`job_id`**, **`crop_to_mask`**, **`init_guide`**, **`init_image_strength`**, **`init_baked_into_inpaint_input`**, **`inpainting_input`** (path actually sent as **`inpainting_image`**), paths, bases, **`description_verbatim`**.

---

## `state/edge_index.json`

Entries: **`{ "source_wang_index", "side", "signature", "signature_kind": "vertical"|"horizontal", "strip_relpath?": "edges/…" }`**. **Rebuild** on load and after each completion; **only** from existing **`tiles/tile_{ii}.png`**.

## `state/incremental_state.json`

**`completed_wang_indices`**, **`last_completed_wang_index`**, **`last_job_id`**, tool version. **Donor / arm selection** uses this list ∩ existing **`tile_*.png`**. If the file is **missing**, omit **`jj`** from the effective set. **Completion truth** for skipping work: **`tiles/tile_{ii}.png`** exists; state is updated after each completion.

---

## Resume and edge accounting

**No strict index order:** Any subset of **`{0…15}`** on disk is valid.

**Truth:** **`tiles/tile_{ii}.png` exists** ⇒ **`ii`** complete.

**Startup:** (1) **Glob** **`tiles/tile_*.png`**. (2) Signatures from packed index — **no PNG read**. (3) **`edge_index.json`**. (4) **Next** missing **`ii`** (**max** **`k`**, **`donor_reuse_extra`**, **`ii`**, **`(r,c)`**). (5) **Arms / center bands** per Part 1 generated set.

**Never** assume **`jj < ii`** or monotonic runs—only **set membership** + **signature** + **pixels** from disk.

**Interrupted run:** **`intermediate/composite_{ii}.png`** without **`tiles/tile_{ii}.png`** ⇒ **incomplete**; **resume** polls **`job_id`** (use **`meta`** **`api_canvas`** for decode: **192** vs legacy **64**).

---

## Center-island second pass (`pytool/wang_incremental_64.py`)

**Flag:** **`--refine-center-island II`** ( **`II`** = **`wang_index`** ). Requires existing **`tiles/tile_{ii}.png`**.

**Behavior:** **inpaint-v3** on a **64×64** canvas. **Mask:** **white** only on the inner **32×32** (tile pixel coordinates **16–47** inclusive on **x** and **y**); **black** on the outer **16px** ring so **edge strips** stay fixed for **neighbor contracts**. **Init** (unless **`--no-init-image`**): **`init_guide_{ii}_center_island.png`** = bilinear corner tint under that island + current tile (same idea as **192×** **`init_guide`**). **Artifacts:** **`intermediate/mask_{ii}_center_island.png`**, optional **`init_guide_{ii}_center_island.png`**. **Meta:** **`center_island_refine`** object ( **`api_canvas`: 64**, **`job_id`**, prompt, paths). Default text matches the **verbatim** Wang prompt plus **ring-as-ground-truth**: extend **only** what the **16px** outer ring already shows (passage, bay, coast, or strait—**no** thematic clash); override with **`--description`**.

---

## Logging

**Implementation** logs via **`logging`**: **startup**, **each** arm (**side**, **`sig`**, **`tile_{jj}`** or **`open_edge:*`**), **center fill** sides (if any), **anchors**, **mask** summary, **writes**, **API** polls, **completion** / **skip** / **resume**. **Never** log the API key. **`--verbose`** → **DEBUG**.
