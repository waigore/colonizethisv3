# In-game shell: hamburger menu and layout

**SPEC/ui** — The in-game screen has a **hamburger** slide-out with **Game Parameters** (read-only) and **Debug log**. **Empire actions** live on the map **left rail** ([empire-buttons.md](empire-buttons.md)). Available at all viewport sizes. Authority: [empire-overview.md](empire-overview.md).

---

## Top bar

The top bar shows:

- **Left:** Hamburger control (menu trigger). Opens the side menu.
- **Center/right:** Turn counter/button (e.g. "Next turn (N / year)").
- **Below:** Region tabs (Old World / New World).

**No empire buttons in the top bar.** Empire actions are on the **map left rail** (always visible).

---

## Hamburger side menu

Widget contract and navigation: **[game-side-menu.md](game-side-menu.md)**. Pause bottom-sheet variant: **[pause-menu-panel.md](pause-menu-panel.md)**. Narrow map province/sea detail host: **[game-map-narrow-detail-overlay-slot.md](game-map-narrow-detail-overlay-slot.md)**.

- **Availability:** Available at all viewport sizes (both narrow and wide).
- **Open:** Swipe in from the **left** edge of the **map** (narrow strip), or tap the **hamburger** in the top bar.
- **Close:** Swipe the menu to the **left** (drag to close), tap a **close (×)** button in the menu, tap outside the menu (on scrim), or press **Escape**.
- **Content:** **Game Parameters** (read-only dialog) and **Debug log** (plus close). Does **not** list empire actions.
- **Layout:** Pixel-art **CtPanel** with **CtNinePatchButton** entries; tune icon + label for Game Parameters; bug icon + label for Debug log.
- **Width:** Fixed width (~240 dp) so the map remains partially visible when open; drawer-like overlay.

### Game Parameters (read-only)

- **Entry:** Hamburger menu item **Game Parameters**.
- **Dialog:** `CtDialogShell` with title **Game Parameters** and a read-only row **Infinite mode: On** or **Off** matching `Game.infiniteMode`. No edit controls. **Close** dismisses.
- **Not on load list:** Infinite mode is not shown on the load-game list screen.

---

## Modal behaviour (side menu)

- **Modal:** When the side menu is open, it is **modal with respect to the map widget and in-game controls underneath**:
  - Pointer interaction (tap, drag, scroll, hover) is **captured by the side menu layer** and **does not reach the map widget** or underlying in-game UI.
  - Keyboard interaction that would otherwise affect the map or in-game UI is **ignored by the map** while the menu is open.
  - **OS / platform-level gestures** (system back, platform edge-swipes) continue to work as normal; modality only applies to the app content layer.
