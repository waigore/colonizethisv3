# Main Menu

**Screen ID:** `SHEL10002` — stable; do not reassign.
**SPEC/ui** — Main menu screen (CtMainMenu). Implementation: `app/lib/widgets/main_menu.dart`.
**Widgetbook:** `Main Menu` → `app/lib/widgetbook/catalog.dart`. Authority: UXD 03a (Main Menu and Shell).

---

## Widget contract

The CtMainMenu widget is presentational and accepts the following parameters. The **shell** (or parent) supplies these and handles navigation and app exit.

| Parameter | Type | Description |
|-----------|------|-------------|
| `variant` | `plain` \| `pixelArt` | Both variants use the **pixel-art component catalog** (CtNinePatchButton, CtScreenShell). **plain:** colonial colour theme only (no background illustration). **pixelArt:** pixel-art assets per table below. |
| `state` | `default` \| `afterVictory` \| `noSaves` | **default:** no subtitle; Load Game enabled when saves exist. **afterVictory:** show subtitle "Congratulations, you won your last game." **noSaves:** Load Game disabled with explanatory tooltip/helper text. |
| `version` | string | Version text shown in footer (e.g. `v1.0.0`). The shell passes this through the shared debug-aware formatter so `CT_DEBUG_CONSOLE=true` renders `v1.0.0 (debug)`. |
| `onNewGame` | callback | Invoked when user taps New Game. |
| `resumeGameVisible` | bool | When true, show **Resume game** between New Game and Load Game. When false, omit the control entirely (not disabled). |
| `onResumeGame` | callback | Invoked when user taps **Resume game** (only when `resumeGameVisible` is true). |
| `onLoadGame` | callback | Invoked when user taps Load Game (when enabled). |
| `onSettings` | callback | Invoked when user taps Settings. |
| `onQuit` | callback | Invoked when user taps Quit. |

---

## Trigger conditions

- **Host:** [`shell-screen.md`](shell-screen.md) at `Routes.shell` always mounts `CtMainMenu` with shell-supplied callbacks.
- **Return-from-game:** Pause exit or [`victory-overlay.md`](victory-overlay.md) navigates to shell; menu rebuilds with updated `resumeGameVisible`.

---

## How this spec satisfies UXD 03a

**User stories.** The main menu supports: single tap **New Game** (one action to start fresh); **Load Game** (continue or pick a save); **Settings** (open from menu); **Quit** (exit app). Return-from-in-game is satisfied by the shell/navigation: pause and Victory Screen (03l) navigate back to this screen, which is the destination.

**Acceptance criteria.** (1) **Visibility:** The app shell shows the Main Menu as the first screen after any splash; the widget displays New Game, Load Game, Settings, and Quit, and optionally **Resume game** (see below). (2) **Resume game:** When a valid auto-save exists (`SPEC/program/save-load.md` § Auto-save slot), the shell sets `resumeGameVisible` to true; the widget shows **Resume game** **below New Game** and above Load Game. When no valid auto-save exists, `resumeGameVisible` is false and the widget does not show **Resume game**. (3) **Load Game:** When no manual saves exist, Load Game is disabled and shows explanatory tooltip or helper text; when saves exist, it is enabled. **Resume game** visibility is independent of manual saves. (4) **Navigation:** The widget does not perform routing; it exposes callbacks (`onNewGame`, `onResumeGame`, `onLoadGame`, `onSettings`, `onQuit`). The shell wires: New Game → **combined nation & leader dialog** (`OpenDialogEvent` id `new_game_leader_selection`, `NewGameLeaderSelectionDialog`; same six-slot rules as [Game Setup](game-setup.md) § Shell new game dialog) → [Game Initializing](game-initializing.md) → [Empire overview](empire-overview.md); **Resume game** → load auto-save slot → Empire overview (same entry conditions as a normal load); Load Game → Load list (03b) → Empire overview on load; Settings → Settings (03c); Quit → app exit. (5) **Return from game:** Pause "Exit to Main Menu" and Victory "Return to Main Menu" both navigate to this screen; the shell clears in-memory game state as needed. The shell re-evaluates `resumeGameVisible` when the menu is shown so **Resume game** appears immediately if an auto-save was written during play (no app restart).

