# TrainDialogChrome (component)

**SPEC/ui/components** — Reusable header / divider / resource-bar / row-surface chrome shared by the train-at-capital dialogs. Implementation: [`app/lib/features/game/widgets/train_dialog_chrome.dart`](../../../app/lib/features/game/widgets/train_dialog_chrome.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtNinePatchButton*, § *CtBrassDivider*, § *CtGradients*, § *Editorial-monocle palette*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical chrome consumed by the screen specs in [Consumers](#consumers).

---

## Purpose

Consolidates the chrome (accent title + `×` dismiss, brass divider, boxed resource bar with optional deficit hint, resource chip, per-unit row surface) shared by the train-at-capital dialogs so each composes only its body inside a single [`CtDialogShell`](../pixel-art-ui-catalog.md). The dark editorial-monocle contract (no Material `IconButton` / `Divider`, no raw `Colors.*`) lives in one file.

---

## Widget contract

`TrainDialogHeader` — `title` (`String`) rendered in `theme.textTheme.titleMedium` with `EditorialMonoclePalette.accent`, `kTrainDialogTitleLetterSpacing` (`0.05`), and `FontWeight.w600`; `onClose` (`VoidCallback`) fires when the trailing `×` `CtNinePatchButton` (32 dp min-height; padding `10 × 6`) is tapped.

`TrainDialogSectionDivider` — no props; renders `CtBrassDivider` inside `EdgeInsets.symmetric(vertical: 8)`.

`TrainDialogResourceBarBox` — single `child` inside a boxed inset strip (`bgDeep` background, 1 dp `border`, `EdgeInsets.all(8)`) per mockup `.resource-bar`. Shared by both dialogs.

`TrainDialogResourceEntry` — value object `{ label, value }` (`String`).

`TrainDialogResourceBar` — `entries` (`List<TrainDialogResourceEntry>`) inside a `TrainDialogResourceBarBox` as `Wrap(spacing 16, runSpacing 4, spaceAround)`; each entry is a muted label (`bodyMedium`, `muted`) + a **monospace bold** value (`w700`, `fontFamilyFallback: [SF Mono, Menlo, monospace]`, `tabularFigures`, `fg`). Treasury is `£` + comma-grouped (`£5,000`). Optional `deficitHint` (`String?`) renders below the box in `bodySmall` `danger`.

`TrainDialogResourceChip` — single `child` in a 4 dp-radius `BoxDecoration` (`CtGradients.rowGradient` + 1 dp `accentDim` border, padding `6 × 4`); content renders inside `DefaultTextStyle.merge(color: fg)`.

`TrainDialogUnitRowSurface` — single `child` in `CtGradients.rowGradient` + 1 dp `accentDim` border (padding `12 × 8`). Optional `margin` defaults to `EdgeInsets.only(bottom: 6)`.

Exported constants: `kTrainDialogLockedOpacity = 0.4` (per [#2866](https://github.com/waigore/colonizethisv3/issues/2866) AC); `kTrainDialogTitleLetterSpacing = 0.05`.

---

## Layout / wireframe

```text
CtDialogShell(maxWidth: 480, maxHeight: 600)            -- canonical dialog frame
  Column(min, start)
    TrainDialogHeader(title, onClose)                   -- Row(start) [Expanded(title), CtNinePatchButton('×')]
    TrainDialogSectionDivider()                          -- Padding(8/8) CtBrassDivider
    TrainDialogResourceBar(entries, deficitHint?)       -- boxed inset strip (mono bold values) + optional danger hint
    TrainDialogSectionDivider()
    ListView/Column of TrainDialogUnitRowSurface(...)   -- per unit/regiment row
      Row(...)                                          -- icon + name + cost / stepper / lock badge
    Footer (consumer-owned: Reset CtNinePatchButton)
```

Consumers may skip the resource bar (e.g. no capital) and still render rows.

---

## Behavior

1. **Stateless surfaces.** Every chrome widget is a `StatelessWidget`; affordance recomputation and stepper mutation belong to the host dialog state.
2. **Header dismiss.** `TrainDialogHeader` mounts `CtNinePatchButton` (not Material `IconButton`) so the dark button-surface contract is preserved. Tap fires `onClose`.
3. **Divider colour.** `TrainDialogSectionDivider` always paints `CtBrassDivider` — never Material `Divider` (guards the `check_app_no_material_*` lint ban).
4. **Resource bar styling.** `TrainDialogResourceBar` renders entries inside a `TrainDialogResourceBarBox` (recessed `--bg-deep` strip, 1 dp `--border`) with muted labels and monospace bold `--fg` values. `deficitHint` renders below the box in `--danger`.
5. **Resource chip.** `TrainDialogResourceChip` wraps inline icon + numeric content; military composes its treasury / peasants / six commodity chips (`fabric`, `castIron`, `lumber`, `horses`, `steel`, `bronze`) inside a `TrainDialogResourceBarBox`, keeping commodity icons and the same `£` + comma formatting.
6. **Unit row surface.** `TrainDialogUnitRowSurface` paints `CtGradients.rowGradient` inside a 1 dp `accentDim` border. The consumer owns internal layout (left info column with name over cost, right stepper, lock badge) and applies `kTrainDialogLockedOpacity` (`0.4`) when tech-locked.
7. **Letter-spacing alignment.** `kTrainDialogTitleLetterSpacing = 0.05` matches `CtTopBar` and the combat-mode choice dialog.

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
| `UNIT40001` | [`train-civilians-dialog.md`](../train-civilians-dialog.md) | Civilian list + treasury / paper resource bar; six unit-type rows with optional tech-lock variant. |
| `UNIT50001` | [`train-military-dialog.md`](../train-military-dialog.md) | Regiment list + treasury / peasants + six commodity chips; per-regiment rows with optional tech-lock variant. |
| `UNIT60001` | [`train-naval-dialog.md`](../train-naval-dialog.md) | Ship list + treasury / peasants + four commodity chips (`lumber`, `fabric`, `castIron`, `coal`); per-ship rows with optional tech-lock variant. |

Consumer specs link back here instead of redeclaring the chrome.

---

## Acceptance criteria (Given–When–Then)

- **Given** a `TrainDialogHeader` mounted with `title = 'Train Civilians'`, **When** the tree settles, **Then** exactly one `CtNinePatchButton` is mounted, zero Material `IconButton` widgets are mounted, `Text('Train Civilians')` renders, and its resolved `TextStyle.color` equals `EditorialMonoclePalette.accent`.
- **Given** a `TrainDialogSectionDivider` mounted under any host, **When** the tree settles, **Then** exactly one `CtBrassDivider` is mounted and zero Material `Divider` widgets are mounted.
- **Given** a `TrainDialogResourceBar` mounted with two entries and `deficitHint == null`, **When** the tree settles, **Then** exactly one `TrainDialogResourceBarBox` is mounted, both entry labels + values render, and no descendant carries `EditorialMonoclePalette.danger`.
- **Given** a `TrainDialogResourceBar` mounted with a treasury entry of `5000`, **When** the tree settles, **Then** the rendered value reads `£5,000` (pound symbol + comma grouping).
- **Given** a `TrainDialogResourceBar` mounted with `deficitHint = 'Treasury low'`, **When** the tree settles, **Then** a `Text('Treasury low')` mounts whose resolved `TextStyle.color` equals `EditorialMonoclePalette.danger`.
- **Given** a `TrainDialogUnitRowSurface` mounted around any child, **When** the inner `DecoratedBox` resolves, **Then** its `BoxDecoration.border` is `Border.all(color: EditorialMonoclePalette.accentDim, width: 1)` and its `BoxDecoration.gradient` is `CtGradients.rowGradient`.
- **Given** the source `app/lib/features/game/widgets/train_dialog_chrome.dart`, **When** read, **Then** it declares `kTrainDialogLockedOpacity = 0.4` and `kTrainDialogTitleLetterSpacing = 0.05` (canonical regression guard).

---

## Tests

- `app/test/train_dialog_chrome_test.dart` — pins `TrainDialogHeader` accent title + `CtNinePatchButton` dismiss, `TrainDialogSectionDivider` selection, the resource-bar box + `£`/comma formatting, and `kTrainDialogLockedOpacity`.
- `app/test/train_dialogs_320dp_min_viewport_test.dart` — pins both dialogs at `kMinViewportWidth = 320` dp (Refs [#2870](https://github.com/waigore/colonizethisv3/issues/2870) S8/S10).
- `app/test/spec_components_train_dialog_chrome_test.dart` — spec-pinning test (sections, consumers, constants, ≤1000-word ceiling).

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtDialogShell*, *CtNinePatchButton*, *CtBrassDivider*, *CtGradients*, *Editorial-monocle palette*.
- Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
