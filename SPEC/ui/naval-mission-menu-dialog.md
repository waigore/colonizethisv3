# Naval Mission Menu Dialog

**Screen ID:** `DLG31001` — stable; do not reassign.
**SPEC/ui** — Modal listing assignable naval missions (Patrol, Blockade, Beachhead, Defend) and **Cancel pending** for one fleet. Implementation: `app/lib/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart`.
**Widgetbook:** `Naval Mission Menu Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs.dart`. Flow host: `naval_mission_flow.dart`. Availability: `navalMissionAvailabilityForFleet` ([orders.md](../program/orders.md)). App wiring: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `NavalMissionMenuDialog` | `StatelessWidget` | `game`, `fleet`, `availability` | Local `showDialog` step in `showNavalMissionFlow` after optional fleet picker. Returns `NavalMissionMenuChoice` via `Navigator.pop`. |

---

## Layout / wireframe

```text
+--------------------------------------------------+
| CtDialogShell                                    |
| +----------------------------------------------+ |
| | Assign mission — Fleet <id>                  | |  title (`naval_mission_menuTitle`)
| +----------------------------------------------+ |
| |  Patrol                                      | |  ListTile per enabled mission
| |  Defend                                      | |
| |  Blockade          (subtitle when disabled)    | |
| |  Beachhead         (subtitle when disabled)    | |
| |  Cancel pending mission                      | |  when draft mission exists
| +----------------------------------------------+ |
| |                              [ Cancel ]      | |  CtNinePatchButton
+--------------------------------------------------+
```

- Empty missions: body shows `naval_mission_noMissionsAvailable`; Cancel still dismisses.
- Disabled missions render with `subtitle` = plain-language `disabledReason`; `onTap` is null.
- Patrol / Defend confirm immediately on row tap (no target picker).

---

## Trigger conditions

| Source | Condition | Result |
|--------|-----------|--------|
| Map fleet marker | `OpenNavalMissionMenuEvent` → `showNavalMissionFlow` | Menu after optional `DLG31003` fleet picker. |
| `UNIT30001` **Mission** action | Sea-going at-sea non-Home fleet row | Same flow with single `fleetIds` entry. |
| Early exit | `!availability.baseGatesPass && !availability.canCancelPending` | Flow returns before dialog mounts. |

---

## Behavior

### User actions → outcomes

| Control | When enabled | Result |
|---------|--------------|--------|
| Mission row | `option.isEnabled` | `Navigator.pop(NavalMissionMenuChoiceMission(mission))`; Blockade/Beachhead continue to `DLG31002`. |
| Cancel pending | `availability.canCancelPending` | `Navigator.pop(NavalMissionMenuChoiceCancelPending())` → `NavalMissionCancelRequestedEvent`. |
| Cancel button | always | `Navigator.pop(null)`; no bus event. |

---

## States and variants

| State | Condition | Render difference |
|-------|-----------|-------------------|
| All missions disabled | Peacetime / no targets | Blockade/Beachhead rows visible but disabled with reason; Patrol/Defend may still enable. |
| Cancel only | Pending mission, no new missions | Only Cancel pending + Cancel button. |
| Empty | No rows and no cancel | `naval_mission_noMissionsAvailable` body text. |

---

## Widgetbook

Folder `Naval Mission Menu Dialog`:

| Use case | Proves |
|----------|--------|
| Default — patrol available | At-sea fleet; Patrol/Defend enabled; Blockade disabled (no war). |

---

## Acceptance criteria

- **Given** an at-sea non-Home fleet with `navalMissionAvailabilityForFleet.baseGatesPass == true`, **when** `NavalMissionMenuDialog` opens, **then** the UI layer lists Patrol and Defend as enabled rows and titles the dialog `naval_mission_menuTitle(fleetLabel)`.
- **Given** no factions at war with the player, **when** the menu renders Blockade, **then** the Blockade `ListTile` has `enabled == false` and a non-null disabled-reason subtitle.
- **Given** a pending `NavalMissionOrder` for the fleet, **when** the menu opens, **then** the UI layer shows **Cancel pending mission** and tapping it pops `NavalMissionMenuChoiceCancelPending`.
- **Given** the user taps **Cancel**, **when** the gesture completes, **then** the dialog is removed and no `NavalMissionRequestedEvent` or `NavalMissionCancelRequestedEvent` is emitted from this dialog step.
