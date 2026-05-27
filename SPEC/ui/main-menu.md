# Main Menu

**Screen ID:** `SHEL10002` — stable; do not reassign.
**SPEC/ui** — Main menu screen (CtMainMenu). Implementation: `app/lib/widgets/main_menu.dart`.
**Widgetbook:** `Main Menu` → `app/lib/widgetbook/catalog.dart`. Authority: UXD 03a (Main Menu and Shell).

**Mockup:** [mockups/SHEL10002-main-menu.html](mockups/SHEL10002-main-menu.html)
---

## Widget contract

The CtMainMenu widget is presentational and accepts the following parameters. The **shell** (or parent) supplies these and handles navigation and app exit.

| Parameter | Type | Description |
|-----------|------|-------------|
| `variant` | `plain` \| `pixelArt` | Both variants use the **Ct-* component catalog** (CtNinePatchButton, CtScreenShell). **plain:** theme scaffold color only (no background illustration, no compass rose, no fleur-de-lis, no brass divider, no scroll brackets — see the **Variant rendering** table below). **pixelArt:** dark editorial-monocle layout per mockup `SPEC/ui/mockups/SHEL10002-main-menu.html` (dark SVG collage, CtCompassRose emblem, fleur-de-lis-flanked title, CtBrassDivider, wood-panel `CtNinePatchButton`, scroll brackets, footer Quit chip). |
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

**Acceptance criteria (Given–When–Then).**

Visibility:

- Given the app shell has finished initialisation and any splash screen has dismissed, when the shell mounts the first user-facing screen, then the UI layer renders `CtMainMenu` as that first screen.
- Given `CtMainMenu` is mounted in any `state` (`default`, `afterVictory`, `noSaves`), when the user views the menu, then the UI layer displays the **New Game**, **Load Game**, **Settings**, and **Quit** controls.

Resume game visibility:

- Given a valid auto-save slot exists per `SPEC/program/save-load.md` § Auto-save slot, when the shell builds `CtMainMenu`, then the shell passes `resumeGameVisible: true` to the widget.
- Given `CtMainMenu` receives `resumeGameVisible: true`, when the widget renders the button column, then the UI layer renders the **Resume game** control between **New Game** (immediately above) and **Load Game** (immediately below).
- Given no valid auto-save slot exists per `SPEC/program/save-load.md` § Auto-save slot, when the shell builds `CtMainMenu`, then the shell passes `resumeGameVisible: false` to the widget.
- Given `CtMainMenu` receives `resumeGameVisible: false`, when the widget renders the button column, then the UI layer renders no **Resume game** control (the control is omitted, not merely disabled).

Load Game state:

- Given the save store contains zero manual save slots, when the widget renders `CtMainMenu`, then the UI layer renders the **Load Game** control as disabled and attaches an explanatory tooltip or helper text indicating no saves are available.
- Given the save store contains at least one manual save slot, when the widget renders `CtMainMenu`, then the UI layer renders the **Load Game** control as enabled.
- Given the **Resume game** control's visibility is governed solely by the auto-save slot, when the presence of manual saves changes (added or removed), then the shell does not change `resumeGameVisible` in response (Resume game visibility remains independent of manual saves).

Navigation (widget exposes callbacks; shell performs routing):

- Given `CtMainMenu` is rendered with non-null `onNewGame`, when the user taps **New Game**, then the widget invokes `onNewGame` and performs no routing inside the widget itself.
- Given the shell has wired `onNewGame`, when `onNewGame` fires, then the shell emits `OpenDialogEvent(id: 'new_game_leader_selection')` to mount `NewGameLeaderSelectionDialog` per [Game Setup](game-setup.md) § Shell new game dialog, then on confirm navigates to [Game Initializing](game-initializing.md) and on initialisation complete to [Empire overview](empire-overview.md).
- Given `CtMainMenu` is rendered with `resumeGameVisible: true` and a non-null `onResumeGame`, when the user taps **Resume game**, then the widget invokes `onResumeGame`.
- Given the shell has wired `onResumeGame`, when `onResumeGame` fires, then the shell loads the auto-save slot under the same entry conditions as a normal load and then navigates to [Empire overview](empire-overview.md).
- Given the **Load Game** control is enabled and `CtMainMenu` is rendered with non-null `onLoadGame`, when the user taps **Load Game**, then the widget invokes `onLoadGame`.
- Given the shell has wired `onLoadGame`, when `onLoadGame` fires, then the shell navigates to the Load list (UXD 03b) and, on a successful load selection, navigates to [Empire overview](empire-overview.md).
- Given `CtMainMenu` is rendered with non-null `onSettings`, when the user taps **Settings**, then the widget invokes `onSettings` and the shell navigates to the Settings screen (UXD 03c).
- Given `CtMainMenu` is rendered with non-null `onQuit`, when the user taps **Quit**, then the widget invokes `onQuit` and the shell exits the application.

