# Overlay Army Move Picker Dialog

**Screen ID:** `DLG20002` — stable; do not reassign.
**SPEC/ui** — Chooses one human non-Home field army when several can Move from or Invade into the viewed `MAP20001` province. Implementation: `app/lib/features/game/widgets/unit_orders/overlay_army_move_picker_dialog.dart`.
**Widgetbook:** `Overlay Army Move Picker Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs.dart`. Flow: `overlay_army_move_flow.dart`. Mirror: [naval-mission-fleet-picker-dialog.md](naval-mission-fleet-picker-dialog.md). Row chrome: [move-units-dialog-base.md](components/move-units-dialog-base.md). Composition helper: `unit_picker_composition.dart` (Refs #4385).

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
| |      Peasant Levies: 2 · Pikemen: 1            | |  muted bodySmall (that army only)
| |  [ ] Army <id B>                               | |
| |      Pikemen: 3                                | |
| |              [ Cancel ]        [ Confirm ]     | |
+--------------------------------------------------+
```

- One `MoveDialogDestinationRow` per `armyIds` entry; title `military_units_army(armyId)`.
- Under the title, a muted `bodySmall` composition line whose type counts come only from that army's `regimentUnitIds` resolved via `WorldState.tryGetUnitById` (same unit-lookup pattern as `rowsForArmyUnits`). Labels use `regimentTypeDisplayName`. Do **not** use `regimentTypeCountsForPlayer`. Empty / unresolved: `military_units_noRegimentsAssigned`.
- Narrow (320 dp): composition wraps or ellipsizes; no horizontal overflow.
- Initial selection: `initialArmyId ?? armyIds.first`.
- Confirm disabled when no selection (defensive; default always selects first). Prefer Ct-* chrome; no Material radios.

---

## Trigger conditions

| Source | Condition | Result |
|--------|-----------|--------|
| `MAP20001` Move / Invade | Eligible army ids length > 1 | Picker before `DLG20001`. |
| `MAP10001` army stack marker | `OpenArmyStackMarkerEvent.fieldArmyIds.length > 1` | Picker before `DLG20001`; Home Army never listed. |
| Single army | length == 1 | Picker skipped. |

---

## Behavior

| Control | When enabled | Result |
|---------|--------------|--------|
| Army row | always | Updates selection. Composition lines are read-only. |
| Confirm | selection non-null | `Navigator.pop(selectedArmyId)` → `MoveArmyDialog` for that army. |
| Cancel | always | `Navigator.pop(null)`; flow aborts. |

Picker rows do not emit orders. Observe / read-only hosts may still show the picker; Confirm only returns an id.

---

## Widgetbook

Folder `Overlay Army Move Picker Dialog`:

| Use case | Proves |
|----------|--------|
| Default — two armies | Two rows with distinct per-army composition; Confirm returns selection. |
| Narrow — two armies | Same rows at 320 dp; composition wraps/ellipsizes. |

---

## Acceptance criteria

- **Given** `armyIds` has two entries whose armies have different `regimentUnitIds` type mixes, **when** the dialog opens, **then** the UI layer renders two army rows titled with `military_units_army` and a muted composition line per row whose type counts come only from that army's `regimentUnitIds` (via `tryGetUnitById`) and whose labels use `regimentTypeDisplayName`.
- **Given** the player owns additional land units outside those two armies, **when** the picker rows render, **then** neither composition line includes those extra units (`regimentTypeCountsForPlayer` is not the source).
- **Given** `showOverlayArmyMoveFlow` runs with a single eligible army, **when** the flow opens, **then** the UI layer does not mount `OverlayArmyMovePickerDialog`. **Given** the dialog is mounted with one id, **when** it builds, **then** the UI layer shows one `military_units_army` title and does not duplicate that title as the composition line.
- **Given** the user taps Confirm with an army selected, **when** the dialog closes, **then** `Navigator` returns that army id string.
- **Given** the user taps Cancel, **when** the gesture completes, **then** the dialog closes with `null` and no `MoveArmyDialog` opens.
- **Given** the picker at the 320 dp minimum viewport, **when** composition lines build, **then** `WidgetTester.takeException()` is `null` and Confirm remains reachable.

Tests: `app/test/unit_picker_composition_test.dart`, `app/test/unit_picker_composition_widget_test.dart`, `app/test/unit_picker_composition_320dp_test.dart`, `app/test/overlay_army_move_flow_test.dart`.
