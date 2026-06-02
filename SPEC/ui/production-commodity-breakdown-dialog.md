# Production Commodity Breakdown Dialog

**Screen ID:** `PROD20001` — stable; do not reassign.
**SPEC/ui** — Read-only modal that shows the human player's per-commodity preview deltas across each `EconomyPreviewStockpilePhase`, opened from [production-panel.md](production-panel.md). Economy preview model: [economy-preview.md](../game/economy-preview.md). App wiring and events: [app-ui-wiring.md](../program/app-ui-wiring.md).

**Mockup:** [mockups/PROD20001-production-commodity-breakdown.html](mockups/PROD20001-production-commodity-breakdown.html)
---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `ProductionCommodityBreakdownDialog` | `ConsumerStatefulWidget` | `game` (`Game`), `player` (`Player`), `topology` (`MapTopology`), `tileMapByRegion` (`Map<String, TileMapResult>?`), `currentOrders` (`Orders`) | Local `showDialog` modal opened from `ProductionScreen` Commodity Breakdown button. Pure read-only preview dialog — emits no `AppEvent`s. |

Implementation: `app/lib/features/game/widgets/production_commodity_breakdown_dialog.dart`. Wrapped in `CtDialogShell` whose `maxWidth` depends on the surrounding viewport per § Layout below (wide viewports use a larger cap and drop the visible horizontal `Scrollbar` chrome around the `DataTable` so the full 7-column table is comfortably visible without advertising a scroll affordance the user does not need; narrow viewports keep the default 720 dp cap and surface the visible horizontal `Scrollbar`). Per-commodity values are computed by `previewStockpilePhaseDeltasByCommodityForPlayer` using the player's current `desiredOutputByRecipe` (resolved via `productionDesiredOutputProvider`).

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

