# Empire buttons

**SPEC/ui** — In-game actions for the human player (Production, Civilian Units, Military Units, Diplomacy, Technology). Display depends on viewport width. Authority: [empire-overview.md](empire-overview.md); [in-game-shell-narrow.md](in-game-shell-narrow.md) for narrow layout.

---

## Definition

**Empire buttons** are the set of in-game toolbar actions that open panels or full-screen screens. They are the same set in all viewport sizes; only their **placement** changes.

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

## Display by viewport

- **Wide viewport (width ≥ 600 dp):** Empire buttons are shown in the **top bar** (toolbar row) with region tabs, in the order above. No side menu.
- **Narrow viewport (width < 600 dp):** Empire buttons are **not** shown in the top bar. They are shown only inside the **side menu** (see [in-game-shell-narrow.md](in-game-shell-narrow.md)). Top bar on narrow shows only hamburger (menu trigger) and turn counter.

Breakpoint: **600 dp** (same as production panel, military units panel).

---

## Styling

- All empire buttons use **CtNinePatchButton** with pixel-art icon + label.
- Icon: `Image.asset('assets/images/ui_icon_<id>.png', width: 20, height: 20)`; 8 dp gap; then `Text(label)`.
- Same visual style in top bar (wide) and in side menu (narrow). No Material buttons.

---

## References

- [game-toolbar-icons.md](game-toolbar-icons.md) — icon assets and prompts
- [in-game-shell-narrow.md](in-game-shell-narrow.md) — narrow layout, side menu
- [empire-overview.md](empire-overview.md) — in-game shell
- [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) — CtNinePatchButton
