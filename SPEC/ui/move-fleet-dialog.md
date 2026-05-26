# Move Fleet Dialog

**Screen ID:** `DLG30001` — stable; do not reassign.
**SPEC/ui** — Modal that lets the human player move a sea-going fleet to an adjacent sea zone or owned port from the [naval-units-panel.md](naval-units-panel.md). Implementation: `app/lib/features/game/widgets/move_fleet_dialog.dart`.
**Widgetbook:** `Move Fleet Dialog` → `app/lib/widgetbook/catalog.dart`. Game model: [ships-and-naval.md](../game/ships-and-naval.md). Movement: [naval-movement-resolution.md](../program/naval-movement-resolution.md). Map locate: [map-widget.md](map-widget.md). App wiring: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

**Mockup:** [mockups/DLG30001-move-fleet-dialog.html](mockups/DLG30001-move-fleet-dialog.html)
---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `MoveFleetDialog` | `StatefulWidget` | `game` (`Game`), `topology` (`MapTopology`), `humanPlayerId` (`String`), `fleet` (`Fleet`), `bus` (`AppEventBus`) | Local `showDialog` modal opened from `NavalUnitsPanel` fleet row Move action. Emits a naval move request on confirm and per-row `LocateMapTileEvent`s on locate. |

Implementation: `app/lib/features/game/widgets/move_fleet_dialog.dart`. Wrapped Material `AlertDialog`; not a `CtDialogShell`. `_buildNavalMovePicks` plus the `_PickSeaZone` / `_PickPort` variants build the sealed `_MovePick` list and order conversion.

---

## Layout / wireframe

```text
+--------------------------------------------------+
| Move fleet — Fleet <id>  (N destinations)        |  title row
+--------------------------------------------------+
|  SizedBox(width: 420)                            |
|                                                  |
|  Sea zones                                       |  section header (bold)
|   ( ) Adjacent Sea               [locate]        |
|   ( ) Warp Sea links                  [locate]   |
|   ( ) Cross Sea links to <Region>     [locate]   |
|                                                  |
|  Provinces (dock)                                |  section header (bold)
|   ( ) Coastal Province           [locate]        |
|   ( ) Capital Province (capital — joins         |
|         Home Fleet)              [locate]        |
|                                                  |
+--------------------------------------------------+
|              [ Cancel ]   [ Confirm ]            |  Material TextButtons
+--------------------------------------------------+
```

- Title: `moveFleet_title(fleetLabel)` when `picks.isEmpty`, else `moveFleet_titleWithDestinations(fleetLabel, picks.length)`. `fleetLabel` is `'Fleet <fleet.id>'`.
- Empty state: `moveFleet_noAdjacentSeaZones` replaces the picks column; Confirm stays disabled.
- Body: `SingleChildScrollView` over a `Column` with two optional sections (`moveFleet_seaZonesSection`, `moveFleet_provincesDockSection`) separated by 12 dp when both render. When `kCtE2EEnabled`, the column is wrapped in a `KeyedSubtree` keyed `kCtE2EMoveFleetDialogScrollRootKey`.
- Rows: each pick is a `RadioListTile<_MovePick>` whose title is a `Row` of `Expanded(Text(rowLabel))` + an `IconButton` (`Icons.my_location`, size 18) with tooltip `moveFleet_locateOnMap` that calls `pick.emitLocate(bus, game)`.
- Sea-zone labels: non-warp zones show the localized sea-zone name; warp zones append `moveFleet_warpLink` for same-region warps, else `moveFleet_warpLinkToRegion(<region label>)` for cross-region warps. Names come from `seaZoneDisplayName`.
- Port labels: province display name (fallback to id). Capital port appends ` (capital — joins Home Fleet)` per [ships-and-naval.md](../game/ships-and-naval.md) Home Fleet merge semantics. Port rows render only when the fleet is at sea and the dock target belongs to the human player.
- Sort order: sea picks then port picks; within each section, rows are sorted by `rowLabel`.

---

## Trigger conditions

- Opened from `NavalUnitsPanel` non-Home fleet row **Move** action; the **Home Fleet** row never shows Move ([naval-units-panel.md](naval-units-panel.md) § Move fleet).
- `_buildNavalMovePicks` derives candidates from `navalMoveTopologyPicksForFleet(topology, fleet)`. With zero topology picks the dialog opens in the empty state.
- The dialog does not mutate game state; it emits `NavalMoveFleetRequestedEvent` and the shell/turn-resolution pipeline applies the order.

