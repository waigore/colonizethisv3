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
| `naval_units` | Naval Units | Ship/anchor icon for naval fleets | 32×32 |
| `diplomacy` | Diplomacy | Dove with olive branch | 32×32 |
| `technology` | Technology | Book/scroll or beaker icon | 32×32 |
| `layer_toggle` | Base Layer Cycle | Stacked layers/sheets icon for map layer toggle | 32×32 |
| `home_capital` | Home to Capital | Flag/pole icon for centering on capital |32×32 |
| `map_options` | Map Display Options | Gear/cog icon for map display settings | 32×32 |
| `region_minimap` | Region minimap toggle | Globe / New World–style compass icon (`ui_icon_region_minimap.png`; may match `ui_icon_tech_new_world` style) | 32×32 |
| `treasury_coin` | Treasury indicator | Gold coin icon for map control-row treasury display (`ui_icon_treasury_coin.png`) | 32×32 |

**File naming:** `ui_icon_<icon_id>.png` in `app/assets/icons/`. Example: `ui_icon_diplomacy.png`. List `assets/icons/` in `pubspec.yaml` under `flutter: assets:` (directory entry is enough).

**Loading (app):** Paths use `kAppIconAssetPrefix` (`assets/icons/32/`, `lib/config/app_constants.dart`, re-exported from `lib/config/app_assets.dart`). In-game and overlays use `StrictAssetIcon` (`lib/widgets/strict_asset_icon.dart`): missing or invalid PNGs throw `FlutterError` when the asset resolves. Flame `ResourceIconCache` loads `ui_icon_com_<resource_id>.png` from the 64px prefix (`kAppIcon64AssetPrefix`); toolbar uses the 32px prefix.

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

Before generating, check `app/assets/icons/` for existing icons. Only generate missing or intentionally replaced assets.

```bash
ls app/assets/icons/ui_icon_*.png 2>/dev/null || echo "No icons found"
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
curl --fail -o app/assets/icons/ui_icon_<icon_id>.png "https://api.pixellab.ai/mcp/map-objects/<object_id>/download"
```

**Important:** Map objects are stored for 8 hours only. Download immediately after generation.

### Step 4: Verify icons

Check file integrity and size:

