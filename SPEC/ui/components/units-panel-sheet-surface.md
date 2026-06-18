# UnitsPanelSheetSurface (component)

**SPEC/ui/components** — Bottom-sheet host chrome shared by the three unit panels (Civilian, Military, Naval). Implementation: [`app/lib/features/game/widgets/units/shared/units_panel_sheet_surface.dart`](../../../app/lib/features/game/widgets/units/shared/units_panel_sheet_surface.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *Editorial-monocle palette*, § *Radius tokens*.

This composite is **not** a screen and has **no** stable screen ID. It is the modal-bottom-sheet frame chrome for the three unit-panel screen specs listed under [Consumers](#consumers).

---

## Purpose

The three unit panels (`UNIT10001`, `UNIT20001`, `UNIT30001`) mount inside a `showModalBottomSheet` host in [`app_event_handler.dart`](../../../app/lib/core/services/app_event_handler.dart). Without bespoke chrome the sheet renders with the bare Material surface, which diverges from the per-panel HTML mockups. `UnitsPanelSheetSurface` paints the mockup `.sheet` frame so the modal host matches the mockups while the inner [`UnitsPanelShell`](units-panel-shell.md) keeps owning the panel body. Tracking issue: [#3514](https://github.com/waigore/colonizethisv3/issues/3514) (owner decision #4).

The mockup `.sheet` rule reproduced is:

```css
.sheet {
  background: linear-gradient(180deg, var(--surface) 0%, var(--bg-deep) 100%);
  border-top: 2px solid var(--accent-dim);
  border-radius: 4px 4px 0 0;
}
```

---

## Widget contract

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `child` | `Widget` | required | Panel content rendered inside the decorated sheet (typically a `UnitsPanelShell`-based panel, optionally wrapped in a height `ConstrainedBox` by the host). |

Exposed constants:

- `UnitsPanelSheetSurface.topEdgeWidth = 2.0` — width of the `--accent-dim` top edge.
- `UnitsPanelSheetSurface.topCornerRadius = CtRadius.medium` (`4` dp) — top corner radius.

The surface contributes only the outer frame; it does **not** constrain the panel's own sizing. Mockup `max-width` / `max-height` sizing parity (Civilian `680` / Military `720` / Naval sidebar `340`) is tracked as follow-up work on #3514.

---

## Layout / wireframe

```text
DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(topCenter -> bottomCenter,
      [EditorialMonoclePalette.surface, EditorialMonoclePalette.bgDeep]),
    border: Border(top: BorderSide(EditorialMonoclePalette.accentDim, 2.0)),
    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
  ),
  child: child,            -- panel content (UnitsPanelShell-based)
)
```

The host passes `showModalBottomSheet(backgroundColor: Colors.transparent, elevation: 0, ...)` so the Material sheet contributes no competing surface behind this frame.

---

## Behavior

1. **Gradient background.** Vertical `surface → bgDeep` gradient mirrors `.sheet { background: linear-gradient(180deg, var(--surface) 0%, var(--bg-deep) 100%) }`.
2. **Top edge.** A 2 dp `--accent-dim` top `BorderSide` mirrors `.sheet { border-top: 2px solid var(--accent-dim) }`.
3. **Top corner radius.** A 4 dp top-left/top-right radius (bottom radii `0`) mirrors `.sheet { border-radius: 4px 4px 0 0 }`.
4. **No internal state.** The composite is a `StatelessWidget`; it adds no padding, height cap, or sizing of its own.

---

## States and variants

The composite has no internal state and no variants. The same frame is painted for all three consumers and for all panel content states (populated, empty, observe read-only).

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `UNIT10001` | [`civilian-units-panel.md`](../civilian-units-panel.md) | Bottom-sheet host (`isScrollControlled: true`). |
| `UNIT20001` | [`military-units-panel.md`](../military-units-panel.md) | Bottom-sheet host. |
| `UNIT30001` | [`naval-units-panel.md`](../naval-units-panel.md) | Bottom-sheet host. |

---

## Acceptance criteria (Given–When–Then)

- **Given** a `UnitsPanelSheetSurface` mounted with any `child`, **When** the tree settles, **Then** exactly one `DecoratedBox` wraps the child whose `BoxDecoration.border.top` is a `BorderSide` of `EditorialMonoclePalette.accentDim` with `width == 2.0`.
- **Given** a `UnitsPanelSheetSurface` mounted with any `child`, **When** the tree settles, **Then** the wrapping `DecoratedBox` has a `BoxDecoration.borderRadius` whose `topLeft` and `topRight` radii equal `4.0` and whose `bottomLeft` and `bottomRight` radii equal `0.0`.
- **Given** a `UnitsPanelSheetSurface` mounted with any `child`, **When** the tree settles, **Then** the wrapping `BoxDecoration.gradient` is a `LinearGradient` whose `colors` are `[EditorialMonoclePalette.surface, EditorialMonoclePalette.bgDeep]`.
- **Given** a `UnitsPanelSheetSurface` mounted with a keyed `child`, **When** the tree settles, **Then** the child remains reachable in the subtree (the surface is a pure wrapper that does not replace its content).

---

## Tests

- `app/test/units_panel_sheet_surface_test.dart` — widget tests pinning the gradient, 2 dp `accent-dim` top edge, and 4 dp top corner radius, and the pass-through of the child.

---

## Related

- Inner body chrome: [`units-panel-shell.md`](units-panel-shell.md).
- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *Editorial-monocle palette*, § *Radius tokens*.
- Host: [`app_event_handler.dart`](../../../app/lib/core/services/app_event_handler.dart) `_openCivilianUnitsPanel` / `_openMilitaryUnitsPanel` / `_openNavalUnitsPanel`.
- Tracking issue: [#3514](https://github.com/waigore/colonizethisv3/issues/3514) (owner decision #4).
