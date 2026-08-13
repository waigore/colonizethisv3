# Overlay Army Move Picker Dialog

**Screen ID:** `DLG20002` — stable; do not reassign.
**SPEC/ui** — Chooses one human non-Home field army when several can Move from or Invade into the viewed `MAP20001` province. Implementation: `app/lib/features/game/widgets/unit_orders/overlay_army_move_picker_dialog.dart`.
**Widgetbook:** `Overlay Army Move Picker Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs.dart`. Flow: `overlay_army_move_flow.dart`. Mirror: [naval-mission-fleet-picker-dialog.md](naval-mission-fleet-picker-dialog.md).

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `OverlayArmyMovePickerDialog` | `StatefulWidget` | `game`, `humanPlayerId`, `armyIds`, `initialArmyId?` | First step of `showOverlayArmyMoveFlow` when `armyIds.length > 1`. Returns selected army id or `null`. |

---

## Layout / wireframe

```text
+--------------------------------------------------+
| CtDialogShell                                    |
| | Select army                                    | |  `provinceOverlay_selectArmyTitle`
| |  [ ] Army <id A>                               | |  MoveDialogDestinationRow
| |  [ ] Army <id B>                               | |
| |              [ Cancel ]        [ Confirm ]     | |
+--------------------------------------------------+
```

- One `MoveDialogDestinationRow` per `armyIds` entry; label `military_units_army(armyId)`.
- Initial selection: `initialArmyId ?? armyIds.first`.
- Confirm disabled when no selection (defensive; default always selects first). Prefer Ct-* chrome; no Material radios.

---

## Trigger conditions

| Source | Condition | Result |
|--------|-----------|--------|
| `MAP20001` Move / Invade | Eligible army ids length > 1 | Picker before `DLG20001`. |
| Single army | length == 1 | Picker skipped. |

---

## Behavior

| Control | When enabled | Result |
|---------|--------------|--------|
| Army row | always | Updates selection. |
| Confirm | selection non-null | `Navigator.pop(selectedArmyId)` → `MoveArmyDialog` for that army. |
| Cancel | always | `Navigator.pop(null)`; flow aborts. |

---

## Widgetbook

Folder `Overlay Army Move Picker Dialog`:

| Use case | Proves |
|----------|--------|
| Default — two armies | Two rows; Confirm returns selection. |

---

## Acceptance criteria

- **Given** `armyIds` has two entries, **when** the dialog opens, **then** the UI layer renders two army rows titled with `military_units_army` and pre-selects `initialArmyId` when provided.
- **Given** the user taps Confirm with an army selected, **when** the dialog closes, **then** `Navigator` returns that army id string.
- **Given** the user taps Cancel, **when** the gesture completes, **then** the dialog closes with `null` and no `MoveArmyDialog` opens.