Return from game and resume visibility refresh:

- Given the user is in the pause menu during an active game, when the user activates **Exit to Main Menu**, then the shell clears in-memory game state and navigates back to `CtMainMenu`.
- Given the user is on the Victory Screen (UXD 03l), when the user activates **Return to Main Menu**, then the shell clears in-memory game state and navigates back to `CtMainMenu`.
- Given an auto-save slot was written during play and the user has returned to the main menu without restarting the app, when the shell mounts `CtMainMenu`, then the shell re-evaluates `resumeGameVisible` against the current auto-save slot so that **Resume game** appears immediately (no app restart required).

Variant rendering (mockup-aligned dark editorial-monocle):

- Given `CtMainMenu` is rendered with `variant: pixelArt`, when the widget builds, then the UI layer renders the dark SVG collage background, a `CtCompassRose` above the title, a `CtFleurDeLisOrnament` on each side of the "ColonizeThis" title, a `CtBrassDivider` between the logo and buttons regions, wood-panel `CtNinePatchButton` instances for the menu actions, and scroll-bracket gutters flanking the buttons region.
- Given `CtMainMenu` is rendered with `variant: plain`, when the widget builds, then the UI layer renders no SVG collage, no `CtCompassRose`, no `CtFleurDeLisOrnament`, no `CtBrassDivider`, no scroll-bracket gutters, and no wood-panel chrome on the buttons; only the theme scaffold color, the title text, and plain `CtNinePatchButton` controls are shown.
- Given the `pixelArt` variant is rendered on a viewport ≤ 430 dp wide, when the buttons region builds, then the wood-panel button labels render with reduced `letter-spacing` (`0.04em` instead of `0.08em`) per the mockup responsive rule.
- Given `SPEC/ui/main-menu.md` is read after the S0 spec update, when the **Main menu aesthetic (dark editorial-monocle)** section is inspected, then it describes the dark editorial-monocle redesign and embeds (or references) the **Variant rendering** table; no remaining narrative refers to the retired 16th-century pixel-art study-room aesthetic, `ui_main_menu_background.png`, or the legacy PixelLab prompts for this screen.

**Debug indicator formatting.** `CT_DEBUG_CONSOLE` is the sole mode flag for display suffix behavior. The shell must route version display through the shared debug-aware formatter; when the compile-time flag is true, all user-visible app version labels append ` (debug)` as a terminal suffix, and when false/undefined, labels remain unchanged.

**Shell behaviour.** Shell responsibility (first screen after splash, callback wiring, clear in-memory game state on return from game) is defined in the dedicated UI spec [shell-screen.md](shell-screen.md) and the app TDD: [ctdev-app.md](../program/ctdev-app.md) (app screens and navigation). For Flutter shell and route ownership see [repo-and-packages.md](../program/repo-and-packages.md).

**Interaction.** The main menu widget is presentational: it receives callbacks for each action. The shell (or parent) supplies `onNewGame`, `onResumeGame` (when resume is shown), `onLoadGame`, `onSettings`, `onQuit` and handles navigation and app exit. No routing logic lives in the widget.

**Automated tests.** Widget tests in `app/test/screen_spec_acceptance_test.dart` assert the acceptance criteria above (visibility, Load Game state/tooltip, Resume visibility, callbacks). Run: `flutter test test/screen_spec_acceptance_test.dart` from the app package.

