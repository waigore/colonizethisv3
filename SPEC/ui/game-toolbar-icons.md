# Game Toolbar Icons

**SPEC/ui** — Pixel-art icons for in-game toolbar buttons (Civilian Units, Military Units, Technology, Diplomacy). Authority: UI design rule; derives from GDD/TDD and [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md).

---

## Purpose

The in-game screen (game_screen.dart) has a toolbar with buttons for Civilian Units, Military Units, Technology, and Diplomacy. Each button currently uses Material icons (`Icons.people_outline`, `Icons.military_tech_outlined`, `Icons.science`, `Icons.handshake_outlined`). This spec defines pixel-art replacements that match the colonial 16th/17th century aesthetic established in [main-menu.md](main-menu.md).

---

## Icons required

| Icon ID | Button | Description | Size |
|---------|--------|-------------|------|
| `production` | Production | Tools/gear icon for resource production | 32×32 |
| `civilian_units` | Civilian Units | Worker/people icon, colonial era style | 32×32 |
| `military_units` | Military Units | Sword/shield or soldier icon | 32×32 |
| `diplomacy` | Diplomacy | Dove with olive branch | 32×32 |
| `technology` | Technology | Book/scroll or beaker icon | 32×32 |
| `layer_toggle` | Base Layer Cycle | Stacked layers/sheets icon for map layer toggle | 32×32 |
| `home_capital` | Home to Capital | Flag/pole icon for centering on capital | 32×32 |

**File naming:** `ui_icon_<icon_id>.png` in `app/assets/images/`. Example: `ui_icon_diplomacy.png`.

**Style lock:** Must match the color palette and pixel style from `ui_main_menu_button.png` (per [main-menu.md](main-menu.md) § Color palette):
- Frame: deep reddish-brown `#3E1F1A`–`#5A332C`
- Inner: warmer reddish-brown `#A85C3A`–`#C87A5B`
- Accents: gold `#E8C838`–`#FFED7F`, shadow `#B08B2A`

---

## MCP tool: create_map_object

Use `pixellab_create_map_object` to generate toolbar icons. This tool creates pixel art objects with transparent backgrounds, suitable for UI icons.

**Why this tool:**
- Creates standalone objects (not tilesets or characters)
- Supports transparent backgrounds
- Style matching via `background_image` parameter
- Supports small sizes (32px minimum, but 32×32 works well for toolbar icons)

---

## Generation workflow

### Step 1: Check existing assets

Before generating, check `app/assets/images/` for existing icons. Only generate missing or intentionally replaced assets.

```bash
ls app/assets/images/ui_icon_*.png 2>/dev/null || echo "No icons found"
```

### Step 2: Generate each icon

Call `pixellab_create_map_object` with the following parameters:

| Parameter | Value | Notes |
|-----------|-------|-------|
| `description` | See prompts below | Descriptive text for the icon |
| `width` | `32` | Icon width in pixels |
| `height` | `32` | Icon height in pixels |
| `view` | `high top-down` | Orthographic top-down view for UI icons |
| `outline` | `single color outline` | Consistent outline style |
| `shading` | `medium shading` | Medium detail for clarity at small size |
| `detail` | `medium detail` | Balanced detail for 32×32 |

**Optional: Style matching** (recommended for consistency):
| Parameter | Value | Notes |
|-----------|-------|-------|
| `background_image` | `{"type": "path", "path": "app/assets/images/ui_main_menu_button.png"}` | Uses existing button as style reference |
| `inpainting` | `{"type": "oval", "percentage": 0.6}` | Default inpainting for style matching |

### Step 3: Download generated icons

After each generation completes, download using the returned URL:

```bash
curl --fail -o app/assets/images/ui_icon_<icon_id>.png "https://api.pixellab.ai/mcp/map-objects/<object_id>/download"
```

**Important:** Map objects are stored for 8 hours only. Download immediately after generation.

### Step 4: Verify icons

Check file integrity and size:

```bash
file app/assets/images/ui_icon_*.png
```

Expected output: `PNG image data, 32 x 32, 8-bit/color RGBA, non-interlaced`

---

## PixelLab prompts (exact wording)

Record exact prompts for reproducibility.

### ui_icon_production.png (32×32)

```
pixellab_create_map_object(
  description='pixel art tools gear icon for production button, colonial era style, crossed hammer and pickaxe or anvil with hammer, top-down game UI icon, simple clean design',
  width=32,
  height=32,
  view='high top-down',
  outline='single color outline',
  shading='medium shading',
  detail='medium detail'
)
```

**Prompt:** `pixel art tools gear icon for production button, colonial era style, crossed hammer and pickaxe or anvil with hammer, top-down game UI icon, simple clean design`

### ui_icon_civilian_units.png (32×32)

```
pixellab_create_map_object(
  description='pixel art worker people icon for civilian units button, colonial era style, group of workers with tools, top-down game UI icon, simple clean design',
  width=32,
  height=32,
  view='high top-down',
  outline='single color outline',
  shading='medium shading',
  detail='medium detail'
)
```

