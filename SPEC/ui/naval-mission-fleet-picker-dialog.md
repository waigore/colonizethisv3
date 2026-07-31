# Naval Mission Fleet Picker Dialog

**Screen ID:** `DLG31003` — stable; do not reassign.
**SPEC/ui** — Chooses one fleet when multiple human fleets share a map marker scope. Implementation: `app/lib/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart` (`NavalMissionFleetPickerDialog`).
**Widgetbook:** `Naval Mission Fleet Picker Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs.dart`. Flow: `naval_mission_flow.dart`.

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `NavalMissionFleetPickerDialog` | `StatefulWidget` | `game`, `humanPlayerId`, `fleetIds`, `initialFleetId?` | First step of `showNavalMissionFlow` when `fleetIds.length > 1`. Returns selected fleet id or `null`. |

---

## Layout / wireframe

```text
+--------------------------------------------------+
| CtDialogShell                                    |
| | Select fleet                                   | |  `naval_mission_selectFleetTitle`
| |  ( ) Fleet <id A>                              | |
| |  ( ) Fleet <id B>                              | |
| |              [ Cancel ]        [ Confirm ]     | |
+--------------------------------------------------+
```

- Radio `ListTile` per `fleetIds` entry; label `naval_fleetLabel(fleetId)`.
- Initial selection: `initialFleetId ?? fleetIds.first`.
- Confirm disabled when no selection (defensive; default always selects first).

---

## Trigger conditions

| Source | Condition | Result |
|--------|-----------|--------|
| Map marker tap | `OpenNavalMissionMenuEvent.fleetIds.length > 1` | Picker before `DLG31001`. |
| Single fleet | `fleetIds.length == 1` | Picker skipped. |

---

## Behavior

| Control | When enabled | Result |
|---------|--------------|--------|
| Fleet row / radio | always | Updates `_selected`. |
| Confirm | `_selected != null` | `Navigator.pop(selectedFleetId)` → mission menu for that fleet. |
| Cancel | always | `Navigator.pop(null)`; flow aborts. |

---

## Widgetbook

Folder `Naval Mission Fleet Picker Dialog`:

| Use case | Proves |
|----------|--------|
| Default — two fleets | Two radio rows; Confirm returns selection. |

---

## Acceptance criteria

- **Given** `fleetIds` has two entries, **when** the dialog opens, **then** the UI layer renders two fleet radio rows titled with `naval_fleetLabel` and pre-selects `initialFleetId` when provided.
- **Given** the user taps Confirm with a fleet selected, **when** the dialog closes, **then** `Navigator` returns that fleet id string.
- **Given** the user taps Cancel, **when** the gesture completes, **then** the dialog closes with `null` and no mission menu opens.
