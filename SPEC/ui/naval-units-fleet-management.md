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

2. **Selecting another fleet at the same location** (e.g. checkbox on its title row):
   - That fleet is added to the selection set.
   - Visual feedback shows all selected fleets.

3. **Tapping Confirm on the target fleet** (after selecting sources):
   - All selected fleets (non-target sources) are merged into the **target fleet**.
   - **Ship instances** (`id` + `typeId`) from each source fleet are **appended** to the target fleet’s instance list (each hull keeps its unique id).
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
// Before: Fleet A (target) + Fleet B (source), each with List<ShipInstance> ships
// After: Fleet A.ships = [...A.ships, ...B.ships]; Fleet B removed from WorldState.fleets
```

### UI

- **Combine button**: Nine-patch button in the **expanded** fleet tile (scroll if needed in short panels), labeled "Combine".
- **Selection state**: Checkbox appears next to each eligible fleet title. Selected fleets show a checked checkbox.
- **Target indicator**: Target fleet shows a **TARGET** badge on the title row; its action button is **Confirm**.
- **Ineligible fleets**: Fleets at different locations are not selectable (no checkbox).
- **Expansion vs locate:** Tapping the fleet **header** expands or collapses the tile. **Locate fleet** runs only from the **location icon** in the header (not a whole-row tap).

---

## Split Fleet

### Trigger

Each fleet row in the expanded state shows a **"Split Fleet"** button, including the Home Fleet.

### Dialog

Clicking "Split Fleet" opens a modal dialog: **Split Fleet Dialog**.

### Reusable Transfer Component

Split Fleet uses a reusable app-level transfer component (`CtTransferList`) for
dual-list quantity movement. The naval split dialog configures this component
with fleet-specific labels and validation.

`CtTransferList` API requirements:
- Inputs: left/right titles, optional subtitles, initial counts for both sides
- Transfer controls: per-row one/all moves in both directions (`<`, `>`, `<<`, `>>`) on each list row (no separate “selected type” step)
- Validation hook: `canConfirm(leftCounts, rightCounts)`
- Confirm callback: `onConfirm(leftCounts, rightCounts)`
- Optional cancel callback and customizable action labels
- Customizable item label and empty-state labels

Naval-specific behavior remains outside the component:
- Home-fleet split rule override
- Fleet location labeling
- Conversion from right-side counts to the set of **ship instance ids** transferred to the new fleet

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
│  │ Ships:                │    │ Ships:                ││
│  │ Carrack (2)  [>][>>]  │    │ [<<][<] Carrack (0)  ││
│  │ Fluyte (1)   [>][>>]  │    │ [<<][<] Fluyte (0)   ││
│  │ Galleon (1)  [>][>>]  │    │ [<<][<] Galleon (0)  ││
│  │                       │    │                       ││
│  └─────────────────────┘    └─────────────────────┘│
│                                                     │
│  Total: 4 ships             Total: 0 ships          │
│                                                     │
├─────────────────────────────────────────────────────┤
│              [Cancel]  [Confirm Split]              │
└─────────────────────────────────────────────────────┘
```

### Ship Movement

- **Individual move**: On each Original row, use `>` to move one ship of that type to New; on each New row, use `<` to move one back.
- **Move all**: On each Original row, use `>>` to move all ships of that type to New; on each New row, use `<<` to move all of that type back to Original.
- **Disabled transfer controls**: Row buttons for a type are absent when that side has zero of that type; otherwise controls respect minimum-ship rules via Confirm validation.

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
| **>>** (Move All to New) | Moves all ships of the selected type from Original to New. |
| **<<** (Move All to Original) | Moves all ships of the selected type from New to Original. |
| **Cancel** | Closes dialog, no changes. |
| **Confirm Split** | Creates the new fleet with the specified ships; removes those ships from the original. Disabled if original would have 0 ships and the original is not the Home Fleet. |

### Data changes

```dart
// Original Fleet: ships: [ShipInstance(id: ship_1, carrack), …]
// After moving one carrack instance to new:
// Original Fleet: remaining instances only; New Fleet: the moved instances (same ids)
```

---

## Empty Fleet Cleanup

After any fleet operation (split or combine):
- Fleets with an **empty** `ships` list are removed from `WorldState.fleets`.
- Exception: The Home Fleet is **never deleted**, even when empty.

---

## State Management

- Fleet management operations modify `WorldState.fleets`.
- The UI layer (NavalUnitsPanel) receives the updated game state and rebuilds immediately to reflect changes.
- These are immediate UI operations (not turn-based orders).

---

## Acceptance Criteria

### Combine

- **Given** two fleets at the same port province owned by the human player, **when** the user expands Fleet A, taps Combine, selects Fleet B via its checkbox, and taps Confirm on the target, **then** Fleet A’s instance list contains every hull from both fleets (each **instance id** appears once), Fleet B is removed, and the panel reflects these changes immediately.

- **Given** three fleets at the same sea zone owned by the human player, **when** the user combines them, **then** the target fleet receives all ships, the two source fleets are removed, and the panel updates immediately.

- **Given** a fleet at a port province and another fleet at a different port province, **when** the user attempts to combine them, **then** the combine operation is not available between these fleets.

- **Given** the Home Fleet is present, **when** the user views fleet options, **then** the Home Fleet does not show a Combine button.

### Split

- **Given** a non-Home Fleet with multiple ships, **when** the user clicks Split Fleet, **then** a modal dialog opens showing the fleet's ship composition with transfer controls.

- **Given** the Split Fleet dialog is open with a fleet containing ships, **when** the user moves ships to the new fleet panel and clicks Confirm, **then** a new fleet is created with the **moved ship instances** (same instance ids), the original fleet retains the remaining instances, and both fleets appear in the panel.

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
- **TARGET badge**: Theme-colored badge next to target fleet name
- **Checkboxes**: Appear on eligible fleets during combine mode

