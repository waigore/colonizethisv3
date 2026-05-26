# Move Army Dialog

**Screen ID:** `DLG20001` — stable; do not reassign.
**SPEC/ui** — Modal that lets the human player move a non-Home army to a legal destination province from the [military-units-panel.md](military-units-panel.md). Implementation: `app/lib/features/game/widgets/move_army_dialog.dart`.
**Widgetbook:** `Move Army Dialog` → `app/lib/widgetbook/catalog.dart`. Game model: [military-armies.md](../game/military-armies.md), [world-model.md](../game/world-model.md). Orders: [orders.md](../program/orders.md). Order suggestions: [order-suggestions.md](../program/order-suggestions.md). App wiring: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

**Mockup:** [mockups/DLG20001-move-army-dialog.html](mockups/DLG20001-move-army-dialog.html)
---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `MoveArmyDialog` | `StatefulWidget` | `army` (`Army`), `game` (`Game`), `humanPlayerId` (`String`), `bus` (`AppEventBus`), `topology` (`MapTopology`), `draftOrders` (`Orders`), `playerView` (`PlayerView?`, optional) | Local `showDialog` modal opened from `MilitaryUnitsPanel` army row Move action. Emits move + optional declare-war on confirm. |

Implementation: `app/lib/features/game/widgets/move_army_dialog.dart`. Wrapped Material `AlertDialog`; not a `CtDialogShell`.

---

## Layout / wireframe

```text
+--------------------------------------------------+
| Move army <armyId>                               |  title row
+--------------------------------------------------+
|  SizedBox(width: 320)                            |
|                                                  |
|  ┌────────────────────────────────────────────┐  |
|  │ Destination province                  v   │  |  DropdownButtonFormField
|  └────────────────────────────────────────────┘  |
|     [ Your provinces           ]   (header)      |
|       <player province 1>                        |
|       <player province 2>                        |
|     [ <Faction display name>   ]   (header)      |
|       <invasion target province>                 |
|                                                  |
+--------------------------------------------------+
|              [ Cancel ]   [ Confirm ]            |  Material TextButtons
+--------------------------------------------------+
```

- Content: `SizedBox(width: 320)` → either `moveArmy_noValidDestinations` text (empty state) or `DropdownButtonFormField<String>` with `labelText: moveArmy_destinationProvince` and `isExpanded: true`.
- Dropdown items are produced from `armyMovePickerDestinations(...)` and grouped by faction. Disabled header rows use bold text and a synthetic value `__header__<key>`; selectable rows show `entry.provinceLabel` keyed by `entry.fullProvinceId`. Header label resolution: `moveArmyFactionGroupHeaderLabel` — `moveArmy_groupYourProvinces` for player-owned, `moveArmy_groupUnowned` for the literal `__unowned__` owner, otherwise the great-power / minor-nation / tribe display name (fallback: raw owner id).
- Actions: Material `TextButton`s — `common_cancel` and `common_confirm` (confirm disabled when `_selected == null`).
- Initial selection: first destination in `armyMovePickerDestinations` order (player-owned group is emitted first; see [military-units-panel.md](military-units-panel.md) § Move destination UX).

---

## Trigger conditions

- Opened from `MilitaryUnitsPanel` non-Home army row **Move** action; **Home Army** never shows Move and cannot open this dialog.
- The panel passes the current `currentOrders` as `draftOrders` and optionally a cached `playerView` so the dialog reuses an `IncrementalCandidateValidator` per [order-suggestions.md](../program/order-suggestions.md) instead of rebuilding per probe.
- Destination probing calls `armyMovePickerDestinations` exactly as `MilitaryUnitsPanel` does, so the dialog never offers a destination that the order engine would reject for the current `(game, topology, playerView, draftOrders)`.

---

## States and variants

| State | Condition | UI |
|-------|-----------|-----|
| Empty | `armyMovePickerDestinations` returns `[]` | Dropdown replaced with `moveArmy_noValidDestinations`; Confirm disabled. |
| Owned-only | All destinations have `isPlayerOwned == true` | Single `Your provinces` group. Confirm enabled when a row is selected. |
| Mixed groups | Destinations include both player-owned and other-owned entries | Dropdown shows `Your provinces` first, then per-faction groups in source order from `armyMovePickerDestinations`. |
| Invade-confirm | Selected entry has `requiresDeclareWarOnConfirm == true` | Tapping `Confirm` opens a second `AlertDialog` (`moveArmy_invadeProvinceTitle` / `moveArmy_invadeProvinceBody(<ownerLabel>)`) with `common_cancel` and `moveArmy_declareWarAndMove`. |
| Draft / view refresh | `draftOrders`, `game`, `army`, or `playerView` changed (`didUpdateWidget`) | Validator and cached destinations rebuild; `_selected` is cleared if the prior selection is no longer offered (falls back to first entry or `null`). |

