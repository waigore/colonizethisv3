// Read-only commodity phase breakdown for Production panel. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../providers/production_allocation_provider.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_resource_cell.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/resource_icon.dart';

part 'production_commodity_breakdown_dialog_layout.dart';
part 'production_commodity_breakdown_dialog_table_cells.dart';
part 'production_commodity_breakdown_dialog_table.dart';
part 'production_commodity_breakdown_dialog_table_data.dart';

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
