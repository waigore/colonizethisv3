# Empire buttons

**SPEC/ui** — In-game actions for the human player (Production, Civilian Units, Military Units, Diplomacy, Technology). All empire buttons are accessed via the side menu (hamburger menu) at all viewport sizes. Authority: [empire-overview.md](empire-overview.md); [in-game-shell-narrow.md](in-game-shell-narrow.md) for side menu implementation.

---

## Definition

**Empire buttons** are the set of in-game toolbar actions that open panels or full-screen screens.

| Order | Id | Label | Action |
|-------|-----|--------|--------|
| 1 | production | Production | Opens Production panel/screen |
| 2 | civilian_units | Civilian Units | Opens Civilian Units panel (e.g. bottom sheet or route) |
| 3 | military_units | Military Units | Opens Military Units panel |
| 4 | naval_units | Naval Units | Opens Naval Units panel |
| 5 | diplomacy | Diplomacy | Opens Diplomacy screen |
| 6 | technology | Technology | Opens Technology screen |

Icons and assets: [game-toolbar-icons.md](game-toolbar-icons.md) (`ui_icon_<id>.png`, 32×32; display at 20×20 in buttons). The `naval_units` button uses `ui_icon_naval_units.png` and opens the Naval Units panel defined in [naval-units-panel.md](naval-units-panel.md).

---

## Display

- **All viewports:** Empire buttons are shown **only** in the **side menu** (opened via hamburger menu). The side menu is available at all viewport sizes (both narrow and wide). No empire buttons appear in the top bar.
- **Top bar:** Shows hamburger (menu trigger) on the left, turn counter/button on the right, and region tabs centered below. No empire buttons.

---

## Side menu

The side menu contains all empire buttons and is accessible at all viewport sizes.

- **Open:** Tap the hamburger menu in the top bar, or swipe in from the left edge.
- **Close:** Tap outside the menu (on scrim), swipe left, tap the close (×) button, or press Escape.
- **Content:** All empire buttons in order (Production, Civilian Units, Military Units, Diplomacy, Technology).
- **Layout:** Pixel-art layout with CtPanel and CtNinePatchButton.
- **Modal:** When open, the map underneath is non-interactive.

See [in-game-shell-narrow.md](in-game-shell-narrow.md) for full side menu specification.

---

## Styling

- All empire buttons use **CtNinePatchButton** with pixel-art icon + label.
- Icon: `Image.asset('assets/images/ui_icon_<id>.png', width: 20, height: 20)`; 8 dp gap; then `Text(label)`.
- Same visual style in side menu at all viewport sizes. No Material buttons.

---

## References

- [game-toolbar-icons.md](game-toolbar-icons.md) — icon assets and prompts
- [in-game-shell-narrow.md](in-game-shell-narrow.md) — side menu implementation
- [empire-overview.md](empire-overview.md) — in-game shell
- [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) — CtNinePatchButton