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

Icons and assets: [game-toolbar-icons.md](game-toolbar-icons.md) — files live in `app/assets/icons/` as `ui_icon_<id>.png` (32×32 source; display at 24×24 inside the 36×36 dp wide-layout rail button per § Styling below, narrow rail measurements per [mobile-adaptation.md](mobile-adaptation.md)). The `naval_units` button uses `ui_icon_naval_units.png` and opens the Naval Units panel defined in [naval-units-panel.md](naval-units-panel.md).

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

Dark editorial-monocle chrome aligned to `SPEC/ui/mockups/GAME10001-game-screen.html` (`.left-rail` / `.empire-btn`) and `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette. Issue #2861 R4.

- **Tap target (wide / desktop):** Each rail icon button paints a **36 × 36 dp** square surface. Narrow-layout measurement is **26 × 26 dp** per [mobile-adaptation.md](mobile-adaptation.md) and is governed by issue #2870; this spec authorises the wide-layout baseline only.
- **Rail layout:** Vertical `Column` with a **3 dp** vertical gap between consecutive icon buttons. The rail anchors at `left: kEdgeSwipeStripWidth` of the map `Stack` and starts from the top of the rail container (host owns vertical placement); the rail itself has no inner padding around the button column.
- **Surface chrome:** Vertical gradient from `--surface-lite` (top, `EditorialMonoclePalette.surfaceLite`) to `--bg-deep` (bottom, `EditorialMonoclePalette.bgDeep`), painted via `CtGradients.railButtonGradient`. A **1 dp** outline in `--border` (`EditorialMonoclePalette.border`) frames every edge of the surface.
- **Icon glyph:** Centered `StrictAssetIcon` rendered at **24 × 24 dp**, tinted via a colour overlay using the same token cycle as the surface chrome: `--accent-dim` default, `--accent` on hover, `--accent-bright` on pressed. Pointer hover lifts the outline from `--border` to `--accent-dim` to mirror the mockup `.empire-btn:hover` rule.
- **Disabled state:** When a button is disabled (e.g., debug-only icon hidden), the button is **removed from the tree** rather than rendered greyed out. Visible buttons are always interactive.
- **Tooltip:** Each button hosts a `Tooltip` with the label from the [Definition](#definition) table; the localised string is the source of truth. The mockup's CSS hover tooltip is the inspiration for the side-mounted dark popup; the Flutter `Tooltip` provides the equivalent behaviour with the default platform timing.
- **Accessibility:** Each button is wrapped in `Semantics(button: true, label: <tooltip>)` so assistive tech still reports the action even when the visual is icon-only.
- **Tokens / no light hex:** All chrome and glyph colours resolve from [EditorialMonoclePalette](../../app/lib/config/editorial_monocle_palette.dart). Hard-coded light hex (e.g. `Colors.white.withOpacity(0.9)`, parchment `#F5F5DC`) is forbidden in the rail — those colours regress the dark theme mandate from `colonizethis-ui-design.mdc`.
- **Asset error handling:** Asset paths follow `ui_icon_<id>.png` per [game-toolbar-icons.md](game-toolbar-icons.md); missing or invalid assets throw `FlutterError`.

### Acceptance criteria (left rail chrome)

- **Given** the in-game map is rendered on the wide layout (`MediaQuery.size.width ≥ kNarrowBreakpoint`), **when** [GameMapEmpireLeftRail](../../app/lib/features/game/flame/game_map_empire_left_rail.dart) lays out the six core empire buttons (`production`, `civilian_units`, `military_units`, `naval_units`, `diplomacy`, `technology`), **then** every visible rail icon button paints a **36 × 36 dp** square surface.
- **Given** the rail is rendered, **when** the chrome painter resolves a single rail button's surface, **then** the surface paints `CtGradients.railButtonGradient` (vertical gradient from `EditorialMonoclePalette.surfaceLite` to `EditorialMonoclePalette.bgDeep`) and a **1 dp** outline in `EditorialMonoclePalette.border`.
- **Given** the rail is rendered, **when** the chrome painter resolves a rail button's icon glyph, **then** the glyph paints `StrictAssetIcon` at exactly **24 × 24 dp**, tinted via `EditorialMonoclePalette.accentDim` while the button is idle.
- **Given** the rail is rendered, **when** the user hovers the `production` rail button with a pointer device, **then** the outline updates to `EditorialMonoclePalette.accentDim` and the icon-glyph tint updates to `EditorialMonoclePalette.accent`.
- **Given** the rail is rendered, **when** the user presses (pointer-down or active highlight) the `production` rail button, **then** the icon-glyph tint updates to `EditorialMonoclePalette.accentBright`.
- **Given** the rail is rendered, **when** the layout resolves the rail column, **then** consecutive rail buttons have a **3 dp** vertical gap between them and no other padding inside the rail column.
- **Given** the rail is rendered, **when** the layout enumerates colour usage anywhere inside the rail buttons, **then** no rail node paints `Colors.white`, `Colors.black`, or other light-theme parchment hex literals; every colour resolves from `EditorialMonoclePalette` tokens.

