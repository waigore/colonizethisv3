# Plan: Convert Province/Sea Zone Detail Overlay to Non-Material (Pixel-Art Friendly)

**Goal:** Remove Material design from `ProvinceSeaZoneDetailOverlay` so it works well with pixel art (UXD 02). The overlay will use only non-Material widgets and explicit styling.

**Scope:** Single file `app/lib/features/game/widgets/province_sea_zone_detail_overlay.dart` plus one new reusable widget for tabs; spec and tests updated as needed.

---

## 1. Current Material Usage (to remove)

| Location | Current | Replacement |
|----------|---------|-------------|
| Import | `flutter/material.dart` | `flutter/widgets.dart` (+ keep material only if `CtPanel`/theme need it; see below) |
| Shell | `Card` (margin 8, child: Column…) | `CtPanel` (pixel-art nine-patch). Wrap in `Padding(padding: 8)` or add margin in parent. |
| Header title | `Theme.of(context).textTheme.titleMedium` | Explicit `TextStyle` constant (e.g. bold, size 16) for pixel-art consistency. |
| Close control | `IconButton(icon: Icons.close, …)` | Custom close control: `GestureDetector` + `Container` + label (e.g. `Text('×')` or small sprite). Use `Key('overlay_close')` for tests. |
| Narrow layout tabs | `DefaultTabController` + `TabBar` + `TabBarView` + `Tab` | Custom tab strip + content: see §2. |
| Section titles | `TextStyle(fontWeight: FontWeight.bold)` | Keep (not Material-specific); can centralize in a constant. |

**Note on imports:** `CtPanel` and `CtNinePatchButton` currently use `Theme.of(context)` and some still use `Material`/`InkWell`. For the **overlay only**, we stop using Material widgets and use explicit styling where possible. We can keep `material.dart` in this file if the app still wraps the overlay in `MaterialApp` (so `CtPanel`’s theme fallback works), or we pass a fallback color into `CtPanel` later. Plan: keep `material.dart` for now only for `Theme.of(context)` used by `CtPanel` (or refactor `CtPanel` to accept an optional `Color? fallbackSurface` and use it when no theme).

---

## 2. Custom Tab Strip (narrow layout)

- **Remove:** `DefaultTabController`, `TabBar`, `TabBarView`, `Tab`.
- **Add:** A small, reusable **tab strip** widget that:
  - Takes `List<String> tabLabels` and `List<Widget> tabViews`.
  - Holds `selectedIndex` (state). So the overlay’s narrow branch will use a **StatefulWidget** for the tabbed area only (e.g. `_OverlayTabbedContent`), or a reusable `CtTabStrip` in `app/lib/widgets/`.
- **Layout:** One row of tab labels (each a `GestureDetector` + `Container`/`DecoratedBox` for border/background when selected) + `Expanded(IndexedStack(children: tabViews, index: selectedIndex))`.
- **Styling:** Explicit colors and text style (no `Theme` for the strip if we want to be strict), or use `Theme.of(context)` for colors only. Pixel-art friendly: simple rectangles, 1px border, no Material ripple.
- **Data change:** `_OverlayContent` currently has `tabs` (List of `Tab` widgets) and `tabViews`. Change to `tabLabels` (List<String>) and keep `tabViews`. All call sites that build `tabs` (e.g. `Tab(text: 'Tile')`) become `'Tile'`, etc.

**Recommendation:** Implement `CtTabStrip` in `app/lib/widgets/ct_tab_strip.dart` (reusable for other panels) with: `tabLabels`, `tabViews`, optional `selectedIndex`/`onChanged` if we want controlled mode, or internal state. For overlay, internal state is enough.

---

## 3. Replace Card with CtPanel

- Root of overlay build: replace `Card(margin: 8, child: Column(…))` with `Padding(padding: EdgeInsets.all(8), child: CtPanel(padding: …, child: Column(…)))`.
- Preserve existing padding (header has `EdgeInsets.only(left: 12, right: 8, top: 8)`; content has `EdgeInsets.all(12)`). CtPanel has a `padding` parameter; use it for the inner content and add the header padding inside the Column, or set CtPanel padding to zero and wrap content in a Padding that matches current insets. Prefer: CtPanel with padding that matches the current content padding (e.g. 12), and keep the header row’s own padding as is.

---

## 4. Close Button

- New: `GestureDetector(onTap: onClose, child: Container(… decoration… child: Text('×')))` with a `Key('overlay_close')` for tests.
- Or use `CtNinePatchButton` with `Text('×')` if we accept that CtNinePatchButton still uses Material internally (then we only remove IconButton from overlay). **Plan:** Prefer a minimal custom close control in this file (GestureDetector + Container + Text) so the overlay is fully free of Material widgets; no Icon, no IconButton.

---

## 5. Text Styling

- Define local constants or a small `_OverlayStyles` with:
  - Title: e.g. `TextStyle(fontSize: 16, fontWeight: FontWeight.bold)`.
  - Section header: already `FontWeight.bold`; keep or use same constant.
- Replace `Theme.of(context).textTheme.titleMedium` with the title style constant.

---

## 6. Spec Update

- In `SPEC/ui/province-sea-zone-detail-overlay.md`, add a short **Style** or **Implementation notes** bullet:
  - “Overlay uses non-Material, pixel-art friendly components: CtPanel, custom tab strip, explicit text styles (no Material Card/TabBar/IconButton).”

---

## 7. Tests

- `app/test/province_overlay_test.dart`:
  - Replace `find.byIcon(Icons.close)` with `find.byKey(Key('overlay_close'))` (or `find.text('×')` if unique). Prefer key for stability.
  - If any test asserts on `TabBar`/`Tab`/`TabBarView`, remove or change to assert on the new tab strip (e.g. by label text or by key).
  - Keep `MaterialApp` in test harness so that `Theme.of(context)` still works for `CtPanel` until/unless we refactor CtPanel to not require theme.

---

## 8. Implementation Order

1. **Spec:** Update `SPEC/ui/province-sea-zone-detail-overlay.md` with the style note.
2. **CtTabStrip:** Add `app/lib/widgets/ct_tab_strip.dart` (stateful: tabLabels, tabViews, internal selectedIndex; pixel-art styling).
3. **Overlay data:** Change `_OverlayContent` to use `List<String> tabLabels` instead of `List<Widget> tabs`; update `_provinceContent` and `_seaZoneContent` to pass labels and same `tabViews`.
4. **Overlay shell:** Replace Card with Padding + CtPanel; replace header title style with constant; replace IconButton with custom close (Key); in narrow branch, use CtTabStrip(tabLabels, tabViews) instead of DefaultTabController/TabBar/TabBarView.
5. **Imports:** Use `flutter/widgets.dart` for core widgets; keep `material.dart` only if CtPanel/the test harness need Theme (or remove once theme is not used in overlay).
6. **Tests:** Update province_overlay_test to use Key for close button and adjust any tab-related finds.

---

## 9. Out of Scope (for this plan)

- Changing other screens or panels to non-Material.
- Refactoring `CtPanel`/`CtNinePatchButton` to be theme-optional (can be done later).
- Adding new assets (e.g. close icon sprite) unless we decide to use one; Text('×') is sufficient for the plan.

---

## 10. Acceptance (from spec, unchanged)

All existing overlay AC in `SPEC/ui/province-sea-zone-detail-overlay.md` still hold; the only behavioral change is that the close control and tabs are non-Material and pixel-art friendly. No change to open/close/switch/hover behavior or content.
