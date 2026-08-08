# Naval Mission Target Dialog

**Screen ID:** `DLG31002` — stable; do not reassign.
**SPEC/ui** — Province picker for Blockade and Beachhead naval missions. Implementation: `app/lib/features/game/widgets/unit_orders/naval_mission_target_dialog.dart`.
**Widgetbook:** `Naval Mission Target Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs.dart`. Shared scaffold: [`components/move-units-dialog-base.md`](components/move-units-dialog-base.md). Flow: `naval_mission_flow.dart`.

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `NavalMissionTargetDialog` | `StatefulWidget` | `game`, `mission`, `fleet`, `targetProvinceIds` | Local `showDialog` after Blockade/Beachhead selection. Returns selected full `targetProvinceId` string or `null`. |

`targetProvinceIds` are pre-filtered by `navalMissionAvailabilityForFleet` (adjacent at-war provinces; beachhead = hostile coastal).

---

## Layout / wireframe

Uses [`MoveUnitsDialogState`](components/move-units-dialog-base.md) scaffold (`CtDialogShell` + radio rows + Cancel/Confirm):

```text
+--------------------------------------------------+
| CtDialogShell                                    |
| | Select target — <mission label>                | |
| | <mission caption>                              | |  Blockade / Beachhead only
| |  ( ) Enemy Province A                          | |
| |  ( ) Enemy Province B                          | |
| |                    [ Cancel ]    [ Confirm ]   | |
+--------------------------------------------------+
```

- Title: `naval_mission_selectTargetTitle(missionLabel)`.
- **Mission caption** (Refs #4295): muted line under the title from `naval_mission_targetCaption_blockade` or `naval_mission_targetCaption_beachhead`; omitted for other missions.
- Empty list: `naval_mission_noTargetsAvailable`; Confirm disabled.
- Row label: province `displayName` fallback to id.

---

## Trigger conditions

| Source | Condition | Result |
|--------|-----------|--------|
| `NavalMissionMenuDialog` | User chose Blockade or Beachhead | Opens with `blockadeTargetProvinceIds` or `beachheadTargetProvinceIds`. |

---

## Behavior

| Control | When enabled | Result |
|---------|--------------|--------|
| Province row | `targetProvinceIds` non-empty | Sets `_selected`; highlights row. |
| Confirm | `_selected != null` | `Navigator.pop(targetProvinceId)` → flow emits `NavalMissionRequestedEvent` with `targetProvinceId`. |
| Cancel | always | `Navigator.pop(null)`; no bus event. |

---

## States and variants

| State | Condition | UI |
|-------|-----------|-----|
| Blockade | `mission == blockade` | Title uses Blockade label; targets = war-enemy adjacent provinces. |
| Beachhead | `mission == beachhead` | Title uses Beachhead label; targets = hostile coastal adjacent provinces. |
| Empty | `targetProvinceIds.isEmpty` | Empty-state text; Confirm disabled. |

---

## Widgetbook

Folder `Naval Mission Target Dialog`:

| Use case | Proves |
|----------|--------|
| Default — two war targets | Blockade mission; two selectable province rows; Confirm gated on selection. |

---

## Acceptance criteria

- **Given** `targetProvinceIds` contains two legal provinces, **when** the dialog opens, **then** the UI layer renders two `MoveDialogDestinationRow` entries and disables Confirm until one is selected.
- **Given** the user selects a province and taps Confirm, **when** the dialog closes, **then** `Navigator` returns that province’s full prefixed id string.
- **Given** `targetProvinceIds` is empty, **when** the dialog opens, **then** the UI layer shows `naval_mission_noTargetsAvailable` and Confirm is disabled.
- **Given** the player opens the dialog for Beachhead with at least one legal target, **when** the dialog renders, **then** the UI layer shows `naval_mission_targetCaption_beachhead` under the title (Refs #4295).
- **Given** the player opens the dialog for Blockade with at least one legal target, **when** the dialog renders, **then** the UI layer shows `naval_mission_targetCaption_blockade` under the title (Refs #4295).
