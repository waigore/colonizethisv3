# Transfer to Home Fleet Dialog

**Screen ID:** `DLG40001` — stable; do not reassign.
**SPEC/ui** — Modal that lets the human player move ship instances from a regular fleet **at the capital port** into the same-region **Home Fleet** from the [naval-units-panel.md](naval-units-panel.md). Game model: [ships-and-naval.md](../game/ships-and-naval.md) (Home Fleet merge semantics). Implementation: `app/lib/features/game/widgets/transfer_to_home_fleet_dialog.dart`. App wiring and events: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).
**Widgetbook:** `Transfer to Home Fleet Dialog` → `app/lib/widgetbook/catalog.dart` (see § Widgetbook).

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `TransferToHomeFleetDialog` | `StatelessWidget` | `sourceFleet` (`Fleet`), `homeFleet` (`Fleet`), `game` (`Game`), `humanPlayerId` (`String`), `bus` (`AppEventBus`) | Local `showDialog` modal opened from `NavalUnitsPanel` regular-fleet **Transfer to Home Fleet** action. Emits a single `NavalTransferShipsRequestedEvent` on confirm. |

Implementation: `app/lib/features/game/widgets/transfer_to_home_fleet_dialog.dart`. Wrapped in `CtDialogShell` (`maxWidth: 560`, `maxHeight: 520`) hosting a `CtTransferList`. Ship instance selection is delegated to `shipInstancesForTransferCounts` (see [naval-units-fleet-management.md](naval-units-fleet-management.md)).

---

## Layout / wireframe

```text
+--------------------------------------------------------+
| Transfer Ships to Home Fleet                           |  titleLarge
+--------------------------------------------------------+
|  CtTransferList (listHeight: 240)                      |
|                                                        |
|  ┌─ Fleet <sourceFleet.id> ──┐ ┌─ Home Fleet ────────┐ |
|  │ <location>                │ │ <location>          │ |
|  │  carrack          [2 -]   │ │  carrack    [1 +]   │ |
|  │  fluyte           [1 -]   │ │                     │ |
|  │  Total: 3 ships           │ │  Total: 1 ships     │ |
|  └───────────────────────────┘ └─────────────────────┘ |
|                                                        |
|              [ Cancel ]   [ Confirm Transfer ]         |
+--------------------------------------------------------+
```

- Body: `Padding(16)` → `Column(min)` with the dialog title and a single `CtTransferList`.
- `leftTitle` is `naval_transferToHome_sourceTitle(sourceFleet.id)`; `rightTitle` is `naval_homeFleetLabel`. Subtitles are the per-fleet **location label** (sea-zone + region for fleets at sea, otherwise province + region; falls back to region label when neither resolves).
- `initialLeftCounts` / `initialRightCounts` are derived from each fleet's `shipTypeIds` (one entry per ship instance, aggregated by `typeId`).
- Empty per-side label: `splitFleet_noShips`. Total label: `splitFleet_totalShips(total)`.
- Cancel action label: `common_cancel` (from `CtTransferList` default). Confirm label: `naval_transferToHome_confirm` ("Confirm Transfer").

---

## Trigger conditions

- Opened from `NavalUnitsPanel` regular-fleet row **Transfer to Home Fleet** action when a same-region Home Fleet exists; the row is not shown for the Home Fleet itself. See [naval-units-panel.md](naval-units-panel.md) § Move fleet for the cross-link.
- Source and Home Fleet must belong to `humanPlayerId` and share the same `regionId` (the panel pre-resolves the pair).
- The dialog does not mutate game state; it emits `NavalTransferShipsRequestedEvent` and the handler scope applies the merge via `applyNavalTransferShips`.

---

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| `NavalUnitsPanel` regular-fleet row **Transfer to Home Fleet** tap | Source fleet is not the Home Fleet and a same-region Home Fleet exists for `humanPlayerId` | `showDialog` mounts `TransferToHomeFleetDialog` with the pre-resolved `(sourceFleet, homeFleet)` pair. |
| Initial `CtTransferList` mount | The dialog just opened | Left side shows `sourceFleet` inventory, right side shows `homeFleet` inventory, both aggregated by ship `typeId`; Confirm stays disabled until at least one row moves. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Source row `-` button | The row's source count is greater than `0` | Decrements the source count and increments the matching home-side count | Confirm enables once any source row has a positive delta from `initialLeftCounts`. |
| Source row `+` button | The row's source count is below `initialLeftCounts[typeId]` (i.e. previously moved) | Increments source / decrements home | Confirm disables again when all rows return to their initial counts. |
| `common_cancel` action | Always | `Navigator.of(context).pop()` | No event emitted; dialog removed from tree. |
| `naval_transferToHome_confirm` action — no ships moved | Movement totals reduce to zero | `_handleConfirm` returns early before emitting | No event; dialog stays open. |
| `naval_transferToHome_confirm` action — at least one ship moved | `movedByType` resolves to at least one instance via `shipInstancesForTransferCounts(sourceFleet.ships, movedByType)` | `bus.emit(NavalTransferShipsRequestedEvent(humanPlayerId, sourceFleet.id, targetFleetId: homeFleet.id, shipInstanceIdsToTransfer: [...]))` then `Navigator.of(context).pop()` | Dialog removed; merge applies via `applyNavalTransferShips` per [app-ui-wiring.md](../program/app-ui-wiring.md). |

