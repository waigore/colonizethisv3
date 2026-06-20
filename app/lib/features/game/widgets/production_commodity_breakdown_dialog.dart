// Read-only commodity phase breakdown for Production panel. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/production_allocation_provider.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_resource_cell.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/resource_icon.dart';

/// Minimum viewport width at which the breakdown dialog drops the
/// trailing horizontal `Scrollbar` + `SingleChildScrollView` and lets the
/// 7-column `DataTable` lay out without horizontal scroll.
///
/// SPEC/ui/production-commodity-breakdown-dialog.md § Layout (viewport-
/// adaptive dialog width). Refs #2862 S8c / C6.
const double kProductionBreakdownDialogWideViewportThreshold = 900;

/// `CtDialogShell.maxWidth` used when the surrounding viewport is at least
/// [kProductionBreakdownDialogWideViewportThreshold]. Chosen so the 7
/// column `DataTable` (`Commodity` + 5 phase columns + `Total`) lays out
/// without horizontal scroll at desktop / wide viewports while still
/// leaving comfortable insets on either side of the dialog frame.
///
/// SPEC/ui/production-commodity-breakdown-dialog.md § Layout (viewport-
/// adaptive dialog width). Refs #2862 S8c / C6.
const double kProductionBreakdownDialogWideMaxWidth = 900;

/// `CtDialogShell.maxWidth` used when the surrounding viewport is
/// strictly narrower than [kProductionBreakdownDialogWideViewportThreshold].
/// Keeps the historical narrow cap so the horizontal `Scrollbar` +
/// `SingleChildScrollView` fallback path remains the same on small
/// viewports.
///
/// SPEC/ui/production-commodity-breakdown-dialog.md § Layout (viewport-
/// adaptive dialog width). Refs #2862 S8c / C6.
const double kProductionBreakdownDialogNarrowMaxWidth = 720;

/// Computes the per-column content widths used on the wide-viewport path so the
/// 7-column breakdown `DataTable` fills the full `CtDialogShell` content column
/// instead of sizing to intrinsic content.
///
/// The returned list has `phaseColumnCount + 2` entries in column order
/// (`Commodity`, one per phase, `Total`). The `Commodity` column receives a
/// larger share (twice the per-numeric width) while the phase columns and the
/// trailing `Total` column share the remaining content budget evenly (owner
/// decision **B** on #3509). Width consumed by [horizontalMargin] (both outer
/// edges) and [columnSpacing] (between columns) is subtracted from the
/// distributed budget so the laid-out table width equals [availableWidth] with
/// no trailing gap.
///
/// The per-numeric width is floored so every phase / `Total` column is exactly
/// equal; the `Commodity` column absorbs the rounding remainder, keeping it
/// strictly wider than each numeric column and the summed content width exactly
/// equal to the budget. A non-positive or unbounded [availableWidth] falls back
/// to equal, non-negative widths so the caller never forces a negative
/// `SizedBox` width.
///
/// SPEC/ui/production-commodity-breakdown-dialog.md § Layout (wide-path
/// full-width column distribution). Refs #3509.
@visibleForTesting
List<double> productionBreakdownWideColumnContentWidths({
  required double availableWidth,
  required int phaseColumnCount,
  required double columnSpacing,
  required double horizontalMargin,
}) {
  final int numericColumns = phaseColumnCount + 1; // phases + Total
  final int totalColumns = phaseColumnCount + 2; // + Commodity
  final double chrome =
      horizontalMargin * 2 + columnSpacing * (totalColumns - 1);
  final double contentBudget = availableWidth - chrome;
  const int commodityShares = 2;
  final int totalShares = commodityShares + numericColumns;
  if (!contentBudget.isFinite || contentBudget <= 0 || totalShares <= 0) {
    final double fallback =
        (!contentBudget.isFinite || contentBudget <= 0)
            ? 0
            : contentBudget / totalColumns;
    return List<double>.filled(totalColumns, fallback);
  }
  final double numericWidth = (contentBudget / totalShares).floorToDouble();
  final double commodityWidth = contentBudget - numericWidth * numericColumns;
  return <double>[
    commodityWidth,
    for (var i = 0; i < phaseColumnCount; i++) numericWidth,
    numericWidth,
  ];
}

