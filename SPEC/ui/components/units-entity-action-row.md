# UnitsEntityActionRow (component)

**SPEC/ui/components** — Reusable per-entity row for unit, army, and fleet rows hosted inside [`UnitsPanelShell`](units-panel-shell.md) panels. Implementation: [`app/lib/features/game/widgets/units/shared/units_entity_action_row.dart`](../../../app/lib/features/game/widgets/units/shared/units_entity_action_row.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtNinePatchButton*, § *Editorial-monocle palette*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical row layout referenced by the screen specs under [Consumers](#consumers).

---

## Purpose

Consolidates the per-entity row layout shared by the Civilian, Military, and Naval unit panels: a left details cluster, a right actions cluster, and the narrow-width icon-only collapse rule. Callers supply `details` and a list of [`UnitsEntityAction`](#widget-contract) entries; the composite owns the `UnitsPanelRowChrome` gradient surface, the `CtNinePatchButton` pills, the wrap-vs-row choice driven by `dense`, the collapse breakpoints, and the per-action icon-only opt-in. Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.

---

## Widget contract

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `details` | `Widget` | required | Left details cluster, wrapped in `Expanded`. |
| `actions` | `List<UnitsEntityAction>` | `const []` | Right actions cluster. Empty list → no cluster mounted. |
| `iconOnlyBreakpoint` | `double` | `280` | Outer-width threshold below which default-mode actions collapse to icon-only. |
| `spacing` | `double` | `6` | Inter-button gap (`Wrap.spacing/runSpacing` in default mode, `SizedBox.width` between dense actions). |
| `dense` | `bool` | `false` | Switches the cluster to the naval inline-pill footprint (no wrap, smaller pills). Naval rows opt in; civilian/military rows keep `dense: false`. |

`UnitsEntityAction` is the per-action descriptor: `tooltip`, `icon`, `label`, `onPressed`, `iconOnly` (per-action icon-only opt-in, used by the naval right-end Locate pill), and `variant` (`UnitsEntityActionVariant`, default `neutral`; `danger` marks civilian destructive pills — issue #3514 — ignored here).

---

## Layout / wireframe

### Shared outer frame

```text
LayoutBuilder(maxWidth)
  iconOnly = maxWidth < iconOnlyBreakpoint           -- default 280 dp
  UnitsPanelRowChrome(margin: 0, padding: 8 / 6)
    Row(crossAxisAlignment: start)
      Expanded(details)
      if actions.isNotEmpty:
        SizedBox(width: dense ? spacing : 8)
        Flexible(fit: loose, align: topRight) [cluster — mode below]
```

### Default cluster (`dense: false`)

```text
Wrap(alignment: end, spacing, runSpacing)
  [Tooltip · CtNinePatchButton(minHeight: 32,
    padding: (iconOnly||action.iconOnly ? 8 : 10) / 6,
    child: iconOnly||action.iconOnly
      ? Icon(16)
      : Row(min) Icon(16) · SizedBox(4) · Text(label))]
```

### Dense cluster (`dense: true`)

```text
LayoutBuilder(denseMaxWidth)
  denseIconOnly = iconOnly || denseMaxWidth < 70 * actions.length
  Row(min)
    [Tooltip · CtNinePatchButton(minHeight: 24,
      padding: (denseIconOnly||action.iconOnly ? 4 : 7) / 3,
      child: denseIconOnly||action.iconOnly
        ? Icon(14)
        : Row(min) Icon(14) · SizedBox(3) · Text(label))]
    separated by SizedBox(width: spacing)
```

The dense `Row` is `mainAxisSize: min`, so it cannot wrap at the naval default width (420–640 dp). The `70 * actions.length` heuristic keeps Move + Split + Locate in label mode there and collapses to icons below ~150 dp.

---

## Behavior

1. **Outer chrome.** Every row paints through `UnitsPanelRowChrome` (gradient + 1 dp `EditorialMonoclePalette.accentDim` border). No outer `Padding`; host lists supply `listPadding` via [`UnitsPanelShell`](units-panel-shell.md).
2. **Default collapse.** Outer width `< iconOnlyBreakpoint` drops every default-mode action label; the `Wrap` may still flow onto a second run.
3. **Dense collapse.** Dense rows cannot wrap; the inner `LayoutBuilder` forces icon-only when the cluster is narrower than `70 dp * actions.length`. The outer `iconOnly` predicate also forces the same collapse.
4. **Per-action `iconOnly` opt-in.** `UnitsEntityAction.iconOnly == true` always renders icon-only (used by the naval right-end Locate pill so Move and Split keep their labels).
5. **No internal state.** `StatelessWidget`. Presses forward to `onPressed`; `null` handlers render the pill disabled via `CtNinePatchButton.enabled = false`.

---

## States and variants

| `dense` | Effective width | Action rendering |
|---------|-----------------|------------------|
| `false` | outer `>= iconOnlyBreakpoint` | `Wrap` of `Icon + label` pills |
| `false` | outer `< iconOnlyBreakpoint` | `Wrap` of icon-only pills |
| `true` | outer `>= iconOnlyBreakpoint` **and** dense `>= 70 * actions.length` | `Row(min)` of compact `Icon + label` pills |
| `true` | outer `< iconOnlyBreakpoint` **or** dense `< 70 * actions.length` | `Row(min)` of compact icon-only pills |

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `UNIT10001` | [`civilian-units-panel.md`](../civilian-units-panel.md) | Default mode. Row actions: Assign (idle), Cancel (work in progress). |
| `UNIT20001` | [`military-units-panel.md`](../military-units-panel.md) | Default mode. Army actions: Move, Split (each gated on its callback). |
| `UNIT30001` | [`naval-units-panel.md`](../naval-units-panel.md) | Dense mode (R25). Fleet actions: Move (regular only), Split (when allowed), right-end Locate via `iconOnly = true` (R27). |

Consumer specs link back here instead of redeclaring the gradient surface, pill footprint, and collapse thresholds.

---

## Acceptance criteria (Given–When–Then)

- **Given** a row with `details = Text('Left')` and one `UnitsEntityAction(label: 'Move', icon: Icons.route)` inside a 420 dp parent, **When** the tree settles, **Then** `Left` and `Move` both render and exactly one `UnitsPanelRowChrome` ancestor is mounted.
- **Given** the same row inside a 220 dp parent (`< iconOnlyBreakpoint`), **When** the tree settles, **Then** the button renders `Icons.route` and the `Move` label is absent.
- **Given** `actions = const []`, **When** the row builds, **Then** the outer `Row` contains only `Expanded(details)` (no `Flexible` action host).
- **Given** `dense = true` and three actions inside a 400 dp parent, **When** the tree settles, **Then** the cluster mounts a `Row(mainAxisSize: MainAxisSize.min)` (no `Wrap` ancestor).
- **Given** `dense = true` and the dense cluster is constrained below `70 dp * actions.length`, **When** the tree settles, **Then** every dense action renders icon-only.
- **Given** `iconOnly = true` on one action in an otherwise label-eligible row, **When** the row builds, **Then** that action renders icon-only and the siblings keep their labels.
- **Given** an action with `onPressed = null`, **When** the row builds, **Then** the `CtNinePatchButton` reports `enabled == false`.

---

## Tests

- `app/test/units_panel_shared_widgets_test.dart` — wide vs narrow rendering and the `UnitsPanelRowChrome` wrapper (`group UnitsEntityActionRow`).
- `app/test/naval_units_panel_mockup_fidelity_test.dart` — naval `dense: true` R25 footprint and R27 Locate-iconOnly contract against the naval mockup.
- `app/test/spec_components_units_entity_action_row_test.dart` — spec-pinning tests for canonical sections, consumer enumeration, the `iconOnlyBreakpoint = 280` default, and the 1000-word ceiling.

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtNinePatchButton*, *Editorial-monocle palette*.
- Sibling composite: [`units-panel-shell.md`](units-panel-shell.md) (outer chrome that hosts these rows).
- Consumer screen specs: [`civilian-units-panel.md`](../civilian-units-panel.md), [`military-units-panel.md`](../military-units-panel.md), [`naval-units-panel.md`](../naval-units-panel.md).
- Narrow-viewport policy: [`mobile-adaptation.md`](../mobile-adaptation.md) § 7.
- Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
