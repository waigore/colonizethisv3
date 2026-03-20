# Naval Units Panel — Fleet Management (Split & Combine)

**SPEC/ui** — Extends [naval-units-panel.md](naval-units-panel.md) with fleet management actions: **split fleet** and **combine fleets**. These operations allow players to reorganize their naval forces.

---

## Purpose

Players need to reorganize their fleets:
- **Split**: Divide a fleet into two fleets (e.g., send a detachment on a separate mission).
- **Combine**: Merge multiple fleets at the same location into a single fleet.

---

## Combine Fleets

### Trigger

Each non-Home Fleet row in the expanded state shows a **"Combine"** button.

### Behavior

1. **First tap on a fleet's Combine button**:
   - The button changes to indicate the fleet is the **combine target**.
   - Other fleets at the **same location** (same port province OR same sea zone) that are also owned by the human player become visually selectable (e.g., highlighted with a checkbox).

2. **Tapping Combine on another fleet at the same location**:
   - That fleet is added to the selection.
   - Visual feedback shows all selected fleets.

3. **Tapping Combine on the target fleet again** (confirm):
   - All selected fleets (including the target) are merged into the **target fleet**.
   - Ship type IDs from all source fleets are appended to the target fleet's `shipTypeIds`.
   - Source fleets (non-target) are **removed** from `WorldState.fleets`.
   - The Home Fleet is **excluded** from combine operations.

4. **Cancel**: Tapping elsewhere dismisses the combine mode without changes.

### Rules

| Rule | Description |
|------|-------------|
| Same location | Only fleets at the same port province OR same sea zone can be combined. |
| Same owner | Only fleets owned by the human player. |
| Home Fleet excluded | Home Fleet cannot be combined into or used as source. |
| Empty fleets auto-deleted | After combining, source fleets with no ships (edge case) are removed. Home Fleet is never deleted even if empty. |
| Target selection | The fleet whose Combine button was tapped first becomes the target. |

### Data changes

```dart
// Before: Fleet A (target) + Fleet B (source)
// After: Fleet A (shipTypeIds = A.ships + B.ships), Fleet B removed
```

### UI

- **Combine button**: Text button in the expanded fleet tile, labeled "Combine".
- **Selection state**: Checkbox appears next to each eligible fleet. Selected fleets have checked checkbox.
- **Target indicator**: Target fleet's button changes to "Confirm Combine".
- **Ineligible fleets**: Fleets at different locations are greyed out/not selectable.

---

## Split Fleet

### Trigger

Each fleet row in the expanded state shows a **"Split Fleet"** button, including the Home Fleet.

### Dialog

Clicking "Split Fleet" opens a modal dialog: **Split Fleet Dialog**.

### Layout

```
┌─────────────────────────────────────────────────────┐
│ Split Fleet                                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Original Fleet              New Fleet              │
│  ┌─────────────────────┐    ┌─────────────────────┐│
│  │ Fleet 5             │    │ Fleet 6             ││
│  │ Location: OW-Lisbon │    │ Location: OW-Lisbon ││
│  │                     │    │                     ││
│  │ Ships:              │    │ Ships:              ││
│  │ □ Carrack (2)       │    │ □ Carrack (0)       ││
│  │ □ Fluyte (1)        │    │ □ Fluyte (0)        ││
│  │ □ Galleon (1)       │    │ □ Galleon (0)       ││
│  │                     │    │                     ││
│  └─────────────────────┘    └─────────────────────┘│
│                                                     │
│  Total: 4 ships             Total: 0 ships          │
│                                                     │
│              [ < ]       [ > ]                      │
│                                                     │
├─────────────────────────────────────────────────────┤
│              [Cancel]  [Confirm Split]              │
└─────────────────────────────────────────────────────┘
```

### Ship Movement

- **Individual move**: Click `>` to move one ship of the selected type from Original to New. Click `<` to move back.
- **Move all**: Long-press `>` to move all ships of a type. Long-press `<` to move all back.
- **Selection**: Clicking a ship row selects/deselects it for movement.

### Rules

