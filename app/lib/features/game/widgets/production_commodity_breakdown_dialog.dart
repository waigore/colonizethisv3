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
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_resource_cell.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/resource_icon.dart';

part 'production_commodity_breakdown_dialog_table.dart';

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

  static String phaseColumnLabel(
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

  static String formatDelta(int v) {
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

    final viewportWidth = MediaQuery.of(context).size.width;
    final isWideViewport =
        viewportWidth >= kProductionBreakdownDialogWideViewportThreshold;
    final resolvedMaxWidth = isWideViewport
        ? kProductionBreakdownDialogWideMaxWidth
        : kProductionBreakdownDialogNarrowMaxWidth;

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
          CtGap.m,
          ProductionBreakdownTableBody(
            l10n: l10n,
            sections: sections,
            phaseDeltas: phaseDeltas,
            isWideViewport: isWideViewport,
            horizontalScrollController: _horizontalScrollController,
          ),
          CtGap.ml,
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
