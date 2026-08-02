// Shared ProductionPanel wrappers and host (Refs #4013).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel_support_allocation.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'app_shell_harness.dart';
import 'panel_fixtures/production.dart'
    show productionPanelTestGameFor;
export 'panel_fixtures/production.dart'
    show
        productionPanelTestFullPlayer,
        productionPanelTestGameFor,
        productionPanelTestPartialPlayer;

/// Labour readiness for tests that construct [ProductionPanel] directly.
LabourReadinessSnapshot labourReadinessForPlayer(Player player) =>
    computeLabourReadiness(
      workers: player.workerPool,
      stockpile: player.stockpile,
    );

/// Holds allocation map in state so [ProductionPanel] rebuilds after each change
/// (matches Riverpod-driven app behaviour; required for long-press repeat tests).
class ProductionPanelTestWrapper extends StatefulWidget {
  const ProductionPanelTestWrapper({
    super.key,
    required this.displayGame,
    required this.player,
    required this.initialDesiredOutput,
    required this.netDeltasByCommodity,
    required this.labourReadiness,
    required this.onDesiredOutputChanged,
    this.onOpenCommodityBreakdown,
    this.currentOrders,
    this.labourCallbacks,
    this.canEditLabour = true,
    this.starredProduceRecommendationsByRecipeId = const {},
    this.onOpenCounsel,
  });

  final Game displayGame;
  final Player player;
  final Map<String, int> initialDesiredOutput;
  final Map<String, int> netDeltasByCommodity;
  final LabourReadinessSnapshot labourReadiness;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;
  final VoidCallback? onOpenCommodityBreakdown;
  final Orders? currentOrders;
  final ProductionLabourCallbacks? labourCallbacks;
  final bool canEditLabour;
  final Map<String, IndustryCounselRecommendation>
  starredProduceRecommendationsByRecipeId;
  final ProductionOpenCounselCallback? onOpenCounsel;

  @override
  State<ProductionPanelTestWrapper> createState() =>
      _ProductionPanelTestWrapperState();
}

class _ProductionPanelTestWrapperState
    extends State<ProductionPanelTestWrapper> {
  late Map<String, int> _desiredOutput;

  @override
  void initState() {
    super.initState();
    _desiredOutput = Map<String, int>.from(widget.initialDesiredOutput);
  }

  @override
  Widget build(BuildContext context) {
    return ProductionPanel(
      game: widget.displayGame,
      player: widget.player,
      desiredOutputByRecipe: _desiredOutput,
      netDeltasByCommodity: widget.netDeltasByCommodity,
      labourReadiness: widget.labourReadiness,
      onDesiredOutputChanged: (next) {
        setState(() {
          _desiredOutput = Map<String, int>.from(next);
        });
        widget.onDesiredOutputChanged(next);
      },
      onOpenCommodityBreakdown: widget.onOpenCommodityBreakdown,
      currentOrders: widget.currentOrders,
      labourCallbacks: widget.labourCallbacks,
      canEditLabour: widget.canEditLabour,
      starredProduceRecommendationsByRecipeId:
          widget.starredProduceRecommendationsByRecipeId,
      onOpenCounsel: widget.onOpenCounsel,
    );
  }
}

/// Canonical [ProductionPanel] host for widget tests via [buildAppShell]
/// (Refs #4013, #4035).
Widget buildProductionPanel({
  required Player player,
  Game? gameOverride,
  Map<String, int> desiredOutputByRecipe = const {},
  ValueChanged<Map<String, int>>? onDesiredOutputChanged,
  VoidCallback? onOpenCommodityBreakdown,
  Orders? currentOrders,
  ProductionLabourCallbacks? labourCallbacks,
  bool canEditLabour = true,
  Map<String, IndustryCounselRecommendation>
  starredProduceRecommendationsByRecipeId = const {},
  ProductionOpenCounselCallback? onOpenCounsel,
  LabourReadinessSnapshot? labourReadinessOverride,
  double width = 800,
  double height = 500,
}) {
  final displayGame = gameOverride ?? productionPanelTestGameFor(player);
  final labourReadiness =
      labourReadinessOverride ??
      computeLabourReadiness(
        workers: player.workerPool,
        stockpile: player.stockpile,
      );
  final netDeltasByCommodity = <String, int>{};
  for (final entry in desiredOutputByRecipe.entries) {
    final recipe = ProductionRecipesCatalog.byId[entry.key];
    if (recipe == null) continue;
    for (final input in recipe.inputQuantities.entries) {
      netDeltasByCommodity[input.key] =
          (netDeltasByCommodity[input.key] ?? 0) - (input.value * entry.value);
    }
    netDeltasByCommodity[recipe.outputCommodityId] =
        (netDeltasByCommodity[recipe.outputCommodityId] ?? 0) +
        (recipe.outputQuantity * entry.value);
  }
  return buildPanelScaffoldShell(
    SizedBox(
      width: width,
      height: height,
      child: ProductionPanelTestWrapper(
        displayGame: displayGame,
        player: player,
        initialDesiredOutput: desiredOutputByRecipe,
        netDeltasByCommodity: netDeltasByCommodity,
        labourReadiness: labourReadiness,
        onDesiredOutputChanged: onDesiredOutputChanged ?? (_) {},
        onOpenCommodityBreakdown: onOpenCommodityBreakdown,
        currentOrders: currentOrders,
        labourCallbacks: labourCallbacks,
        canEditLabour: canEditLabour,
        starredProduceRecommendationsByRecipeId:
            starredProduceRecommendationsByRecipeId,
        onOpenCounsel: onOpenCounsel,
      ),
    ),
    viewport: Size(width, height),
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
  );
}
