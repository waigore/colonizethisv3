# UnitsPanelShell (component)

**SPEC/ui/components** — Reusable scaffold for human-player unit panels (civilian, military, naval). Implementation: [`app/lib/features/game/widgets/units/shared/units_panel_shell.dart`](../../../app/lib/features/game/widgets/units/shared/units_panel_shell.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtPanel*, § *CtTopBar*, § *Editorial-monocle palette*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical chrome for the three unit-panel screen specs listed under [Consumers](#consumers).

---

## Purpose

Consolidates the constrained-panel + `CtPanel` + `CtTopBar` + scrollable-list / empty-state chrome shared by the Civilian, Military, and Naval unit panels so each panel composes only its row content. Callers supply a title, trailing actions, `hasContent`, list children, and `emptyMessage`; the composite owns the `ConstrainedBox`, `Padding`, `CtPanel`, `CtTopBar` (no back button), `ListView`, and muted-italic empty copy. The outer modal bottom-sheet frame is the sibling [`UnitsPanelSheetSurface`](units-panel-sheet-surface.md). Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.

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
| `panelConstraints` | `BoxConstraints` | `UnitsPanelShell.defaultPanelConstraints` | Outer `ConstrainedBox` bounds. Default `maxWidth: 400` / `maxHeight: 500` mirrors the bottom-sheet sizing pinned by every consumer panel today. |

Exposed constant: `UnitsPanelShell.defaultPanelConstraints = BoxConstraints(maxWidth: 400, maxHeight: 500)`.

---

## Layout / wireframe

```text
ConstrainedBox(panelConstraints)                 -- default 400 × 500 dp
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

The `CtPanel` + `Column` + top-bar skeleton is the shared
[`CtPanelWithTopBar`](ct-panel-with-top-bar.md) (#3279 §5). The outer 8 dp
padding is a gutter so the `CtPanel` border never touches the edge. The `CtTopBar` always renders without the leading back button — every consumer is hosted in a side panel, bottom sheet, or rail surface that owns its own back/close affordance.

---

## Behavior

1. **Trailing-actions layout.** Zero actions → `CtTopBar.trailing == null`; one action → that widget; two or more → a `Row(mainAxisSize: min)` with 4 dp `SizedBox` separators. Consumers that need additional spacing wrap their actions before passing them in.
2. **Populated branch.** With `hasContent == true`, the body is a `ListView(shrinkWrap: true)` with the supplied `listPadding`. The shell mounts no Material elevation, divider, or row of its own; row chrome is the consumer's responsibility.
3. **Empty branch.** With `hasContent == false`, the body is a centered `Text(emptyMessage)` in `EditorialMonoclePalette.muted` italic so the empty surface honours the editorial-monocle dark contract instead of the default Material `onSurfaceVariant` token.
4. **No internal state.** The composite is a `StatelessWidget`. Every consumer-driven mutation (selection, expansion, sort) re-runs `build` from the parent.
5. **Constraints owner.** The outer `ConstrainedBox` defaults to `defaultPanelConstraints`. The Naval panel widens it on `>= 1280` dp viewports per [naval-units-panel.md](../naval-units-panel.md); every consumer falls back to `defaultPanelConstraints` at narrower viewports so the same 320 dp pin contract applies (see [mobile-adaptation.md](../mobile-adaptation.md) § 7).

---

## States and variants

The composite has no internal state. Variants are driven entirely by `panelConstraints` and `hasContent`:

| Variant | `panelConstraints` | `hasContent` | Body |
|---------|---------------------|--------------|------|
| Default populated | `defaultPanelConstraints` | `true` | `ListView` |
| Default empty | `defaultPanelConstraints` | `false` | Muted-italic empty text |
| Wide populated | naval `>= 1280` dp override | `true` | `ListView` |

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `UNIT10001` | [`civilian-units-panel.md`](../civilian-units-panel.md) | Bottom-sheet host; trailing actions include sort + scope toggles. |
| `UNIT20001` | [`military-units-panel.md`](../military-units-panel.md) | Side-panel host; trailing includes the **Train** entry-point. |
| `UNIT30001` | [`naval-units-panel.md`](../naval-units-panel.md) | Side-panel host; widens `panelConstraints` on `>= 1280` dp viewports. |

Each consumer spec links back here for the chrome contract instead of redeclaring the `ConstrainedBox` + `CtPanel` + `CtTopBar` + `ListView` hierarchy.

---

## Acceptance criteria (Given–When–Then)

- **Given** a `UnitsPanelShell` mounted with `title = 'Civilian Units'`, `hasContent = true`, and a single-child `listChildren`, **When** the tree settles, **Then** exactly one `CtPanel` and exactly one `CtTopBar` with `title == 'Civilian Units'` and `showBackButton == false` are mounted, and the supplied child is reachable inside a `ListView` descendant.
- **Given** a `UnitsPanelShell` mounted with `hasContent = false` and `emptyMessage = 'No civilian units.'`, **When** the tree settles, **Then** no `ListView` is mounted, the empty message renders, and its resolved `TextStyle.color` equals `EditorialMonoclePalette.muted` with `fontStyle == FontStyle.italic`.
- **Given** `actions = const []`, **When** the shell builds, **Then** `CtTopBar.trailing == null` in the rendered subtree.
- **Given** `actions = [a, b]`, **When** the shell builds, **Then** the trailing slot mounts a `Row(mainAxisSize: MainAxisSize.min)` with a 4 dp `SizedBox` between the two children.
- **Given** the host pumps the shell with no override, **When** the outer `ConstrainedBox` resolves, **Then** its `constraints.maxWidth == 400` and `constraints.maxHeight == 500`.
- **Given** the source `app/lib/features/game/widgets/units/shared/units_panel_shell.dart`, **When** read, **Then** it contains `defaultPanelConstraints` with `maxWidth: 400` / `maxHeight: 500` and references `EditorialMonoclePalette.muted` (canonical chrome regression guard).

---

## Tests

- `app/test/units_panel_shared_widgets_test.dart` — widget-level contract tests pinning the trailing-actions layout, populated vs empty branches, and the default panel constraints.
- `app/test/unit_panels_320dp_min_viewport_test.dart` — pins the three hosted panels at `kMinViewportWidth = 320` dp without horizontal overflow inside `defaultPanelConstraints`.
- `app/test/spec_components_units_panel_shell_test.dart` — spec-pinning tests asserting this spec exists, declares the canonical sections, enumerates the three consumers by stable screen id, and restates the `maxWidth: 400` / `maxHeight: 500` default constraints.

---

## Related

- Bottom-sheet host frame: [`units-panel-sheet-surface.md`](units-panel-sheet-surface.md).
- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtPanel*, § *CtTopBar*, § *Editorial-monocle palette*.
- Shared skeleton: [`ct-panel-with-top-bar.md`](ct-panel-with-top-bar.md).
- Hosting surfaces: [`empire-overview.md`](../empire-overview.md), [`in-game-shell-narrow.md`](../in-game-shell-narrow.md), [`mobile-adaptation.md`](../mobile-adaptation.md) § 7.
- Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
