# ProductionAllocationRow (component)

**SPEC/ui/components** — Per-recipe Allocation row. Implementation: [`production_allocation_row.dart`](../../../app/lib/features/game/widgets/production/production_allocation_row.dart). Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtSlider*, *StrictAssetIcon*, *Editorial-monocle palette*, *CtGradients*. Not a screen; no stable ID. Row layout referenced under [Consumers](#consumers). Tracking: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.

---

## Purpose

Header (label + affordance), body (`Expanded` `CtSlider` + desired output + four step/action icons), chrome via [`ProductionAllocationRowChrome`](../../../app/lib/features/game/widgets/production/production_allocation_row_chrome.dart). Owns affordance recompute, slider clamp, four-button footprint, and ± long-press repeat. Step surface ([`ProductionStepButtonSurface`](../../../app/lib/features/game/widgets/production/production_allocation_row_buttons.dart): 26 dp `CtGradients.buttonGradient`, 1 dp `EditorialMonoclePalette.border`, 0.3 disabled opacity) is shared with Labour Controls.

---

## Widget contract

| Prop | Type | Description |
|------|------|-------------|
| `recipe` | `ProductionRecipe` | Catalog recipe for this row. |
| `player` | `Player` | Human whose stockpile + workers drive affordance. |
| `effectiveLabour` | `int` | Labour available this turn. |
| `desiredOutputByRecipe` | `Map<String, int>` | Desired outputs; `0` may be absent. |
| `onDesiredOutputChanged` | `ValueChanged<Map<String, int>>` | Receives a fresh map clone. |
| `buildRecipeLabel` | `Widget Function(ProductionRecipe, bool locked)` | Header label; appends `(locked)` when locked. |
| `l10n` | `AppLocalizations` | Affordance / action / tooltip strings. |
| `theme` | `ThemeData` | Editorial-monocle theme. |
| `locked` | `bool` (default `false`) | Tech-gated: grayed and inert when `true`. |

All props except `locked` are `required`. Constants: `kProductionAllocationSliderCap = 50`, `kProductionAllocationStepButtonSize = 26`, `kProductionAllocationStepButtonDisabledOpacity = 0.3`, `kProductionRecipeLockedOpacity = 0.4`.

---

## Layout / wireframe

```text
ProductionAllocationRowChrome(padding: 8/8)
  Column(min, start)
    Row(start) -- header: Expanded(flex 2, buildRecipeLabel(recipe, locked))
                          [optional counsel star]
                          Expanded(flex 1, unlocked only: Tooltip + Text(affordance, right, wraps))
    Row(center) -- body (locked: IgnorePointer + Opacity(0.4))
        Expanded(CtSlider(value, max: sliderMax, divisions, comfortHeadroomActive))
        Row(min)
          SizedBox(30, Text(desired, right))
          ProductionAllocationStepButton(−   alloc_decrement)
          ProductionAllocationStepButton(+   alloc_increment)
          ProductionAllocationActionIconButton(max  alloc_maximize)
          ProductionAllocationActionIconButton(clr  alloc_clear)
```

Buttons use `SizedBox(width: 4)` gaps and `ProductionStepButtonSurface`.

---

## Behavior

1. **Affordance.** Each `build` runs `computeRecipeAffordance(...)` for `maxDesiredOutput` and limiter (`Labour` or input name); re-runs on map mutation.
2. **Slider clamp.** `sliderMax = maxAchievable == 0 ? 0.0 : maxAchievable.clamp(1, kProductionAllocationSliderCap).toDouble()`; thumb `desired.clamp(0, maxAchievable)`. Drag rounds/clamps; `value == 0` drops the key.
3. **Gating.** `−` / Clear iff `desired > 0`. `+` / Maximize iff `maxAchievable > 0 && desired < maxAchievable`.
4. **Steps.** `±` use `applyProductionRecipeIncrement` / `Decrement` in [`production_allocation_mutations.dart`](../../../app/lib/features/game/widgets/production/production_allocation_mutations.dart) (`false` stops repeat). Maximize writes `maxDesiredOutput`; Clear removes the key.
5. **Long-press (±).** ~500 ms then `Timer.periodic` at 125 ms; Maximize/Clear are single-tap.
6. **Comfort headroom.** From `recipeAllocationComfortHeadroomActive(...)` per [`production-panel.md`](../production-panel.md).
7. **Stateless.** Only `ProductionAllocationStepButton` holds a repeat `Timer?`.
8. **Locked.** Host sets from `ProductionRecipesCatalog.isRecipeAvailableForPlayer`. Locked: `maxAchievable = 0`, muted `production_recipeLocked` marker, **affordance omitted**, body in `IgnorePointer` + `Opacity(0.4)`.
9. **Affordance copy (unlocked).** `formatProductionRecipeAffordanceCopy` → `Up to N` / `Cannot run` + limiter. Hover/long-press `Tooltip` + matching `semanticsLabel`; text wraps (no ellipsis).

---

## States and variants

| `maxAchievable` | `desired` | `−` | `+` | Max | Clear |
|-----------------|-----------|-----|-----|-----|-------|
| `0` | `0` | off | off | off | off |
| `> 0` | `0` | off | on | on | off |
| `> 0` | `0 < d < max` | on | on | on | on |
| `> 0` | `d == max` | on | off | off | on |

Always through `ProductionAllocationRowChrome`. Width tracks the host cell.

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `GAME20001` | [`production-panel.md`](../production-panel.md) | One row per recipe between `CtBrassDivider`s. |

Labour Controls reuse only `ProductionStepButtonSurface`.

---

## Acceptance criteria (Given–When–Then)

- **Given** `maxAchievable > 0` and `desired = 0`, **When** the row builds, **Then** `−` and clear are disabled while `+` and maximize are enabled.
- **Given** the user taps `+` with `desired < maxAchievable`, **When** committed, **Then** `onDesiredOutputChanged` receives a clone with `recipe.id = desired + 1`.
- **Given** the user taps `−` with `desired = 1`, **When** committed, **Then** the clone **removes** `recipe.id`.
- **Given** the user long-presses `+` past ~500 ms, **When** still held, **Then** increments fire at 125 ms until release or `false`, clamped at `maxAchievable`.
- **Given** the user taps maximize, **When** committed, **Then** the map sets `recipe.id == affordance.maxDesiredOutput`; clear with `desired > 0` removes `recipe.id`.
- **Given** `maxAchievable == 0`, **When** the row builds, **Then** slider `max == 0`, `divisions == 1`, and every action button is disabled.
- **Given** the row is mounted, **When** settled, **Then** one `ProductionAllocationRowChrome` paints `CtGradients.rowGradient` inside a 1 dp `accentDim` border.
- **Given** `locked == true`, **When** the row builds, **Then** the locked marker shows, affordance is omitted, body is `IgnorePointer` + `Opacity(0.4)`, max is `0`, and buttons are disabled.
- **Given** `locked == false` and `maxAchievable > 0`, **When** the row builds, **Then** affordance copy (`Up to N, limited by …`) is in a `Tooltip` and wraps without ellipsis.

---

## Tests

- `app/test/production_allocation_row_buttons_test.dart` — ± / max / clear gating, long-press, disabled opacity.
- `app/test/production_allocation_row_chrome_test.dart` — row gradient + `accentDim` border.
- `app/test/production_allocation_provider_test.dart` — mutation helpers.
- `app/test/spec_components_production_allocation_row_test.dart` — sections, `GAME20001`, cap `50`, 1000-word ceiling.
- `app/test/production_panel_cotton_weaving_lock_test.dart` — locked/unlocked/wool (Refs #3470).

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtSlider*, *StrictAssetIcon*, *Editorial-monocle palette*, *CtGradients*.
- Sibling: [`ProductionStepButtonSurface`](../../../app/lib/features/game/widgets/production/production_allocation_row_buttons.dart) (Labour Controls too).
- Consumer: [`production-panel.md`](../production-panel.md). Tracking: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
