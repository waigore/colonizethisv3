# Naval Units Panel — Fleet Management (Split & Combine)

**SPEC/ui** — Extends [naval-units-panel.md](naval-units-panel.md) with fleet management actions: **split fleet** and **combine fleets**. These operations allow players to reorganize their naval forces.

---

## Purpose

Players need to reorganize their fleets:

- **Split**: Divide a fleet into two fleets (e.g., send a detachment on a separate mission).
- **Combine**: Merge **two or more selected** fleets that share the **same naval locality** (see below) into one fleet.

---

## Combine Fleets

### Trigger and layout

- The panel **title row** includes:
  - A **Select all / Deselect all** control implemented as a **tristate header checkbox** (unchecked = none selected; checked = all fleets selected; indeterminate = partial selection). Interacting with it **selects every fleet row** or **clears all selection** (same behavior as typical “select all” patterns: from none or partial → select all; from all → deselect all).
  - A **Combine** button (same family as other panel actions, e.g. nine-patch), placed in the title row next to that checkbox.
- **No separate Cancel** for combine; clearing selection uses the header control or per-row checkboxes.

### Per-fleet selection

- Every fleet row (including **Home Fleet**) shows a **checkbox** in the row header **at all times** (collapsed or expanded). Checking does not require expanding the row.
- **Combine** is **enabled** only when:
  - **At least two** fleets are checked, and
  - Every checked fleet shares the **same combine locality**: either the **same sea zone** (fleets at sea) or the **same port province** (fleets in port). Ports are **not** mixed with sea zones for this rule—a fleet in port and a fleet at sea in an adjacent zone cannot combine.
- **Combine** is **disabled** when fewer than two fleets are checked, or when checked fleets span more than one locality.

### Merge target and ship data

- **Survivor fleet** (merge target):
  - If **Home Fleet** is among the checked fleets, the **Home Fleet** is always the target (all other checked fleets merge **into** it).
  - Otherwise, the target is the checked fleet that appears **first in panel display order** (same ordering as [naval-units-panel.md](naval-units-panel.md): region groups, Home Fleet section when present, then location nodes and stable fleet order within each node).
- **Sources:** every **other** checked fleet, in **panel display order** after the target.
- **Ship instances:** Append each source’s `ships` list onto the target’s list in that order; each hull keeps its unique instance `id` (no duplicate ids across fleets).
- **Remove** every **source** fleet from `WorldState.fleets` after the merge.
- **Mission:** The **surviving** fleet’s mission is set to **`none`** (missions from merged fleets do not carry over). Clear any mission-specific targets on the merged fleet if the model supports them.

### Rules

| Rule | Description |
|------|-------------|
| Same locality | Only fleets in the **same port province** or the **same sea zone** may be combined together in one action. |
| Same owner | Only fleets owned by the human player are listed; combine only affects the player’s selection. |
| Home Fleet | **May** be selected and combined. When checked with other fleets, Home Fleet is **always** the merge target. |
| Empty fleets | After combining, any non-Home fleet with no ships is removed. Home Fleet is **never** deleted when empty. |

### Join Selected Ships To Home Fleet (Scope B extension)

When Home Fleet is selected with exactly one non-home source fleet, combine opens a transfer dialog so the user can move a selected ship subset into Home Fleet instead of forcing an all-ships merge.

- **Target:** Home Fleet is always the destination.
- **Source:** Exactly one selected non-home fleet (same owner).
- **Ship transfer semantics:** Player moves ship counts by type using `CtTransferList`; moved hulls preserve their instance ids and are appended to Home Fleet in source-fleet order.
- **Source location rules (authoritative):**
  - Source fleet is valid when it is **in port at the player's capital province**, or
  - Source fleet is valid when it is **at sea in a sea zone adjacent to the player's capital province** under the same `MapTopology` adjacency rules used by naval transfer validation.
- **Cross-region exclusion:** If no adjacency edge exists between source sea zone and the capital province in the current topology, transfer is not offered.
- **Source cleanup:** If the transfer leaves source with zero ships, source fleet is removed; otherwise source remains with the unmoved ships.
- **Home Fleet persistence:** Home Fleet always remains and stays at the capital port.

### Data changes

```dart
// Checked fleets at same locality: target T (Home if selected, else first in panel order among checked),
// sources S1, S2, … in display order after T.
// After: T.ships = [...T.ships, ...S1.ships, ...]; S1, S2, … removed; T.mission = none.
```

### UI notes

- **Locate fleet** remains on the **location icon** in the header (not the whole row), per [naval-units-panel.md](naval-units-panel.md) interaction with fleet management.
- **Expansion vs locate:** Tapping the fleet **title text** (or default expansion affordance) expands or collapses the tile; the checkbox only toggles selection.

---

## Split Fleet

### Trigger

Each fleet row shows a **Split** action in the collapsed header content so the action is available without expanding first, including for the Home Fleet. The expanded section remains for detailed composition and transfer context, not for primary action discovery.

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
- **Narrow-viewport layout:** Below `kCtTransferListSideBySideMinWidth` (`360` dp) — measured against the host's `LayoutBuilder` constraint, not the raw viewport — the two side panels stack vertically (left panel → 16 dp gap → right panel → 16 dp gap → action row) and the trailing Cancel / Confirm action row flows through a `Wrap(alignment: end)` so the long Cinzel engraved-label `CtNinePatchButton` pair (e.g. "Cancel" + "Confirm Split", "Cancel" + "Transfer") never overflows horizontally on narrow shells like `CtDialogShell` at `kMinViewportWidth` (`320` dp). Wider hosts keep the canonical side-by-side `Row` layout and the right-aligned single-run action `Row` so existing widget tests + SPEC mockups see unchanged chrome.