- **Scrim:** A dimmed background (scrim) is shown behind the side menu while it is open. The scrim colour MUST resolve to `EditorialMonoclePalette.dialogScrim` — the canonical `--dialog-scrim` token defined in [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Dialog scrim — so the wash matches every other modal scrim on the editorial-monocle theme (exit-confirm dialog, overture, call to arms, intervention, victory). Hard-coded scrim colours such as `Colors.black54` are treated as regressions.
- **Exception — region minimap:** The bottom-right **region minimap** (see [empire-overview.md](empire-overview.md) § Region minimap) stays **above** the scrim so it remains tappable; the main map under the scrim stays non-interactive. This is an intentional exception to “map under scrim” for minimap hit targets only.
- **Dismissal:**
  - Pressing **Escape** (or the equivalent back key on desktop/web) closes the side menu.
  - Tapping or clicking **outside** the side menu, on the scrim, closes the side menu and **does not trigger any map interaction** for that tap/click.
  - Tapping the **hamburger** again while the menu is open closes the side menu.
  - Existing close affordances (swipe/drag to the left, close (×) button) continue to close the menu.

---

## Android back confirm (exit to main menu)

- **Scope:** Applies in any state where pressing Android system back from the in-game shell would leave the current game screen.
- **Interception:** The in-game shell traps Android back before route pop, then decides whether to present confirmation.
- **Dialog:** The app shows a pixel-art confirmation dialog using **CtDialogShell** and **CtNinePatchButton** (no Material `AlertDialog` / Material action buttons). The host call MUST resolve `barrierColor` to `EditorialMonoclePalette.dialogScrim` ([pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Dialog scrim) instead of the Flutter default `Colors.black54` so the scrim matches every other modal on the running app theme.
- **Text:**
  - Title: `Exit game?` (rendered in `--accent`, display font slot)
  - Body: `Your current progress will be lost if not saved.` (rendered in `--fg`)
  - Actions: `Cancel` and `Exit`
- **Actions:**
  - `Cancel` dismisses the dialog and keeps the player on the in-game shell. `Cancel` is rendered with the default `CtNinePatchButton` brass styling.
  - `Exit` navigates to the main menu (`Routes.shell`), ending the in-game shell route. `Exit` is the destructive action: the button label is rendered in `--danger` (`EditorialMonoclePalette.danger`) so the destructive intent is visually distinct from `Cancel`.
- **Dismissal:** Tapping outside the dialog (barrier area) dismisses the dialog and keeps the player in-game.

---

## Province/sea zone detail overlay

- **Wide viewport (≥ 600 dp):** Province detail appears as a side panel (width 320 dp) to the right of the map.
- **Narrow viewport (< 600 dp):** Province detail appears as a bottom sheet (height ~33% of viewport) **stacked above** the map area so it **overlays** the lower portion of the map (including bottom-left map tools if they intersect). Partial overlap is acceptable; the detail layer is **above** map chrome for hit testing.

This layout difference is retained because wide viewports have horizontal space for a side panel, while narrow viewports do not.

---

## Wireframe

```
+------------------------------------------+
| [≡]     Next turn (42 / 1650)            |  <- top bar: hamburger + turn counter
+------------------------------------------+
| [Old World] [New World]                  |  <- region tabs
+------------------------------------------+
|                                          |
|              Map area                     |
|                                          |
+------------------------------------------+

Map left rail (always visible, icon-only + tooltips):
| [P][C][M][N][D][T]  (vertical column of empire icons)

Hamburger menu (when open):
+------------------+
| [×]              |
| [bug] Debug log  |
+------------------+
```

---

## Acceptance criteria

- **Given** the in-game shell is shown, **when** the user looks at the top bar, **then** the hamburger (menu trigger) and the turn counter/button are shown; empire buttons are **not** in the top bar.
- **Given** the in-game map is visible, **when** the user looks at the **left** of the map (east of the edge-swipe strip), **then** the **empire icon rail** is visible with all actions in [empire-buttons.md](empire-buttons.md) order (icon-only; labels via tooltip/semantics).
- **Given** the side menu is closed, **when** the user swipes in from the left edge of the map, **then** the side menu opens and displays **Debug log** (pixel-art style).
- **Given** the side menu is closed, **when** the user taps the hamburger in the top bar, **then** the side menu opens and displays **Debug log**.
- **Given** the side menu is open, **when** the user swipes the menu to the left (drag to close), **then** the side menu closes.
- **Given** the side menu is open, **when** any single `HorizontalDragUpdate` event over the menu surface delivers `details.delta.dx < -5.0` logical pixels, **then** the UI layer invokes the host-supplied `onClose` callback exactly once for that drag event (positive swipe-to-close contract, [game_side_menu.dart](../../app/lib/features/game/flame/game_side_menu.dart) `GameSideMenu._kSwipeToCloseDeltaThreshold`).
- **Given** the side menu is open, **when** the user performs a horizontal drag whose `details.delta.dx` stays at `>= 0` (right-ward or stationary), **then** the UI layer does **not** invoke `onClose` from the swipe-to-close gesture handler (negative regression guard against accidentally closing on right-swipes or noise).
- **Given** the side menu is open, **when** the user taps the close (cross) button in the menu, **then** the side menu closes.
- **Given** the side menu is open, **when** the user taps **Debug log**, **then** the app navigates to the debug log route and the side menu closes.
- **Given** the side menu is built, **when** it renders, **then** it uses pixel-art layout (CtPanel, CtNinePatchButton for Debug log).

- **Given** the side menu is **open**, **when** the user attempts to interact with the map area (tap, drag, scroll, hover), **then** the map widget does not respond and no province selection or camera movement occurs until the side menu is closed.
- **Given** the side menu is **open**, **when** the user performs a keyboard action that would normally affect the map (e.g. map hotkeys), **then** the map does not react while the menu is open.
- **Given** the side menu is **open**, **when** the user taps or clicks outside the menu (on the dimmed background), **then** the side menu closes and that tap/click is **not** forwarded to the map (no province selection or camera movement is triggered).
- **Given** the side menu is **open**, **when** the user presses **Escape** (or the platform back key where applicable), **then** the side menu closes and focus/input returns to the in-game shell.
- **Given** the side menu is **open**, **when** the scrim layer behind the side menu is built, **then** its `Container` colour equals `EditorialMonoclePalette.dialogScrim` (no `Colors.black54` literal in the host code).
- **Given** the in-game shell is visible and Android back would leave the game screen, **when** the user presses Android back, **then** the UI layer shows a pixel-art confirmation dialog with title `Exit game?`, body `Your current progress will be lost if not saved.`, and actions `Cancel` and `Exit`.
- **Given** the exit confirmation dialog is visible, **when** the user taps `Cancel`, **then** the UI layer dismisses the dialog and remains on the in-game shell.
- **Given** the exit confirmation dialog is visible, **when** the user taps outside the dialog, **then** the UI layer dismisses the dialog and remains on the in-game shell.
- **Given** the exit confirmation dialog is visible, **when** the user taps `Exit`, **then** the UI layer navigates to the main menu route (`Routes.shell`).
- **Given** the exit confirmation dialog is shown via `showDialog`, **when** the underlying widget tree is built, **then** the `barrierColor` passed to `showDialog` equals `EditorialMonoclePalette.dialogScrim` (no `Colors.black54` literal in the host code).
- **Given** the exit confirmation dialog is visible, **when** the `Exit` action label is rendered, **then** the label text colour resolves to `EditorialMonoclePalette.danger` so the destructive action is visually distinct from `Cancel` (which keeps the default brass label color).

---

## References

- [empire-buttons.md](empire-buttons.md) — list and order of empire buttons, styling
- [empire-overview.md](empire-overview.md) — in-game shell
- [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) — CtPanel, CtNinePatchButton