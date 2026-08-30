# Transfer to Home Fleet Dialog

**Screen ID:** `DLG40001` — stable; do not reassign.
**SPEC/ui** — Move ship instances from a regular fleet at the capital into the same-region **Home Fleet**. Implementation: `app/lib/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart`.
**Widgetbook:** `Transfer to Home Fleet Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs.dart`. Model: [ships-and-naval.md](../game/ships-and-naval.md). Wiring: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).
**Mockup:** [mockups/DLG40001-transfer-to-home-fleet.html](mockups/DLG40001-transfer-to-home-fleet.html)

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `TransferToHomeFleetDialog` | `StatelessWidget` | `sourceFleet`, `homeFleet`, `game`, `humanPlayerId`, `bus`, `overseasCargoUsed` (`int`, default `0`), `isCargoUsedReliable` (`bool`, default `true`), `cargoNotDefined` (`bool`, default `false`) | Local `showDialog` from `NavalUnitsPanel` **Transfer to Home Fleet** / **Combine**. Emits `NavalTransferShipsRequestedEvent` on confirm. Cargo flags match [naval-units-fleet-management.md](naval-units-fleet-management.md) § Home Fleet cargo consequence; the dialog does **not** import Riverpod. |

`CtDialogShell` (`maxWidth: 560`, `maxHeight: 520`, editorial-monocle chrome) hosts `CtTransferList`. Instance pick uses `shipInstancesForTransferCounts`.

## Layout / wireframe

```text
CtDialogShell
  title: Transfer Ships to Home Fleet
  CtTransferList (listHeight 240)
    left: Fleet <id> / location / type rows / Total
    right: Home Fleet / location / type rows / Total
  extraContent: transfer cargo line
  Cancel | Transfer
```

- Title: `naval_transferToHome_dialogTitle` in `--accent` `titleMedium`, `letter-spacing: 0.05em`.
- Body: `Padding(16)` → `Column(min)`: title, `CtTransferList`.
- `leftTitle` `naval_transferToHome_sourceTitle(sourceFleet.id)`; `rightTitle` `naval_homeFleetLabel`. Subtitles: sea-zone + region at sea, else province + region.
- Counts from each fleet’s `shipTypeIds`. Empty: `splitFleet_noShips`. Totals: `splitFleet_totalShips`. Confirm: `naval_transferToHome_confirm`. Disabled until a positive source delta.
- Cargo line (`extraContentBuilder`): remaining holds = `NavalStatsCatalog.cargoHold` summed on **Home Fleet / right** staged counts. Copy is transfer-specific (`naval_transferToHome_homeCargoConsequence` + `mapControls_cargoHold_details_free`). Colour matches Home Fleet split (`--muted` remaining **>** used; `--accent` **==**; `--danger` **<**; unreliable / not-defined used is `—` and never a shortfall). Split/detach copy is unchanged ([naval-units-fleet-management.md](naval-units-fleet-management.md) `Refs #4448`).
- Narrow viewport: below `kCtTransferListSideBySideMinWidth` (`360` dp) the lists stack and Cancel / Transfer wrap ([mobile-adaptation.md](mobile-adaptation.md) § 7). The cargo line wraps in the same column.

## Trigger conditions

- `NavalUnitsPanel` regular-fleet **Transfer to Home Fleet**, or **Combine** of Home Fleet plus one eligible source. Home Fleet row never shows Transfer. See [naval-units-panel.md](naval-units-panel.md).
- Panel passes the same `overseasCargoUsed` / `isCargoUsedReliable` / `cargoNotDefined` it already passes to `SplitFleetDialog`.
- Confirm emits `NavalTransferShipsRequestedEvent`; apply is outside this dialog.

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `DLG40001` | Initial | Open | Source/home inventories; Confirm disabled; cargo line uses Home Fleet initial holds. |
| `DLG40001` | Selecting | Source `-` | Source down, home up; Confirm enabled; cargo line live on right counts. |
| `DLG40001` | Reverted | Source restored | Confirm disabled. |
| `DLG40001` | Mixed types | Several `typeId`s | One row per type. |
| `DLG40001` | Cargo unreliable | `cargoNotDefined` or `!isCargoUsedReliable` | Used and free-for-trade show `—`; `--muted`. |

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| `NavalUnitsPanel` Transfer / Combine | Eligible source + Home Fleet | `showDialog` mounts this dialog with panel cargo flags. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Cancel | Always | `Navigator.pop` | No bus event. |
| Transfer | At least one hull moved (`canConfirm` positive source delta only; cargo shortfall does **not** disable) | `NavalTransferShipsRequestedEvent` (`humanPlayerId`, `sourceFleetId`, `targetFleetId`, `shipInstanceIdsToTransfer`) | Dialog popped. |
| Transfer (no ships) | Zero instances after `_handleConfirm` | — | Dialog stays open. |