The dialog never mutates `Game` or `Fleet` state directly; effects flow through `NavalTransferShipsRequestedEvent`.

---

## States and variants

| State | Condition | UI |
|-------|-----------|-----|
| Initial | Dialog opens | Source list shows the source fleet's full inventory; Home list shows the home fleet's full inventory. Confirm disabled because no ship has moved across yet. |
| Selecting | User taps a row's `-` button on the source side | Source count decreases; Home count increases; Confirm becomes enabled (any positive delta on source). |
| Reverted | User taps `+` on a previously moved row until source count equals initial | Confirm disables again (no positive delta). |
| Mixed types | Source contains multiple ship type ids | Each type id renders its own row with `shipTypeDisplayName` label and shared counters per type. |

The dialog **does not** mutate game state. All state changes flow through `NavalTransferShipsRequestedEvent`.

---

## Navigation

| Action | Behavior |
|--------|----------|
| Cancel | `Navigator.of(context).pop()`; no event emitted. |
| Confirm — no ships moved | Internal `_handleConfirm` computes `movedByType` and returns early when `shipInstancesForTransferCounts` yields zero instances; no event, dialog stays open. |
| Confirm — at least one ship moved | `bus.emit(NavalTransferShipsRequestedEvent(humanPlayerId, sourceFleetId, targetFleetId: homeFleetId, shipInstanceIdsToTransfer: [...]))` with the deterministic instance ids returned by `shipInstancesForTransferCounts(sourceFleet.ships, movedByType)`; then pop. |

---

## Components

- `CtDialogShell`, `CtTransferList` (see [shared widgets](../program/app-ui-wiring.md) and `app/lib/widgets/ct_transfer_list.dart`).
- Helper: `shipInstancesForTransferCounts` (from `colonizethis_models`).
- Localized keys via `appL10n(context)`: `naval_transferToHome_dialogTitle`, `naval_transferToHome_sourceTitle`, `naval_homeFleetLabel`, `naval_transferToHome_confirm`, `splitFleet_noShips`, `splitFleet_totalShips`, `common_cancel`.

---

## Acceptance Criteria (Given–When–Then)

- Given a regular fleet with 2 carracks and a same-region Home Fleet with 1 carrack, when `TransferToHomeFleetDialog` opens, then the UI layer renders exactly one `CtTransferList` whose source side total reads `Total: 2 ships` and whose target side total reads `Total: 1 ships`.

- Given the dialog has just opened and no source row counters have been changed, when the user looks at the Confirm button, then `CtTransferList.canConfirm` returns `false` and the Confirm action is disabled.

- Given the user moves at least one carrack from the source side to the home side via the source row `-` button, when the user taps Confirm Transfer, then the UI layer emits exactly one `NavalTransferShipsRequestedEvent` on the supplied bus with `humanPlayerId` equal to `widget.humanPlayerId`, `sourceFleetId` equal to `sourceFleet.id`, `targetFleetId` equal to `homeFleet.id`, and `shipInstanceIdsToTransfer` equal to the deterministic instance ids returned by `shipInstancesForTransferCounts(sourceFleet.ships, movedByType)`, and the dialog is removed from the widget tree.

- Given the user reverts every moved row back to its initial source count, when the user taps Confirm Transfer, then no `NavalTransferShipsRequestedEvent` is emitted and the dialog remains mounted.

- Given the user taps Cancel, when the gesture completes, then no `NavalTransferShipsRequestedEvent` is emitted and the dialog is removed from the widget tree.

- Given the source fleet is at sea in a known sea zone, when the dialog builds, then the source-side subtitle is the localized sea-zone display name joined to the region display label by ` - ` (for example `Adjacent Sea - Old World`).

---

## Widgetbook

Catalog folder: **Transfer to Home Fleet Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use case:

1. **Default — source + home, mixed ship types:** Minimal `Game` fixture with a regular `Fleet` containing 2 carracks + 1 fluyte and a same-region `Home Fleet` containing 1 carrack. Demo opener renders an `ElevatedButton` that calls `showDialog`.

Automated widget tests: `app/test/transfer_to_home_fleet_dialog_spec_test.dart`.
