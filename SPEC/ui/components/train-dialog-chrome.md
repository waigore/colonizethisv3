# TrainDialogChrome (component)

**SPEC/ui/components** — Reusable header / divider / resource-bar / row-surface chrome shared by the train-at-capital dialogs. Implementation: [`app/lib/features/game/widgets/train_dialog_chrome.dart`](../../../app/lib/features/game/widgets/train_dialog_chrome.dart). Catalog atoms in [Related](#related).

This composite is **not** a screen and has **no** stable screen ID; consumers are listed in [Consumers](#consumers).

---

## Purpose

Consolidates the chrome (centered accent title, locked-name line, boxed resource bar + deficit hint, resource chip, inline cost segment, per-unit row surface, available brass divider) shared by the train-at-capital dialogs so each composes only its body inside a single [`CtDialogShell`](../pixel-art-ui-catalog.md). The dark editorial-monocle contract (no Material `IconButton` / `Divider`, no raw `Colors.*`) lives in one file. Per #3568 mockup parity the dialogs render a **centered title with no `×` dismiss** and **no brass section dividers** (dismiss via scrim / back; orders apply on close).

---

## Widget contract

`TrainDialogHeader` — `title` (`String`) rendered **centered** (`TextAlign.center`) in `theme.textTheme.titleMedium` with `EditorialMonoclePalette.accent`, `kTrainDialogTitleLetterSpacing` (`0.05`), and `FontWeight.w600`. No dismiss control — the dialog closes via scrim tap / system back (#3568 parity, supersedes the original `×` `CtNinePatchButton`).

`TrainDialogUnitNameLine` — `name` (`String`) + `isLocked` (`bool`). Renders the unit name in `bodyLarge` `w600`; locked rows prefix `name` with `kTrainDialogLockPrefix` (🔒) instead of a separate lock-icon column.

`TrainDialogSectionDivider` — no props; renders `CtBrassDivider` inside `EdgeInsets.symmetric(vertical: 8)`. Retained for reuse but **not placed between sections** by the train dialogs (#3568 parity); sections are separated by `SizedBox(height: 12)` gaps.

`TrainDialogResourceBarBox` — single `child` inside a boxed inset strip (`bgDeep` background, 1 dp `border`, `EdgeInsets.all(8)`) per mockup `.resource-bar`.

`TrainDialogResourceEntry` — value object `{ label, value }` (`String`).

`TrainDialogResourceBar` — `entries` inside a `TrainDialogResourceBarBox` as `Wrap(spacing 16, runSpacing 4, spaceAround)`; each entry is a muted label + a **monospace bold** value (`w700`, `tabularFigures`, `fg`). Treasury is `£` + comma-grouped (`£5,000`). Optional `deficitHint` (`String?`) renders below in `bodySmall` `danger`.

`TrainDialogResourceChip` — single `child` in a 4 dp-radius `BoxDecoration` (`CtGradients.rowGradient` + 1 dp `accentDim` border); content in `DefaultTextStyle.merge(color: fg)`.

`TrainDialogUnitRowSurface` — single `child` in `CtGradients.rowGradient` + 1 dp `accentDim` border. Optional `margin` defaults to `EdgeInsets.only(bottom: 6)`.

`TrainDialogInlineCost` — inline cost segment (`icon`, numeric `label`, `tooltipMessage`, `isInsufficient`). The `icon + label` `Row` sits in a tap/hover `Tooltip` (`triggerMode: TooltipTriggerMode.tap`) within a `>= kMinTouchTargetSize` (44 dp) `ConstrainedBox`; `label` turns `danger` when `isInsufficient`. Rules: [`resource-icon-tooltip.md`](resource-icon-tooltip.md).

Exported constants: `kTrainDialogLockedOpacity = 0.5` (canonical mockup `.unit-row.locked`, #3568 parity — supersedes the [#2866](https://github.com/waigore/colonizethisv3/issues/2866) `0.4`); `kTrainDialogTitleLetterSpacing = 0.05`; `kTrainDialogLockPrefix` (🔒 + space); `kTrainDialogCostIconSize = 30`.

---

## Layout / wireframe

```text
CtDialogShell(maxWidth: 480, maxHeight: 600)
  Column(min, stretch)
    TrainDialogHeader(title)                            -- centered; no × button
    SizedBox(height: 12)
    TrainDialogResourceBar(entries, deficitHint?)
    SizedBox(height: 12)
    Column of TrainDialogUnitRowSurface(...)            -- per unit row
      Row(...)                                          -- TrainDialogUnitNameLine (🔒 prefix when locked)
                                                        --   + TrainDialogInlineCost wrap / stepper
    SizedBox(height: 12)
    Footer (consumer-owned: Reset CtNinePatchButton)
```

Consumers may skip the resource bar (e.g. no capital).

---

## Behavior

1. **Stateless surfaces.** Every chrome widget is a `StatelessWidget`; affordance recomputation and stepper mutation belong to the host dialog state. Footer `Reset` and steppers use `CtNinePatchButton`, never Material `IconButton`.
2. **Header / dismiss.** `TrainDialogHeader` renders a centered title with **no dismiss control**; the host dialog dismisses via scrim tap / system back and applies orders on close through its `PopScope` (#3568 parity).
3. **No section dividers.** `TrainDialogSectionDivider` still paints `CtBrassDivider` (never Material `Divider`) but the train dialogs no longer place it between sections (#3568 parity); they use plain `SizedBox` gaps.
4. **Row styling.** `TrainDialogResourceBar`/`TrainDialogResourceChip`/`TrainDialogUnitRowSurface` use muted labels + monospace bold `--fg` values, `£`+comma treasury, `CtGradients.rowGradient`, and `kTrainDialogLockedOpacity` (`0.5`) when tech-locked. Locked names use `TrainDialogUnitNameLine`'s 🔒 prefix.
5. **Inline cost tooltips.** `TrainDialogInlineCost` wraps each `icon + number` segment in a tap/hover `Tooltip` (localized resource name) with a `>= 44` dp touch region. `kTrainDialogTitleLetterSpacing = 0.05` matches `CtTopBar`. Tooltip content: [`resource-icon-tooltip.md`](resource-icon-tooltip.md).

---

## States and variants

| Widget | Variant | Render difference |
|--------|---------|--------------------|
| `TrainDialogResourceBar` | `deficitHint == null` | Hint row omitted. |
| `TrainDialogResourceBar` | `deficitHint != null` | Danger-coloured hint row appended below the box. |
| `TrainDialogUnitRowSurface` | Locked | Host applies `Opacity(kTrainDialogLockedOpacity)` (0.5) + `TrainDialogUnitNameLine(isLocked: true)` 🔒 prefix. |

Editorial-monocle is the only target (no theme-mode branches).

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

- **Given** a `TrainDialogHeader` (`title = 'Train Civilians'`), **When** settled, **Then** zero `CtNinePatchButton`s, zero `IconButton`s, and no `×` glyph mount, and the centered `Text` resolves to `EditorialMonoclePalette.accent` with `TextAlign.center`.
- **Given** a `TrainDialogUnitNameLine` (`name = 'Merchant'`), **When** `isLocked`, **Then** the text is `🔒 Merchant`; otherwise the bare `Merchant`.
- **Given** any train dialog at runtime, **When** it renders, **Then** zero `TrainDialogSectionDivider`s mount; a `TrainDialogSectionDivider` mounted directly renders one `CtBrassDivider` and zero Material `Divider`s.
- **Given** a `TrainDialogResourceBar` (treasury `5000`, `deficitHint == null`), **When** settled, **Then** one `TrainDialogResourceBarBox` mounts, the value reads `£5,000`, and no descendant carries `EditorialMonoclePalette.danger`.
- **Given** a `TrainDialogResourceBar` (`deficitHint = 'Treasury low'`), **When** settled, **Then** `Text('Treasury low')` resolves to `EditorialMonoclePalette.danger`.
- **Given** a `TrainDialogUnitRowSurface`, **When** resolved, **Then** the `DecoratedBox` border is `accentDim` 1 dp and gradient is `CtGradients.rowGradient`.
- **Given** `train_dialog_chrome.dart`, **When** read, **Then** it declares `kTrainDialogLockedOpacity = 0.5` and `kTrainDialogTitleLetterSpacing = 0.05`.
- **Given** a `TrainDialogInlineCost` (`tooltipMessage = 'Treasury'`), **When** settled, **Then** one `Tooltip` (`triggerMode == TooltipTriggerMode.tap`) mounts with a `>= 44` dp trigger height and its icon renders at `kTrainDialogCostIconSize` (30 dp).

---

## Tests

- `app/test/train_dialog_chrome_test.dart` — `TrainDialogHeader` centered title (no dismiss), `TrainDialogUnitNameLine` 🔒 prefix, `TrainDialogSectionDivider`, resource-bar box + `£`/comma, `kTrainDialogLockedOpacity`.
- `app/test/train_dialogs_goldens_test.dart` — per-dialog chrome parity (no `×`, no dividers) + visual baselines.
- `app/test/train_dialogs_320dp_min_viewport_test.dart` — both dialogs at `kMinViewportWidth = 320` dp ([#2870](https://github.com/waigore/colonizethisv3/issues/2870)).
- `app/test/spec_components_train_dialog_chrome_test.dart` — spec-pinning (sections, consumers, constants, ≤1000-word ceiling).
- `app/test/train_dialog_inline_cost_tooltip_test.dart` — `TrainDialogInlineCost` tooltip + 44 dp target.

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) (*CtDialogShell*, *CtNinePatchButton*, *CtBrassDivider*, *CtGradients*, *Editorial-monocle palette*).
- Tooltip convention: [`resource-icon-tooltip.md`](resource-icon-tooltip.md). Tracking: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
