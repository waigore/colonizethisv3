# MoveUnitsDialogState / MoveDialogDestinationRow (component)

**SPEC/ui/components** — Shared scaffold + destination-row chrome for the in-game move dialogs. Implementation: [`app/lib/features/game/widgets/unit_orders/move_units_dialog_base.dart`](../../../app/lib/features/game/widgets/unit_orders/move_units_dialog_base.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtDialogShell*, § *CtSectionLabel*, § *CtNinePatchButton*, § *Editorial-monocle palette*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical chrome for the two move-dialog screen specs listed under [Consumers](#consumers).

---

## Purpose

Consolidates the `CtDialogShell` body skeleton (accent title row, empty-state fallback, trailing `Wrap` of Cancel/Confirm `CtNinePatchButton`s) and the canonical 1 px/2 px `--border`/`--accent` radio-row outline contract (#2867 R1/R7) shared by [`MoveArmyDialog`](../move-army-dialog.md) and [`MoveFleetDialog`](../move-fleet-dialog.md). Each dialog previously inlined ~30 lines of identical scaffold plus a near-verbatim destination-row + radio-dot widget; this composite removes that duplication so the two dialogs cannot drift. Tracking issue: [#3546](https://github.com/waigore/colonizethisv3/issues/3546) (app deduplication / decoupling).

---

## Widget contract

### `MoveUnitsDialogState<W extends StatefulWidget>` (abstract `State`)

Subclasses (`_MoveArmyDialogState`, `_MoveFleetDialogState`) implement these members; the base composes the shared scaffold via `buildMoveDialogScaffold(context)`.

| Member | Type | Description |
|--------|------|-------------|
| `moveDialogTitle` | `String get` | Localized title rendered in `--accent` `titleMedium` with 0.05em letter-spacing. |
| `moveDialogHasDestinations` | `bool get` | When `false`, the base renders `moveDialogEmptyText` instead of the destination body. |
| `moveDialogEmptyText` | `String get` | Localized empty-state copy, rendered in `--muted` body style. |
| `moveDialogCanConfirm` | `bool get` | Enables the Confirm action (a destination is selected). |
| `buildMoveDialogDestinations` | `Widget Function(BuildContext)` | Builds the `CtSectionLabel`-headed destination groups. Only invoked when `moveDialogHasDestinations`. |
| `onMoveDialogConfirm` | `void Function()` | Invoked when the enabled Confirm action is tapped. |
| `onMoveDialogCancel` | `void Function()` | Invoked when Cancel is tapped. |
| `buildMoveDialogScaffold` | `Widget Function(BuildContext)` | Concrete; returns the `CtDialogShell` body. Subclass `build` returns this. |

### `MoveDialogDestinationRow` (`StatelessWidget`)

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `selected` | `bool` | required | Drives outline width/color and the filled radio dot. |
| `onTap` | `VoidCallback` | required | Row selection gesture (opaque hit test). |
| `semanticsLabel` | `String` | required | `Semantics(button, selected, label)` value. |
| `content` | `Widget` | required | Flexible middle slot (wrapped in `Expanded`). |
| `trailing` | `Widget?` | `null` | Optional trailing action (e.g. locate icon). |

Exposed constants: `MoveDialogDestinationRow.selectedBorderWidth = 2`, `idleBorderWidth = 1`; `MoveDialogRadioDot.outerDiameter = 14`, `innerDiameter = 6`.

`UnitPickerCompositionContent` fills `content` for `DLG20002` / `DLG31003` unit pickers: title (`bodyMedium`) plus muted `bodySmall` composition lines (`maxLines` + ellipsis at 320 dp). Strings come from `unit_picker_composition.dart`. Implementation: `unit_picker_composition_row.dart` (Refs #4385).

### Style helpers

`moveDialogTitleTextStyle(theme)`, `moveDialogEmptyTextStyle(theme)`, `moveDialogRowLabelStyle(theme, selected:)`, `moveDialogCompositionTextStyle(theme)` — title, empty copy, row label, and muted picker composition lines.

---

## Layout / wireframe

```text
CtDialogShell
  Column(mainAxisSize: min, crossAxisAlignment: stretch)
    Text(moveDialogTitle, style: moveDialogTitleTextStyle)
    SizedBox(height: CtSpacing.ml)
    moveDialogHasDestinations
      ? buildMoveDialogDestinations(context)
      : Text(moveDialogEmptyText, style: moveDialogEmptyTextStyle)
    SizedBox(height: CtSpacing.l)
    Wrap(alignment: end, spacing: 8, runSpacing: 8)
      CtNinePatchButton(Cancel)          -- onMoveDialogCancel
      CtNinePatchButton(Confirm)         -- enabled: moveDialogCanConfirm

MoveDialogDestinationRow
  Padding(vertical: 3)
    Semantics(button, selected, label)
      GestureDetector(opaque, onTap)
        Container(border: 1px --border | 2px --accent when selected,
                  padding: h10 / v CtSpacing.m)
          Row(crossAxisAlignment: center)
            MoveDialogRadioDot(selected)  -- 14 dp; 6 dp --accent fill when selected
            SizedBox(width: 10)
            Expanded(content)
            trailing?
```

The trailing `Wrap` lets Cancel/Confirm flow onto a second run at narrow viewports (`SPEC/ui/mobile-adaptation.md` § 7, Refs #2870 S8/S10). No Material `Radio`/`RadioListTile` appears in the rendered tree (catalog ban).

---

## Behavior

1. **Title / empty fallback.** The scaffold always renders the title row; the destination body is replaced by `moveDialogEmptyText` when `moveDialogHasDestinations == false`.
2. **Confirm gating.** Confirm is a `CtNinePatchButton` with `enabled: moveDialogCanConfirm` and `onPressed` wired to `onMoveDialogConfirm` only when enabled (else `null`). Cancel is always enabled.
3. **Row selection contract.** Idle rows paint a 1 px `--border` outline; selected rows paint a 2 px `--accent` outline plus a filled `--accent` dot in the leading slot (#2867 R7).
4. **No internal state.** Both `MoveDialogDestinationRow` and `MoveDialogRadioDot` are stateless; selection state lives in the consuming dialog state.

---

## Consumers

| Screen ID | Spec | Subclass-specific body |
|-----------|------|------------------------|
| `DLG20001` | [`move-army-dialog.md`](../move-army-dialog.md) | Owned/invasion groups; invasion rows append a `--danger` italic declare-war trigger; Confirm may open a war-confirmation sub-dialog. |
| `DLG30001` | [`move-fleet-dialog.md`](../move-fleet-dialog.md) | Sea-zone/port groups; each row adds a trailing locate `CtIconAction`; rows carry CT_E2E keys. |
| `DLG20002` | [`overlay-army-move-picker-dialog.md`](../overlay-army-move-picker-dialog.md) | Army picker rows; `content` is `UnitPickerCompositionContent` (per-army type counts). |
| `DLG31003` | [`naval-mission-fleet-picker-dialog.md`](../naval-mission-fleet-picker-dialog.md) | Fleet picker rows; same content helper (ships / mission / mixed location). |

---

## Acceptance criteria (Given–When–Then)

- **Given** a `MoveDialogDestinationRow` with `selected == false`, **When** it builds, **Then** the surrounding `Container` border width equals `MoveDialogDestinationRow.idleBorderWidth` (1) and color resolves to `EditorialMonoclePalette.border`.
- **Given** a `MoveDialogDestinationRow` with `selected == true`, **When** it builds, **Then** the border width equals `MoveDialogDestinationRow.selectedBorderWidth` (2), color resolves to `EditorialMonoclePalette.accent`, and a filled `EditorialMonoclePalette.accent` dot is mounted in the leading `MoveDialogRadioDot`.
- **Given** a `MoveDialogDestinationRow` built with a non-null `trailing`, **When** the tree settles, **Then** the trailing widget is reachable as a descendant of the row; **Given** `trailing == null`, **Then** no trailing widget follows the `Expanded(content)`.
- **Given** a `MoveDialogDestinationRow`, **When** the user taps it, **Then** the supplied `onTap` callback fires exactly once.
- **Given** the source `app/lib/features/game/widgets/unit_orders/move_units_dialog_base.dart`, **When** read, **Then** it references `EditorialMonoclePalette.accent`/`border` and exposes `MoveUnitsDialogState`, `MoveDialogDestinationRow`, and `MoveDialogRadioDot` (canonical chrome regression guard).

---

## Tests

- `app/test/move_units_dialog_base_test.dart` — widget-level contract tests pinning the idle/selected outline widths, the radio-dot fill, the trailing slot, and the tap callback.
- `app/test/move_dialogs_specs_part1_test.dart` / `move_dialogs_specs_part2_test.dart` — pin army/fleet consumer dialogs over this chrome (section labels, confirm/cancel, declare-war flow, locate).
- `app/test/move_dialogs_320dp_min_viewport_test.dart` — pins both dialogs at `kMinViewportWidth = 320` dp without overflow.
- `app/test/unit_picker_composition_test.dart` / `unit_picker_composition_320dp_test.dart` — `DLG20002` / `DLG31003` composition content in `MoveDialogDestinationRow`.

---

## Related

- Consumer screens: [`move-army-dialog.md`](../move-army-dialog.md), [`move-fleet-dialog.md`](../move-fleet-dialog.md), [`overlay-army-move-picker-dialog.md`](../overlay-army-move-picker-dialog.md), [`naval-mission-fleet-picker-dialog.md`](../naval-mission-fleet-picker-dialog.md).
- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtDialogShell*, § *CtSectionLabel*, § *CtNinePatchButton*, § *Editorial-monocle palette*.
- Tracking issue: [#3546](https://github.com/waigore/colonizethisv3/issues/3546).
