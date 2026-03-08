# Pytool: Python image manipulation tools

**SPEC/ui** — Python scripts under `pytool/` for UI asset processing. Used to refine main-menu pixel-art assets (e.g. button contrast and wood grain) and to run the Wang tileset asset pipeline. Authority: [main-menu.md](main-menu.md) (pixel aesthetic, palette); [wang-tileset-and-assets.md](wang-tileset-and-assets.md) (tileset layers and tools).

---

## Location and environment

- **Path:** `pytool/` at repo root (sibling to `tool/`, `app/`).
- **Venv:** The project uses a dedicated Python venv for pixel/image tools: **`.venv_pixel`** at repo root. Activate it before running any script, e.g. `source .venv_pixel/bin/activate`. Then install deps once: `pip install -r pytool/requirements.txt` (from repo root). Run scripts as below.
- **Tileset pipeline (uv):** For the Wang tileset pipeline (Layer 1–4), use **uv** for dependency management: from repo root run `cd pytool && uv sync`, then `uv run pytool/tileset_terrain.py ...` (or from pytool: `uv run python tileset_terrain.py ...`). Layer 1–3 require **PIXELLAB_API_KEY**; Layer 4 (pack) does not. See [wang-tileset-and-assets.md](wang-tileset-and-assets.md).

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
