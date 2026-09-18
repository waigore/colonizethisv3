import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../config/constants.dart';
import '../../../../config/ui_screen_ids.dart';
import 'production_labour_helpers.dart';
import 'production_panel_constants.dart';
import 'production_panel_layouts.dart';
import 'production_panel_support_allocation.dart';
import 'production_panel_support_available.dart';

export 'production_panel_constants.dart';

/// Production screen panel: Available stockpile + Allocation recipe rows.
/// SPEC/ui/production-panel.md.
class ProductionPanel extends StatefulWidget {
  const ProductionPanel({
    super.key,
    required this.game,
    required this.player,
    required this.desiredOutputByRecipe,
    required this.netDeltasByCommodity,
    required this.labourReadiness,
    required this.forcesFeeding,
    required this.onDesiredOutputChanged,
    this.onOpenCommodityBreakdown,
    this.currentOrders,
    this.labourCallbacks,
    this.canEditLabour = false,
    this.starredProduceRecommendationsByRecipeId = const {},
    this.onOpenCounsel,
    this.onOpenTradeMarket,
    this.onOpenDevelopment,
  });

  /// SPEC/ui/production-panel.md — [UiScreenIds.productionScreen]. Hosted by
  /// `ProductionScreen`; shares its stable surface ID.
  static const screenId = UiScreenIds.productionScreen;

  final Game game;
  final Player player;
  final Map<String, int> desiredOutputByRecipe;
  final Map<String, int> netDeltasByCommodity;
  final LabourReadinessSnapshot labourReadiness;
  final ForceFeedingSnapshot forcesFeeding;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;

  /// When set, Available header shows a text button that opens the breakdown dialog.
  final VoidCallback? onOpenCommodityBreakdown;

  /// Required for the Labour controls to display queued counts. When `null`
  /// the Labour section renders read-only with zero pending counts.
  final Orders? currentOrders;

  /// Callbacks bound to the screen's providers. When `null`, the Labour
  /// controls render in read-only mode (no +/-/Disband buttons).
  final ProductionLabourCallbacks? labourCallbacks;

  /// True when Labour and Allocation controls may mutate state; counsel stars
  /// stay tappable when false (turn-resolution read-only).
  final bool canEditLabour;

  final Map<String, IndustryCounselRecommendation>
  starredProduceRecommendationsByRecipeId;

  final ProductionOpenCounselCallback? onOpenCounsel;
  final void Function(String commodityId)? onOpenTradeMarket;
  final void Function(String commodityId)? onOpenDevelopment;

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
  State<ProductionPanel> createState() => _ProductionPanelState();
}

class _ProductionPanelState extends State<ProductionPanel> {
  int _labourControlsFocusToken = 0;

  void _focusLabourControls() {
    setState(() => _labourControlsFocusToken++);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final effectiveLabour = widget.labourReadiness.effectiveLabour;
    final inputCommodityIds = ProductionPanel._inputCommodityIds;
    final outputCommodityIds = ProductionPanel._outputCommodityIds;
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final availableSubpanel = ProductionPanelAvailableSubpanel(
      game: widget.game,
      player: widget.player,
      labourReadiness: widget.labourReadiness,
      forcesFeeding: widget.forcesFeeding,
      inputCommodityIds: inputCommodityIds,
      outputCommodityIds: outputCommodityIds,
      netDeltasByCommodity: widget.netDeltasByCommodity,
      l10n: l10n,
      onOpenCommodityBreakdown: widget.onOpenCommodityBreakdown,
      currentOrders: widget.currentOrders,
      labourCallbacks: widget.labourCallbacks,
      canEditLabour: widget.canEditLabour,
      onOpenTradeMarket: widget.onOpenTradeMarket,
      labourControlsFocusToken: _labourControlsFocusToken,
    );
    final allocationSubpanel = ProductionPanelAllocationSubpanel(
      player: widget.player,
      effectiveLabour: effectiveLabour,
      desiredOutputByRecipe: widget.desiredOutputByRecipe,
      onDesiredOutputChanged: widget.onDesiredOutputChanged,
      l10n: l10n,
      canEditLabour: widget.canEditLabour,
      starredProduceRecommendationsByRecipeId:
          widget.starredProduceRecommendationsByRecipeId,
      onOpenCounsel: widget.onOpenCounsel,
      onOpenDevelopment: widget.onOpenDevelopment,
      onFocusLabourControls: _focusLabourControls,
    );

    if (isNarrow) {
      return ProductionPanelNarrowLayout(
        key: kProductionPanelNarrowLayoutKey,
        availableSubpanel: availableSubpanel,
        allocationSubpanel: allocationSubpanel,
      );
    }

    return ProductionPanelWideLayout(
      key: kProductionPanelWideLayoutKey,
      availableSubpanel: availableSubpanel,
      allocationSubpanel: allocationSubpanel,
    );
  }
}
