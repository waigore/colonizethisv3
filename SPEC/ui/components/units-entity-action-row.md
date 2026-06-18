# UnitsEntityActionRow (component)

**SPEC/ui/components** — Reusable per-entity row for unit, army, and fleet rows hosted inside [`UnitsPanelShell`](units-panel-shell.md) panels. Implementation: [`app/lib/features/game/widgets/units/shared/units_entity_action_row.dart`](../../../app/lib/features/game/widgets/units/shared/units_entity_action_row.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtActionTextButton*, § *CtDangerTextButton*, § *CtCircularLocateButton*, § *CtNinePatchButton*, § *Editorial-monocle palette*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical row layout referenced by the screen specs under [Consumers](#consumers).

---

## Purpose

Consolidates the per-entity row layout shared by the Civilian, Military, and Naval unit panels: a left details cluster, a right actions cluster, and the narrow-width icon-only collapse rule. Callers supply `details` and a list of [`UnitsEntityAction`](#widget-contract) entries; the composite owns the `UnitsPanelRowChrome` gradient surface, the mockup compact-pill row actions (see [Action pill family](#action-pill-family-both-modes)), the wrap-vs-row choice driven by `dense`, the collapse breakpoints, and the per-action icon-only opt-in. Tracking issues: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9, [#3514](https://github.com/waigore/colonizethisv3/issues/3514).

---

## Widget contract

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `details` | `Widget` | required | Left details cluster, wrapped in `Expanded`. |
| `actions` | `List<UnitsEntityAction>` | `const []` | Right actions cluster. Empty list → no cluster mounted. |
| `iconOnlyBreakpoint` | `double` | `280` | Outer-width threshold below which default-mode actions collapse to icon-only. |
| `spacing` | `double` | `6` | Inter-button gap (`Wrap.spacing/runSpacing` in default mode, `SizedBox.width` between dense actions). |
| `dense` | `bool` | `false` | Switches the cluster to the naval inline-pill footprint (no wrap, smaller pills). Naval rows opt in; civilian/military rows keep `dense: false`. |

`UnitsEntityAction` is the per-action descriptor: `tooltip`, `icon`, `label`, `onPressed`, `buttonKey` (stable e2e key applied to the rendered pill), `iconOnly` (per-action icon-only opt-in; renders the circular `CtCircularLocateButton`, used by the military/naval right-end Locate pill), and `variant` (`UnitsEntityActionVariant`, default `neutral`; `danger` selects the `CtDangerTextButton` pill).

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

### Action pill family (both modes)

```text
action.iconOnly         -> CtCircularLocateButton(icon, key: buttonKey)   -- circular .locate-btn
action.variant == danger-> CtDangerTextButton(label, icon, iconOnly: forced, key)
otherwise               -> CtActionTextButton(label, icon, iconOnly: forced, key)
```

`forced` = the width-driven collapse predicate; it suppresses the label on neutral/danger pills only. Per-action `iconOnly` Locate controls always render circular.

### Default cluster (`dense: false`)

```text
Wrap(alignment: end, crossAxisAlignment: center, spacing, runSpacing)
  [action pill (forced = iconOnly)]
```

### Dense cluster (`dense: true`)

```text
LayoutBuilder(denseMaxWidth)
  denseIconOnly = iconOnly || denseMaxWidth < 70 * actions.length
  Row(min, crossAxisAlignment: center)
    [action pill (forced = denseIconOnly)] separated by SizedBox(width: spacing)
```

The dense `Row` is `mainAxisSize: min`, so it cannot wrap at the naval default width (420–640 dp). The `70 * actions.length` heuristic keeps Move + Split + Locate in label mode and collapses below ~150 dp.

---

## Behavior

1. **Outer chrome.** Every row paints through `UnitsPanelRowChrome` (gradient + 1 dp `EditorialMonoclePalette.accentDim` border). No outer `Padding`; host lists supply `listPadding` via [`UnitsPanelShell`](units-panel-shell.md).
2. **Default collapse.** Outer width `< iconOnlyBreakpoint` drops every default-mode neutral/danger label via the pill `iconOnly` flag; the `Wrap` may flow onto a second run.
3. **Dense collapse.** Dense rows cannot wrap; the inner `LayoutBuilder` forces icon-only below `70 dp * actions.length`. The outer `iconOnly` predicate forces the same collapse.
4. **Per-action `iconOnly` opt-in.** `UnitsEntityAction.iconOnly == true` always renders the rightmost circular `CtCircularLocateButton` so Move and Split keep their labels.
5. **No internal state.** `StatelessWidget`. Presses forward to `onPressed`; `null` handlers render the pill disabled (`enabled = false`).

---

## States and variants

| `dense` | Effective width | Action rendering |
|---------|-----------------|------------------|
| `false` | outer `>= iconOnlyBreakpoint` | `Wrap` of `Icon + label` pills |
| `false` | outer `< iconOnlyBreakpoint` | `Wrap` of icon-only pills |
| `true` | outer `>= iconOnlyBreakpoint` **and** dense `>= 70 * actions.length` | `Row(min)` of `Icon + label` pills |
| `true` | outer `< iconOnlyBreakpoint` **or** dense `< 70 * actions.length` | `Row(min)` of icon-only pills |

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `UNIT10001` | [`civilian-units-panel.md`](../civilian-units-panel.md) | Default mode. Row actions: Assign (idle), Cancel (work in progress). |
| `UNIT20001` | [`military-units-panel.md`](../military-units-panel.md) | Default mode. Army actions: Move, Split, right-end Locate via `iconOnly = true` (issue #3514). |
| `UNIT30001` | [`naval-units-panel.md`](../naval-units-panel.md) | Dense mode (R25). Fleet actions: Move (regular only), Split (when allowed), right-end Locate via `iconOnly = true` (R27). |

Consumer specs link back here instead of redeclaring the surface, pill footprint, and thresholds.

---

## Acceptance criteria (Given–When–Then)

- **Given** a row with one neutral `UnitsEntityAction(label: 'Move')` in a 420 dp parent, **When** settled, **Then** a `CtActionTextButton` shows the `Move` label and exactly one `UnitsPanelRowChrome` is mounted.
- **Given** the same row in a 220 dp parent (`< iconOnlyBreakpoint`), **When** settled, **Then** the `CtActionTextButton` has `iconOnly == true` and the `Move` label `Text` is absent.
- **Given** `actions = const []`, **When** the row builds, **Then** the outer `Row` contains only `Expanded(details)`.
- **Given** `dense = true` and three actions in a 400 dp parent, **When** settled, **Then** the cluster mounts a `Row(mainAxisSize: MainAxisSize.min)` (no `Wrap`).
- **Given** `iconOnly = true` on one action, **When** the row builds, **Then** it renders a `CtCircularLocateButton` and sibling pills keep labels.
- **Given** a `danger`-variant action, **When** the row builds, **Then** it renders a `CtDangerTextButton`.
- **Given** `onPressed = null`, **When** the row builds, **Then** the rendered pill reports `enabled == false`.

---

## Tests

- `app/test/units_panel_shared_widgets_test.dart` — wide vs narrow rendering and the `UnitsPanelRowChrome` wrapper (`group UnitsEntityActionRow`).
- `app/test/naval_units_panel_mockup_fidelity_test.dart` — naval `dense: true` R25 footprint and R27 Locate-iconOnly contract against the naval mockup.
- `app/test/spec_components_units_entity_action_row_test.dart` — spec-pinning tests for canonical sections, consumer enumeration, the `iconOnlyBreakpoint = 280` default, and the 1000-word ceiling.

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtActionTextButton*, *CtDangerTextButton*, *CtCircularLocateButton*, *CtNinePatchButton*, *Editorial-monocle palette*.
- Sibling composite: [`units-panel-shell.md`](units-panel-shell.md) (outer chrome that hosts these rows).
- Consumer screen specs: [`civilian-units-panel.md`](../civilian-units-panel.md), [`military-units-panel.md`](../military-units-panel.md), [`naval-units-panel.md`](../naval-units-panel.md).
- Narrow-viewport policy: [`mobile-adaptation.md`](../mobile-adaptation.md) § 7.
- Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