**Debug indicator formatting.** `CT_DEBUG_CONSOLE` is the sole mode flag for display suffix behavior. The shell must route version display through the shared debug-aware formatter; when the compile-time flag is true, all user-visible app version labels append ` (debug)` as a terminal suffix, and when false/undefined, labels remain unchanged.

**Shell behaviour.** Shell responsibility (first screen after splash, callback wiring, clear in-memory game state on return from game) is defined in the dedicated UI spec [shell-screen.md](shell-screen.md) and the app TDD: [ctdev-app.md](../program/ctdev-app.md) (app screens and navigation). For Flutter shell and route ownership see [repo-and-packages.md](../program/repo-and-packages.md).

**Interaction.** The main menu widget is presentational: it receives callbacks for each action. The shell (or parent) supplies `onNewGame`, `onResumeGame` (when resume is shown), `onLoadGame`, `onSettings`, `onQuit` and handles navigation and app exit. No routing logic lives in the widget.

**Automated tests.** Widget tests in `app/test/screen_spec_acceptance_test.dart` assert the acceptance criteria above (visibility, Load Game state/tooltip, Resume visibility, callbacks). Run: `flutter test test/screen_spec_acceptance_test.dart` from the app package.

---

## Layout / wireframe

Positions, layout, and hierarchy (per UXD 03a; 44dp min touch targets).

**Default:**

```text
+------------------------------------------------------+
|                     GAME LOGO                        |
|                "ColonizeThis V3"                     |
|                                                      |
|  [ New Game ]                                        |
|  [ Resume game ]  (only if auto-save exists)         |
|  [ Load Game ]    (disabled if no saves)             |
|  [ Settings ]                                        |
|                                                      |
|                              v1.0.0                  |
|                              [ Quit ]                |
+------------------------------------------------------+
```

**After victory:** Same layout; add subtitle line below title: "Congratulations, you won your last game."

**Regions (UXD 07–style):** canvas full-screen; logo_region (top, title + optional subtitle); buttons_region (column: New Game, Load Game, Settings); footer_region (version text, Quit button).

**Layout (pixel-art variant):** The menu content column is constrained to a **maximum width of 400 dp** (content only; padding is additional). Buttons and logo area use this width so that the button asset is never upscaled on typical screens. Content is **centered** (e.g. `Center` + `ConstrainedBox(maxWidth: 400)` in code). All buttons use `CtNinePatchButton`; **Material buttons (ElevatedButton, TextButton, etc.) are not permitted for this screen.**

**Mobile:** See [mobile-adaptation.md](mobile-adaptation.md). The main menu scrolls when the viewport is short (wrap content in `SingleChildScrollView`). No breakpoint layout change; vertical list suits narrow width. Safe area and 44 dp touch targets apply.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| `ShellScreen` | `Routes.shell` is active | `CtMainMenu` fills the route with shell callbacks. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| New Game | Always | `onNewGame` | Shell opens leader-selection dialog. |
| Resume game | `resumeGameVisible == true` | `onResumeGame` | Shell loads auto-save and navigates to game. |
| Load Game | Saves exist | `onLoadGame` | Shell loads game or no-op when disabled. |
| Settings | Always | `onSettings` | Shell opens Settings (stub). |
| Quit | Always | `onQuit` | App exit. |

---

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `SHEL10002` | `default` | `state == default` | No subtitle; Load enabled when saves exist. |
| `SHEL10002a` | `afterVictory` | `state == afterVictory` | Subtitle "Congratulations, you won your last game." |
| `SHEL10002b` | `noSaves` | `state == noSaves` | Load disabled with helper/tooltip. |
| — | `plain` / `pixelArt` | `variant` param | Pixel-art assets per tables below when `pixelArt`. |

---

## Pixel-art assets

When the pixel-art variant is used, the following assets are required. Check `assets/images/` first; only generate missing or intentionally replaced assets (ration generation per UI design rule).

| Asset id | pixellab_type | size (px) | Notes |
|----------|---------------|----------|-------|
| main_menu_logo | ui_element | 256×64 | **Textless** decorative banner; the title "ColonizeThis V3" is **rendered in Flutter** over the asset (Option B). |
| main_menu_button | ui_element | 400×48 | Matches max content width 400 dp × button height 48 dp for 1:1 at that width; on narrower screens the image is scaled down only (no upscale = no blur). |
| main_menu_panel | ui_element | 64×64 | (Optional.) Wooden panel / frame for content area; carved wood bevel per UXD 02. |

