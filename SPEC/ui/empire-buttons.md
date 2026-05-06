# Empire buttons

**SPEC/ui** — In-game actions for the human player (Production, Civilian Units, Military Units, Naval Units, Diplomacy, Technology). At all viewport sizes these are **always visible** as **icon-only** controls along the **left edge** of the map (east of the edge-swipe strip); **labels** appear on **hover** (e.g. tooltip). The **hamburger** side menu is **Debug log** only. Authority: [empire-overview.md](empire-overview.md); [in-game-shell-narrow.md](in-game-shell-narrow.md) for hamburger menu.

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
| 7 (debug only) | debug_console | Debug Console | Toggles non-modal in-map debug console overlay |

Icons and assets: [game-toolbar-icons.md](game-toolbar-icons.md) — files live in `app/assets/icons/` as `ui_icon_<id>.png` (32×32; display at 20×20 in buttons). The `naval_units` button uses `ui_icon_naval_units.png` and opens the Naval Units panel defined in [naval-units-panel.md](naval-units-panel.md).

---

## Display

- **All viewports:** Empire actions appear as an **icon column** on the **left** of the map ([GameMapEmpireLeftRail](../../app/lib/features/game/flame/game_map_empire_left_rail.dart)), **always visible**, same order as the table below. **Tooltip** (or equivalent) shows the full label on hover; **Semantics** expose the label for accessibility.
- **Debug gate:** `debug_console` appears only when compile-time flag `CT_DEBUG_CONSOLE=true` is supplied. Production/default builds omit this icon.
- **Top bar:** Shows hamburger (opens **Debug log** menu only), turn counter/button, and region tabs. **No** empire buttons in the top bar.
- **Edge swipe:** A narrow strip at the **left** edge of the map still opens the **hamburger** menu (Debug log); the empire rail begins **to the right** of that strip so both coexist.

---

## Hamburger menu (Debug log only)

- **Open:** Tap the hamburger in the top bar, or swipe in from the **left** edge of the map.
- **Content:** **Debug log** entry only (plus close affordances). Empire actions are **not** duplicated here.

See [in-game-shell-narrow.md](in-game-shell-narrow.md) for modal behaviour and dismissal.

---

## Styling (left rail)

- **Icon row/column:** `Material` + `InkWell` + `StrictAssetIcon` at **20×20** with light semi-opaque backing, aligned with map tool buttons ([GameMapCornerControls](../../app/lib/features/game/flame/game_map_corner_controls.dart)) for visual consistency.
- Asset paths: `ui_icon_<id>.png` per [game-toolbar-icons.md](game-toolbar-icons.md); missing or invalid assets throw `FlutterError`.

---

## References

- [game-toolbar-icons.md](game-toolbar-icons.md) — icon assets and prompts
- [in-game-shell-narrow.md](in-game-shell-narrow.md) — side menu implementation
- [empire-overview.md](empire-overview.md) — in-game shell
- [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) — CtNinePatchButton