The dialog **does not** mutate game state. All state changes flow through the bus event and turn-resolution pipeline.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| `MilitaryUnitsPanel` Move action | Non-Home army row; at least one valid destination from `armyMovePickerDestinations` | `showDialog` mounts `MoveArmyDialog` with `draftOrders` and optional `playerView`. |
| — | Home Army row | Move action hidden; dialog never opens. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Cancel | Always | `Navigator.pop` | No bus event. |
| Confirm — owned destination | `_selected != null` and `requiresDeclareWarOnConfirm == false` | `ArmyMoveRequestedEvent` (`declareWarTargetFactionId: null`) | Dialog popped. |
| Confirm — invasion accepted | Secondary dialog Confirm | `ArmyMoveRequestedEvent` with `declareWarTargetFactionId = entry.ownerFactionId` | Inner then outer pop; `context.mounted` guard before emit. |
| Confirm — invasion declined | Secondary dialog Cancel | — | Outer dialog stays open; no event. |

---

## Components

- `AlertDialog`, `DropdownButtonFormField`, `DropdownMenuItem`, `TextButton` (Material).
- Localized keys (`appL10n(context)`): `moveArmy_title`, `moveArmy_destinationProvince`, `moveArmy_noValidDestinations`, `moveArmy_groupYourProvinces`, `moveArmy_groupUnowned`, `moveArmy_invadeProvinceTitle`, `moveArmy_invadeProvinceBody`, `moveArmy_declareWarAndMove`, `common_cancel`, `common_confirm`.

---

## Acceptance Criteria (Given–When–Then)

- Given a non-Home army with at least one player-owned destination, when `MoveArmyDialog` is opened, then the UI layer renders exactly one `MoveArmyDialog` widget with a `DropdownButtonFormField<String>` whose initial value equals the first entry returned by `armyMovePickerDestinations`.

- Given the destination list includes both player-owned and other-owned entries, when the dropdown items are expanded, then the UI layer shows a disabled header row labelled `Your provinces` before any player-owned destinations.

- Given the selected destination has `requiresDeclareWarOnConfirm == false`, when the user taps Confirm, then the UI layer emits exactly one `ArmyMoveRequestedEvent` on the supplied bus with `moveOrder.armyId` equal to `widget.army.id`, `moveOrder.destinationProvinceId` equal to the selected `fullProvinceId`, and `declareWarTargetFactionId == null`, and the dialog is removed from the widget tree.

- Given the selected destination has `requiresDeclareWarOnConfirm == true` and the user taps Confirm and then `moveArmy_declareWarAndMove` in the secondary dialog, when the system processes the gesture, then the emitted `ArmyMoveRequestedEvent.declareWarTargetFactionId` equals the destination's `ownerFactionId`.

- Given the selected destination has `requiresDeclareWarOnConfirm == true` and the user taps `common_cancel` in the secondary dialog, when the system processes the gesture, then no `ArmyMoveRequestedEvent` is emitted and `MoveArmyDialog` remains mounted.

- Given `armyMovePickerDestinations` returns an empty list for the current `(game, army, topology, draftOrders, playerView)`, when `MoveArmyDialog` builds, then no `DropdownButtonFormField<String>` is rendered, the `moveArmy_noValidDestinations` text is shown, and the Confirm `TextButton.onPressed` is `null`.

- Given the user taps Cancel, when the gesture completes, then no `ArmyMoveRequestedEvent` is emitted on the bus and the dialog is removed from the widget tree.

---

## Widgetbook

Catalog folder: **Move Army Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use case:

1. **Default — grouped destinations:** Minimal `Game`, `MapTopology`, and `Army` fixture wired so the dropdown shows both `Your provinces` and an other-owned group with at least one invasion destination, plus an empty `Orders()` draft and a fresh `AppEventBus`.

Automated widget tests: `app/test/move_dialogs_specs_test.dart`.