**Naming in app:** Snake_case under `assets/images/` per asset rule: `ui_main_menu_logo.png`, `ui_main_menu_button.png`, `ui_main_menu_panel.png`.

**Style lock:** UXD 02 (palette, no anti-aliasing, 1x grid, 16th/17th century); UXD 06 for PixelLab prompt injection when generating.

---

## Main menu pixel aesthetic

Single source of truth for look/feel, colour palette, and asset pipeline for the pixel-art variant. Style reference: `ui_main_menu_button.png` only; other existing PNGs are disregarded for look-and-feel.

### Aesthetic

16th-century European / colonial study room. Sturdy, slightly luxurious; dark wood and golden embellishments; pixel art, no anti-aliasing, 1x grid (align with UXD 02).

### Color palette (from reference button)

- **Frame:** deep reddish-brown (e.g. `#3E1F1A`–`#5A332C`), subtle wood grain.
- **Inner panel:** warmer reddish-brown (e.g. `#A85C3A`–`#C87A5B`), lighter wood.
- **Accents:** bright gold filigree — highlight `#E8C838`–`#FFED7F`, shadow `#B08B2A`; dark edge `#7D472D`.

Use this palette as the single source of truth for all generated assets.

### Background

Interior of a 16th-century study: statue, globe, drawing table, windows/doors, and other period-appropriate elements; same palette and pixel style. Asset: `ui_main_menu_background.png`.

### Logo

**Fluttering flag with text "ColonizeThis".** Colonial-style fabric flag (not wooden banner); dark reddish brown and gold brass; text "ColonizeThis" on the asset. Optional: Flutter can overlay " V3" or full title. Asset: `ui_main_menu_logo.png` (static), `ui_main_menu_logo_animated.png` (spritesheet when available).

**Logo animation:** flag fluttering in wind. **Primary:** PixelLab `animate_with_text` with static flag as reference, action "flag fluttering in wind" / "gentle waving"; output spritesheet. **Fallback:** If PixelLab output is unusable, Flutter-only — no spritesheet; subtle periodic `Transform` on static logo. Asset when used: `ui_main_menu_logo_animated.png`.

### Buttons

Base asset: `ui_main_menu_button.png`. **Idle:** subtle glint/shimmer (PixelLab spritesheet; Flutter plays it). **Hover (pointer enter):** (1) Gentle bobbing starts, stops on pointer exit — Flutter only (`Transform.translate`, 2–3 px, subtle). (2) Hovered button uses a slightly darker palette (Flutter `ColorFilter` or semi-transparent dark overlay). **On hover exit:** bobbing stops, palette returns to normal. All motion and contrast changes stay subtle. Glint spritesheet when used: `ui_main_menu_button_animated.png`.

### Typography (initial)

Use a **serif font** for title and button labels in the pixel-art variant (basic colonial theme; e.g. Cinzel, Merriweather, or bundled serif). Pixel font: to be defined and created later; out of scope for this spec.

### MCP tool mapping

| Asset / task | MCP tool | Purpose |
|--------------|----------|---------|
| Background (study room) | **PixelLab Bitforge** | Generate from description; `style_image_path` = button PNG; `style_strength` ~60–80. |
| Logo (static, fluttering flag) | **PixelLab Pixflux** | Colonial flag with text "ColonizeThis"; 256×64. |
| Logo animation (flag fluttering) | **PixelLab `animate_with_text`** (primary) / **Flutter** (fallback) | Primary: flag as reference, action "flag fluttering in wind"; spritesheet. Fallback: Flutter-only Transform. |
| Optional panel / frame | **PixelLab Bitforge** | Same style reference. |
| Palette extraction | **pixel-mcp `analyze_reference`** | Optional; refine Bitforge prompts. |
| Resize / composite | **Imagesorcery** | Only if needed. |
| Button contrast/wood (post-process) | **pytool** | [pytool-image-tools.md](pytool-image-tools.md): `button_contrast_wood_pil.py` for PNG; `button_contrast_wood.py` for pixel JSON. Run with `pytool/.venv` (or uv in pytool) activated. |
| Button animation spritesheet (glint) | **PixelLab `animate_with_text`** | Glint/shimmer only; button as reference; n_frames 4–6. |
| Button playback, hover bobbing/tint | **Flutter** | Idle: play glint spritesheet. Hover: bobbing + darker tint. |
| Font (colonial theme) | **None (asset / Google Fonts)** | Serif (e.g. Cinzel, Merriweather). Pixel font deferred. |