---

## States and variants

| State | Condition | UI |
|-------|-----------|-----|
| Empty | `_buildNavalMovePicks` returns `[]` | Body shows `moveFleet_noAdjacentSeaZones`; Confirm disabled. |
| At sea, sea + port | Fleet at sea, has adjacent sea zones and at least one owned dock province | Both sections render with a 12 dp spacer. |
| At sea, sea only | Fleet at sea, no owned dock destinations | Only `Sea zones` section renders. |
| In port | `fleet.isAtSea == false` | Only `Sea zones` section renders (P→P disallowed). |
| Cross-region warp | Warp-zone in a different region than the fleet's sea region | Row label appends `moveFleet_warpLinkToRegion(<region label>)`. |
| Same-region warp | Warp-zone in the same region | Row label appends `moveFleet_warpLink`. |
| Capital dock | Dock province equals the player's capital | Row label appends ` (capital — joins Home Fleet)`. |
| Selection | A row is tapped | `_selected` updates; Confirm becomes enabled. |

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| `NavalUnitsPanel` Move action | Fleet row; `navalMoveTopologyPicksForFleet` non-empty | `showDialog` mounts `MoveFleetDialog`. |
| — | Zero move picks | Dialog may open with empty state (`moveFleet_noAdjacentSeaZones`). |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Cancel | Always | `Navigator.pop(context, false)` | No bus event. |
| Confirm | `_selected != null` | `NavalMoveFleetRequestedEvent` via `selected.toOrder(fleet.id)` | Dialog popped with `true`. |
| Locate (per row) | Tile key resolves | `LocateMapTileEvent` | Panel may stay open. |

---

## Components

- Material `AlertDialog`, `RadioListTile`, `IconButton`, `TextButton`, `SingleChildScrollView`, `Column`.
- Localized keys via `appL10n(context)`: `moveFleet_title`, `moveFleet_titleWithDestinations`, `moveFleet_noAdjacentSeaZones`, `moveFleet_seaZonesSection`, `moveFleet_provincesDockSection`, `moveFleet_warpLink`, `moveFleet_warpLinkToRegion`, `moveFleet_locateOnMap`, `common_cancel`, `common_confirm`.

---

## Acceptance Criteria (Given–When–Then)

- Given a fleet at sea with at least one adjacent sea zone and at least one owned dock province, when `MoveFleetDialog` opens, then the UI layer shows both `moveFleet_seaZonesSection` and `moveFleet_provincesDockSection` headers and the dialog title is `moveFleet_titleWithDestinations(fleetLabel, count)` where `count` equals the total `_MovePick` count.

- Given a fleet whose `navalMoveTopologyPicksForFleet` returns zero candidates, when `MoveFleetDialog` opens, then the UI layer shows title `moveFleet_title(fleetLabel)`, body text `moveFleet_noAdjacentSeaZones`, and `TextButton.onPressed` is `null` for Confirm.

- Given the user selects a sea-zone row and taps Confirm, when the bus is observed, then the UI layer emits exactly one `NavalMoveFleetRequestedEvent` with `moveOrder.destinationSeaZoneId` set to the selected zone id, `destinationPortProvinceId == null`, and the dialog is removed from the widget tree.

- Given the user selects a dock-port row and taps Confirm, when the bus is observed, then the emitted `NavalMoveFleetRequestedEvent.moveOrder.destinationPortProvinceId` equals the selected full province id and `destinationSeaZoneId` is `null`.

- Given a warp-zone destination in a region different from the fleet's current sea region, when the row renders, then the row label contains `links to <region>` and not the bare `moveFleet_warpLink` suffix.

- Given the user taps the per-row locate icon on any row whose tile key resolves, when the gesture completes, then the UI layer emits exactly one `LocateMapTileEvent` with a non-empty `tileKey`.

- Given the user taps Cancel, when the gesture completes, then no `NavalMoveFleetRequestedEvent` is emitted and the dialog is removed from the widget tree.

---

## Widgetbook

Catalog folder: **Move Fleet Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use case:

1. **Default — sea zones + dock:** Minimal `Game`, `MapTopology`, and `Fleet` fixture wired so the dialog renders both sections with at least one warp-zone destination and one capital dock row, plus a fresh `AppEventBus`.

Automated widget tests: `app/test/move_dialogs_specs_test.dart`; broader behavior coverage in `app/test/move_fleet_dialog_test.dart`.