**Prompt:** `pixel art worker people icon for civilian units button, colonial era style, group of workers with tools, top-down game UI icon, simple clean design`

### ui_icon_military_units.png (32×32)

```
pixellab_create_map_object(
  description='pixel art sword and shield icon for military units button, colonial era style, crossed swords with shield, top-down game UI icon, simple clean design',
  width=32,
  height=32,
  view='high top-down',
  outline='single color outline',
  shading='medium shading',
  detail='medium detail'
)
```

**Prompt:** `pixel art sword and shield icon for military units button, colonial era style, crossed swords with shield, top-down game UI icon, simple clean design`

### ui_icon_technology.png (32×32)

```
pixellab_create_map_object(
  description='pixel art book scroll icon for technology button, colonial era style, open book with quill pen, top-down game UI icon, simple clean design',
  width=32,
  height=32,
  view='high top-down',
  outline='single color outline',
  shading='medium shading',
  detail='medium detail'
)
```

**Prompt:** `pixel art book scroll icon for technology button, colonial era style, open book with quill pen, top-down game UI icon, simple clean design`

### ui_icon_layer_toggle.png (32×32)

```
pixellab_create_map_object(
  description='pixel art stacked layers icon for map layer toggle button, colonial era style, three horizontal stacked sheets or papers showing layer switching, top-down game UI icon, simple clean design',
  width=32,
  height=32,
  view='high top-down',
  outline='single color outline',
  shading='medium shading',
  detail='medium detail'
)
```

**Prompt:** `pixel art stacked layers icon for map layer toggle button, colonial era style, three horizontal stacked sheets or papers showing layer switching, top-down game UI icon, simple clean design`

### ui_icon_home_capital.png (32×32)

```
pixellab_create_map_object(
  description='pixel art home capital icon for center on capital button, colonial era style, small flag on pole or castle keep tower, top-down game UI icon, simple clean design',
  width=32,
  height=32,
  view='high top-down',
  outline='single color outline',
  shading='medium shading',
  detail='medium detail'
)
```

**Prompt:** `pixel art home capital icon for center on capital button, colonial era style, small flag on pole or castle keep tower, top-down game UI icon, simple clean design`

---

## Style matching (optional but recommended)

For visual consistency with existing assets, use the button PNG as a style reference:

```python
# Example with style matching
pixellab_create_map_object(
  description='pixel art dove bird icon for diplomacy button...',
  width=32,
  height=32,
  view='high top-down',
  outline='single color outline',
  shading='medium shading',
  detail='medium detail',
  background_image='{"type": "path", "path": "app/assets/images/ui_main_menu_button.png"}',
  inpainting='{"type": "oval", "percentage": 0.6}'
)
```

This uses the existing button as a style reference for color palette and pixel style.

---

## Implementation in Flutter

After icons are generated and placed in `app/assets/images/`:

1. Add to `pubspec.yaml` under `flutter:assets:`
   ```yaml
   flutter:
     assets:
       - assets/images/ui_icon_diplomacy.png
       - assets/images/ui_icon_civilian_units.png
       - assets/images/ui_icon_military_units.png
       - assets/images/ui_icon_technology.png
   ```

2. Update `game_screen.dart` to use `Image.asset` instead of `Icon`:
   ```dart
   // Before (Material icon)
   Icon(Icons.handshake_outlined, size: 20)
   
   // After (pixel-art icon)
   Image.asset('assets/images/ui_icon_diplomacy.png', width: 20, height: 20)
   ```

3. Update button layouts as needed. Example:
   ```dart
   CtNinePatchButton(
     onPressed: () { /* ... */ },
     child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Image.asset('assets/images/ui_icon_diplomacy.png', width: 20, height: 20),
         const SizedBox(width: 8),
         const Text('Diplomacy'),
       ],
     ),
   )
   ```

---

## Regeneration

To regenerate an icon:

1. Delete the existing file: `rm app/assets/images/ui_icon_<icon_id>.png`
2. Call `pixellab_create_map_object` with the same prompt (or adjust)
3. Download the new icon
4. Verify integrity

---

## Asset manifest

| Asset ID | Filename | Status | Generated |
|----------|----------|--------|-----------|
| production | ui_icon_production.png | ✅ Generated | 2026-03-15 |
| civilian_units | ui_icon_civilian_units.png | ✅ Generated | 2026-03-15 |
| military_units | ui_icon_military_units.png | ✅ Generated | 2026-03-15 |
| diplomacy | ui_icon_diplomacy.png | ✅ Generated | 2026-03-15 |
| technology | ui_icon_technology.png | ✅ Generated | 2026-03-15 |
| layer_toggle | ui_icon_layer_toggle.png | ✅ Generated | 2026-03-16 |
| home_capital | ui_icon_home_capital.png | ✅ Generated | 2026-03-16 |

All icons verified: 32×32 PNG with RGBA transparency.