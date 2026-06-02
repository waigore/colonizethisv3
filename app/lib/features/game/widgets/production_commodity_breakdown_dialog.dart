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
      tileMapByRegion: widget.tileMapByRegion,
      currentOrders: widget.currentOrders,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
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
            ...EconomyPreviewStockpilePhase.values.map(
              (p) => DataCell(_deltaCell(context, phaseValue(c.id, p))),
            ),
            DataCell(_deltaCell(context, total)),
          ],
        );
      }).toList();
    }

    final phaseColCount = EconomyPreviewStockpilePhase.values.length;
    final dividerColor =
        EditorialMonoclePalette.accentDim.withValues(alpha: 0.5);

    final viewportWidth = MediaQuery.of(context).size.width;
    final isWideViewport =
        viewportWidth >= kProductionBreakdownDialogWideViewportThreshold;
    final resolvedMaxWidth = isWideViewport
        ? kProductionBreakdownDialogWideMaxWidth
        : kProductionBreakdownDialogNarrowMaxWidth;

    final dataTable = DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 48,
      dividerThickness: 1,
      // Tighten DataTable's default column padding (`columnSpacing` 56 dp /
      // `horizontalMargin` 24 dp) so the 7-column breakdown fits inside the
      // wide-viewport `CtDialogShell` body without requiring a horizontal
      // scroll affordance at viewport width >= 900 dp. The looser defaults
      // pushed the table's intrinsic width past the dialog's content column
      // and forced a RenderFlex overflow on the wide path. The narrow path
      // still wraps the table in a `Scrollbar` + horizontal
      // `SingleChildScrollView` so the same table remains reachable below
      // the 900 dp viewport threshold (see the conditional below).
      // SPEC/ui/production-commodity-breakdown-dialog.md § Layout >
      // Viewport-adaptive dialog width. Refs #2862 S8c / C6.
      columnSpacing: 24,
      horizontalMargin: 12,
      headingRowColor: WidgetStatePropertyAll<Color?>(
        EditorialMonoclePalette.surfaceLite,
      ),
      border: TableBorder(
        horizontalInside: BorderSide(color: dividerColor),
      ),
      headingTextStyle: _headingStyle(context),
      columns: [
        DataColumn(label: Text(l10n.production_breakdown_commodity)),
        ...EconomyPreviewStockpilePhase.values.map(
          (p) => DataColumn(
            label: Text(
              ProductionCommodityBreakdownDialog._phaseColumnLabel(
                l10n,
                p,
              ),
              softWrap: true,
            ),
          ),
        ),
        DataColumn(label: Text(l10n.production_breakdown_total)),
      ],
      rows: [
        for (final (label, commodities) in sections)
          if (commodities.isNotEmpty) ...[
            DataRow(
              cells: [
                DataCell(_sectionHeaderCell(context, label)),
                ...List<DataCell>.generate(
                  phaseColCount + 1,
                  (_) => const DataCell(SizedBox.shrink()),
                ),
              ],
            ),
            ...rowsFor(commodities),
          ],
      ],
    );

    // Wide viewports use the larger `maxWidth` so the 7-column DataTable
    // fits comfortably without the user needing to scroll horizontally,
    // and the visible Scrollbar chrome is suppressed so the dialog does
    // not advertise a scroll affordance the user does not need. Narrow
    // viewports keep the historical narrow cap and surface the
    // horizontal Scrollbar chrome so the wide table stays reachable.
    //
    // Both viewports keep the underlying horizontal `SingleChildScrollView`
    // in place: it lets the DataTable measure to its intrinsic width
    // (avoiding a RenderFlex overflow if the table is fractionally wider
    // than the dialog content column) and remains the SPEC's "Wide table"
    // escape hatch at narrow widths.
    //
    // SPEC/ui/production-commodity-breakdown-dialog.md § Layout > Viewport-
    // adaptive dialog width. Refs #2862 S8c / C6.
    final Widget scrollableTable = SingleChildScrollView(
      controller: _horizontalScrollController,
      scrollDirection: Axis.horizontal,
      child: dataTable,
    );
    final Widget tableBody = isWideViewport
        ? scrollableTable
        : Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: scrollableTable,
          );

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
