# ProductionAllocationRow (component)

**SPEC/ui/components** — Reusable per-recipe row inside the Production panel Allocation subpanel. Implementation: [`app/lib/features/game/widgets/production_allocation_row.dart`](../../../app/lib/features/game/widgets/production_allocation_row.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtSlider*, *StrictAssetIcon*, *Editorial-monocle palette*, *CtGradients*.

Not a screen; no stable screen ID. Canonical row layout referenced by the screen spec under [Consumers](#consumers).

---

## Purpose

Consolidates the per-recipe layout used by the Allocation subpanel: a header (label + affordance readout), a body row (`Expanded` `CtSlider` + numeric desired output + four icon-only step / action buttons), and the row chrome painted by [`ProductionAllocationRowChrome`](../../../app/lib/features/game/widgets/production_allocation_row_chrome.dart). Callers supply recipe, player state, effective labour, the desired-output map, and the change callback; the composite owns affordance recomputation, the slider cap clamp, the four-button cluster footprint, and long-press repeat for the ± buttons. The inner step-button surface ([`ProductionStepButtonSurface`](../../../app/lib/features/game/widgets/production_allocation_row_buttons.dart): 26 dp `CtGradients.buttonGradient` inside a 1 dp `EditorialMonoclePalette.border` outline, 0.3 disabled opacity) is shared with the Available subpanel's per-tier Labour Controls. Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.

---

## Widget contract

| Prop | Type | Description |
|------|------|-------------|
| `recipe` | `ProductionRecipe` | Catalog recipe rendered by the row. |
| `player` | `Player` | Human player whose stockpile + worker pool drive affordance. |
| `effectiveLabour` | `int` | Labour pool available this turn. |
| `desiredOutputByRecipe` | `Map<String, int>` | Desired-output map; recipes with desired `0` may be absent. |
| `onDesiredOutputChanged` | `ValueChanged<Map<String, int>>` | Mutation callback receiving a fresh map clone. |
| `buildRecipeLabel` | `Widget Function(ProductionRecipe)` | Builds the left header cell (icon + name + parenthesised inputs). |
| `l10n` | `AppLocalizations` | Affordance / action / tooltip strings. |
| `theme` | `ThemeData` | Active editorial-monocle theme; styles header right cell + read-back numeral. |

All props `required`. Constants: `kProductionAllocationSliderCap = 50`, `kProductionAllocationStepButtonSize = 26`, `kProductionAllocationStepButtonDisabledOpacity = 0.3`.

---

## Layout / wireframe

```text
ProductionAllocationRowChrome(padding: 8/8)
  Column(min, start)
    Row(start)                                                  -- header
      Expanded(flex 2, buildRecipeLabel(recipe))
      Expanded(flex 1, Text(max · bottleneck, theme.labelSmall, right))
    Row(center)                                                 -- body
      Expanded(CtSlider(value, max: sliderMax, divisions,
                        comfortHeadroomActive))
      Row(min)                                                  -- buttons
        SizedBox(30, Text(desired, right, theme.bodySmall))
        ProductionAllocationStepButton(−   alloc_decrement)
        ProductionAllocationStepButton(+   alloc_increment)
        ProductionAllocationActionIconButton(max  alloc_maximize)
        ProductionAllocationActionIconButton(clr  alloc_clear)
```

Buttons are separated by `SizedBox(width: 4)`. Each paints `ProductionStepButtonSurface` and fades to 0.3 opacity when disabled.

---

## Behavior

1. **Affordance recompute.** Every `build` calls `computeRecipeAffordance(recipe, stockpile, desiredOutputByRecipe, effectiveLabour)` for `maxDesiredOutput` and the limiting label (`Labour` or input display name). Cross-row coupling re-runs the affordance pass when `desiredOutputByRecipe` mutates.
2. **Slider clamp.** `sliderMax = maxAchievable == 0 ? 0.0 : maxAchievable.clamp(1, kProductionAllocationSliderCap).toDouble()`. Thumb is `desired.clamp(0, maxAchievable).toDouble()`. Drag callbacks round and clamp; `value == 0` removes the recipe key, otherwise sets it.
3. **Enabled gating.** `−` iff `desired > 0`. `+` iff `maxAchievable > 0 && desired < maxAchievable`. **Maximize** iff `+` would be (`canIncrement`). **Clear** iff `desired > 0`.
4. **Step mutations.** `±` delegate to `applyProductionRecipeIncrement` / `applyProductionRecipeDecrement` in [`production_allocation_mutations.dart`](../../../app/lib/features/game/widgets/production_allocation_mutations.dart); each returns `false` on no-change (stops repeat timers). **Maximize** writes `affordance.maxDesiredOutput`; **Clear** removes the recipe key.
5. **Long-press repeat (± only).** `ProductionAllocationStepButton` uses `GestureDetector` long-press (~500 ms via `kProductionAllocationRepeatInitialDelay`) plus `Timer.periodic` at `kProductionAllocationRepeatInterval` (125 ms). Repeats stop at bounds, on release, or on dispose. Maximize and Clear are single-tap.
6. **Comfort headroom.** The slider receives `comfortHeadroomActive` from `recipeAllocationComfortHeadroomActive(...)` so the thumb→max segment paints in the comfort tint per [`production-panel.md`](../production-panel.md) § *Comfort headroom (slider track)*.
7. **Stateless.** `ProductionAllocationRow` is `StatelessWidget`; only `ProductionAllocationStepButton` carries a per-button `Timer?` for repeats.

---

## States and variants

| `maxAchievable` | `desired` | `−` | `+` | Max | Clear |
|-----------------|-----------|-----|-----|-----|-------|
| `0` | `0` | off | off | off | off |
| `> 0` | `0` | off | on | on | off |
| `> 0` | `0 < d < max` | on | on | on | on |
| `> 0` | `d == max` | on | off | off | on |

No theme variants; always paints through `ProductionAllocationRowChrome`. Narrow / wide layout is decided by the host panel; row width tracks the host cell.

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `GAME20001` | [`production-panel.md`](../production-panel.md) | Allocation subpanel renders one `ProductionAllocationRow` per recipe between `CtBrassDivider` separators. |

The Available subpanel's per-tier Labour Controls reuse only `ProductionStepButtonSurface`, not this row composite.

---

## Acceptance criteria (Given–When–Then)

- **Given** a recipe with `maxAchievable > 0` and `desired = 0`, **When** the row builds, **Then** `−` is disabled, `+` and maximize are enabled, and clear is disabled.
- **Given** the user taps `+` with `desired < maxAchievable`, **When** the gesture commits, **Then** `onDesiredOutputChanged` receives a map clone where `recipe.id` is `desired + 1` and other entries are preserved.
- **Given** the user taps `−` with `desired = 1`, **When** the gesture commits, **Then** `onDesiredOutputChanged` receives a map clone where `recipe.id` is **removed** (zero encoded as absence).
- **Given** the user long-presses `+`, **When** the press passes ~500 ms and is still held, **Then** the composite dispatches additional `applyProductionRecipeIncrement` invocations at `kProductionAllocationRepeatInterval` cadence until release or `false` (clamped at `maxAchievable`).
- **Given** the user taps maximize, **When** the gesture commits, **Then** `onDesiredOutputChanged` receives a map where `recipe.id == affordance.maxDesiredOutput`.
- **Given** the user taps clear with `desired > 0`, **When** the gesture commits, **Then** `onDesiredOutputChanged` receives a map where `recipe.id` is removed.
- **Given** `maxAchievable == 0`, **When** the row builds, **Then** the slider renders `max == 0`, `divisions == 1`, and every action button reports `enabled == false`.
- **Given** the row is mounted, **When** the tree settles, **Then** exactly one `ProductionAllocationRowChrome` ancestor wraps the column and paints `CtGradients.rowGradient` inside a 1 dp `EditorialMonoclePalette.accentDim` border (chrome regression guard).

---

## Tests

- `app/test/production_allocation_row_buttons_test.dart` — ± / maximize / clear gating, long-press repeat, disabled-opacity contract.
- `app/test/production_allocation_row_chrome_test.dart` — `CtGradients.rowGradient` + 1 dp `accentDim` border surface.
- `app/test/production_allocation_provider_test.dart` — mutation helpers consumed by this row.
- `app/test/spec_components_production_allocation_row_test.dart` — spec-pinning: canonical sections, `GAME20001` consumer, `kProductionAllocationSliderCap = 50`, 1000-word ceiling.

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtSlider*, *StrictAssetIcon*, *Editorial-monocle palette*, *CtGradients*.
- Sibling chrome: [`ProductionStepButtonSurface`](../../../app/lib/features/game/widgets/production_allocation_row_buttons.dart) — also consumed by Labour Controls in the Available subpanel.
- Consumer: [`production-panel.md`](../production-panel.md) § *Allocation row chrome*, § *Allocation step buttons*.
- Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