```bash
file app/assets/icons/ui_icon_*.png
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

### ui_icon_map_options.png (32×32)

```
pixellab_create_map_object(
  description='gear icon, mechanical cog wheel with teeth, simple pixel art style for UI button',
  width=32,
  height=32,
  view='high top-down',
  outline='single color outline',
  shading='basic shading',
  detail='medium detail'
)
```

**Prompt:** `gear icon, mechanical cog wheel with teeth, simple pixel art style for UI button`

### ui_icon_naval_units.png (32×32)

Use PixelLab’s Pixflux generator for the naval units panel icon. This icon represents fleets and should read clearly at 32×32 while matching the existing toolbar icon style.

```text
generate_image_pixflux(
  description='pixel art naval fleet icon for naval units button, colonial era style, small sailing ship with mast and sail on stylized waves, with anchor motif, top-down game UI icon, simple clean design, limited palette',
  width=32,
  height=32,
  outline='single color outline',
  shading='medium shading',
  detail='medium detail',
  no_background=true
)
```

**Prompt:** `pixel art naval fleet icon for naval units button, colonial era style, small sailing ship with mast and sail on stylized waves, with anchor motif, top-down game UI icon, simple clean design, limited palette`

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

After icons are generated and placed in `app/assets/icons/`:

1. Ensure `pubspec.yaml` lists the icons directory under `flutter: assets:`:
   ```yaml
   flutter:
     assets:
       - assets/icons/
   ```

2. Use `StrictAssetIcon` with `kAppIconAssetPrefix` instead of bare `Image.asset`:
   ```dart
   // Before (Material icon)
   Icon(Icons.handshake_outlined, size: 20)
   
   // After (pixel-art icon; fails fast if asset missing)
   StrictAssetIcon(
     assetPath: '${kAppIconAssetPrefix}ui_icon_diplomacy.png',
     width: 20,
     height: 20,
   )
   ```

3. Update button layouts as needed. Example:
   ```dart
   CtNinePatchButton(
     onPressed: () { /* ... */ },
     child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         StrictAssetIcon(
           assetPath: '${kAppIconAssetPrefix}ui_icon_diplomacy.png',
           width: 20,
           height: 20,
         ),
         const SizedBox(width: 8),
         const Text('Diplomacy'),
       ],
     ),
   )
   ```

---

## Regeneration

To regenerate an icon:

1. Delete the existing file: `rm app/assets/icons/ui_icon_<icon_id>.png`
2. Call `pixellab_create_map_object` with the same prompt (or adjust)
3. Download the new icon
4. Verify integrity

---

## Asset manifest

### Toolbar Icons

| Asset ID | Filename | Status | Generated |
|----------|----------|--------|-----------|
| production | ui_icon_production.png | ✅ Generated | 2026-03-15 |
| civilian_units | ui_icon_civilian_units.png | ✅ Generated | 2026-03-15 |
| military_units | ui_icon_military_units.png | ✅ Generated | 2026-03-15 |
| naval_units | ui_icon_naval_units.png | ☐ Pending | — |
| diplomacy | ui_icon_diplomacy.png | ✅ Generated | 2026-03-15 |
| technology | ui_icon_technology.png | ✅ Generated | 2026-03-15 |
| layer_toggle | ui_icon_layer_toggle.png | ✅ Generated | 2026-03-16 |
| home_capital | ui_icon_home_capital.png | ✅ Generated | 2026-03-16 |
| map_options | ui_icon_map_options.png | ✅ Generated | 2026-03-18 |
| treasury_coin | ui_icon_treasury_coin.png | ☐ Pending | — |

### Resource & Worker Icons (Production Panel)

Per [production-panel.md](production-panel.md) § Resource and Worker Icons.

**Food:**
| Commodity ID | Filename | Description |
|--------------|----------|-------------|
| grain | ui_icon_com_grain.png | Wheat sheaf or grain bundle |
| meat | ui_icon_com_meat.png | Meat cut or ham |

**Raw Materials:**
| Commodity ID | Filename | Description |
|--------------|----------|-------------|
| timber | ui_icon_com_timber.png | Wooden log |
| iron | ui_icon_com_iron.png | Iron ore chunk or ingot |
| wool | ui_icon_com_wool.png | Wool bundle or fleece |
| cotton | ui_icon_com_cotton.png | Cotton boll |
| coal | ui_icon_com_coal.png | Coal lump |
| sugarCane | ui_icon_com_sugar_cane.png | Sugar cane stalk |
| tobacco | ui_icon_com_tobacco.png | Tobacco leaf |
| furs | ui_icon_com_furs.png | Fur pelt |
| copper | ui_icon_com_copper.png | Copper ingot |
| tin | ui_icon_com_tin.png | Tin ingot |
| horses | ui_icon_com_horses.png | Horse head |

**Manufactured:**
| Commodity ID | Filename | Description |
|--------------|----------|-------------|
| lumber | ui_icon_com_lumber.png | Stack of lumber planks |
| castIron | ui_icon_com_cast_iron.png | Cast iron product |
| fabric | ui_icon_com_fabric.png | Fabric bolt or cloth roll |
| refinedSugar | ui_icon_com_refined_sugar.png | Sugar loaf |
| cigars | ui_icon_com_cigars.png | Cigar bundle |
| furHats | ui_icon_com_fur_hats.png | Fur hat |
| steel | ui_icon_com_steel.png | Steel ingot |
| paper | ui_icon_com_paper.png | Paper scroll or sheet |
| bronze | ui_icon_com_bronze.png | Bronze ingot |

**Riches:**
| Commodity ID | Filename | Description |
|--------------|----------|-------------|
| gold | ui_icon_com_gold.png | Gold nugget |
| silver | ui_icon_com_silver.png | Silver ingot |
| gems | ui_icon_com_gems.png | Colorful gem stones |
| diamonds | ui_icon_com_diamonds.png | Brilliant diamond |

**Advanced:**
| Commodity ID | Filename | Description |
|--------------|----------|-------------|
| spices | ui_icon_com_spices.png | Spice bags pouch |

**Workers:**
| Worker Type | Filename | Description |
|-------------|----------|-------------|
| peasant | ui_icon_worker_peasant.png | Peasant worker |
| apprentice | ui_icon_worker_apprentice.png | Apprentice worker |
| journeyman | ui_icon_worker_journeyman.png | Journeyman worker |
| master | ui_icon_worker_master.png | Master craftsman |

All icons verified: 32×32 PNG with RGBA transparency. Generated 2026-03-17.

---

## Production allocation row controls (32×32)

**Panel:** Production → Allocation recipe rows (`production_panel.dart`). **Display:** `StrictAssetIcon` with `kAppIconAssetPrefix` at ~14–16 logical px in the slider row.

**Generation:** PixelLab **`generate_image_pixflux`** (standalone UI icon, `no_background: true`) — same class of tool as [naval units](#ui_icon_naval_unitspng-3232) when `pixellab_create_map_object` is unavailable in the MCP toolchain. Colonial palette per § Style lock (`#3E1F1A`–`#5A332C` frame, `#A85C3A`–`#C87A5B` inner, `#E8C838`–`#FFED7F` gold accents).

| Asset filename | Role | Pixflux prompt (summary) |
|----------------|------|---------------------------|
| `ui_icon_production_alloc_decrement.png` | **−** stepper | pixel art minus sign button, colonial UI, terracotta/gold, transparent background |
| `ui_icon_production_alloc_increment.png` | **+** stepper | pixel art plus sign button, colonial UI, terracotta/gold, transparent background |
| `ui_icon_production_alloc_maximize.png` | **Maximize** row | fill-to-cap / stacked bars upward, colonial UI, transparent background |
| `ui_icon_production_alloc_clear.png` | **Clear** row | X or zero-row clear motif, colonial UI, transparent background |

**Semantics / l10n:** `production_allocationDecrementRecipe`, `production_allocationIncrementRecipe`, `production_allocationMaximizeRecipe`, `production_allocationClearRecipe` in `app/lib/l10n/arb/app_en.arb`.