/// Dialog showing per-commodity preview deltas for each economy preview phase.
class ProductionCommodityBreakdownDialog extends ConsumerStatefulWidget {
  const ProductionCommodityBreakdownDialog({
    super.key,
    required this.game,
    required this.player,
    required this.topology,
    required this.tileMapByRegion,
    required this.currentOrders,
  });

  final Game game;
  final Player player;
  final MapTopology topology;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Orders currentOrders;

  @override
  ConsumerState<ProductionCommodityBreakdownDialog> createState() =>
      _ProductionCommodityBreakdownDialogState();

  static String _phaseColumnLabel(
    AppLocalizations l10n,
    EconomyPreviewStockpilePhase phase,
  ) {
    return switch (phase) {
      EconomyPreviewStockpilePhase.pendingBuildCosts =>
        l10n.production_breakdown_phase_pendingBuildCosts,
      EconomyPreviewStockpilePhase.extraction =>
        l10n.production_breakdown_phase_extraction,
      EconomyPreviewStockpilePhase.richesToTreasury =>
        l10n.production_breakdown_phase_richesToTreasury,
      EconomyPreviewStockpilePhase.consumption =>
        l10n.production_breakdown_phase_consumption,
      EconomyPreviewStockpilePhase.production =>
        l10n.production_breakdown_phase_production,
    };
  }

  static String _formatDelta(int v) {
    if (v > 0) return '+$v';
    return '$v';
  }
}

