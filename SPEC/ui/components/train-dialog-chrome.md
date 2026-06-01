# TrainDialogChrome (component)

**SPEC/ui/components** — Reusable header / divider / resource-bar / row-surface chrome shared by the two train-at-capital dialogs. Implementation: [`app/lib/features/game/widgets/train_dialog_chrome.dart`](../../../app/lib/features/game/widgets/train_dialog_chrome.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtNinePatchButton*, § *CtBrassDivider*, § *CtGradients*, § *Editorial-monocle palette*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical chrome consumed by the two screen specs listed under [Consumers](#consumers).

---

## Purpose

Consolidates the chrome (accent title + `×` dismiss, brass section divider, resource bar with optional deficit hint, compact resource chip, per-unit row surface) shared by Train Civilians and Train Military so each dialog composes only its body inside a single [`CtDialogShell`](../pixel-art-ui-catalog.md). The dark editorial-monocle contract (no Material `IconButton`, no Material `Divider`, no raw `Colors.*` literals) lives in one file. Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.

---

## Widget contract

`TrainDialogHeader` — `title` (`String`) rendered in `theme.textTheme.titleMedium` with `EditorialMonoclePalette.accent`, `kTrainDialogTitleLetterSpacing` (`0.05`), and `FontWeight.w600`; `onClose` (`VoidCallback`) fires when the trailing `×` `CtNinePatchButton` (32 dp min-height; padding `10 × 6`) is tapped.

`TrainDialogSectionDivider` — no props; renders `CtBrassDivider` inside `EdgeInsets.symmetric(vertical: 8)`.

`TrainDialogResourceBar` — `lines` (`List<String>`) renders one `Text` per entry inside `Wrap(spacing: 16, runSpacing: 4)`, resolved to `bodyMedium.copyWith(color: EditorialMonoclePalette.fg)`; optional `deficitHint` (`String?`) appends a row in `bodySmall.copyWith(color: EditorialMonoclePalette.danger)`.

`TrainDialogResourceChip` — single `child`, wrapped in a 4 dp-radius `BoxDecoration` (`CtGradients.rowGradient` + 1 dp `accentDim` border) with `EdgeInsets.symmetric(horizontal: 6, vertical: 4)`; content renders inside `DefaultTextStyle.merge(style: TextStyle(color: EditorialMonoclePalette.fg))`.

`TrainDialogUnitRowSurface` — single `child`, wrapped in `CtGradients.rowGradient` + 1 dp `accentDim` border with `EdgeInsets.symmetric(horizontal: 12, vertical: 8)`. Optional `margin` defaults to `EdgeInsets.only(bottom: 6)`.

Exported constants: `kTrainDialogLockedOpacity = 0.4` (per [#2866](https://github.com/waigore/colonizethisv3/issues/2866) AC); `kTrainDialogTitleLetterSpacing = 0.05`.

---

## Layout / wireframe

```text
CtDialogShell(maxWidth: 480, maxHeight: 600)            -- canonical dialog frame
  Column(min, start)
    TrainDialogHeader(title, onClose)                   -- Row(start) [Expanded(title), CtNinePatchButton('×')]
    TrainDialogSectionDivider()                          -- Padding(8/8) CtBrassDivider
    TrainDialogResourceBar(lines, deficitHint?)         -- Wrap(spacing 16, runSpacing 4) + optional danger hint
    TrainDialogSectionDivider()
    ListView/Column of TrainDialogUnitRowSurface(...)   -- per unit/regiment row
      Row(...)                                          -- icon + name + cost / stepper / lock badge
    Footer (consumer-owned: Reset CtNinePatchButton)
```

The chrome widgets are independent — consumers may skip the resource bar (e.g. when capital is missing) and still render unit rows.

---

## Behavior

1. **Stateless surfaces.** Every chrome widget is a `StatelessWidget`; affordance recomputation and stepper mutation belong to the host dialog state.
2. **Header dismiss.** `TrainDialogHeader` mounts `CtNinePatchButton` (not Material `IconButton`) so the dark button-surface contract is preserved. Tap fires `onClose`.
3. **Divider colour.** `TrainDialogSectionDivider` always paints `CtBrassDivider` — never Material `Divider`. Guards both dialogs against the Material ban that the `check_app_no_material_*` lints enforce.
4. **Resource bar styling.** Each `lines` entry resolves to `EditorialMonoclePalette.fg`. `deficitHint`, when supplied, uses `EditorialMonoclePalette.danger` (warm-red) so the deficit message is unambiguous on the dark surface.
5. **Resource chip.** `TrainDialogResourceChip` wraps inline icon + numeric content; military uses six per dialog for the commodity readout (`fabric`, `castIron`, `lumber`, `horses`, `steel`, `bronze`).
6. **Unit row surface.** `TrainDialogUnitRowSurface` paints `CtGradients.rowGradient` inside a 1 dp `accentDim` border. The consumer owns internal layout (icon, name, cost columns, stepper, lock badge) and applies `kTrainDialogLockedOpacity` (`0.4`) via its own `Opacity` wrapper when the row is tech-locked.
7. **Letter-spacing alignment.** `kTrainDialogTitleLetterSpacing = 0.05` matches `CtTopBar` and the combat-mode choice dialog so the title rhythm aligns.

---

## States and variants

| Widget | Variant | Trigger | Render difference |
|--------|---------|---------|--------------------|
| `TrainDialogResourceBar` | No-deficit | `deficitHint == null` | Hint row omitted; only the `Wrap` renders. |
| `TrainDialogResourceBar` | Deficit | `deficitHint != null` | `SizedBox(height: 4)` + danger-coloured hint row appended. |
| `TrainDialogUnitRowSurface` | Locked | Host wraps the row in `Opacity(opacity: kTrainDialogLockedOpacity)` | Whole surface fades to 0.4 opacity. |
| `TrainDialogUnitRowSurface` | Custom margin | Caller overrides `margin` | Outer `Padding` adopts the caller margin (default `EdgeInsets.only(bottom: 6)`). |

The chrome widgets have no theme-mode branches; the dark editorial-monocle theme is the only authorised render target.

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `UNIT40001` | [`train-civilians-dialog.md`](../train-civilians-dialog.md) | Civilian list + treasury / paper resource bar; six unit-type rows with optional tech-lock variant. |
| `UNIT50001` | [`train-military-dialog.md`](../train-military-dialog.md) | Regiment list + treasury / peasants + six commodity chips; per-regiment rows with optional tech-lock variant. |

Both consumer specs link back here for the chrome contract instead of redeclaring the header / divider / resource-bar / row-surface hierarchy.

---

## Acceptance criteria (Given–When–Then)

- **Given** a `TrainDialogHeader` mounted with `title = 'Train Civilians'`, **When** the tree settles, **Then** exactly one `CtNinePatchButton` is mounted, zero Material `IconButton` widgets are mounted, `Text('Train Civilians')` renders, and its resolved `TextStyle.color` equals `EditorialMonoclePalette.accent`.
- **Given** a `TrainDialogSectionDivider` mounted under any host, **When** the tree settles, **Then** exactly one `CtBrassDivider` is mounted and zero Material `Divider` widgets are mounted.
- **Given** a `TrainDialogResourceBar` mounted with two lines and `deficitHint == null`, **When** the tree settles, **Then** two `Text` descendants render the line values and no descendant carries `EditorialMonoclePalette.danger`.
- **Given** a `TrainDialogResourceBar` mounted with `deficitHint = 'Treasury low'`, **When** the tree settles, **Then** a `Text('Treasury low')` mounts whose resolved `TextStyle.color` equals `EditorialMonoclePalette.danger`.
- **Given** a `TrainDialogUnitRowSurface` mounted around any child, **When** the inner `DecoratedBox` resolves, **Then** its `BoxDecoration.border` is `Border.all(color: EditorialMonoclePalette.accentDim, width: 1)` and its `BoxDecoration.gradient` is `CtGradients.rowGradient`.
- **Given** the source `app/lib/features/game/widgets/train_dialog_chrome.dart`, **When** read, **Then** it declares `kTrainDialogLockedOpacity = 0.4` and `kTrainDialogTitleLetterSpacing = 0.05` (canonical regression guard).

---

## Tests

- `app/test/train_dialog_chrome_test.dart` — widget-level pins for `TrainDialogHeader` accent title + `CtNinePatchButton` dismiss, `TrainDialogSectionDivider` `CtBrassDivider` selection, and the `kTrainDialogLockedOpacity` constant.
- `app/test/train_dialogs_320dp_min_viewport_test.dart` — pins `TrainCiviliansDialog` and `TrainMilitaryDialog` at `kMinViewportWidth = 320` dp with the shared chrome composed inside `CtDialogShell` (Refs [#2870](https://github.com/waigore/colonizethisv3/issues/2870) S8/S10).
- `app/test/spec_components_train_dialog_chrome_test.dart` — spec-pinning test asserting this spec exists, declares the canonical sections, enumerates the two consumers by stable screen id, restates the chrome constants, and stays under the 1000-word ceiling.

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtDialogShell*, § *CtNinePatchButton*, § *CtBrassDivider*, § *CtGradients*, § *Editorial-monocle palette*.
- Sibling chrome: [`production-allocation-row.md`](production-allocation-row.md) — same row-surface gradient + border pattern.
- Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
