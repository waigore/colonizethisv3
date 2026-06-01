# Transfer to Home Fleet Dialog

**Screen ID:** `DLG40001` — stable; do not reassign.
**SPEC/ui** — Modal that lets the human player move ship instances from a regular fleet **at the capital port** into the same-region **Home Fleet** from the [naval-units-panel.md](naval-units-panel.md). Implementation: `app/lib/features/game/widgets/transfer_to_home_fleet_dialog.dart`.
**Widgetbook:** `Transfer to Home Fleet Dialog` → `app/lib/widgetbook/catalog.dart`. Game model: [ships-and-naval.md](../game/ships-and-naval.md). App wiring: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

**Mockup:** [mockups/DLG40001-transfer-to-home-fleet.html](mockups/DLG40001-transfer-to-home-fleet.html)
---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `TransferToHomeFleetDialog` | `StatelessWidget` | `sourceFleet` (`Fleet`), `homeFleet` (`Fleet`), `game` (`Game`), `humanPlayerId` (`String`), `bus` (`AppEventBus`) | Local `showDialog` modal opened from `NavalUnitsPanel` regular-fleet **Transfer to Home Fleet** action. Emits a single `NavalTransferShipsRequestedEvent` on confirm. |

Implementation: `app/lib/features/game/widgets/transfer_to_home_fleet_dialog.dart`. Wrapped in `CtDialogShell` (`maxWidth: 560`, `maxHeight: 520`, dark editorial-monocle chrome per #2867 R1 — 2 px `--accent-dim` border + `surface-lite → surface → bg-deep` panel gradient) hosting a `CtTransferList`. Ship instance selection is delegated to `shipInstancesForTransferCounts` (see [naval-units-fleet-management.md](naval-units-fleet-management.md)).

---

## Layout / wireframe

```text
+--------------------------------------------------------+
| CtDialogShell (2 px --accent-dim border)               |
| Transfer Ships to Home Fleet                           |  title row (--accent, letter-spacing 0.05em)
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
|              [ Cancel ]   [ Transfer ]                 |  CtNinePatchButton row
+--------------------------------------------------------+
```

- Title: `naval_transferToHome_dialogTitle` rendered with dark-theme `titleMedium` in `--accent` and `letter-spacing: 0.05em` per #2867 R2.
- Body: `Padding(16)` → `Column(min)` with the dialog title and a single `CtTransferList`.
- `leftTitle` is `naval_transferToHome_sourceTitle(sourceFleet.id)`; `rightTitle` is `naval_homeFleetLabel`. Subtitles are the per-fleet **location label** (sea-zone + region for fleets at sea, otherwise province + region; falls back to region label when neither resolves).
- `initialLeftCounts` / `initialRightCounts` are derived from each fleet's `shipTypeIds` (one entry per ship instance, aggregated by `typeId`).
- Empty per-side label: `splitFleet_noShips`. Total label: `splitFleet_totalShips(total)`.
- Cancel action label: `common_cancel` (from `CtTransferList` default). Primary action label: `naval_transferToHome_confirm` ("Transfer", #2867 R12). Confirm `CtNinePatchButton` is disabled (`CtNinePatchButton.disabledOpacity = 0.4`) until at least one ship row has moved from source to home.
- Narrow-viewport layout: When the `CtTransferList` constraint maxWidth is below `kCtTransferListSideBySideMinWidth` (`360` dp) — which is always the case at `kMinViewportWidth` (`320` dp) because `CtDialogShell` inset (`16` dp each side) + outer padding (`16` dp each side) + body padding (`16` dp each side) leaves a ~`224` dp body column — the two side panels stack vertically (`source` above `home`) and the trailing Cancel / Transfer action row flows through a `Wrap(alignment: end)` so the Cinzel engraved labels never overflow horizontally per [mobile-adaptation.md](mobile-adaptation.md) § 7.

---

## Trigger conditions

- Opened from `NavalUnitsPanel` regular-fleet row **Transfer to Home Fleet** action when a same-region Home Fleet exists; the row is not shown for the Home Fleet itself. See [naval-units-panel.md](naval-units-panel.md) § Move fleet for the cross-link.
- Source and Home Fleet must belong to `humanPlayerId` and share the same `regionId` (the panel pre-resolves the pair).
- The dialog does not mutate game state; it emits `NavalTransferShipsRequestedEvent` and the handler scope applies the merge via `applyNavalTransferShips`.

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

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| `NavalUnitsPanel` Transfer to Home Fleet | Regular fleet at capital port; eligible ship instances | `showDialog` mounts `TransferToHomeFleetDialog`. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Cancel | Always | `Navigator.pop` | No bus event. |
| Confirm | At least one ship moved (`movedByType` non-empty) | `NavalTransferShipsRequestedEvent` with `shipInstanceIdsToTransfer` | Dialog popped. |
| Confirm (no ships) | Zero instances after `_handleConfirm` | — | Dialog stays open. |

---

## Components

- `CtDialogShell`, `CtTransferList` (see [shared widgets](../program/app-ui-wiring.md) and `app/lib/widgets/ct_transfer_list.dart`).
- `CtTransferList` ([`components/ct-transfer-list.md`](components/ct-transfer-list.md)) — canonical dual-list transfer scaffold reused by Split Fleet, Split Army, and Transfer to Home Fleet; pins the `kCtTransferListSideBySideMinWidth = 360 dp` narrow-stack threshold so this dialog inherits the 320 dp viewport contract without redeclaring it (Refs #2914 S9).
- Helper: `shipInstancesForTransferCounts` (from `colonizethis_models`).
- Localized keys via `appL10n(context)`: `naval_transferToHome_dialogTitle`, `naval_transferToHome_sourceTitle`, `naval_homeFleetLabel`, `naval_transferToHome_confirm`, `splitFleet_noShips`, `splitFleet_totalShips`, `common_cancel`.

---

## Acceptance Criteria (Given–When–Then)

- Given a regular fleet with 2 carracks and a same-region Home Fleet with 1 carrack, when `TransferToHomeFleetDialog` opens, then the UI layer renders exactly one `CtTransferList` whose source side total reads `Total: 2 ships` and whose target side total reads `Total: 1 ships`.

- Given the dialog has just opened and no source row counters have been changed, when the user looks at the Confirm button, then `CtTransferList.canConfirm` returns `false` and the Confirm action is disabled.

- Given the user moves at least one carrack from the source side to the home side via the source row `-` button, when the user taps Transfer, then the UI layer emits exactly one `NavalTransferShipsRequestedEvent` on the supplied bus with `humanPlayerId` equal to `widget.humanPlayerId`, `sourceFleetId` equal to `sourceFleet.id`, `targetFleetId` equal to `homeFleet.id`, and `shipInstanceIdsToTransfer` equal to the deterministic instance ids returned by `shipInstancesForTransferCounts(sourceFleet.ships, movedByType)`, and the dialog is removed from the widget tree.

- Given the user reverts every moved row back to its initial source count, when the user taps Transfer, then no `NavalTransferShipsRequestedEvent` is emitted and the dialog remains mounted.

- Given `TransferToHomeFleetDialog` is mounted, when the widget tree is inspected, then the surface is wrapped in exactly one `CtDialogShell`, the title text uses `EditorialMonoclePalette.accent`, and no `AlertDialog` / `TextButton` Material chrome appears among dialog descendants (#2867 R1 regression guard).

- Given the dialog has just opened and no source row counters have changed, when the user looks at the Transfer primary action, then the `CtNinePatchButton` for `naval_transferToHome_confirm` has `enabled == false` (#2867 R12).

- Given the user taps Cancel, when the gesture completes, then no `NavalTransferShipsRequestedEvent` is emitted and the dialog is removed from the widget tree.

- Given the source fleet is at sea in a known sea zone, when the dialog builds, then the source-side subtitle is the localized sea-zone display name joined to the region display label by ` - ` (for example `Adjacent Sea - Old World`).

---

## Widgetbook

Catalog folder: **Transfer to Home Fleet Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use case:

1. **Default — source + home, mixed ship types:** Minimal `Game` fixture with a regular `Fleet` containing 2 carracks + 1 fluyte and a same-region `Home Fleet` containing 1 carrack. Demo opener renders an `ElevatedButton` that calls `showDialog`.

Automated widget tests: `app/test/transfer_to_home_fleet_dialog_spec_test.dart`.