### Narrow rail measurements (`< kNarrowBreakpoint`)

When the in-game map renders on a narrow viewport (`MediaQuery.size.width < kNarrowBreakpoint`, `600 dp`), the host (`GameMapArea`) constructs [GameMapEmpireLeftRail](../../app/lib/features/game/flame/game_map_empire_left_rail.dart) with `narrow: true`. The rail then renders at the narrow measurements defined in [mobile-adaptation.md](mobile-adaptation.md) § In-game shell, normative for issue #2870 S3:

- **Tap target:** **26 × 26 dp** per button (mockup `.empire-btn @media (max-width:600px) { width:26px; height:26px }`).
- **Vertical gap:** **2 dp** between consecutive buttons (tightened from the wide `3 dp` value so the six-icon column still fits the shorter narrow chrome stack).
- **Icon glyph:** Unchanged at **24 × 24 dp** (mockup keeps `.empire-btn img { 24 × 24 }` at narrow); the visible padding around the glyph compresses to 1 dp per side.
- **Tooltip:** Tooltips are suppressed on narrow buttons (touch-only; mobile devices have no hover cursor). The `Semantics(button: true, label: <tooltip>)` wrapper is preserved so assistive tech still reports each action.
- **Chrome tokens:** Unchanged — narrow buttons keep the wide gradient/border/icon-tint contracts above.

#### Acceptance criteria (narrow rail)

- **Given** the in-game map is rendered on the narrow layout (`MediaQuery.size.width < kNarrowBreakpoint`), **when** `GameMapEmpireLeftRail` is constructed with `narrow: true` and lays out the six core empire buttons, **then** every visible rail icon button paints a **26 × 26 dp** square surface.
- **Given** the narrow rail is rendered, **when** the layout resolves the rail column, **then** consecutive rail buttons have a **2 dp** vertical gap between them.
- **Given** the narrow rail is rendered, **when** the chrome painter resolves a rail button's icon glyph, **then** the glyph paints `StrictAssetIcon` at exactly **24 × 24 dp** (icon size is unchanged from the wide layout).
- **Given** the narrow rail is rendered, **when** the descendant widget tree of any rail button is enumerated, **then** no `Tooltip` widget is mounted under the rail button (tooltips are suppressed for touch-only narrow viewports).
- **Given** the narrow rail is rendered, **when** the descendant widget tree of each rail button is enumerated, **then** the existing `Semantics(button: true, label: <tooltip>)` wrapper is still mounted so assistive tech reports the action label.

---

## Widgetbook stories

Catalog folder **Game Map Empire Left Rail** — registered from [`gameMapEmpireLeftRailDirectories`](../../app/lib/widgetbook/catalog_part7.dart) and aggregated into `_ctWidgetbookDirectories` in [`catalog.dart`](../../app/lib/widgetbook/catalog.dart). Issue #2861 S12 story (3) "left rail with tooltips".

| Story | Purpose | Authority |
|-------|---------|-----------|
| Wide — six core empire buttons with tooltips | Pins § Styling (left rail): 36 × 36 dp surface, `CtGradients.railButtonGradient`, 24 × 24 dp glyph, `Tooltip` per button. | § Styling (left rail) |
| Wide — debug console enabled (7 icons) | Exercises the seventh `debug_console` icon gated behind `debugConsoleEnabledProvider` (`CT_DEBUG_CONSOLE=true` in production). | § Definition, § Display |
| Narrow (360 dp) — 26 × 26 dp buttons, tooltips suppressed | Pins § Narrow rail measurements: 26 × 26 dp surface, 2 dp gap, suppressed `Tooltip` widgets, preserved `Semantics` label. | § Narrow rail measurements; [mobile-adaptation.md](mobile-adaptation.md) § In-game shell |

Stories provide a stand-in `gameServiceProvider` whose `getMapData(...)` returns `null` so the rail's diplomacy nav payload falls back to the existing empty `MapTopology()` branch in `GameMapEmpireLeftRail.build`. No Hive box is opened from the Widgetbook bootstrap.

---

## References

- [game-toolbar-icons.md](game-toolbar-icons.md) — icon assets and prompts
- [in-game-shell-narrow.md](in-game-shell-narrow.md) — side menu implementation
- [empire-overview.md](empire-overview.md) — in-game shell
- [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) — CtNinePatchButton + editorial-monocle palette
- [mobile-adaptation.md](mobile-adaptation.md) — narrow rail measurement (26 × 26 dp, deferred to issue #2870)
- [`SPEC/ui/mockups/GAME10001-game-screen.html`](mockups/GAME10001-game-screen.html) — canonical visual contract (`.empire-btn`)