- Header: `production_breakdown_title` rendered with `titleMedium` coloured `--accent` (`EditorialMonoclePalette.accent`). No hard-coded light-theme colours.
- Table columns: leading **Commodity** column, one column per value of `EconomyPreviewStockpilePhase` (label resolved by static `_phaseColumnLabel`), and a trailing **Total** column. Column headings use `labelSmall` coloured `--muted`; the heading row paints `--surface-lite` as its background.
- Rows: three section headers in fixed order — **Food**, **Raw materials** (filtered to commodities that appear as inputs in any `ProductionRecipesCatalog.all` recipe), **Manufactured** — each followed by the commodities in `CommodityCatalog.all` for that category. Sections with zero qualifying commodities collapse to nothing (no header row). Section header rows render the label in small-caps `--muted` with a 1 px `--accent-dim` bottom border spanning the row (same visual contract as `CtSectionLabel` without replacing the `DataTable` row structure).
- Each commodity row renders `ResourceIcon(commodityId: c.id, size: 16)` + display name (`maxLines: 1, ellipsis`, colour `--fg`) and one cell per phase. Cell value is `_formatDelta(int)`: positive values prefixed with `+`, zero shown as `0`, negative values keep their leading `-`. Numeric phase and **Total** cells use the dark-theme monospace stack with tabular figures; cell colour follows the same sign convention as `CtResourceCell` R10 (`+N` → `--success`, `-N` → `--danger`, `0` → `--muted`).
- Table chrome: horizontal dividers between rows use 1 px `--accent-dim` at 50% opacity; commodity data rows alternate between transparent and `--surface` at 40% opacity for readability on the `CtDialogShell` gradient background.
- Layout sizes: `headingRowHeight: 40`, `dataRowMinHeight: 32`, `dataRowMaxHeight: 48`. A single horizontal `ScrollController` is owned by the dialog state and disposed in `dispose`.
- Footer: right-aligned `CtNinePatchButton` with label `common_close`.
- Modal barrier: callers MUST pass `barrierColor: EditorialMonoclePalette.dialogScrim` to `showDialog` (canonical `--dialog-scrim` per `SPEC/ui/pixel-art-ui-catalog.md` § Dialog scrim).
- **Viewport-adaptive dialog width (Refs #2862 S8c / C6):** The `CtDialogShell.maxWidth` cap is selected from the surrounding `MediaQuery.size.width` viewport. When the viewport width is **greater than or equal to** `kProductionBreakdownDialogWideViewportThreshold` (`900` logical px), the dialog uses the wider cap `kProductionBreakdownDialogWideMaxWidth` (`900` logical px) and **drops the visible horizontal `Scrollbar` chrome** around the 7-column `DataTable` (`Commodity` + 5 `EconomyPreviewStockpilePhase` columns + `Total`) so the dialog does not advertise a scroll affordance the user does not need at the wide viewport. The underlying horizontal `SingleChildScrollView` MAY remain in the wide-path widget tree as a no-op safety wrapper so the `DataTable` measures to its intrinsic width without forcing a `RenderFlex` overflow when its intrinsic minimum is fractionally wider than the dialog content column. The wide path MUST tighten the `DataTable.columnSpacing` / `horizontalMargin` (e.g. `columnSpacing: 24`, `horizontalMargin: 12`) so the full 7-column table fits comfortably inside the wide `CtDialogShell` content column without horizontal panning. When the viewport width is **strictly less than** the threshold, the dialog falls back to the existing `720` logical px cap and the table is hosted inside a horizontal `Scrollbar` (with `thumbVisibility: true`) + `SingleChildScrollView` so every column remains reachable on narrow viewports. The wide path MUST NOT hide any phase column. The narrow path MUST NOT skip the `Scrollbar` chrome — reviewers rely on the visible scrollbar to discover off-screen columns.

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

- `CtDialogShell`, `CtNinePatchButton`, `ResourceIcon`, `CtResourceCell.deltaColor` / `CtResourceCell.formattedDeltaText` (sign + colour helpers for numeric cells; see `app/lib/widgets/`).
- `DataTable`, `DataColumn`, `DataRow`, `DataCell`, `Scrollbar`, `SingleChildScrollView` (Flutter Material table primitives only — no Material `AlertDialog` chrome).
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

- Given the breakdown dialog is mounted under `AppThemes.editorialMonocle`, when the title text renders, then its `TextStyle.color` resolves to `EditorialMonoclePalette.accent` (no hard-coded hex literals).

- Given a commodity row renders a phase cell whose delta value is strictly positive, when the cell text is inspected, then the displayed string is prefixed with `+` and the `TextStyle.color` resolves to `EditorialMonoclePalette.success`.

- Given a commodity row renders a phase cell whose delta value is strictly negative, when the cell text is inspected, then the `TextStyle.color` resolves to `EditorialMonoclePalette.danger`.

- Given a commodity row renders a phase cell whose delta value is zero, when the cell text is inspected, then the displayed string equals `0` and the `TextStyle.color` resolves to `EditorialMonoclePalette.muted`.

- Given `ProductionScreen` opens the breakdown dialog via `showDialog`, when the route is pushed, then `ModalRoute.barrierColor` equals `EditorialMonoclePalette.dialogScrim`.

- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when `ProductionCommodityBreakdownDialog` (PROD20001) is rendered against the `getDebugInitGameResult()` fixture with the seeded human player id, an empty `Orders()`, and the canonical `EditorialMonoclePalette.dialogScrim` `barrierColor`, then `WidgetTester.takeException()` returns `null`, the localized `production_breakdown_title` text and the trailing `common_close` `CtNinePatchButton` both render within the ~288 dp [CtDialogShell](pixel-art-ui-catalog.md) content column (`maxWidth: 720` clamped by outer `Dialog.insetPadding: 16` × 2), exactly one `DataTable` mounts with column count equal to `1 + EconomyPreviewStockpilePhase.values.length + 1` (commodity + per-phase + total) inside a horizontal-axis `SingleChildScrollView` wrapped by a visible `Scrollbar`, and at least one upper-cased section header label (`FOOD` / `RAW MATERIALS` / `MANUFACTURED`) renders inside the table body (cross-reference AC pinned by `app/test/production_commodity_breakdown_dialog_320dp_min_viewport_test.dart`; satisfies the parent contract in [mobile-adaptation.md](mobile-adaptation.md) § 7).

- Given the viewport width is comfortably above every per-screen breakpoint (1024 × 768 dp) and the same fixture is used as the 320 dp positive AC above, when `ProductionCommodityBreakdownDialog` is rendered, then `WidgetTester.takeException()` returns `null` and both the localized `production_breakdown_title` text and trailing `common_close` `CtNinePatchButton` render (wide regression sentinel — keeps the 320 dp positive pin meaningful by catching regressions in the host overflow contract upstream of `ProductionCommodityBreakdownDialog`; cross-reference pinned by `app/test/production_commodity_breakdown_dialog_320dp_min_viewport_test.dart`).

- **Wide-viewport no-horizontal-scroll (Refs #2862 S8c / C6):** Given the viewport width is **greater than or equal to** `kProductionBreakdownDialogWideViewportThreshold` (`900` logical px) and a valid fixture, when `ProductionCommodityBreakdownDialog` renders, then the dialog mounts the `DataTable` **without** a visible `Scrollbar` ancestor (the wide path drops the `Scrollbar` chrome so it does not advertise a scroll affordance the user does not need), the resolved `CtDialogShell.maxWidth` equals `kProductionBreakdownDialogWideMaxWidth` (`900`), and the table column count remains `1 + EconomyPreviewStockpilePhase.values.length + 1` so no phase column is hidden.

- **Narrow-viewport horizontal-scroll preserved (Refs #2862 S8c / C6):** Given the viewport width is **strictly less than** `kProductionBreakdownDialogWideViewportThreshold` (for example `720` dp), when `ProductionCommodityBreakdownDialog` renders, then the dialog wraps the `DataTable` in a horizontal `Scrollbar` whose `thumbVisibility == true` and a `SingleChildScrollView` whose `scrollDirection == Axis.horizontal`, and the resolved `CtDialogShell.maxWidth` equals the narrow cap (`720`).

---

## Widgetbook

Catalog folder: **Production Commodity Breakdown Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use case:

1. **Default — three sections, mixed deltas:** Uses `getDebugInitGameResult()` for a baseline `Game` + topology and the first human player. Demo opener renders an `ElevatedButton` that calls `showDialog` so reviewers can launch the breakdown table; the widget is wrapped in a `ProviderScope` overriding `productionDesiredOutputProvider` to a deterministic non-empty map.

Automated widget tests: `app/test/production_commodity_breakdown_dialog_spec_test.dart`.
