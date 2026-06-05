# CtPanelWithTopBar (component)

**SPEC/ui/components** — Reusable inner panel skeleton: a `CtPanel` (zero padding) wrapping a stretch `Column` whose first child is an optional top bar. Implementation: [`app/lib/widgets/ct_panel_with_top_bar.dart`](../../../app/lib/widgets/ct_panel_with_top_bar.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtPanel*, § *CtTopBar*.

This composite is **not** a screen and has **no** stable screen ID.

---

## Purpose

Consolidates the duplicated `CtPanel(padding: EdgeInsets.zero)` > `Column(crossAxisAlignment: stretch)` > `[topBar, ...content]` skeleton shared by `CtScreenShell` and `UnitsPanelShell` (issue [#3279](https://github.com/waigore/colonizethisv3/issues/3279) §5). Only the inner skeleton is shared: the two consumers differ in their outer frame (`Scaffold` + `SafeArea` vs `ConstrainedBox`), the column `mainAxisSize`, and how the body sizes itself (`Expanded` vs `Flexible`), so those concerns remain with the callers.

---

## Widget contract

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `topBar` | `Widget?` | no | `null` | First column child (typically a `CtTopBar`). When `null`, only `children` are mounted so callers can suppress the title band. |
| `children` | `List<Widget>` | yes | — | Column body rendered below `topBar`. Callers own any `Expanded` / `Flexible` wrapping and inter-child spacing. |
| `mainAxisSize` | `MainAxisSize` | no | `MainAxisSize.max` | Forwarded to the inner `Column`. `CtScreenShell` uses the default (`max`); `UnitsPanelShell` uses `min`. |

---

## Layout / wireframe

```text
CtPanel(padding: EdgeInsets.zero)
  Column(mainAxisSize, crossAxisAlignment: stretch)
    topBar?                                  -- mounted only when topBar != null
    ...children
```

---

## Behavior

1. **Optional top bar.** When `topBar == null`, the top-bar child is omitted entirely (no empty slot) so the panel frames only `children`.
2. **Stretch column.** The inner `Column` always uses `crossAxisAlignment: stretch` so children fill the panel width.
3. **No internal state.** The composite is a `StatelessWidget`; it owns no spacing or body sizing beyond the panel + column skeleton.

---

## Consumers

| Consumer | Spec | `mainAxisSize` | `topBar` |
|----------|------|----------------|----------|
| `CtScreenShell` | catalog § *CtScreenShell* | `max` | `CtTopBar` when `showTitleBar`, else `null` |
| `UnitsPanelShell` | [`units-panel-shell.md`](units-panel-shell.md) | `min` | `CtTopBar` (no back button, optional trailing) |

---

## Acceptance criteria (Given–When–Then)

- **Given** a `CtPanelWithTopBar` mounted with `topBar: CtTopBar(title: 'X')` and a single-child `children`, **When** the tree settles, **Then** exactly one `CtPanel` and exactly one `CtTopBar` with `title == 'X'` are mounted, and the supplied child is reachable in the subtree.
- **Given** a `CtPanelWithTopBar` mounted with `topBar: null` and a single-child `children`, **When** the tree settles, **Then** no `CtTopBar` is mounted, exactly one `CtPanel` is mounted, and the supplied child is reachable in the subtree.
- **Given** a `CtPanelWithTopBar` mounted with `mainAxisSize: MainAxisSize.min`, **When** the inner `Column` resolves, **Then** the mounted `Column.mainAxisSize == MainAxisSize.min`.

---

## Tests

- `app/test/ct_panel_with_top_bar_test.dart` — widget-level contract tests pinning the optional top-bar slot, the `CtPanel` wrapper, and the `mainAxisSize` forwarding.

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtPanel*, § *CtTopBar*.
- Consumers: [`units-panel-shell.md`](units-panel-shell.md), catalog § *CtScreenShell*.
- Tracking issue: [#3279](https://github.com/waigore/colonizethisv3/issues/3279) §5.
