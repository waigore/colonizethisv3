# In-port Fleet Marker Actions Dialog

**Screen ID:** `DLG31004` — stable; do not reassign.
**SPEC/ui** — Chooses Sail/Move or Transfer to Home Fleet after a capital in-port sea-going fleet marker tap. Implementation: `app/lib/features/game/widgets/unit_orders/in_port_fleet_marker_actions_dialog.dart`.
**Widgetbook:** `In-port Fleet Marker Actions Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs_naval_mission.dart`. Marker flow: [map-widget.md](map-widget.md). Transfer: [transfer-to-home-fleet-dialog.md](transfer-to-home-fleet-dialog.md). Move: [move-fleet-dialog.md](move-fleet-dialog.md). Join-home location rules: [naval-units-fleet-management.md](naval-units-fleet-management.md). Overlay Transfer remains on `MAP20001` ([province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md)). This is not a mission menu (do not add Transfer to `DLG31001`).

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `InPortFleetMarkerActionsDialog` | `StatelessWidget` | none | Returns `InPortFleetMarkerAction.sailMove`, `.transferHome`, or `null` on cancel. |

---

## Layout / wireframe

```text
+----------------------------------------------+
| CtDialogShell                                |
| | Choose an action                           |
| | [ Sail / Move ]                            |
| | [ Transfer to Home Fleet ]                 |
| |                           [ Cancel ]       |
+----------------------------------------------+
```

Labels: `inPortFleetMarker_chooseActionTitle`, `naval_mission_sail`, `provinceOverlay_transferToHomeFleetAction`, `common_cancel`. Ct-* chrome only.

---

## Trigger conditions

| Source | Condition | Result |
|--------|-----------|--------|
| `showNavalFleetMarkerFlow` in-port branch | Selected sea-going fleet is an eligible Home-Fleet transfer source (in port at the human capital; Home Fleet exists) | This dialog, then `DLG30001` or `DLG40001`. |
| Same branch, not eligible | In-port but not capital-eligible (or no Home Fleet) | Dialog skipped; `DLG30001` only. |
| At-sea marker | — | Never shown (`DLG31001` path). |

---

## Behavior

| Control | When enabled | Result |
|---------|--------------|--------|
| Sail / Move | always | Pop `sailMove` → existing `MoveFleetDialog`. |
| Transfer to Home Fleet | always (dialog only mounts when eligible) | Pop `transferHome` → existing `DLG40001` for that source. |
| Cancel | always | Pop `null`; no follow-on dialog. |

Confirm of Transfer still emits `NavalTransferShipsRequestedEvent` from `DLG40001`. Does not change dock-merge-after-Next-turn.

---

## Widgetbook

Folder `In-port Fleet Marker Actions Dialog`:

| Use case | Proves |
|----------|--------|
| Default | Title plus Sail/Move and Transfer rows. |
| Narrow | Same at 320 dp without overflow. |

---

## Acceptance criteria

- Given a sea-going fleet in port at the human capital with a Home Fleet, when `showNavalFleetMarkerFlow` selects that fleet, then the UI layer mounts `DLG31004` before `DLG30001` or `DLG40001`.
- Given the player activates Sail / Move on `DLG31004`, when the chooser closes, then the UI layer opens `DLG30001` for that fleet and does not open `DLG40001`.
- Given the player activates Transfer to Home Fleet on `DLG31004`, when the chooser closes, then the UI layer opens `DLG40001` for that source and does not open `DLG30001`.
- Given a sea-going fleet in port at a non-capital owned port, when the marker flow selects that fleet, then the UI layer does not mount `DLG31004` and opens `DLG30001`.
- Given Widgetbook folder **In-port Fleet Marker Actions Dialog**, when the catalog is inspected, then Default and Narrow use cases exist.

Tests: `app/test/naval_fleet_marker_flow_test.dart`, `app/test/naval_fleet_marker_sail_move_test.dart`, `app/test/widgetbook_unit_picker_composition_test.dart`.