**Ship type labels:** The dialog passes `itemLabelBuilder: shipTypeDisplayName` so each row shows the same human-readable ship name as the Naval Units panel composition table ([ships-and-naval.md](../game/ships-and-naval.md)), not raw `ship_type_id` strings.

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

- **Given** two fleets in the **same port province** owned by the human player, **when** the user checks both and taps **Combine**, **then** the first-checked fleet in **panel order** among the selection (or **Home Fleet** if it is checked) receives every ship instance from the other, the source fleet is removed, the survivor’s mission is **`none`**, and the panel updates immediately.

- **Given** the **Home Fleet** and another fleet **in port at the capital** (same locality), **when** the user checks both and taps **Combine**, **then** all ship instances merge **into the Home Fleet** regardless of panel order relative to the other fleet, the non-home fleet is removed, and the Home Fleet’s mission is **`none`**.

- **Given** a fleet at a port province and another fleet at a **different** port or at **sea**, **when** the user checks both, **then** **Combine** remains **disabled** and no merge occurs until the selection is valid.

- **Given** the Naval Units panel is open, **when** fewer than two fleets are checked, **then** **Combine** is **disabled**.

- **Given** the panel title **select-all** checkbox, **when** the user uses it to select all fleets then uses it again, **then** selection clears (deselect all).

- **Given** **three or more** fleets sharing the **same port** or the **same sea zone**, **when** the user checks them and taps **Combine**, **then** one survivor fleet (Home if selected, else first in panel order) contains every ship in panel order, the other checked fleets are removed, the survivor’s mission is **`none`**, and the panel updates immediately.

- **Given** two fleets **at sea** in **different** sea zones, **when** both are checked, **then** **Combine** stays **disabled**.

- **Given** one fleet **at sea** and one **in port**, **when** both are checked, **then** **Combine** stays **disabled** (mixed locality).

- **Given** the Home Fleet and one source fleet in port at the player's capital are selected, **when** the user taps **Combine** and transfers only a subset of source ships, **then** only the selected ship instances move to Home Fleet, source fleet remains with the remainder, and Home Fleet remains at the capital port.

- **Given** the Home Fleet and one source fleet at sea in a sea zone adjacent to the player's capital are selected, **when** the user confirms selected-ship transfer, **then** only the selected source ship instances move to Home Fleet and source fleet remains only if ships are left.

- **Given** the Home Fleet and one source fleet are selected and every source ship is transferred, **when** the transfer is confirmed, **then** source fleet is removed and Home Fleet remains with increased ship count.

- **Given** the Home Fleet and one source fleet at sea with no topology adjacency edge to the capital province are selected, **when** the user views combine availability, **then** Combine is disabled and no transfer dialog opens.

### Split

- **Given** a non-Home Fleet with multiple ships, **when** the user clicks Split Fleet, **then** a modal dialog opens showing the fleet's ship composition with transfer controls.

- **Given** the Split Fleet dialog is open and the fleet includes ships of type `carrack`, **when** the user reads a transfer-list row label, **then** the UI layer shows **Carrack** (via `shipTypeDisplayName`), not the raw id string `carrack`.

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

1. **Combine selection**: Title row with header checkbox and Combine; several fleets with per-row checkboxes; Combine disabled until two+ at same locality.
2. **Split Dialog Open**: Shows the split fleet modal dialog with ship transfer controls.
3. **Post-Operation State**: Shows the panel after a combine/split operation.

### Test Coverage

- Unit tests for combine logic (same locality validation, ship aggregation, Home Fleet target priority, mission reset).
- Widget tests for combine UI (selection, header select-all, disabled Combine when invalid).

---

## Implementation Notes

### Files

| File | Description |
|------|-------------|
| `app/lib/features/game/widgets/naval_units_panel.dart` | Main panel with combine/split UI |
| `app/lib/features/game/widgets/split_fleet_dialog.dart` | Split fleet modal dialog |
| `app/test/naval_units_panel_test.dart` | Tests for fleet management |

### Key Implementation Details

1. **Combine selection**: `Set<String>` of canonical fleet ids (`homeFleetIdFor(player)` for Home Fleet rows; otherwise row `fleetId`).

2. **Split Dialog**: `SplitFleetDialog` uses `CtDialogShell` for pixel-art framing, `CtNinePatchButton` for actions, and `CtPanel` for fleet panels.

3. **Fleet Location Key**: Fleets are grouped by location using `locationKey` field: `port:{regionId}|{provinceId}` for in-port fleets, `sea:{seaZoneKey}` for at-sea fleets.

4. **New Fleet ID**: Extracted by parsing integer suffixes from existing fleet IDs and using `max + 1`.

5. **State Propagation**: Changes are propagated via `onFleetsChanged` callback which calls the Riverpod `currentGameProvider.notifier.state`.

### UI labels

- **Split** button: shortened from "Split Fleet" in-row.
- **Combine**: single action in the panel title row (not per-row).

GitHub tracking: [issue #1390](https://github.com/waigore/colonizethisv3/issues/1390) (naval combine UX: checkbox multi-select, locality rule, Home Fleet target).
