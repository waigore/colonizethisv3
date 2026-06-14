# ProductionAllocationRow (component)

**SPEC/ui/components** — Reusable per-recipe row inside the Production panel Allocation subpanel. Implementation: [`app/lib/features/game/widgets/production_allocation_row.dart`](../../../app/lib/features/game/widgets/production_allocation_row.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtSlider*, *StrictAssetIcon*, *Editorial-monocle palette*, *CtGradients*.

Not a screen; no stable screen ID. Canonical row layout referenced by the screen spec under [Consumers](#consumers).

---

## Purpose

Consolidates the per-recipe Allocation-subpanel layout: a header (label + affordance readout), a body row (`Expanded` `CtSlider` + numeric desired output + four icon-only step / action buttons), and chrome painted by [`ProductionAllocationRowChrome`](../../../app/lib/features/game/widgets/production_allocation_row_chrome.dart). The composite owns affordance recomputation, the slider cap clamp, the four-button footprint, and long-press repeat for the ± buttons. The inner step-button surface ([`ProductionStepButtonSurface`](../../../app/lib/features/game/widgets/production_allocation_row_buttons.dart): 26 dp `CtGradients.buttonGradient` inside a 1 dp `EditorialMonoclePalette.border` outline, 0.3 disabled opacity) is shared with the Available subpanel's Labour Controls. Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.

---

## Widget contract

| Prop | Type | Description |
|------|------|-------------|
| `recipe` | `ProductionRecipe` | Catalog recipe rendered by the row. |
| `player` | `Player` | Human player whose stockpile + worker pool drive affordance. |
| `effectiveLabour` | `int` | Labour pool available this turn. |
| `desiredOutputByRecipe` | `Map<String, int>` | Desired-output map; desired `0` may be absent. |
| `onDesiredOutputChanged` | `ValueChanged<Map<String, int>>` | Mutation callback receiving a fresh map clone. |
| `buildRecipeLabel` | `Widget Function(ProductionRecipe, bool locked)` | Builds the header label (icon + name + inputs); appends the `(locked)` marker when `locked`. |
| `l10n` | `AppLocalizations` | Affordance / action / tooltip strings. |
| `theme` | `ThemeData` | Active editorial-monocle theme. |
| `locked` | `bool` (default `false`) | When `true`, the recipe's `requiredTechId` is not unlocked for `player`; row renders visible-but-grayed and inert. |

All props except `locked` are `required`. Constants: `kProductionAllocationSliderCap = 50`, `kProductionAllocationStepButtonSize = 26`, `kProductionAllocationStepButtonDisabledOpacity = 0.3`, `kProductionRecipeLockedOpacity = 0.4`.

---

## Layout / wireframe

```text
ProductionAllocationRowChrome(padding: 8/8)
  Column(min, start)
    Row(start) -- header: Expanded(flex 2, buildRecipeLabel(recipe, locked))
                          Expanded(flex 1, Text(max · bottleneck, right))
    Row(center) -- body (locked: wrapped in IgnorePointer + Opacity(0.4))
        Expanded(CtSlider(value, max: sliderMax, divisions, comfortHeadroomActive))
        Row(min)
          SizedBox(30, Text(desired, right))
          ProductionAllocationStepButton(−   alloc_decrement)
          ProductionAllocationStepButton(+   alloc_increment)
          ProductionAllocationActionIconButton(max  alloc_maximize)
          ProductionAllocationActionIconButton(clr  alloc_clear)
```

Buttons are separated by `SizedBox(width: 4)`; each paints `ProductionStepButtonSurface`, fading to 0.3 opacity when disabled.

---

## Behavior

1. **Affordance recompute.** Every `build` calls `computeRecipeAffordance(recipe, stockpile, desiredOutputByRecipe, effectiveLabour)` for `maxDesiredOutput` and the limiting label (`Labour` or input name); cross-row coupling re-runs it when the map mutates.
2. **Slider clamp.** `sliderMax = maxAchievable == 0 ? 0.0 : maxAchievable.clamp(1, kProductionAllocationSliderCap).toDouble()`; thumb is `desired.clamp(0, maxAchievable)`. Drag rounds/clamps; `value == 0` removes the recipe key.
3. **Enabled gating.** `−` iff `desired > 0`. `+` iff `maxAchievable > 0 && desired < maxAchievable`. **Maximize** iff `+` would be. **Clear** iff `desired > 0`.
4. **Step mutations.** `±` delegate to `applyProductionRecipeIncrement` / `applyProductionRecipeDecrement` in [`production_allocation_mutations.dart`](../../../app/lib/features/game/widgets/production_allocation_mutations.dart) (return `false` on no-change to stop repeat timers). **Maximize** writes `affordance.maxDesiredOutput`; **Clear** removes the key.
5. **Long-press repeat (± only).** `ProductionAllocationStepButton` uses `GestureDetector` long-press (~500 ms, `kProductionAllocationRepeatInitialDelay`) + `Timer.periodic` at `kProductionAllocationRepeatInterval` (125 ms), stopping at bounds/release/dispose. Maximize and Clear are single-tap.
6. **Comfort headroom.** The slider's `comfortHeadroomActive` comes from `recipeAllocationComfortHeadroomActive(...)` per [`production-panel.md`](../production-panel.md) § *Comfort headroom (slider track)*.
7. **Stateless.** `ProductionAllocationRow` is `StatelessWidget`; only `ProductionAllocationStepButton` holds a `Timer?` for repeats.
8. **Locked (tech-gated) rows.** Host sets `locked` from `ProductionRecipesCatalog.isRecipeAvailableForPlayer(recipe, player.techUnlocked)`. When locked, `maxAchievable` is `0`, `buildRecipeLabel` appends the `--muted` `production_recipeLocked` marker, and the body Row is wrapped in `IgnorePointer` + `Opacity(kProductionRecipeLockedOpacity = 0.4)`; the row stays mounted.

---

## States and variants

| `maxAchievable` | `desired` | `−` | `+` | Max | Clear |
|-----------------|-----------|-----|-----|-----|-------|
| `0` | `0` | off | off | off | off |
| `> 0` | `0` | off | on | on | off |
| `> 0` | `0 < d < max` | on | on | on | on |
| `> 0` | `d == max` | on | off | off | on |

No theme variants; always paints through `ProductionAllocationRowChrome`. Narrow / wide layout is decided by the host; row width tracks the host cell.

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `GAME20001` | [`production-panel.md`](../production-panel.md) | Allocation subpanel renders one `ProductionAllocationRow` per recipe between `CtBrassDivider` separators. |

The Labour Controls reuse only `ProductionStepButtonSurface`, not this composite.

---

## Acceptance criteria (Given–When–Then)

- **Given** `maxAchievable > 0` and `desired = 0`, **When** the row builds, **Then** `−` and clear are disabled while `+` and maximize are enabled.
- **Given** the user taps `+` with `desired < maxAchievable`, **When** committed, **Then** `onDesiredOutputChanged` receives a clone with `recipe.id = desired + 1`, other entries preserved.
- **Given** the user taps `−` with `desired = 1`, **When** committed, **Then** the clone **removes** `recipe.id` (zero = absence).
- **Given** the user long-presses `+` past ~500 ms, **When** still held, **Then** further `applyProductionRecipeIncrement` calls fire at `kProductionAllocationRepeatInterval` until release or `false`, clamped at `maxAchievable`.
- **Given** the user taps maximize, **When** committed, **Then** the map sets `recipe.id == affordance.maxDesiredOutput`; clear with `desired > 0` removes `recipe.id`.
- **Given** `maxAchievable == 0`, **When** the row builds, **Then** the slider renders `max == 0`, `divisions == 1`, and every action button is `enabled == false`.
- **Given** the row is mounted, **When** settled, **Then** exactly one `ProductionAllocationRowChrome` ancestor paints `CtGradients.rowGradient` inside a 1 dp `EditorialMonoclePalette.accentDim` border.
- **Given** `locked == true`, **When** the row builds, **Then** the header shows the localized `production_recipeLocked` marker, the body Row is wrapped in `IgnorePointer` + `Opacity(0.4)`, affordance reads max `0`, and every action button is `enabled == false`.

---

## Tests

- `app/test/production_allocation_row_buttons_test.dart` — ± / maximize / clear gating, long-press repeat, disabled-opacity contract.
- `app/test/production_allocation_row_chrome_test.dart` — `CtGradients.rowGradient` + 1 dp `accentDim` border surface.
- `app/test/production_allocation_provider_test.dart` — mutation helpers consumed by this row.
- `app/test/spec_components_production_allocation_row_test.dart` — spec-pinning: canonical sections, `GAME20001` consumer, `kProductionAllocationSliderCap = 50`, 1000-word ceiling.
- `app/test/production_panel_cotton_weaving_lock_test.dart` — locked marker + `Opacity(0.4)`, unlocked, wool-never-locked (Refs #3470).

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtSlider*, *StrictAssetIcon*, *Editorial-monocle palette*, *CtGradients*.
- Sibling chrome: [`ProductionStepButtonSurface`](../../../app/lib/features/game/widgets/production_allocation_row_buttons.dart) — also used by Labour Controls.
- Consumer: [`production-panel.md`](../production-panel.md) § *Allocation row chrome* / *step buttons*. Tracking: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
