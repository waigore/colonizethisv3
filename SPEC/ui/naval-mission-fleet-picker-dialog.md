# Naval Mission Fleet Picker Dialog

**Screen ID:** `DLG31003` — stable; do not reassign.
**SPEC/ui** — Chooses one fleet when multiple human fleets share a map marker scope. Implementation: `app/lib/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart` (`NavalMissionFleetPickerDialog`).
**Widgetbook:** `Naval Mission Fleet Picker Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs.dart`. Flow: `naval_mission_flow.dart`. Mirror: [overlay-army-move-picker-dialog.md](overlay-army-move-picker-dialog.md). Row chrome: [move-units-dialog-base.md](components/move-units-dialog-base.md). Composition helper: `unit_picker_composition.dart` (Refs #4385).

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `NavalMissionFleetPickerDialog` | `StatefulWidget` | `game`, `humanPlayerId`, `fleetIds`, `initialFleetId?` | First step of `showNavalMissionFlow` / `showNavalFleetMarkerFlow` when `fleetIds.length > 1`. Returns selected fleet id or `null`. |

---

## Layout / wireframe

```text
+--------------------------------------------------+
| CtDialogShell                                    |
| | Select fleet                                   | |  `naval_mission_selectFleetTitle`
| |  [ ] Fleet <id A>                              | |  MoveDialogDestinationRow
| |      Total ships: 2 · Warships: 2 · Merchants: 0 | |  muted bodySmall
| |      On mission: Patrol                        | |  when mission != none
| |      (at sea)                                  | |  when picker mixes in-port / at-sea
| |  [ ] Fleet <id B>                              | |
| |              [ Cancel ]        [ Confirm ]     | |
+--------------------------------------------------+
```

- One `MoveDialogDestinationRow` per `fleetIds` entry; title `naval_fleetLabel(fleetId)`. No Material `Radio` / `ListTile`.
- Under the title, muted `bodySmall` lines: `naval_units_compositionSummary` from that fleet's `ships` / `shipTypeIds` (warship = `cargoHold == 0`; merchant = `cargoHold > 0`, same as `navalTreeFleetShipAggregates`).
- When `Fleet.mission != none`, a pending line via `naval_mission_pendingLine` (never claims `none`).
- When the picker list mixes in-port and at-sea fleets, append `naval_units_locInPort` or `naval_units_locAtSea` for that row. Omit location when every listed fleet shares the same in-port/at-sea state.
- Narrow (320 dp): composition wraps or ellipsizes; no horizontal overflow.
- Initial selection: `initialFleetId ?? fleetIds.first`.
- Confirm disabled when no selection (defensive; default always selects first).

---

## Trigger conditions

| Source | Condition | Result |
|--------|-----------|--------|
| Map marker tap | `OpenNavalMissionMenuEvent.fleetIds.length > 1` | Picker before `DLG31001` / Move / `UNIT30001`. |
| Single fleet | `fleetIds.length == 1` | Picker skipped. |

---

## Behavior

| Control | When enabled | Result |
|---------|--------------|--------|
| Fleet row | always | Updates `_selected`. Composition lines are read-only. |
| Confirm | `_selected != null` | `Navigator.pop(selectedFleetId)` → mission menu, Move, or naval panel for that fleet. |
| Cancel | always | `Navigator.pop(null)`; flow aborts. |

Picker rows do not emit orders. Observe / read-only hosts may still show the picker; Confirm only returns an id.

---

## Widgetbook

Folder `Naval Mission Fleet Picker Dialog`:

| Use case | Proves |
|----------|--------|
| Default — two fleets | Two `MoveDialogDestinationRow`s with composition; Confirm returns selection. |
| Narrow — two fleets | Same rows at 320 dp; composition wraps/ellipsizes. |

---

## Acceptance criteria

- **Given** `fleetIds` has two entries, **when** the dialog opens, **then** the UI layer renders two fleet rows titled with `naval_fleetLabel` using `MoveDialogDestinationRow` chrome (not Material radios) and pre-selects `initialFleetId` when provided.
- **Given** those fleets have different ship mixes, **when** the rows render, **then** each muted composition line uses `naval_units_compositionSummary` derived from that fleet only.
- **Given** a listed fleet has `mission != none`, **when** its row renders, **then** the UI layer shows `naval_mission_pendingLine` for that mission and does not claim `none`.
- **Given** the picker list mixes in-port and at-sea fleets, **when** the rows render, **then** each row includes `naval_units_locInPort` or `naval_units_locAtSea`. **Given** every listed fleet is at sea, **when** the rows render, **then** the UI layer omits those location qualifiers.
- **Given** the user taps Confirm with a fleet selected, **when** the dialog closes, **then** `Navigator` returns that fleet id string.
- **Given** the user taps Cancel, **when** the gesture completes, **then** the dialog closes with `null` and no mission menu opens.
- **Given** the picker at the 320 dp minimum viewport, **when** composition lines build, **then** `WidgetTester.takeException()` is `null` and Confirm remains reachable.

Tests: `app/test/unit_picker_composition_test.dart`, `app/test/unit_picker_composition_widget_test.dart`, `app/test/unit_picker_composition_320dp_test.dart`, `app/test/naval_mission_goldens_test.dart`.