## Components

- `CtDialogShell`, `CtTransferList` ([`components/ct-transfer-list.md`](components/ct-transfer-list.md)).
- `homeFleetTransferCargoLine` in `home_fleet_cargo_consequence.dart` (shared math/colour with split; transfer copy + free-for-trade).
- Keys: `naval_transferToHome_dialogTitle`, `naval_transferToHome_sourceTitle`, `naval_homeFleetLabel`, `naval_transferToHome_confirm`, `naval_transferToHome_homeCargoConsequence`, `mapControls_cargoHold_details_free`, `splitFleet_noShips`, `splitFleet_totalShips`, `common_cancel`.

## Widgetbook

Folder **Transfer to Home Fleet Dialog** (`widgetbook_host/lib/catalogs/catalog_dialogs.dart`):

1. **Default — source + home, mixed ship types:** 2 carracks + 1 fluyte vs Home Fleet 1 carrack; cargo flags reliable used `2`.
2. **Cargo line wraps (320 dp):** same fixture at 320 dp so the transfer cargo line wraps.

## Acceptance Criteria (Given–When–Then)

- Given source 2 carracks + 1 fluyte and Home Fleet 1 carrack, when the dialog opens, then the UI layer shows one `CtTransferList` with source `Total: 3 ships` and home `Total: 1 ships`.
- Given no source counts have changed, when the user inspects Transfer, then `canConfirm` is `false` and `naval_transferToHome_confirm` is disabled.
- Given the user moves at least one carrack home, when the user taps Transfer, then the UI layer emits one `NavalTransferShipsRequestedEvent` (`humanPlayerId`, `sourceFleetId`, `targetFleetId`, `shipInstanceIdsToTransfer` from `shipInstancesForTransferCounts`) and pops the dialog.
- Given every moved row is restored to the initial source count, when the user taps Transfer, then no transfer event is emitted and the dialog stays mounted.
- Given the dialog is mounted, when the tree is inspected, then one `CtDialogShell` wraps the surface, the title uses `--accent`, and no `AlertDialog` appears (#2867 R1).
- Given the user taps Cancel, when the gesture completes, then no transfer event is emitted and the dialog is removed.
- Given the source fleet is at sea in a known sea zone, when the dialog builds, then the source subtitle is sea-zone name + ` - ` + region label.
- Given constructor-passed cargo flags with used reliable, when the player stages merchants onto Home Fleet, then the UI layer shows a live **transfer** (not split) line: remaining holds from right staged counts, this turn’s overseas load, and `Free for trade bids: {free}` with `free = max(0, remaining − used)`.
- Given used is reliable, when remaining **>** / **==** / **<** used, then the line uses `--muted` / `--accent` / `--danger`.
- Given used is unreliable or `cargoNotDefined`, when the line renders, then used and free-for-trade are `—` and colour is `--muted`.
- Given the player stages only warships (`cargoHold == 0`), when the line updates, then remaining holds equal the pre-transfer Home Fleet total.
- Given a legal transfer (at least one hull moved), when remaining holds fall short of overseas load, then Transfer stays enabled.
- Given `UNIT30001` Transfer or Combine opens `DLG40001`, when the dialog mounts, then it receives the panel cargo used / reliability / not-defined flags.

Tests: `app/test/transfer_to_home_fleet_dialog_spec_test.dart`, `transfer_to_home_fleet_dialog_cargo_test.dart`, `transfer_to_home_fleet_dialog_cargo_goldens_test.dart`.
