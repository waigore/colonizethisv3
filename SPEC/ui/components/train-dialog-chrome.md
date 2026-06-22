# TrainDialogChrome (component)

**SPEC/ui/components** — Reusable header / divider / resource-bar / row-surface chrome shared by the train-at-capital dialogs. Implementation: [`app/lib/features/game/widgets/train_dialog_chrome.dart`](../../../app/lib/features/game/widgets/train_dialog_chrome.dart). Catalog atoms in [Related](#related).

This composite is **not** a screen and has **no** stable screen ID; consumers are listed in [Consumers](#consumers).

---

## Purpose

Consolidates the chrome (accent title + `×` dismiss, brass divider, boxed resource bar + optional deficit hint, resource chip, inline cost segment, per-unit row surface) shared by the train-at-capital dialogs so each composes only its body inside a single [`CtDialogShell`](../pixel-art-ui-catalog.md). The dark editorial-monocle contract (no Material `IconButton` / `Divider`, no raw `Colors.*`) lives in one file.

---

## Widget contract

`TrainDialogHeader` — `title` (`String`) rendered in `theme.textTheme.titleMedium` with `EditorialMonoclePalette.accent`, `kTrainDialogTitleLetterSpacing` (`0.05`), and `FontWeight.w600`; `onClose` (`VoidCallback`) fires when the trailing `×` `CtNinePatchButton` (32 dp min-height; padding `10 × 6`) is tapped.

`TrainDialogSectionDivider` — no props; renders `CtBrassDivider` inside `EdgeInsets.symmetric(vertical: 8)`.

`TrainDialogResourceBarBox` — single `child` inside a boxed inset strip (`bgDeep` background, 1 dp `border`, `EdgeInsets.all(8)`) per mockup `.resource-bar`. Shared by both dialogs.

`TrainDialogResourceEntry` — value object `{ label, value }` (`String`).

`TrainDialogResourceBar` — `entries` (`List<TrainDialogResourceEntry>`) inside a `TrainDialogResourceBarBox` as `Wrap(spacing 16, runSpacing 4, spaceAround)`; each entry is a muted label (`bodyMedium`, `muted`) + a **monospace bold** value (`w700`, `fontFamilyFallback: [SF Mono, Menlo, monospace]`, `tabularFigures`, `fg`). Treasury is `£` + comma-grouped (`£5,000`). Optional `deficitHint` (`String?`) renders below the box in `bodySmall` `danger`.

`TrainDialogResourceChip` — single `child` in a 4 dp-radius `BoxDecoration` (`CtGradients.rowGradient` + 1 dp `accentDim` border, padding `6 × 4`); content renders inside `DefaultTextStyle.merge(color: fg)`.

`TrainDialogUnitRowSurface` — single `child` in `CtGradients.rowGradient` + 1 dp `accentDim` border (padding `12 × 8`). Optional `margin` defaults to `EdgeInsets.only(bottom: 6)`.

`TrainDialogInlineCost` — inline per-unit-row cost segment (`icon`, numeric `label`, `tooltipMessage`, `isInsufficient`). The `icon + label` `Row` sits in a tap/hover `Tooltip` (`triggerMode: TooltipTriggerMode.tap`) within a `>= kMinTouchTargetSize` (44 dp) `ConstrainedBox` touch region; `label` (`bodySmall`) turns `danger` when `isInsufficient`. Tooltip-content rules: [`resource-icon-tooltip.md`](resource-icon-tooltip.md).

Exported constants: `kTrainDialogLockedOpacity = 0.4` (per [#2866](https://github.com/waigore/colonizethisv3/issues/2866) AC); `kTrainDialogTitleLetterSpacing = 0.05`.

---

## Layout / wireframe

```text
CtDialogShell(maxWidth: 480, maxHeight: 600)
  Column(min, start)
    TrainDialogHeader(title, onClose)
    TrainDialogSectionDivider()
    TrainDialogResourceBar(entries, deficitHint?)
    TrainDialogSectionDivider()
    Column of TrainDialogUnitRowSurface(...)            -- per unit row
      Row(...)                                          -- name + TrainDialogInlineCost wrap / stepper
    Footer (consumer-owned: Reset CtNinePatchButton)
```

Consumers may skip the resource bar (e.g. no capital).

---

## Behavior

1. **Stateless surfaces.** Every chrome widget is a `StatelessWidget`; affordance recomputation and stepper mutation belong to the host dialog state.
2. **Header dismiss.** `TrainDialogHeader` mounts `CtNinePatchButton` (not Material `IconButton`) so the dark button-surface contract is preserved. Tap fires `onClose`.
3. **Divider colour.** `TrainDialogSectionDivider` always paints `CtBrassDivider` — never Material `Divider` (guards the `check_app_no_material_*` lint ban).
4. **Resource bar styling.** `TrainDialogResourceBar` renders entries in a `TrainDialogResourceBarBox` with muted labels + monospace bold `--fg` values; `deficitHint` sits below in `--danger`.
5. **Resource chip.** `TrainDialogResourceChip` wraps inline icon + numeric content; the military/naval bars compose treasury / peasants / commodity chips inside a `TrainDialogResourceBarBox` with `£` + comma formatting.
6. **Unit row surface.** `TrainDialogUnitRowSurface` paints `CtGradients.rowGradient` in a 1 dp `accentDim` border; the consumer owns internal layout and applies `kTrainDialogLockedOpacity` (`0.4`) when tech-locked.
7. **Letter-spacing alignment.** `kTrainDialogTitleLetterSpacing = 0.05` matches `CtTopBar` and the combat-mode choice dialog.
8. **Inline cost tooltips.** `TrainDialogInlineCost` wraps each `icon + number` segment in a tap/hover `Tooltip` (localized resource name) with a `>= 44` dp touch region. Content rules: [`resource-icon-tooltip.md`](resource-icon-tooltip.md).

---

## States and variants

| Widget | Variant | Trigger | Render difference |
|--------|---------|---------|--------------------|
| `TrainDialogResourceBar` | No-deficit | `deficitHint == null` | Hint row omitted; only the `Wrap` renders. |
| `TrainDialogResourceBar` | Deficit | `deficitHint != null` | `SizedBox(height: 4)` + danger-coloured hint row appended. |
| `TrainDialogUnitRowSurface` | Locked | Host wraps the row in `Opacity(opacity: kTrainDialogLockedOpacity)` | Whole surface fades to 0.4 opacity. |
| `TrainDialogUnitRowSurface` | Custom margin | Caller overrides `margin` | Outer `Padding` adopts the caller margin (default `EdgeInsets.only(bottom: 6)`). |

The chrome widgets have no theme-mode branches; editorial-monocle is the only target.

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `UNIT40001` | [`train-civilians-dialog.md`](../train-civilians-dialog.md) | Civilian list + treasury / paper bar; six unit rows. |
| `UNIT50001` | [`train-military-dialog.md`](../train-military-dialog.md) | Regiment list + treasury / peasants + six commodity chips. |
| `UNIT60001` | [`train-naval-dialog.md`](../train-naval-dialog.md) | Ship list + treasury / peasants + four commodity chips. |

Consumer specs link back here instead of redeclaring the chrome.

---

## Acceptance criteria (Given–When–Then)

- **Given** a `TrainDialogHeader` with `title = 'Train Civilians'`, **When** the tree settles, **Then** one `CtNinePatchButton` and zero Material `IconButton`s are mounted, and `Text('Train Civilians')` resolves to `EditorialMonoclePalette.accent`.
- **Given** a `TrainDialogSectionDivider`, **When** the tree settles, **Then** one `CtBrassDivider` and zero Material `Divider`s are mounted.
- **Given** a `TrainDialogResourceBar` with two entries and `deficitHint == null`, **When** the tree settles, **Then** one `TrainDialogResourceBarBox` mounts, both labels + values render, and no descendant carries `EditorialMonoclePalette.danger`.
- **Given** a `TrainDialogResourceBar` with a treasury entry of `5000`, **When** the tree settles, **Then** the rendered value reads `£5,000`.
- **Given** a `TrainDialogResourceBar` with `deficitHint = 'Treasury low'`, **When** the tree settles, **Then** `Text('Treasury low')` resolves to `EditorialMonoclePalette.danger`.
- **Given** a `TrainDialogUnitRowSurface`, **When** the inner `DecoratedBox` resolves, **Then** its border is `Border.all(color: EditorialMonoclePalette.accentDim, width: 1)` and gradient is `CtGradients.rowGradient`.
- **Given** the source `app/lib/features/game/widgets/train_dialog_chrome.dart`, **When** read, **Then** it declares `kTrainDialogLockedOpacity = 0.4` and `kTrainDialogTitleLetterSpacing = 0.05` (canonical regression guard).
- **Given** a `TrainDialogInlineCost` with `tooltipMessage = 'Treasury'`, **When** the tree settles, **Then** one `Tooltip` (`message == 'Treasury'`, `triggerMode == TooltipTriggerMode.tap`) is mounted and its trigger-region height is `>= 44` dp.

---

## Tests

- `app/test/train_dialog_chrome_test.dart` — pins `TrainDialogHeader` accent title + `CtNinePatchButton` dismiss, `TrainDialogSectionDivider` selection, the resource-bar box + `£`/comma formatting, and `kTrainDialogLockedOpacity`.
- `app/test/train_dialogs_320dp_min_viewport_test.dart` — pins both dialogs at `kMinViewportWidth = 320` dp (Refs [#2870](https://github.com/waigore/colonizethisv3/issues/2870) S8/S10).
- `app/test/spec_components_train_dialog_chrome_test.dart` — spec-pinning test (sections, consumers, constants, ≤1000-word ceiling).
- `app/test/train_dialog_inline_cost_tooltip_test.dart` — pins `TrainDialogInlineCost` tooltip + tap trigger + 44 dp target, the commodity tooltip helper, the dialog cost-icon tooltips, and the `_InlineCost` de-dup guard.

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) (*CtDialogShell*, *CtNinePatchButton*, *CtBrassDivider*, *CtGradients*, *Editorial-monocle palette*).
- Tooltip convention: [`resource-icon-tooltip.md`](resource-icon-tooltip.md). Tracking: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
