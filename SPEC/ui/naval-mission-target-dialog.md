# Naval Mission Target Dialog

**Screen ID:** `DLG31002` — stable; do not reassign.
**SPEC/ui** — Province picker for Blockade and Beachhead naval missions with fog-respecting per-target intel (Refs #4340). Implementation: `app/lib/features/game/widgets/unit_orders/naval_mission_target_dialog.dart`.
**Widgetbook:** `Naval Mission Target Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs_naval_mission.dart`. Shared scaffold: [`components/move-units-dialog-base.md`](components/move-units-dialog-base.md). Flow: `naval_mission_flow.dart`.

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `NavalMissionTargetDialog` | `StatefulWidget` | `game`, `mission`, `fleet`, `targetProvinceIds`, `humanPlayerId`, `playerView?`, `initialTargetProvinceId?` | Local `showDialog` after Blockade/Beachhead selection. Returns selected full `targetProvinceId` string or `null`. When `initialTargetProvinceId` is in `targetProvinceIds`, that row starts selected (overlay MAP20001 preselect; Refs #4413). |

`targetProvinceIds` are pre-filtered by `navalMissionAvailabilityForFleet` (adjacent at-war provinces; beachhead = hostile coastal). Missing `playerView` degrades to name + unknown intel (same as `DLG20001` without a view).

---

## Layout / wireframe

Uses [`MoveUnitsDialogState`](components/move-units-dialog-base.md) scaffold (`CtDialogShell` + radio rows + Cancel/Confirm):

```text
+--------------------------------------------------+
| CtDialogShell                                    |
| | Select target — <mission label>                | |
| | <mission caption>                              | |  Blockade / Beachhead only
| |  ( ) Enemy Province A                          | |
| |      <one-line target intel>                   | |
| |  ( ) Enemy Province B (selected)               | |
| |      <one-line target intel>                   | |
| |      <selected-row type lines if Beachhead>    | |
| |                    [ Cancel ]    [ Confirm ]   | |
+--------------------------------------------------+
```

- Title: `naval_mission_selectTargetTitle(missionLabel)`.
- **Mission caption** (Refs #4295): muted line under the title from `naval_mission_targetCaption_blockade` or `naval_mission_targetCaption_beachhead`; omitted for other missions.
- Empty list: `naval_mission_noTargetsAvailable`; Confirm disabled.
- Row title: province `displayName` fallback to id.
- **Beachhead intel** (Refs #4340): reuse `computeMoveArmyInvasionIntelSummary` + `moveArmy_*` labels (`Defenders: N regiments` / `Unopposed capture` + fort/siege labels; or `Defenders unknown`). Selected row may append regiment-type breakdown (roster display names) when intel is full.
- **Blockade intel** (Refs #4340): one harbor line — full intel shows port/no-port plus in-port hostile fleet count or empty harbor; without full intel shows harbor-unknown. Never fabricates counts when fogged.
- Copy must not imply Beachhead **captures** the province this turn (landing site is next-turn).

---

## Trigger conditions

| Source | Condition | Result |
|--------|-----------|--------|
| `NavalMissionMenuDialog` via `showNavalMissionFlow` | User chose Blockade or Beachhead | Opens with `blockadeTargetProvinceIds` or `beachheadTargetProvinceIds`; flow forwards `humanPlayerId` and `PlayerView` (built from map topology when omitted by caller). |
| `MAP20001` overlay Blockade / Beachhead | `showNavalMissionFlow` with `initialMission` + `initialTargetProvinceId` | Skips `DLG31001`; opens with the viewed province preselected when that id is in the target list (Refs #4413). |

---

## Behavior

| Control | When enabled | Result |
|---------|--------------|--------|
| Province row | `targetProvinceIds` non-empty | Sets `_selected`; highlights row; selected Beachhead row may expand type breakdown. |
| Confirm | `_selected != null` | `Navigator.pop(targetProvinceId)` → flow emits `NavalMissionRequestedEvent` with `targetProvinceId`. Intel never gates Confirm. |
| Cancel | always | `Navigator.pop(null)`; no bus event. |

---

## States and variants

| State | Condition | UI |
|-------|-----------|-----|
| Blockade | `mission == blockade` | Title uses Blockade label; harbor intel line per row. |
| Beachhead | `mission == beachhead` | Title uses Beachhead label; military intel lines per row; type breakdown on selected full-intel row. |
| Empty | `targetProvinceIds.isEmpty` | Empty-state text; Confirm disabled. |
| No view | `playerView == null` | Name + unknown intel lines; app stable; no hidden-world leak. |

---

## Widgetbook

Folder `Naval Mission Target Dialog`:

| Use case | Proves |
|----------|--------|
| Default — blockade target | Blockade mission; caption; harbor intel or unknown; Confirm gated on selection. |
| Beachhead — coastal target caption | Beachhead mission; caption; military intel or unknown; Confirm gated on selection. |
| Beachhead — full intel unopposed | Full military intel; unopposed + fort labels on rows. |
| Blockade — full intel empty harbor | Full intel; empty-harbor (or equivalent) copy. |

---

## Acceptance criteria

- **Given** `targetProvinceIds` contains two legal provinces, **when** the dialog opens, **then** the UI layer renders two `MoveDialogDestinationRow` entries and disables Confirm until one is selected.
- **Given** the user selects a province and taps Confirm, **when** the dialog closes, **then** `Navigator` returns that province’s full prefixed id string and `NavalMissionRequestedEvent` (via the flow) still carries that `targetProvinceId` unchanged.
- **Given** `targetProvinceIds` is empty, **when** the dialog opens, **then** the UI layer shows `naval_mission_noTargetsAvailable` and Confirm is disabled.
- **Given** the player opens the dialog for Beachhead with at least one legal target, **when** the dialog renders, **then** the UI layer shows `naval_mission_targetCaption_beachhead` under the title (Refs #4295).
- **Given** the player opens the dialog for Blockade with at least one legal target, **when** the dialog renders, **then** the UI layer shows `naval_mission_targetCaption_blockade` under the title (Refs #4295).
- **Given** full military intel and two Beachhead targets (one unopposed, one with a stone fort and two combat-capable regiments), **when** `DLG31002` opens, **then** both rows show the province name and the matching unopposed / defender + siege labels — not raw unit or fort ids (Refs #4340).
- **Given** fogged tiles for a Blockade target, **when** the row renders, **then** the UI layer shows harbor-unknown copy and no defender or in-port fleet counts (Refs #4340).
- **Given** full intel and a Blockade target with a port and two hostile fleets in port, **when** the row renders, **then** the UI layer shows a short in-port summary (not a ship-type dump) (Refs #4340).
- **Given** full intel and a Blockade target with a port and no fleets in port, **when** the row renders, **then** the UI layer shows empty-harbor (or equivalent) copy (Refs #4340).
- **Given** full military intel and mixed regiment types, **when** the player selects a Beachhead row, **then** type breakdown uses roster display names; **when** intel is not full, **then** no fabricated type breakdown (Refs #4340).
- **Given** `PlayerView` is omitted, **when** the dialog builds, **then** rows stay name + unknown and the app remains stable with no hidden-world leak (Refs #4340).
- **Given** the default target surface, **when** the dialog renders, **then** the UI layer does not show intercept formulas, combat odds, or an end-turn “no mission assigned” shell nag, and the `DLG31003` / `DLG31001` / `DLG31002` flow is not collapsed (Refs #4340).
