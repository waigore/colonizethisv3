# UnitsPanelShell (component)

**SPEC/ui/components** — Reusable scaffold for human-player unit panels (civilian, military, naval). Implementation: [`app/lib/features/game/widgets/units/shared/units_panel_shell.dart`](../../../app/lib/features/game/widgets/units/shared/units_panel_shell.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtPanel*, § *CtTopBar*, § *Editorial-monocle palette*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical chrome for the three unit-panel screen specs listed under [Consumers](#consumers).

---

## Purpose

Consolidates the constrained-panel + `CtPanel` + `CtTopBar` + scrollable-list / empty-state chrome shared by the Civilian, Military, and Naval unit panels so each panel composes only its row content. Callers supply a title, trailing actions, `hasContent`, list children, and `emptyMessage`; the composite owns the `ConstrainedBox`, `Padding`, `CtPanel`, `CtTopBar` (no back button), `ListView`, and muted-italic empty copy. Outer frame: [`UnitsPanelSheetSurface`](units-panel-sheet-surface.md). Tracking: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.

---

## Widget contract

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `title` | `String` | required | Title rendered by the inner `CtTopBar` (back button suppressed). |
| `actions` | `List<Widget>` | `const []` | Trailing widgets for the `CtTopBar` trailing slot. Zero widgets → no trailing; one → the widget; ≥2 → `Row(mainAxisSize: min)` separated by 4 dp `SizedBox` gaps. |
| `hasContent` | `bool` | required | Predicate selecting between the populated `ListView` branch and the empty branch. |
| `listChildren` | `List<Widget>` | required | Children mounted into the `ListView(shrinkWrap: true)` when `hasContent == true`. |
| `emptyMessage` | `String` | required | Copy rendered (muted italic) in the empty branch. |
| `listPadding` | `EdgeInsets` | `EdgeInsets.fromLTRB(8, 0, 8, 8)` | Padding applied to the `ListView` in the populated branch. |
| `panelConstraints` | `BoxConstraints` | `defaultPanelConstraints` | Inner `ConstrainedBox` bounds. **Width unbounded** so the host owns width (sizing below); `maxHeight: 500` is an upper bound for standalone / Widgetbook / golden contexts. |

Exposed constant: `UnitsPanelShell.defaultPanelConstraints = BoxConstraints(maxHeight: 500)` (width unbounded — host-governed). Refs #3627.

### Bottom-sheet sizing (host-owned)

Each consumer's bottom-sheet host wraps the panel in a `ConstrainedBox` from `unitsPanelSheetConstraints(viewport)` — the single sizing contract shared by all three panels (Refs #3627):

| Viewport | `maxWidth` | `maxHeight` |
|----------|------------|-------------|
| Narrow (`width < 600` dp) | `viewport.width` (full) | `0.50 × viewport.height` (`50%` cap) |
| Wide (`width >= 600` dp) | `0.70 × viewport.width` | `0.55 × viewport.height` (`55vh`) |

All three hosts set `isScrollControlled: true`. The civilian host widens height to `0.92 × viewport.height` **only** under `kCtE2EEnabled` (Refs #2336).

---

## Layout / wireframe

```text
ConstrainedBox(panelConstraints)                 -- width host-governed, maxHeight 500
  Padding(EdgeInsets.all(8))
    CtPanelWithTopBar(mainAxisSize: min)
      topBar: CtTopBar(title, showBackButton: false, trailing?)
      Flexible
          hasContent
            ? ListView(shrinkWrap, padding: listPadding, children)
            : Padding(EdgeInsets.all(24))
                Center
                  Text(emptyMessage,
                       style: theme.bodyMedium.copyWith(
                         color: EditorialMonoclePalette.muted,
                         fontStyle: italic))
```

The `CtPanel` + top-bar skeleton is the shared [`CtPanelWithTopBar`](ct-panel-with-top-bar.md) (#3279 §5). The 8 dp padding keeps the `CtPanel` border off the edge. `CtTopBar` renders without the back button — each host owns its dismissal.

---

## Behavior

1. **Trailing-actions layout.** Zero actions → `CtTopBar.trailing == null`; one → that widget; ≥2 → `Row(mainAxisSize: min)` with 4 dp `SizedBox` separators.
2. **Populated branch.** With `hasContent == true`, the body is a `ListView(shrinkWrap: true)` with `listPadding`; row chrome is the consumer's responsibility.
3. **Empty branch.** With `hasContent == false`, the body is a centered `Text(emptyMessage)` in `EditorialMonoclePalette.muted` italic (dark-theme contract, not Material `onSurfaceVariant`).
4. **No internal state.** The composite is a `StatelessWidget`; consumer-driven mutations re-run `build` from the parent.
5. **Constraints owner.** The bottom-sheet **host** owns sizing via `unitsPanelSheetConstraints(viewport)` (see [Bottom-sheet sizing](#bottom-sheet-sizing-host-owned)); the shell's inner `ConstrainedBox` leaves width unbounded so the host's `70%` wide / full-width narrow rule applies uniformly. The 320 dp minimum-viewport pin still holds ([mobile-adaptation.md](../mobile-adaptation.md) § 7).

---

## States and variants

No internal state. Variants are driven by host sizing and `hasContent`:

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
| `UNIT30001` | [`naval-units-panel.md`](../naval-units-panel.md) | Bottom-sheet host; shared `70%` wide / full-width narrow sizing (no fixed sidebar). |

Each consumer spec links back here instead of redeclaring the chrome hierarchy.

---

## Acceptance criteria (Given–When–Then)

- **Given** a `UnitsPanelShell` with `title = 'Civilian Units'`, `hasContent = true`, and one `listChildren` child, **When** the tree settles, **Then** one `CtPanel` and one `CtTopBar` (`title == 'Civilian Units'`, `showBackButton == false`) mount, and the child is inside a `ListView`.
- **Given** `hasContent = false` and `emptyMessage = 'No civilian units.'`, **When** the tree settles, **Then** no `ListView` mounts, the empty message renders, and its `TextStyle.color == EditorialMonoclePalette.muted` with `fontStyle == italic`.
- **Given** `actions = const []`, **When** the shell builds, **Then** `CtTopBar.trailing == null`.
- **Given** `actions = [a, b]`, **When** the shell builds, **Then** the trailing slot is a `Row(mainAxisSize: min)` with a 4 dp `SizedBox` between the children.
- **Given** a viewport with `width < 600` dp, **When** `unitsPanelSheetConstraints(viewport)` resolves, **Then** `maxWidth == viewport.width` and `maxHeight == viewport.height * 0.50` (±0.01).
- **Given** a viewport with `width >= 600` dp, **When** `unitsPanelSheetConstraints(viewport)` resolves, **Then** `maxWidth == viewport.width * 0.70` and `maxHeight == viewport.height * 0.55` (±0.01).
- **Given** the shell source, **When** read, **Then** `defaultPanelConstraints` leaves width unbounded (`maxHeight: 500` only) and references `EditorialMonoclePalette.muted`.

---

## Tests

- `app/test/units_panel_shared_widgets_test.dart` — trailing-actions layout and populated vs empty branches.
- `app/test/unit_panels_viewport_sizing_test.dart` — `unitsPanelSheetConstraints` (narrow `50%` / full width; wide `70%` / `55vh`; the `600` dp boundary) and host-governed width. Refs #3627.
- `app/test/unit_panels_320dp_min_viewport_test.dart` — the three panels at `kMinViewportWidth = 320` dp without overflow.
- `app/test/spec_components_units_panel_shell_test.dart` — spec-pin: sections, consumers by screen id, and the viewport-adaptive sizing contract.

---

## Related

- Host frame: [`units-panel-sheet-surface.md`](units-panel-sheet-surface.md). Skeleton: [`ct-panel-with-top-bar.md`](ct-panel-with-top-bar.md).
- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtPanel*, § *CtTopBar*, § *Editorial-monocle palette*.
- Hosting: [`empire-overview.md`](../empire-overview.md), [`mobile-adaptation.md`](../mobile-adaptation.md) § 7. Tracking: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
