# Pytool: Python image manipulation tools

**SPEC/ui** — Python scripts under `pytool/` for UI asset processing. Used to refine main-menu pixel-art assets (e.g. button contrast and wood grain) and to run the Wang tileset asset pipeline. Authority: [main-menu.md](main-menu.md) (pixel aesthetic, palette); [wang-tileset-and-assets.md](wang-tileset-and-assets.md) (tileset layers and tools).

---

## Location and environment

- **Path:** `pytool/` at repo root (sibling to `tool/`, `app/`).
- **Venv:** Use a venv **inside pytool**: create with `cd pytool && python -m venv .venv`, then `source .venv/bin/activate` and `pip install -r requirements.txt`. Run scripts from repo root or from `pytool/` (adjust paths accordingly). Alternatively use **uv**: from repo root run `cd pytool && uv sync`, then `uv run python script.py ...` (from within `pytool/`) or `uv run pytool/script.py ...` (from root). No `.venv_pixel` at repo root is required.
- **Tileset pipeline (uv):** For the Wang tileset pipeline (Layer 1–4), use **uv** as above. Layer 1–3 require **PIXELLAB_API_KEY**; Layer 4 (pack) does not. See [wang-tileset-and-assets.md](wang-tileset-and-assets.md).

---

## Scripts

### button_contrast_wood_pil.py

**Purpose:** Apply higher border/center contrast and randomised wood grain to a button PNG. Reads an image file and writes a new PNG. Tuned for the main-menu colonial wood palette (reddish-brown frame, warm inner wood, gold accents).

**Dependencies:** Pillow (see `pytool/requirements.txt`).

**Usage:**

```bash
python pytool/button_contrast_wood_pil.py <input.png> <output.png>
```

**Example:**

```bash
python pytool/button_contrast_wood_pil.py app/assets/images/ui_main_menu_button.png app/assets/images/ui_main_menu_button_processed.png
```

**Behaviour:** Pixel-based: darkens border pixels, lightens centre wood and adds ±12 RGB noise, leaves gold accents unchanged; uses fixed RNG seed (42) for reproducibility.

---

### button_nine_patch_proper.py

**Purpose:** Build a proper 48×48 (or 3×tile_size) nine-patch PNG from a wide button PNG for Flame's `NineTileBoxWidget`. Creates a nine-patch where corners keep detailed artwork, but edges and center use solid colors that stretch cleanly without deformation. See [buttons-nine-patch.md](buttons-nine-patch.md).

**Dependencies:** Pillow (see `pytool/requirements.txt`).

**Usage:**

```bash
python pytool/button_nine_patch_proper.py <input.png> <output.png> [tile_size]
```

**Example (from repo root):**

```bash
python pytool/button_nine_patch_proper.py app/assets/images/ui_main_menu_button.png app/assets/images/ui_button_nine_patch.png 16
```

**Example (from pytool dir):**

```bash
python button_nine_patch_proper.py ../app/assets/images/ui_main_menu_button.png ../app/assets/images/ui_button_nine_patch.png 16
```

**Behaviour:** Default `tile_size` is 16 (output 48×48). Source must be at least 3×tile_size wide and tile_size tall.

- **Corners (4 tiles):** Keep detailed artwork from source (don't stretch)
- **Horizontal edges (2 tiles):** Solid color extracted from edge region (stretches horizontally)
- **Vertical edges (2 tiles):** Solid color extracted from edge region (stretches vertically)
- **Center (1 tile):** Solid color extracted from center region (stretches in both directions)

This avoids deformation when buttons are scaled to different sizes.

---

### button_contrast_wood.py

**Purpose:** Same contrast/wood logic as above, but works on **pixel JSON** (e.g. exported from an external editor or pipeline) instead of a PNG. Reads JSON from stdin or a file; writes JSON to stdout or a file. Useful when the pipeline is JSON → tool → PNG elsewhere.

**Dependencies:** None (stdlib only).

**Usage:**

```bash
# stdin → stdout
python pytool/button_contrast_wood.py

# file in → stdout
python pytool/button_contrast_wood.py pixels.json

# file in → file out
python pytool/button_contrast_wood.py pixels.json pixels_out.json
```

**Input format:** JSON object with a `"pixels"` array, or a bare array of pixel objects. Each pixel: `{"x": int, "y": int, "color": "#RRGGBB" or "#RRGGBBAA"}`.

**Output format:** `{"pixels": [ ... ]}` with the same structure and modified `color` values.

---

## When to use

- **PIL script:** Use when you have a PNG (e.g. `ui_main_menu_button.png`) and want a quick in-repo pass to increase frame/centre contrast and wood texture without leaving the repo.
- **JSON script:** Use when your pipeline produces or consumes pixel JSON and you want the same effect in that pipeline.

Both scripts share the same colour logic (border, centre wood, gold, dark outline) and seed for reproducible output.
