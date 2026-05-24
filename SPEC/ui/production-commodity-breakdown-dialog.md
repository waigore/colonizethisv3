# Production Commodity Breakdown Dialog

**SPEC/ui** — Read-only modal that shows the human player's per-commodity preview deltas across each `EconomyPreviewStockpilePhase`, opened from [production-panel.md](production-panel.md). Economy preview model: [economy-preview.md](../game/economy-preview.md). App wiring and events: [app-ui-wiring.md](../program/app-ui-wiring.md).

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `ProductionCommodityBreakdownDialog` | `ConsumerStatefulWidget` | `game` (`Game`), `player` (`Player`), `topology` (`MapTopology`), `tileMapByRegion` (`Map<String, TileMapResult>?`), `currentOrders` (`Orders`) | Local `showDialog` modal opened from `ProductionScreen` Commodity Breakdown button. Pure read-only preview dialog — emits no `AppEvent`s. |

Implementation: `app/lib/features/game/widgets/production_commodity_breakdown_dialog.dart`. Wrapped in `CtDialogShell` (`maxWidth: 720`, `maxHeight: 560`, `destTileSize: 16`); content is a horizontally-scrollable `DataTable`. Per-commodity values are computed by `previewStockpilePhaseDeltasByCommodityForPlayer` using the player's current `desiredOutputByRecipe` (resolved via `productionDesiredOutputProvider`).

---

## Layout / wireframe

```text
+--------------------------------------------------------+
| Commodity breakdown                                    |  titleMedium
+--------------------------------------------------------+
|  Scrollbar(horizontal) → DataTable:                    |
|                                                        |
|  | Commodity | Pending… | Extraction | … | Total |     |
|  | Food                                              |  |
|  | 🍇 grain        +5    -2     ...     +3          |  |
|  | 🐟 fish         +0    -1     ...     -1          |  |
|  | Raw materials                                     |  |
|  | 🪵 wood        +4    -1     ...     +3          |  |
|  | Manufactured                                      |  |
|  | 🔫 muskets     +0    -3     ...     -3          |  |
|                                                        |
|                                       [ Close ]        |
+--------------------------------------------------------+
```

- Header: `production_breakdown_title` (`titleMedium`).
- Table columns: leading **Commodity** column, one column per value of `EconomyPreviewStockpilePhase` (label resolved by static `_phaseColumnLabel`), and a trailing **Total** column.
- Rows: three section headers in fixed order — **Food**, **Raw materials** (filtered to commodities that appear as inputs in any `ProductionRecipesCatalog.all` recipe), **Manufactured** — each followed by the commodities in `CommodityCatalog.all` for that category. Sections with zero qualifying commodities collapse to nothing (no header row).
- Each commodity row renders `ResourceIcon(commodityId: c.id, size: 16)` + display name (`maxLines: 1, ellipsis`) and one cell per phase. Cell value is `_formatDelta(int)`: positive values prefixed with `+`, zero shown as `0`, negative values keep their leading `-`.
- Layout sizes: `headingRowHeight: 40`, `dataRowMinHeight: 32`, `dataRowMaxHeight: 48`. A single horizontal `ScrollController` is owned by the dialog state and disposed in `dispose`.
- Footer: right-aligned `CtNinePatchButton` with label `common_close`.

---

## Trigger conditions

- Opened from `ProductionScreen` Commodity Breakdown button via local `showDialog` when `canOpenBreakdown` is true. The button is disabled when `currentOrders` cannot be derived (for example, observer / non-mutable contexts).
- Caller passes the current `displayGame`, `displayPlayer`, `panelTopology`, optional `panelTileMaps`, and the current `currentOrders` so the dialog computes preview deltas against the **same** state visible in the panel.
- The dialog **does not** mutate game state and does not emit any `AppEvent`s. All values are derived per-frame via `previewStockpilePhaseDeltasByCommodityForPlayer`.

---

## States and variants

| State | Condition | UI |
|-------|-----------|-----|
| Initial / refresh | Dialog opens (or rebuilds when `productionDesiredOutputProvider` changes) | Table renders all three sections; per-cell deltas reflect the latest preview computation. |
| Section empty | A `CommodityCategory` produces zero qualifying commodities (for example Raw materials when no recipes use any raw input) | The section header row is omitted entirely. |
| Wide table | Total column count (`1 + EconomyPreviewStockpilePhase.values.length + 1`) exceeds the available width | The `Scrollbar` is visible and the `DataTable` scrolls horizontally; vertical content stays within the `CtDialogShell` bounds. |

---

## Navigation

| Action | Behavior |
|--------|----------|
| Close | `Navigator.of(context).pop()`. No bus event emitted. |

There is no Confirm/Cancel pair: this dialog is read-only and dismiss-only.

---

## Components

- `CtDialogShell`, `CtNinePatchButton`, `ResourceIcon` (see `app/lib/widgets/`).
- `DataTable`, `DataColumn`, `DataRow`, `DataCell`, `Scrollbar`, `SingleChildScrollView` (Flutter Material).
- Logic: `previewStockpilePhaseDeltasByCommodityForPlayer`, `assignedRecipesFromDesiredOutput`, `productionDesiredOutputProvider` (Riverpod).
- Localized keys via `appL10n(context)`: `production_breakdown_title`, `production_breakdown_commodity`, `production_breakdown_total`, `production_breakdown_phase_pendingBuildCosts`, `production_breakdown_phase_extraction`, `production_breakdown_phase_richesToTreasury`, `production_breakdown_phase_consumption`, `production_breakdown_phase_production`, `production_food`, `production_rawMaterials`, `production_manufactured`, `common_close`.

---

## Acceptance Criteria (Given–When–Then)

- Given a player with at least one commodity-producing recipe assignment and a valid `game` / `topology`, when `ProductionCommodityBreakdownDialog` builds, then the UI layer renders exactly one `DataTable` whose column count equals `1 + EconomyPreviewStockpilePhase.values.length + 1` (commodity, one per phase, total).

- Given the table rendered any commodity row for commodity `c`, when the row's trailing **Total** cell is read, then it equals `_formatDelta(Σ phaseDeltas[phase]?[c.id] ?? 0)` summed across every value in `EconomyPreviewStockpilePhase.values`.

- Given a `phaseDelta` for commodity `c` equal to `+3`, when its cell renders, then the displayed text equals `+3`; given `0`, then the text equals `0`; given `-2`, then the text equals `-2`.

- Given the food category yields zero qualifying commodities for the current ruleset, when the table builds, then no section header row labelled `production_food` is rendered.

- Given the user taps the trailing `common_close` button, when the gesture completes, then no `AppEvent` is emitted on any bus and `ProductionCommodityBreakdownDialog` is removed from the widget tree.

- Given the dialog opens with `productionDesiredOutputProvider` returning a non-empty assignment map, when `previewStockpilePhaseDeltasByCommodityForPlayer` is called by the dialog, then `defaultAssignmentsByPlayerId[widget.player.id]` equals `assignedRecipesFromDesiredOutput(desiredOutputByRecipe)`.

---

## Widgetbook

Catalog folder: **Production Commodity Breakdown Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use case:

1. **Default — three sections, mixed deltas:** Uses `getDebugInitGameResult()` for a baseline `Game` + topology and the first human player. Demo opener renders an `ElevatedButton` that calls `showDialog` so reviewers can launch the breakdown table; the widget is wrapped in a `ProviderScope` overriding `productionDesiredOutputProvider` to a deterministic non-empty map.

Automated widget tests: `app/test/production_commodity_breakdown_dialog_spec_test.dart`.