| Rule | Description |
|------|-------------|
| Same location | New fleet spawns at the same port province or sea zone as the original. |
| Minimum ships | Original fleet must retain at least 1 ship (unless it's the Home Fleet). |
| Home Fleet | Home Fleet **can be split** — all newly built ships appear in the Home Fleet, so players must be able to split off a detachment. |
| Naming | New fleet is assigned the next available number: "Fleet N" where N is the next unused integer. |
| Region | New fleet has the same `regionId` as the original. |
| Mission | New fleet has `mission = FleetMission.none`. |

### Dialog Actions

| Action | Behavior |
|--------|----------|
| **>** (Move to New) | Moves one ship of the selected type from Original to New. |
| **<** (Move to Original) | Moves one ship of the selected type from New to Original. |
| **Cancel** | Closes dialog, no changes. |
| **Confirm Split** | Creates the new fleet with the specified ships; removes those ships from the original. Disabled if original would have 0 ships (and is not Home Fleet). |

### Data changes

```dart
// Original Fleet: Fleet { shipTypeIds: [carrack, carrock, fluyte, galleon] }
// After moving 1 carrack to new:
// Original Fleet: Fleet { shipTypeIds: [carrack, fluyte, galleon] }
// New Fleet: Fleet { shipTypeIds: [carrack] }
```

---

## Empty Fleet Cleanup

After any fleet operation (split or combine):
- Fleets with empty `shipTypeIds` are removed from `WorldState.fleets`.
- Exception: The Home Fleet is **never deleted**, even when empty.

---

## State Management

- Fleet management operations modify `WorldState.fleets`.
- The UI layer (NavalUnitsPanel) receives the updated game state and rebuilds immediately to reflect changes.
- These are immediate UI operations (not turn-based orders).

---

## Acceptance Criteria

### Combine

- **Given** two fleets at the same port province owned by the human player, **when** the user taps Combine on Fleet A and then taps Combine on Fleet B, **then** Fleet A contains all ships from both fleets, Fleet B is removed, and the panel reflects these changes immediately.

- **Given** three fleets at the same sea zone owned by the human player, **when** the user combines them, **then** the target fleet receives all ships, the two source fleets are removed, and the panel updates immediately.

- **Given** a fleet at a port province and another fleet at a different port province, **when** the user attempts to combine them, **then** the combine operation is not available between these fleets.

- **Given** the Home Fleet is present, **when** the user views fleet options, **then** the Home Fleet does not show a Combine button.

### Split

- **Given** a non-Home Fleet with multiple ships, **when** the user clicks Split Fleet, **then** a modal dialog opens showing the fleet's ship composition with transfer controls.

- **Given** the Split Fleet dialog is open with a fleet containing ships, **when** the user moves ships to the new fleet panel and clicks Confirm, **then** a new fleet is created with the moved ships, the original fleet retains the remaining ships, and both fleets appear in the panel.

- **Given** a fleet with 4 ships, **when** the user moves all 4 ships to the new fleet in the split dialog, **then** the Confirm button is disabled and the original fleet cannot be split.

- **Given** the Home Fleet is present with ships, **when** the user expands the Home Fleet row, **then** the Home Fleet shows a Split Fleet button, allowing the player to split off a detachment.

### Empty Fleet Cleanup

- **Given** a fleet operation results in a non-Home Fleet having zero ships, **when** the operation completes, **then** that fleet is automatically removed from the game state and the panel updates immediately.

- **Given** the Home Fleet has zero ships, **when** any fleet operation occurs, **then** the Home Fleet remains visible in the panel with "Total ships: 0".

### Panel Update

- **Given** the user completes a split or combine operation, **when** the operation finishes, **then** the Naval Units panel immediately reflects the new fleet composition without requiring a refresh.

---

## Widgetbook

### Stories

1. **Combine Mode Active**: Shows a fleet row with Combine button pressed, other fleets at same location highlighted with checkboxes.
2. **Split Dialog Open**: Shows the split fleet modal dialog with ship transfer controls.
3. **Post-Operation State**: Shows the panel after a combine/split operation.

### Test Coverage

- Unit tests for combine logic (same location validation, ship aggregation).
- Unit tests for split logic (minimum ship validation, new fleet creation).
- Widget tests for combine mode UI (selection, target, confirmation).
- Widget tests for split dialog (ship movement, confirm/cancel).

---

## Implementation Notes

### Files

| File | Description |
|------|-------------|
| `app/lib/features/game/widgets/naval_units_panel.dart` | Main panel with combine/split UI |
| `app/lib/features/game/widgets/split_fleet_dialog.dart` | Split fleet modal dialog |
| `app/test/naval_units_panel_test.dart` | Tests for fleet management |

### Key Implementation Details

1. **Combine Mode State**: Managed via `_NavalUnitsPanelState` with `_combineTargetFleetId` and `_selectedForCombine` fields.

2. **Split Dialog**: `SplitFleetDialog` uses `CtDialogShell` for pixel-art framing, `CtNinePatchButton` for actions, and `CtPanel` for fleet panels.

3. **Fleet Location Key**: Fleets are grouped by location using `locationKey` field: `port:{regionId}|{provinceId}` for in-port fleets, `sea:{seaZoneKey}` for at-sea fleets.

4. **New Fleet ID**: Extracted by parsing integer suffixes from existing fleet IDs and using `max + 1`.

5. **State Propagation**: Changes are propagated via `onFleetsChanged` callback which calls the Riverpod `currentGameProvider.notifier.state`.

### UI Changes

- **Split Button**: Shortened from "Split Fleet" to "Split" to save space
- **Combine Button**: Shows "Select"/"Remove" during selection, "Confirm" for target
- **TARGET Badge**: Red badge appears next to target fleet name
- **Checkboxes**: Appear on eligible fleets during combine mode