---

## Layout / wireframe

Positions, layout, and hierarchy (per UXD 03a; mockup `SPEC/ui/mockups/SHEL10002-main-menu.html`; 44dp min touch targets).

**Pixel-art variant (mockup target):**

```text
+------------------------------------------------------+   <- background_region
|  (dark SVG collage: telescope, compass-rose, anchor, |       editorial-monocle bg
|   sextant, hourglass, muskets, cannon, ship's wheel, |       (--bg / --bg-deep)
|   soldier silhouette, wave bands, trade-route arcs)  |
|                                                      |   <- logo_region
|             "A GAME OF EMPIRE & DISCOVERY"           |       (eyebrow, --muted)
|                       [ CtCompassRose ]              |       (compass emblem)
|         🜲    ColonizeThis    🜲                     |       (title flanked by
|                                                      |        CtFleurDeLisOrnament)
|        Congratulations, you won your last game.      |       (afterVictory only,
|                                                      |        --muted italic)
|                ====<>====                            |       CtBrassDivider
|                                                      |   <- buttons_region
|   |  [ New Game ]                  |                 |       (wood-panel buttons,
|   |  [ Resume Game ] (if auto-save)|                 |        scroll brackets at
|   |  [ Load Game ]   (or tooltip)  |                 |        left/right gutters)
|   |  [ Settings ]                  |                 |
|                                                      |
|                                       v3.0.0  [Quit] |   <- footer_region
+------------------------------------------------------+
```

**Plain variant:** same regions, but background_region renders only the theme scaffold color (no SVG collage), the logo_region omits the eyebrow / compass / fleur-de-lis / brass divider, and the buttons_region omits the scroll brackets and wood-panel chrome (see the **Variant rendering** table for the per-element mapping).

**Regions (UXD 07–style):** background_region (full-screen z-0 canvas); logo_region (top column: eyebrow → CtCompassRose → fleur-de-lis title row → optional subtitle → CtBrassDivider); buttons_region (centered column of CtNinePatchButton; scroll-bracket gutters at left/right edges in pixelArt); footer_region (version text left + Quit button right).

**Layout:** The menu content column is constrained to a **maximum width of 400 dp** (content only; padding is additional). Content is **centered** (`Center` + `ConstrainedBox(maxWidth: 400)` in code). All buttons use `CtNinePatchButton`; **Material buttons (ElevatedButton, TextButton, etc.) are not permitted for this screen.**

---

## Variant rendering

Normative mapping for what the `plain` and `pixelArt` variants render for each visual element. This table is the single source of truth for variant divergence; `app/lib/widgets/main_menu.dart` and the Widgetbook stories must match it.