All new pixel-art imagery (background, logo, optional panel) is generated with **Bitforge** using the button PNG as the sole style reference. Logo animation: **PixelLab `animate_with_text`** (primary) or Flutter-only (fallback). Button glint: **PixelLab `animate_with_text`**.

### Pixel-art asset table (extended)

| Asset id | size (px) | Notes |
|----------|-----------|-------|
| main_menu_background | e.g. 640×360 / 800×450 | 16th-century study room interior. Bitforge, style ref = button. |
| main_menu_logo | 256×64 | Fluttering flag with text "ColonizeThis". Pixflux. |
| main_menu_logo_animated | (spritesheet) | Optional. Flag fluttering; PixelLab `animate_with_text` primary / Flutter fallback. |
| main_menu_button | 400×48 | Existing. Static fallback. |
| main_menu_button_animated | (spritesheet) | Optional. Glint only. PixelLab `animate_with_text`. |
| main_menu_panel | 64×64 | Optional. Wooden panel. |

---

### PixelLab prompts (exact wording)

For each asset, the **exact** wording used in PixelLab is recorded below so regeneration is reproducible.

**main_menu_background (Bitforge or Pixflux), then upscale to 640×360**

- description: `Pixel art scene. One wooden statue visible in the room. One globe on a wooden stand. One drawing table with papers. Window with daylight. Wooden walls and paneling. Door. 16th century study interior. Dark reddish brown wood and gold brass accents. Crisp pixels, no anti-aliasing.` (Bitforge: add "Same color palette as reference.")
- **Bitforge:** style_image_path = button PNG (resize to 128×128); style_strength 70; output 128×128; then resize to 640×360.
- **Pixflux:** width 256, height 144; text_guidance_scale 12; outline single color black outline; shading basic shading; detail medium detail; then resize to 640×360.

**main_menu_logo (fluttering flag with text "ColonizeThis"), 256×64**

- **Pixflux (used):** description: `Pixel art colonial style flag or banner with text ColonizeThis. 16th 17th century, dark reddish brown and gold brass, fabric flag, crisp pixel art no anti-aliasing, limited palette. No wooden frame.` width 256, height 64; text_guidance_scale 12; outline: single color black outline; shading: basic shading; detail: medium detail.
- **Logo animation (PixelLab `animate_with_text`):** description: `Colonial style fabric flag with text ColonizeThis, dark brown and gold`; action: `flag fluttering in wind, gentle waving`; reference_image_path: static logo (resize to 128×128 if API requires square); width 128, height 128; n_frames 6; save_to_file: `ui_main_menu_logo_animated.png`. If API rejects non-square, use 128×128 reference and output then resize/stretch to 256×64 for display.

**main_menu_button, 400×48**

- description: `Wooden UI button with brass corners, pixel art game UI, 16th 17th century period look, dark wood and gold brass, suitable for menu buttons, crisp pixel art no anti-aliasing, limited palette parchment colonial brown dark wood brass.`
- outline: single color black outline; shading: basic shading; detail: medium detail; text_guidance_scale: 12.

**main_menu_panel (optional), 64×64**

- description: `Wooden panel frame for content area, carved wood bevel, 16th 17th century pixel art UI, dark wood grain with brass or iron corners, crisp edges no anti-aliasing, UXD palette parchment colonial brown dark wood.`
- outline: single color black outline; shading: basic shading; detail: medium detail; text_guidance_scale: 12.

---

## Components

- `CtMainMenu` — presentational menu (`app/lib/widgets/main_menu.dart`).
- `CtNinePatchButton`, `CtScreenShell` — pixel-art catalog per [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md).
- Registered in `app/widget_catalog.json` as CtMainMenu (category: screen).

---

## Widgetbook

Folder: **Main Menu** (`app/lib/widgetbook/catalog.dart`). Use cases: **Default**, **After victory**, **No saves**, **Pixel art (mobile)** per variant table.

---

## Acceptance criteria

See **How this spec satisfies UXD 03a** above for full Given–When–Then ACs. Automated tests: `app/test/screen_spec_acceptance_test.dart`.
