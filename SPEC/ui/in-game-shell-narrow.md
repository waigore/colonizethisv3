# In-game shell: side menu

**SPEC/ui** — The in-game screen has a side menu (accessed via hamburger menu) that contains empire buttons. Available at all viewport sizes. Authority: [empire-overview.md](empire-overview.md), [empire-buttons.md](empire-buttons.md).

---

## Top bar

The top bar shows:

- **Left:** Hamburger control (menu trigger). Opens the side menu.
- **Center/right:** Turn counter/button (e.g. "Next turn (N / year)").
- **Below:** Region tabs (Old World / New World).

**No empire buttons in the top bar.** Empire buttons appear only in the side menu.

---

## Side menu

- **Availability:** Available at all viewport sizes (both narrow and wide).
- **Open:** Swipe in from the **left** edge, or tap the **hamburger** in the top bar.
- **Close:** Swipe the menu to the **left** (drag to close), tap a **close (×)** button in the menu, tap outside the menu (on scrim), or press **Escape**.
- **Content:** All [empire buttons](empire-buttons.md) in order: Production, Civilian Units, Military Units, Diplomacy, Technology. Same behaviour in all viewports (each opens the same panel/screen).
- **Layout:** Pixel-art layout. Uses **CtPanel** (or equivalent framed container), **CtNinePatchButton** for each empire button, same icons and labels as [game-toolbar-icons.md](game-toolbar-icons.md). No Material chrome.
- **Width:** Menu has a fixed width (280 dp) so the map remains partially visible or dimmed when open; implementation uses a drawer-like overlay.

---

## Modal behaviour (side menu)

- **Modal:** When the side menu is open, it is **modal with respect to the map widget and in-game controls underneath**:
  - Pointer interaction (tap, drag, scroll, hover) is **captured by the side menu layer** and **does not reach the map widget** or underlying in-game UI.
  - Keyboard interaction that would otherwise affect the map or in-game UI is **ignored by the map** while the menu is open.
  - **OS / platform-level gestures** (system back, platform edge-swipes) continue to work as normal; modality only applies to the app content layer.
- **Scrim:** A dimmed background (scrim) is shown behind the side menu while it is open.
- **Dismissal:**
  - Pressing **Escape** (or the equivalent back key on desktop/web) closes the side menu.
  - Tapping or clicking **outside** the side menu, on the scrim, closes the side menu and **does not trigger any map interaction** for that tap/click.
  - Tapping the **hamburger** again while the menu is open closes the side menu.
  - Existing close affordances (swipe/drag to the left, close (×) button) continue to close the menu.

---

## Province/sea zone detail overlay

- **Wide viewport (≥ 600 dp):** Province detail appears as a side panel (width 320 dp) to the right of the map.
- **Narrow viewport (< 600 dp):** Province detail appears as a bottom sheet (height ~33% of viewport) below the map.

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

Side menu (when open, overlaid from left):
+------------------+
| [×] Close        |
|                  |
| [icon] Production|
| [icon] Civilian  |
| [icon] Military  |
| [icon] Diplomacy  |
| [icon] Technology|
+------------------+
```

---

## Acceptance criteria

- **Given** the in-game shell is shown, **when** the user looks at the top bar, **then** the hamburger (menu trigger) and the turn counter/button are shown; empire buttons are **not** in the top bar.
- **Given** the side menu is closed, **when** the user swipes in from the left edge, **then** the side menu opens and displays all empire buttons in pixel-art style.
- **Given** the side menu is closed, **when** the user taps the hamburger in the top bar, **then** the side menu opens and displays all empire buttons.
- **Given** the side menu is open, **when** the user swipes the menu to the left (drag to close), **then** the side menu closes.
- **Given** the side menu is open, **when** the user taps the close (cross) button in the menu, **then** the side menu closes.
- **Given** the side menu is open, **when** the user taps an empire button, **then** the same panel or screen opens as defined in [empire-buttons.md](empire-buttons.md), and the side menu closes.
- **Given** the side menu is built, **when** it renders, **then** it uses pixel-art layout (CtPanel, CtNinePatchButton, same icons as game-toolbar-icons) and no Material buttons or chrome.

- **Given** the side menu is **open**, **when** the user attempts to interact with the map area (tap, drag, scroll, hover), **then** the map widget does not respond and no province selection or camera movement occurs until the side menu is closed.
- **Given** the side menu is **open**, **when** the user performs a keyboard action that would normally affect the map (e.g. map hotkeys), **then** the map does not react while the menu is open.
- **Given** the side menu is **open**, **when** the user taps or clicks outside the menu (on the dimmed background), **then** the side menu closes and that tap/click is **not** forwarded to the map (no province selection or camera movement is triggered).
- **Given** the side menu is **open**, **when** the user presses **Escape** (or the platform back key where applicable), **then** the side menu closes and focus/input returns to the in-game shell.

---

## References

- [empire-buttons.md](empire-buttons.md) — list and order of empire buttons, styling
- [empire-overview.md](empire-overview.md) — in-game shell
- [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) — CtPanel, CtNinePatchButton