| Element | `plain` variant | `pixelArt` variant |
|---------|-----------------|--------------------|
| Background | Theme scaffold color only (no SVG collage, no compass-rose watermark, no grid overlay) | Dark SVG collage (telescope, muskets, anchor, sextant, hourglass, cannon, ship's wheel, soldier silhouette, wave bands, dashed trade-route arcs) over `editorialMonocle` `--bg` |
| Eyebrow text | Hidden | Visible: "A Game of Empire & Discovery" (small-caps, `--muted`) |
| Compass rose emblem | Hidden | `CtCompassRose` (8 arms + medallion) above the title row |
| Title "ColonizeThis" | Plain `Text` (theme heading style) | Display-font title flanked left and right by `CtFleurDeLisOrnament` |
| After-victory subtitle | Plain `Text` (italic, `bodyMedium`) | Plain `Text` (italic, `--muted`) below the title row |
| Brass divider | Hidden (no divider; standard spacing only) | `CtBrassDivider` between the logo region and the button panel |
| Buttons | `CtNinePatchButton` with default chrome | Wood-panel `CtNinePatchButton` (gradient, brass corner brackets, engraved text, hover glow per #2859 R2 / S2) |
| Scroll brackets flanking buttons | Hidden | Visible bracket ornaments at the left/right gutters of the button panel |
| Quit button | Standard small `CtNinePatchButton` | Secondary, smaller, muted, border-only (`--muted` foreground, no brass corners) |
| Footer version text | Theme `bodySmall` | Monospace (`--font-mono`), `--muted` token from #2858 |

For both variants the widget contract (`variant`, `state`, `version`, callbacks, `resumeGameVisible`) is unchanged.

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
| — | `plain` / `pixelArt` | `variant` param | Per **Variant rendering** table: `pixelArt` adds dark SVG collage background, `CtCompassRose`, fleur-de-lis flanking, `CtBrassDivider`, wood-panel buttons, scroll brackets, and `--muted` Quit chip; `plain` renders the theme scaffold only with standard `CtNinePatchButton` controls. |

---

## Main menu aesthetic (dark editorial-monocle)

Single source of truth for look/feel, colour palette, and decorative primitives of the `pixelArt` variant. The mockup `SPEC/ui/mockups/SHEL10002-main-menu.html` is the visual reference; this section governs how that mockup is realised in Flutter against the `editorialMonocle` theme (issue #2858) and Ct-* catalog primitives (issue #2859 + this issue).

### Aesthetic

Late-Victorian / editorial-monocle dark theme: deep wood-and-brass palette, single-page composition with a heavy background collage, decorative compass-rose emblem above a fleur-de-lis-flanked title, brass divider, and wood-panel buttons. **No** 16th-century pixel-art assets (the prior `ui_main_menu_background.png` / `ui_main_menu_logo.png` / pixel button reference is retired for this screen). All chrome is rendered via Flutter `CustomPainter` / `CtNinePatchButton` against the editorial-monocle palette.

### Color palette (single source of truth)

All colors resolve from the canonical [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md) § Editorial-monocle palette tokens (delivered by issue #2858):

- **Backgrounds:** `--bg` (scaffold), `--bg-deep` (collage gradient lows, medallion pinhole).
- **Surfaces:** `--surface` and `--surface-lite` (wood-panel button gradient stops).
- **Accents (brass):** `--accent` (compass rose arms, divider diamond, button corner highlights), `--accent-dim` (fleur-de-lis flourish, divider gradient, scroll brackets), `--accent-bright` (divider outline, button hover glow).
- **Text:** `--fg` (button labels), `--muted` (eyebrow, subtitle, footer version, Quit button label).

Hard-coded hex literals are forbidden in `app/lib/widgets/main_menu.dart` and the supporting Ct-* primitives; tests assert against `EditorialMonoclePalette` tokens.

### Background

Dark SVG collage rendered via a Flutter `CustomPainter` (`_MainMenuCollagePainter`, S2): telescope, crossed muskets, anchor, sextant, hourglass, cannon, ship's wheel, soldier silhouette, layered wave bands, and dashed trade-route arcs. Painted in `--accent` at low opacity over the scaffold `--bg`. **No external SVG asset is required** — primitives mirror the inline `<svg class="collage-svg">` block of the mockup.

### Logo region

- **Eyebrow text** "A GAME OF EMPIRE & DISCOVERY" — small-caps, `--muted`, display font.
- **Compass rose emblem** — `CtCompassRose` (S1; see [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md)). Centered above the title row at the default `48 dp` size, scaling to `clamp(32, 6vw, 48) dp` on responsive layouts.
- **Title row** — display-font "ColonizeThis" headline flanked by `CtFleurDeLisOrnament` (S4) at default `24 x 32 dp`. Title color: `--accent`; ornaments: `--accent-dim` at 0.6 alpha.
- **Subtitle** (afterVictory only) — italic, `--muted`.
- **Brass divider** — `CtBrassDivider` (issue #2859, R7) below the subtitle / above the buttons region.

### Buttons region

- Each menu entry uses a wood-panel `CtNinePatchButton` (issue #2859 S2 enhancement): linear gradient `--surface-lite` → `--surface` → `--bg-deep` top-to-bottom, top/bottom `--accent-dim` borders, brass corner brackets, engraved text shadow, hover glow.
- **Scroll brackets** flank the buttons column at left/right gutters: thin vertical bars with `--accent-dim` gradient bookended by tiny ornamental dots. Implemented inline in `CtMainMenu.build()` (S5).
- **Load Game disabled state:** `Tooltip` wrapping the disabled wood-panel button: "No saved games found." (per [`acceptance criteria`](#acceptance-criteria)).

### Footer region

- **Version text** — left aligned, monospace (`--font-mono`), `--muted`.
- **Quit button** — right aligned, secondary `CtNinePatchButton` configuration: smaller height, `--muted` foreground, border-only chrome (no brass corner brackets).

### Typography

Display font: `Iowan Old Style, Cinzel, Charter, Georgia, serif` (mirrors mockup `--font-display`). Monospace: `SF Mono, ui-monospace, Menlo, monospace` (mockup `--font-mono`). Both stacks resolve through `AppThemes.editorialMonocle` (issue #2858).

### Responsive rules

- **Max content width:** 400 dp (mockup `--menu-max: 400px`). Content is centered and additional outer padding may be applied per `CtScreenShell` conventions.
- **Letter spacing on narrow viewports:** Below `430 dp` viewport width the wood-panel button labels reduce `letter-spacing` from `0.08em` to `0.04em` (mockup `@media` rule). Mobile rules: see [mobile-adaptation.md](mobile-adaptation.md).

### Decorative-only primitives (no assets)

| Primitive | Source | Mockup reference |
|-----------|--------|------------------|
| `CtCompassRose` | `app/lib/widgets/ct_compass_rose.dart` | `.compass-rose` / `.compass-rose .arm` / `.compass-rose .medallion` / `.compass-rose .ring` |
| `CtFleurDeLisOrnament` | `app/lib/widgets/ct_fleur_de_lis_ornament.dart` | `<svg class="title-flank">` block |
| `CtBrassDivider` | `app/lib/widgets/ct_brass_divider.dart` (issue #2859) | `.brass-divider` |
| `_MainMenuCollagePainter` (S2; not yet landed) | `app/lib/widgets/main_menu.dart` | `<svg class="collage-svg">` block |
| Scroll-bracket gutters (S5; not yet landed) | inline in `main_menu.dart` | `.buttons-region::before` / `.buttons-region::after` |

All decorative primitives are self-painted; **no PixelLab / Bitforge / Pixflux asset generation is required** for the `pixelArt` main menu. The legacy `ui_main_menu_background.png` / `ui_main_menu_logo.png` / `ui_main_menu_button.png` / `ui_main_menu_panel.png` assets are no longer referenced by this screen and may be retired once `CtMainMenu` consumes the new primitives (S5).

---

## Components

- `CtMainMenu` — presentational menu (`app/lib/widgets/main_menu.dart`).
- `CtNinePatchButton` — wood-panel buttons (enhanced gradient/brass-corner variant per issue #2859 S2 in the `pixelArt` variant).
- `CtBrassDivider` — divider between logo and buttons regions in the `pixelArt` variant (issue #2859 R7, [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md)).
- `CtCompassRose` — decorative 8-arm emblem above the title in the `pixelArt` variant (issue #2860 S1, [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md)).
- `CtFleurDeLisOrnament` — decorative flourish flanking the title in the `pixelArt` variant (issue #2860 S4, [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md)).
- `CtScreenShell` — pixel-art shell per [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md).
- Registered in `app/widget_catalog.json` as CtMainMenu (category: screen).

---

## Widgetbook

- **Folder:** **Main Menu** (`app/lib/widgetbook/catalog.dart`) for `CtMainMenu` use cases: **Default**, **After victory**, **No saves**, **Resume game visible**, **Pixel art (mobile)** per the **States and variants** table (each rendered under `AppThemes.editorialMonocle`).
- **Folder:** **Ct- Dark Theme Primitives** (`app/lib/widgetbook/catalog_part5.dart`) hosts the decorative primitives consumed by this screen: `CtBrassDivider`, `CtCompassRose`, `CtFleurDeLisOrnament`. Each story renders the primitive over `AppThemes.editorialMonocle.scaffoldBackgroundColor` so reviewers see the wood-on-brass contrast in context.

---

## Acceptance criteria

See **How this spec satisfies UXD 03a** above for full Given–When–Then ACs. Automated tests: `app/test/screen_spec_acceptance_test.dart`.
