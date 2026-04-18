# Legal 4×4 reference layout (corner Wang)

**SPEC/ui/tileset** — **Authoritative** for **`reference_layout.json`** when a **topologically consistent** preview grid is required (every **internal** edge matches **shared-corner** terrain). **Corner bit order** and **P/S** semantics: [plains-sea-wang-inpaint-64.md](plains-sea-wang-inpaint-64.md). **Artifacts:** [wang-incremental-edge-contracts-64-artifacts.md](wang-incremental-edge-contracts-64-artifacts.md).

---

## Problem

**Grid:** **4×4** cells **`(row, col)`**, **`row,col ∈ {0…3}`**.

**Tiles:** Each **`wang_index`** **`0…15`** appears **exactly once** (bijection onto cells).

**Corners per index `ii`:** **`(nw, ne, sw, se)`** with **`true` = plains**, **`false` = sea**:

`ii = (nw ? 8 : 0) | (ne ? 4 : 0) | (sw ? 2 : 0) | (se ? 1 : 0)`

**Internal edges only** (boundary edges of the 4×4 have no neighbor — no constraint).

### Horizontal internal edge

**Left** cell **A** at **`(r,c)`**, **right** cell **B** at **`(r,c+1)`** (**`c ∈ {0,1,2}`**):

- **Top shared vertex:** **`A.NE == B.NW`**
- **Bottom shared vertex:** **`A.SE == B.SW`**

### Vertical internal edge

**Above** cell **A** at **`(r,c)`**, **below** cell **B** at **`(r+1,c)`** (**`r ∈ {0,1,2}`**):

- **Left shared vertex:** **`A.SW == B.NW`**
- **Right shared vertex:** **`A.SE == B.NE`**

---

## Distinction from atlas row-major layout

**Row-major `wang_index = row×4 + col`** is the **UV / packing** layout for **256×256** atlases ([plains-sea-wang-inpaint-64.md](plains-sea-wang-inpaint-64.md) § 4×4 atlas). It does **not** guarantee that **adjacent cells** in the sheet share matching corners. A **legal layout** is a **permutation** of **`0…15`** into the grid satisfying **all** internal-edge constraints above — used for **`reference.png`** when the sheet should read as a **consistent terrain patch**, not only as a **catalog**.

**Incremental generation** ([wang-incremental-edge-contracts-64.md](wang-incremental-edge-contracts-64.md)) uses **`layout_row` / `layout_col`** from **`reference_layout.json`** for **meta** and **paste position** only; **donor** rules use the **generated set**, not sheet neighbors. Changing to a legal layout **does not** change inpaint **correctness**; it changes **preview** and **recorded cell coordinates** in **`meta_*.json`**.

---

## Tooling

**Script:** **`pytool/wang_reference_legal_layout_64.py`**.

**Algorithm (normative summary):**

1. **Precompute** **`can_right[A][B]`** and **`can_down[A][B]`** for **`A,B ∈ 0…15`**: booleans from the horizontal / vertical rules above.
2. **Search:** assign cells in a fixed order (default **row-major**). At **`(r,c)`**, try each **unused** **`T`** such that **`can_right[W][T]`** if west neighbor **`W`** exists and **`can_down[N][T]`** if north neighbor **`N`** exists.
3. **Optional forward checking:** after a tentative assign, for each **still-empty** orthogonally adjacent cell, if **no** unused tile remains compatible with **already fixed** neighbors, **backtrack**.
4. **Optional value order:** shuffle candidate **`T`** with a **`--seed`** (deterministic **RNG**) to vary solutions among many valid permutations.
5. **Output:** JSON **`{ "wang_index": 4×4 nested list }`** (same shape as existing **`reference_layout.json`**).
6. **Verification:** after search, **re-scan** all **12** horizontal and **12** vertical internal edges with the explicit vertex rules; **assert** **AllDifferent** on the **16** entries. On failure to find a solution, exit **non-zero** with a clear message (**UNSAT**).

**Optional:** **`--update-reference`** — rebuild **`reference.png`** (**256×256**) by pasting **`tiles/tile_{ii}.png`** per cell when present; missing tiles leave **white** **`#FFFFFF`** for that cell (same behaviour as a one-off rebuild script).

---

## Feasibility

A solution **may** or **may not** exist for the full **16**-tile set on **4×4**; the **tool** reports **UNSAT** if none is found. If the repo ships a **legal** **`reference_layout.json`**, it was produced by this tool (or equivalent constraint satisfaction) and **validated** by the same edge rules.
