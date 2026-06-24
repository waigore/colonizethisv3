# UnitsPanelShell (component)

**SPEC/ui/components** — Reusable scaffold for human-player unit panels (civilian, military, naval). Implementation: [`app/lib/features/game/widgets/units/shared/units_panel_shell.dart`](../../../app/lib/features/game/widgets/units/shared/units_panel_shell.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtPanel*, § *CtTopBar*, § *Editorial-monocle palette*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical chrome for the three unit-panel screen specs listed under [Consumers](#consumers).

---

## Purpose

Consolidates the constrained-panel + `CtPanel` + `CtTopBar` + scrollable-list / empty-state chrome for the Civilian, Military, and Naval unit panels so each composes only its row content. Callers supply title, actions, `hasContent`, list children, and `emptyMessage`; the composite owns the `ConstrainedBox`, `Padding`, `CtPanel`, `CtTopBar`, `ListView`, and muted-italic empty copy. Outer frame: [`UnitsPanelSheetSurface`](units-panel-sheet-surface.md). Tracking: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.

---

## Widget contract

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `title` | `String` | required | Title rendered by the inner `CtTopBar` (back button suppressed). |
| `actions` | `List<Widget>` | `const []` | `CtTopBar` trailing slot. Zero → no trailing; one → the widget; ≥2 → `Row(mainAxisSize: min)` with 4 dp `SizedBox` gaps. |
| `hasContent` | `bool` | required | Selects the populated vs empty branch. |
| `listChildren` | `List<Widget>` | required | Children mounted into the body `ListView` (inside an `Expanded`, no `shrinkWrap`) when `hasContent == true`. |
| `emptyMessage` | `String` | required | Copy rendered (muted italic) in the empty branch. |
| `listPadding` | `EdgeInsets` | `EdgeInsets.fromLTRB(8, 0, 8, 8)` | Padding for the populated-branch `ListView`. |
| `panelConstraints` | `BoxConstraints` | `defaultPanelConstraints` | Inner `ConstrainedBox` bounds. **Width unbounded** (host owns width); `maxHeight: 500` upper bound for standalone / Widgetbook / golden contexts. |

Exposed constant: `UnitsPanelShell.defaultPanelConstraints = BoxConstraints(maxHeight: 500)` (width unbounded — host-governed). Refs #3627.

### Bottom-sheet sizing (host-owned)

Each host wraps the panel in a `ConstrainedBox` from `unitsPanelSheetConstraints(viewport)` — one sizing contract for all three panels (Refs #3627):

| Viewport | `maxWidth` | `maxHeight` |
|----------|------------|-------------|
| Narrow (`width < 600` dp) | `viewport.width` (full) | `0.50 × viewport.height` (`50%` cap) |
| Wide (`width >= 600` dp) | `0.70 × viewport.width` | `0.55 × viewport.height` (`55vh`) |

Hosts set `isScrollControlled: true`; the civilian host uses `0.92 × height` only under `kCtE2EEnabled` (Refs #2336).

---

## Layout / wireframe

```text
ConstrainedBox(panelConstraints)                 -- width host-governed, maxHeight 500
  Padding(EdgeInsets.all(8))
    CtPanelWithTopBar(mainAxisSize: max)         -- fills allocated height
      topBar: CtTopBar(title, showBackButton: false, trailing?)
      Expanded                                   -- body fills the sheet cap
          hasContent
            ? ListView(padding: listPadding, children)   -- scrolls internally
            : Padding(EdgeInsets.all(24))
                Center
                  Text(emptyMessage,
                       style: theme.bodyMedium.copyWith(
                         color: EditorialMonoclePalette.muted,
                         fontStyle: italic))
```

The skeleton is the shared [`CtPanelWithTopBar`](ct-panel-with-top-bar.md) (#3279 §5); `CtTopBar` renders without the back button. Body fill behavior: see Behavior 2 (Refs #3627).

---

## Behavior

1. **Trailing-actions layout.** Zero actions → `CtTopBar.trailing == null`; one → that widget; ≥2 → `Row(mainAxisSize: min)` with 4 dp `SizedBox` separators.
2. **Populated branch.** With `hasContent == true`, the body is an `Expanded` `ListView` (no `shrinkWrap`) with `listPadding`; it fills the allocated sheet height and scrolls internally (Refs #3627). Row chrome is the consumer's responsibility.
3. **Empty branch.** With `hasContent == false`, the body is a centered `Text(emptyMessage)` in `EditorialMonoclePalette.muted` italic (dark-theme contract).
4. **No internal state.** A `StatelessWidget`; mutations re-run `build` from the parent.
5. **Constraints owner.** The **host** owns sizing via `unitsPanelSheetConstraints(viewport)`; the inner `ConstrainedBox` leaves width unbounded so the host rule applies. The 320 dp minimum-viewport pin holds ([mobile-adaptation.md](../mobile-adaptation.md) § 7).

---

## States and variants

No internal state. Variants follow host sizing and `hasContent`:

| Variant | Host sizing | `hasContent` | Body |
|---------|-------------|--------------|------|
| Narrow populated | full width × `50%` height | `true` | `ListView` |
| Narrow empty | full width × `50%` height | `false` | Muted-italic empty text |
| Wide populated | `70%` width × `55vh` | `true` | `ListView` |

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `UNIT10001` | [`civilian-units-panel.md`](../civilian-units-panel.md) | Bottom-sheet host; trailing sort + scope toggles. |
| `UNIT20001` | [`military-units-panel.md`](../military-units-panel.md) | Bottom-sheet host; trailing **Train** entry-point. |
| `UNIT30001` | [`naval-units-panel.md`](../naval-units-panel.md) | Bottom-sheet host; shared sizing (no fixed sidebar). |

---

## Acceptance criteria (Given–When–Then)

- **Given** `title = 'Civilian Units'`, `hasContent = true`, and one `listChildren` child, **When** the tree settles, **Then** a `CtPanel` and a `CtTopBar` (`title == 'Civilian Units'`, `showBackButton == false`) mount with the child inside a `ListView`.
- **Given** `hasContent = false` and `emptyMessage = 'No civilian units.'`, **When** the tree settles, **Then** no `ListView` mounts, the empty message renders, and its `TextStyle.color == EditorialMonoclePalette.muted` with `fontStyle == italic`.
- **Given** `actions = const []`, **When** the shell builds, **Then** `CtTopBar.trailing == null`.
- **Given** `actions = [a, b]`, **When** the shell builds, **Then** the trailing slot is a `Row(mainAxisSize: min)` with a 4 dp `SizedBox` between the children.
- **Given** a viewport with `width < 600` dp, **When** `unitsPanelSheetConstraints(viewport)` resolves, **Then** `maxWidth == viewport.width` and `maxHeight == viewport.height * 0.50` (±0.01).
- **Given** a viewport with `width >= 600` dp, **When** `unitsPanelSheetConstraints(viewport)` resolves, **Then** `maxWidth == viewport.width * 0.70` and `maxHeight == viewport.height * 0.55` (±0.01).
- **Given** the shell source, **When** read, **Then** `defaultPanelConstraints` leaves width unbounded (`maxHeight: 500` only) and references `EditorialMonoclePalette.muted`.
- **Given** `hasContent = true` under a height-capped host, **When** the tree settles, **Then** `CtPanelWithTopBar` uses `MainAxisSize.max` and the body `ListView` sits in an `Expanded` (no `shrinkWrap`), so the panel fills the cap and scrolls internally rather than hugging content (Refs #3627).

---

## Tests

- `app/test/units_panel_shared_widgets_test.dart` — trailing-actions layout and populated vs empty branches.
- `app/test/unit_panels_viewport_sizing_test.dart` — `unitsPanelSheetConstraints` (narrow `50%`; wide `70%` / `55vh`; the `600` dp boundary) and host-governed width. Refs #3627.
- `app/test/unit_panels_320dp_min_viewport_test.dart` — the three panels at 320 dp without overflow.
- `app/test/spec_components_units_panel_shell_test.dart` — spec-pin: sections, consumers by screen id, and the viewport-adaptive sizing contract.
- `app/test/unit_panels_goldens_test.dart` — desktop + mobile (`360 × 640` narrow-contract) golden baselines pinning the fill-height layout; Widgetbook **Mobile (360x640)** stories render the same (Refs #3627).

---

## Related

- Host frame: [`units-panel-sheet-surface.md`](units-panel-sheet-surface.md). Skeleton: [`ct-panel-with-top-bar.md`](ct-panel-with-top-bar.md).
- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtPanel*, § *CtTopBar*, § *Editorial-monocle palette*.
- Hosting: [`empire-overview.md`](../empire-overview.md), [`mobile-adaptation.md`](../mobile-adaptation.md) § 7. Tracking: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