class _ProductionCommodityBreakdownDialogState
    extends ConsumerState<ProductionCommodityBreakdownDialog> {
  late final ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  TextStyle _headingStyle(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    return base.copyWith(
      color: EditorialMonoclePalette.muted,
      fontWeight: FontWeight.w600,
    );
  }

  TextStyle _sectionHeaderStyle(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    return base.copyWith(
      color: EditorialMonoclePalette.muted,
      fontWeight: FontWeight.w600,
      fontFeatures: const <FontFeature>[FontFeature.enable('smcp')],
    );
  }

  TextStyle _commodityNameStyle(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return base.copyWith(color: EditorialMonoclePalette.fg);
  }

  TextStyle _deltaCellStyle(BuildContext context, int value) {
    final TextStyle base =
        Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    final Color? color = CtResourceCell.deltaColor(value);
    return base.copyWith(
      color: color ?? EditorialMonoclePalette.muted,
      fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  Widget _deltaCell(BuildContext context, int value) {
    return Text(
      ProductionCommodityBreakdownDialog._formatDelta(value),
      maxLines: 1,
      style: _deltaCellStyle(context, value),
    );
  }

  Widget _sectionHeaderCell(BuildContext context, String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EditorialMonoclePalette.accentDim,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: CtSpacing.xs),
        child: Text(
          label.toUpperCase(),
          style: _sectionHeaderStyle(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);
    final defaultAssignmentsByPlayerId = {
      widget.player.id: assignedRecipesFromDesiredOutput(desiredOutputByRecipe),
    };
    final phaseDeltas = previewStockpilePhaseDeltasByCommodityForPlayer(
      game: widget.game,
      topology: widget.topology,
      playerId: widget.player.id,
      inputs: economyPreviewInputs(
        tileMapByRegion: widget.tileMapByRegion,
        currentOrders: widget.currentOrders,
        defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      ),
    );

    final inputCommodityIds = <String>{};
    for (final recipe in ProductionRecipesCatalog.all) {
      inputCommodityIds.addAll(recipe.inputQuantities.keys);
    }

    List<Commodity> commoditiesForCategory(
      CommodityCategory category, {
      Set<String>? restrictToInputs,
    }) {
      return CommodityCatalog.all
          .where(
            (c) =>
                c.category == category &&
                (restrictToInputs == null || restrictToInputs.contains(c.id)),
          )
          .toList();
    }

    final sections = <(String, List<Commodity>)>[
      (l10n.production_food, commoditiesForCategory(CommodityCategory.food)),
      (
        l10n.production_rawMaterials,
        commoditiesForCategory(
          CommodityCategory.rawMaterial,
          restrictToInputs: inputCommodityIds,
        ),
      ),
      (
        l10n.production_manufactured,
        commoditiesForCategory(CommodityCategory.manufactured),
      ),
    ];

    int phaseValue(String commodityId, EconomyPreviewStockpilePhase phase) {
      return phaseDeltas[phase]?[commodityId] ?? 0;
    }

    int rowTotal(String commodityId) {
      var t = 0;
      for (final p in EconomyPreviewStockpilePhase.values) {
        t += phaseValue(commodityId, p);
      }
      return t;
    }

    final phaseColCount = EconomyPreviewStockpilePhase.values.length;
    final dividerColor =
        EditorialMonoclePalette.accentDim.withValues(alpha: 0.5);

    // Tightened column padding shared by both viewport paths. Declared here
    // so the wide-path full-width distribution math can subtract the exact
    // chrome (`horizontalMargin` on both outer edges + `columnSpacing`
    // between columns) that the DataTable reinstates around/between columns.
    // SPEC/ui/production-commodity-breakdown-dialog.md § Layout. Refs #2862
    // S8c / C6 + #3509.
    const double tableColumnSpacing = 24;
    const double tableHorizontalMargin = 12;

    // Builds the 7-column breakdown table. When [columnContentWidths] is
    // non-null (wide path), every header label and cell child is pinned to an
    // explicit per-column width so the table fills the full dialog content
    // column; when null (narrow path) children keep intrinsic sizing inside
    // the horizontal scroll viewport.
    // SPEC/ui/production-commodity-breakdown-dialog.md § Layout. Refs #3509.
    DataTable buildDataTable(List<double>? columnContentWidths) {
      Widget sizedCell(int columnIndex, Widget child) {
        if (columnContentWidths == null) return child;
        return SizedBox(width: columnContentWidths[columnIndex], child: child);
      }

      // Header wrappers carry stable keys so layout tests can read each
      // column's distributed width directly. Refs #3509.
      Widget sizedHeader(int columnIndex, Widget child) {
        if (columnContentWidths == null) return child;
        return SizedBox(
          key: ValueKey<String>('prodBreakdownHeaderCol_$columnIndex'),
          width: columnContentWidths[columnIndex],
          child: child,
        );
      }

      var commodityRowIndex = 0;

      List<DataRow> rowsFor(List<Commodity> list) {
        return list.map((c) {
          final total = rowTotal(c.id);
          final name = c.displayName ?? c.id;
          final rowShade = commodityRowIndex.isEven
              ? Colors.transparent
              : EditorialMonoclePalette.surface.withValues(alpha: 0.4);
          commodityRowIndex += 1;
          return DataRow(
            color: WidgetStatePropertyAll<Color?>(rowShade),
            cells: [
              DataCell(
                sizedCell(
                  0,
                  Row(
                    children: [
                      ResourceIcon(commodityId: c.id, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _commodityNameStyle(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...EconomyPreviewStockpilePhase.values.indexed.map(
                (entry) => DataCell(
                  sizedCell(
                    1 + entry.$1,
                    _deltaCell(context, phaseValue(c.id, entry.$2)),
                  ),
                ),
              ),
              DataCell(
                sizedCell(phaseColCount + 1, _deltaCell(context, total)),
              ),
            ],
          );
        }).toList();
      }

      return DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 48,
        dividerThickness: 1,
        // Tighten DataTable's default column padding so the 7-column
        // breakdown fits inside the wide-viewport `CtDialogShell` body
        // without requiring a horizontal scroll affordance at viewport
        // width >= 900 dp. The narrow path still wraps the table in a
        // `Scrollbar` + horizontal `SingleChildScrollView` so the same
        // table remains reachable below the threshold (see the conditional
        // below). SPEC/ui/production-commodity-breakdown-dialog.md § Layout.
        // Refs #2862 S8c / C6 + #3509.
        columnSpacing: tableColumnSpacing,
        horizontalMargin: tableHorizontalMargin,
        headingRowColor: WidgetStatePropertyAll<Color?>(
          EditorialMonoclePalette.surfaceLite,
        ),
        border: TableBorder(
          horizontalInside: BorderSide(color: dividerColor),
        ),
        headingTextStyle: _headingStyle(context),
        columns: [
          DataColumn(
            label: sizedHeader(0, Text(l10n.production_breakdown_commodity)),
          ),
          ...EconomyPreviewStockpilePhase.values.indexed.map(
            (entry) => DataColumn(
              label: sizedHeader(
                1 + entry.$1,
                Text(
                  ProductionCommodityBreakdownDialog._phaseColumnLabel(
                    l10n,
                    entry.$2,
                  ),
                  softWrap: true,
                ),
              ),
            ),
          ),
          DataColumn(
            label: sizedHeader(
              phaseColCount + 1,
              Text(l10n.production_breakdown_total),
            ),
          ),
        ],
        rows: [
          for (final (label, commodities) in sections)
            if (commodities.isNotEmpty) ...[
              DataRow(
                cells: [
                  DataCell(sizedCell(0, _sectionHeaderCell(context, label))),
                  ...List<DataCell>.generate(
                    phaseColCount + 1,
                    (i) => DataCell(
                      sizedCell(1 + i, const SizedBox.shrink()),
                    ),
                  ),
                ],
              ),
              ...rowsFor(commodities),
            ],
        ],
      );
    }

    final viewportWidth = MediaQuery.of(context).size.width;
    final isWideViewport =
        viewportWidth >= kProductionBreakdownDialogWideViewportThreshold;
    final resolvedMaxWidth = isWideViewport
        ? kProductionBreakdownDialogWideMaxWidth
        : kProductionBreakdownDialogNarrowMaxWidth;

    final Widget tableBody;
    if (isWideViewport) {
      // Wide path: distribute the full dialog content-column width across the
      // 7 columns (Commodity weighted larger; phase columns + Total share the
      // remainder evenly) so the table fills the dialog with no trailing gap
      // (owner decision B on #3509). No Scrollbar / horizontal scroll
      // affordance is mounted — the table is sized to fit the content column
      // exactly. SPEC/ui/production-commodity-breakdown-dialog.md § Layout.
      // Refs #3509.
      tableBody = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final widths = productionBreakdownWideColumnContentWidths(
            availableWidth: constraints.maxWidth,
            phaseColumnCount: phaseColCount,
            columnSpacing: tableColumnSpacing,
            horizontalMargin: tableHorizontalMargin,
          );
          return buildDataTable(widths);
        },
      );
    } else {
      // Narrow path unchanged: the intrinsic-width table lives inside a
      // visible horizontal `Scrollbar` + `SingleChildScrollView` so every
      // column stays reachable on small viewports.
      // SPEC/ui/production-commodity-breakdown-dialog.md § Layout. Refs #2862
      // S8c / C6.
      final Widget scrollableTable = SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: buildDataTable(null),
      );
      tableBody = Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        child: scrollableTable,
      );
    }

    return CtDialogShell(
      maxWidth: resolvedMaxWidth,
      maxHeight: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.production_breakdown_title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: EditorialMonoclePalette.accent,
            ),
          ),
          const SizedBox(height: 8),
          tableBody,
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_close),
            ),
          ),
        ],
      ),
    );
  }
}
