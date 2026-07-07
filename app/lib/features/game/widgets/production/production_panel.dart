import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_resource_cell.dart';
import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/resource_icon.dart';
import '../chrome/ct_action_text_button.dart';
import '../chrome/ct_danger_text_button.dart';
import 'production_allocation_row.dart';
import 'production_allocation_row_chrome.dart';
import 'production_available_grid.dart';
import 'production_labour_helpers.dart';
import 'production_labour_section.dart';

part 'production_panel_constants.dart';
part 'production_panel_layouts.dart';
part 'production_panel_support_available.dart';
part 'production_panel_support_available_sections.dart';
part 'production_panel_support_allocation.dart';

class ProductionPanel extends StatelessWidget {
  const ProductionPanel({
    super.key,
    required this.game,
    required this.player,
    required this.desiredOutputByRecipe,
    required this.netDeltasByCommodity,
    required this.onDesiredOutputChanged,
    this.onOpenCommodityBreakdown,
    this.currentOrders,
    this.labourCallbacks,
    this.canEditLabour = false,
  });

  /// SPEC/ui/production-panel.md — [UiScreenIds.productionScreen]. Hosted by
  /// `ProductionScreen`; shares its stable surface ID.
  static const screenId = UiScreenIds.productionScreen;

  final Game game;
  final Player player;
  final Map<String, int> desiredOutputByRecipe;
  final Map<String, int> netDeltasByCommodity;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;

  /// When set, Available header shows a text button that opens the breakdown dialog.
  final VoidCallback? onOpenCommodityBreakdown;

  /// Required for the Labour controls to display queued counts. When `null`
  /// the Labour section renders read-only with zero pending counts.
  final Orders? currentOrders;

  /// Callbacks bound to the screen's providers. When `null`, the Labour
  /// controls render in read-only mode (no +/-/Disband buttons).
  final ProductionLabourCallbacks? labourCallbacks;

  /// True when the viewed player may mutate orders or pool via the Labour
  /// controls. Combined with [labourCallbacks] presence to gate buttons.
  final bool canEditLabour;

  static Set<String> get _inputCommodityIds {
    final inputIds = <String>{};
    for (final recipe in ProductionRecipesCatalog.all) {
      inputIds.addAll(recipe.inputQuantities.keys);
    }
    return inputIds;
  }

  static Set<String> get _outputCommodityIds {
    return ProductionRecipesCatalog.all.map((r) => r.outputCommodityId).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final regimentCounts = regimentTypeCountsForPlayer(
      game.worldState,
      player.id,
    );
    final shipCounts = shipTypeCountsForPlayer(game.worldState, player.id);
    final effectiveLabour = effectiveLabourForWorkers(
      workers: player.workerPool,
      stockpile: player.stockpile,
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    );
    final inputCommodityIds = _inputCommodityIds;
    final outputCommodityIds = _outputCommodityIds;
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final availableSubpanel = _AvailableSubpanel(
      game: game,
      player: player,
      effectiveLabour: effectiveLabour,
      inputCommodityIds: inputCommodityIds,
      outputCommodityIds: outputCommodityIds,
      netDeltasByCommodity: netDeltasByCommodity,
      l10n: l10n,
      onOpenCommodityBreakdown: onOpenCommodityBreakdown,
      currentOrders: currentOrders,
      labourCallbacks: labourCallbacks,
      canEditLabour: canEditLabour,
    );
    final allocationSubpanel = _AllocationSubpanel(
      player: player,
      effectiveLabour: effectiveLabour,
      desiredOutputByRecipe: desiredOutputByRecipe,
      onDesiredOutputChanged: onDesiredOutputChanged,
      l10n: l10n,
    );

    if (isNarrow) {
      return _ProductionPanelNarrowLayout(
        key: kProductionPanelNarrowLayoutKey,
        availableSubpanel: availableSubpanel,
        allocationSubpanel: allocationSubpanel,
      );
    }

    return _ProductionPanelWideLayout(
      key: kProductionPanelWideLayoutKey,
      availableSubpanel: availableSubpanel,
      allocationSubpanel: allocationSubpanel,
    );
  }
}
