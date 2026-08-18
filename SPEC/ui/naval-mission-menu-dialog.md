# Naval Mission Menu Dialog

**Screen ID:** `DLG31001` — stable; do not reassign.
**SPEC/ui** — Modal listing assignable naval missions (Patrol, Blockade, Beachhead, Defend) and **Cancel pending** for one fleet. Implementation: `app/lib/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart`.
**Widgetbook:** `Naval Mission Menu Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs.dart`. Flow host: `naval_mission_flow.dart`. Availability: `navalMissionAvailabilityForFleet` ([orders.md](../program/orders.md)). App wiring: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `NavalMissionMenuDialog` | `StatelessWidget` | `game`, `fleet`, `availability` | Local `showDialog` step in `showNavalMissionFlow` after optional fleet picker. Returns `NavalMissionMenuChoice` via `Navigator.pop` (mission, cancel-pending, or Sail/Move). |

---

## Layout / wireframe

```text
+--------------------------------------------------+
| CtDialogShell                                    |
| +----------------------------------------------+ |
| | Assign mission — Fleet <id>                  | |  title (`naval_mission_menuTitle`)
| +----------------------------------------------+ |
| |  Sail / Move                                 | |  always (Refs #4343)
| |    Move this fleet to an adjacent…           | |
| |  Patrol                                      | |  mission row: title + effect line
| |    Stay here and try to intercept…           | |  (`naval_mission_effect_patrol`)
| |  Defend                                      | |
| |    Stay in place without seeking combat…     | |
| |  Blockade                                    | |
| |    Severs the target port's capital link…    | |  (`naval_mission_effect_blockade`; capital-link cut plus intercept)
| |    No adjacent provinces owned by…         | |  disabled reason when gated
| |  Beachhead                                   | |
| |    Stage a landing site…                     | |
| |    No hostile coastal provinces…             | |
| |  Cancel pending mission                      | |  when draft mission exists
| +----------------------------------------------+ |
| |                              [ Cancel ]      | |  CtNinePatchButton
+--------------------------------------------------+
```

- Empty missions: body shows `naval_mission_noMissionsAvailable` only when there are no mission rows, no Sail row, and no cancel; Cancel still dismisses. Sail/Move is always listed first for this dialog (at-sea fleet).
- Every mission row shows its display name and a muted **effect line** from `naval_mission_effect_<mission>` (Refs #4295). Effect lines render for both enabled and disabled missions.
- Sail/Move uses `naval_mission_sail` + `naval_mission_effect_sail` (Refs #4343) and is listed **above** mission rows.
- Disabled missions also render `disabledReason` below the effect line; `onTap` is null.
- Patrol / Defend confirm immediately on row tap (no target picker).

---

## Trigger conditions

| Source | Condition | Result |
|--------|-----------|--------|
| Map fleet marker | `OpenNavalMissionMenuEvent` → `showNavalFleetMarkerFlow` → at-sea branch → `showNavalMissionFlow` | Menu after optional `DLG31003`; Home Fleet / in-port never reach this dialog (Refs #4343). |
| `UNIT30001` **Mission** action | Sea-going at-sea non-Home fleet row | Same flow with single `fleetIds` entry. |
| `MAP20001` overlay Blockade / Beachhead | Overlay Naval shortcut with `initialMission` set | This dialog is **not** mounted; flow continues at `DLG31002` (Refs #4413). Marker/panel paths still open this dialog. |
| Early exit | `!availability.baseGatesPass && !availability.canCancelPending` | `showNavalMissionFlow` returns before dialog mounts (panel / edge cases only). |

---

## Behavior

### User actions → outcomes

| Control | When enabled | Result |
|---------|--------------|--------|
| Mission row | `option.isEnabled` | `Navigator.pop(NavalMissionMenuChoiceMission(mission))`; Blockade/Beachhead continue to `DLG31002`. |
| Sail / Move | always | `Navigator.pop(NavalMissionMenuChoiceSail())` → local `MoveFleetDialog` (`DLG30001`). |
| Cancel pending | `availability.canCancelPending` | `Navigator.pop(NavalMissionMenuChoiceCancelPending())` → `NavalMissionCancelRequestedEvent`. |
| Cancel button | always | `Navigator.pop(null)`; no bus event. |

---

## States and variants

| State | Condition | Render difference |
|-------|-----------|-------------------|
| All missions disabled | Peacetime / no targets | Blockade/Beachhead rows visible but disabled with reason; Patrol/Defend may still enable; Sail/Move still enabled. |
| Cancel + Sail | Pending mission | Cancel pending + Sail/Move + Cancel button (missions may still list). |
| Empty missions text | No mission options and no cancel | `naval_mission_noMissionsAvailable` still yields to Sail/Move row (Refs #4343). |

---

## Widgetbook

Folder `Naval Mission Menu Dialog`:

| Use case | Proves |
|----------|--------|
| Default — patrol available | At-sea fleet; Patrol/Defend enabled; Blockade/Beachhead disabled (no war); Sail/Move row present; Blockade effect names the capital-link / warehouse cut (Refs #4295, #4516). |

---

## Acceptance criteria

- **Given** an at-sea non-Home fleet with `navalMissionAvailabilityForFleet.baseGatesPass == true`, **when** `NavalMissionMenuDialog` opens, **then** the UI layer lists Patrol and Defend as enabled rows and titles the dialog `naval_mission_menuTitle(fleetLabel)`.
- **Given** an at-sea non-Home fleet with `navalMissionAvailabilityForFleet.baseGatesPass == true`, **when** `NavalMissionMenuDialog` opens, **then** each of Patrol, Defend, Blockade, and Beachhead shows its display name and a non-empty `naval_mission_effect_<mission>` line (Refs #4295).
- **Given** `NavalMissionMenuDialog` lists Blockade, **when** the row renders (enabled or disabled), **then** `naval_mission_effect_blockade` states the capital-link / warehouse cut, not intercept-only (Refs #4516).
- **Given** no factions at war with the player, **when** the menu renders Blockade, **then** the Blockade row has `enabled == false`, shows `naval_mission_effect_blockade`, and a non-null disabled-reason line.
- **Given** a pending `NavalMissionOrder` for the fleet, **when** the menu opens, **then** the UI layer shows **Cancel pending mission** and tapping it pops `NavalMissionMenuChoiceCancelPending`.
- **Given** an at-sea non-Home fleet menu is open, **when** the UI layer renders `DLG31001`, **then** a **Sail / Move** row is present and tapping it pops `NavalMissionMenuChoiceSail`.
- **Given** the user taps **Cancel**, **when** the gesture completes, **then** the dialog is removed and no `NavalMissionRequestedEvent` or `NavalMissionCancelRequestedEvent` is emitted from this dialog step.
