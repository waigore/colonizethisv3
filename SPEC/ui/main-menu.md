# Main Menu

**SPEC/ui** — Main menu screen. Authority: UXD 03a (Main Menu and Shell). Catalog widget: CtMainMenu.

---

## Widget contract

The CtMainMenu widget is presentational and accepts the following parameters. The **shell** (or parent) supplies these and handles navigation and app exit.

| Parameter | Type | Description |
|-----------|------|-------------|
| `variant` | `plain` \| `pixelArt` | **plain:** standard Flutter/colonial theme (no pixel-art assets). **pixelArt:** pixel-art assets per table below. |
| `state` | `default` \| `afterVictory` \| `noSaves` | **default:** no subtitle; Load Game enabled when saves exist. **afterVictory:** show subtitle "Congratulations, you won your last game." **noSaves:** Load Game disabled with explanatory tooltip/helper text. |
| `version` | string | Version text shown in footer (e.g. `v1.0.0`). |
| `onNewGame` | callback | Invoked when user taps New Game. |
| `onLoadGame` | callback | Invoked when user taps Load Game (when enabled). |
| `onSettings` | callback | Invoked when user taps Settings. |
| `onQuit` | callback | Invoked when user taps Quit. |

---

## How this spec satisfies UXD 03a

**User stories.** The main menu supports: single tap **New Game** (one action to start fresh); **Load Game** (continue or pick a save); **Settings** (open from menu); **Quit** (exit app). Return-from-in-game is satisfied by the shell/navigation: pause and Victory Screen (03l) navigate back to this screen, which is the destination.

**Acceptance criteria.** (1) **Visibility:** The app shell shows the Main Menu as the first screen after any splash; the widget displays New Game, Load Game, Settings, and Quit. (2) **Load Game:** When no saves exist, Load Game is disabled and shows explanatory tooltip or helper text; when saves exist, it is enabled. (3) **Navigation:** The widget does not perform routing; it exposes callbacks (`onNewGame`, `onLoadGame`, `onSettings`, `onQuit`). The shell wires: New Game → Game Setup (03b), Load Game → Load list (03b), Settings → Settings (03c), Quit → app exit. (4) **Return from game:** Pause "Exit to Main Menu" and Victory "Return to Main Menu" both navigate to this screen; the shell clears in-memory game state as needed.

**Shell behaviour.** Shell responsibility (first screen after splash, callback wiring, clear in-memory game state on return from game) is defined in the app TDD: [ctdev-app.md](../program/ctdev-app.md) (app screens and navigation). For Flutter shell and route ownership see [repo-and-packages.md](../program/repo-and-packages.md).

**Interaction.** The main menu widget is presentational: it receives callbacks for each action. The shell (or parent) supplies `onNewGame`, `onLoadGame`, `onSettings`, `onQuit` and handles navigation and app exit. No routing logic lives in the widget.

---

## Wireframe

Positions, layout, and hierarchy (per UXD 03a; 44dp min touch targets).

**Default:**

```text
+------------------------------------------------------+
|                     GAME LOGO                        |
|                "ColonizeThis V3"                     |
|                                                      |
|  [ New Game ]                                        |
|  [ Load Game ]    (disabled if no saves)             |
|  [ Settings ]                                        |
|                                                      |
|                              v1.0.0                  |
|                              [ Quit ]                |
+------------------------------------------------------+
```

**After victory:** Same layout; add subtitle line below title: "Congratulations, you won your last game."

**Regions (UXD 07–style):** canvas full-screen; logo_region (top, title + optional subtitle); buttons_region (column: New Game, Load Game, Settings); footer_region (version text, Quit button).

**Layout (pixel-art variant):** The menu content column is constrained to a **maximum width of 400 dp** (content only; padding is additional). Buttons and logo area use this width so that the button asset is never upscaled on typical screens. Content is **centered** (e.g. `Center` + `ConstrainedBox(maxWidth: 400)` in code).

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

### PixelLab prompts (exact wording)

For each asset, the **exact** wording used in PixelLab `generate_image_pixflux` is recorded below so regeneration is reproducible.

**main_menu_logo (textless banner), 256×64**

- description: `Colonial 16th 17th century pixel art wooden banner or title frame, carved wood with brass corner rivets, no text no letters, parchment and dark wood and gold brass, crisp pixel art, UI element, limited palette.`
- outline: single color black outline; shading: flat shading; detail: medium detail; text_guidance_scale: 12.

**main_menu_button, 400×48**

- description: `Wooden UI button with brass corners, pixel art game UI, 16th 17th century period look, dark wood and gold brass, suitable for menu buttons, crisp pixel art no anti-aliasing, limited palette parchment colonial brown dark wood brass.`
- outline: single color black outline; shading: basic shading; detail: medium detail; text_guidance_scale: 12.

**main_menu_panel (optional), 64×64**

- description: `Wooden panel frame for content area, carved wood bevel, 16th 17th century pixel art UI, dark wood grain with brass or iron corners, crisp edges no anti-aliasing, UXD palette parchment colonial brown dark wood.`
- outline: single color black outline; shading: basic shading; detail: medium detail; text_guidance_scale: 12.

---

## Widget catalog

Once implemented, the main menu is registered in `app/widget_catalog.json` as CtMainMenu (category: screen, source: pipeline), with `dart_file_path` and optional `widgetbook_story_path` for discovery.
