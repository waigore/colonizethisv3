// Shared ProductionPanel players, wrappers, and host (Refs #4013).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_app_fixtures/demo/production_panel_demo_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'app_shell_harness.dart';

/// Players and games for production panel widget tests without debug game init.
Player productionPanelTestFullPlayer() {
  return Player(
    id: 'test_gp_full',
    displayName: 'Full test',
    isHuman: true,
    stockpile: productionPanelTestFullStockpile,
    workerPool: productionPanelTestFullWorkerPool,
  );
}

Player productionPanelTestPartialPlayer() {
  return Player(
    id: 'test_gp_partial',
    displayName: 'Partial test',
    isHuman: true,
    stockpile: productionPanelTestPartialStockpile,
    workerPool: productionPanelTestPartialWorkerPool,
  );
}

Game productionPanelTestGameFor(Player player) {
  return Game(
    id: 'production-widget-test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
}

/// Holds allocation map in state so [ProductionPanel] rebuilds after each change
/// (matches Riverpod-driven app behaviour; required for long-press repeat tests).
class ProductionPanelTestWrapper extends StatefulWidget {
  const ProductionPanelTestWrapper({
    super.key,
    required this.displayGame,
    required this.player,
    required this.initialDesiredOutput,
    required this.netDeltasByCommodity,
    required this.onDesiredOutputChanged,
    this.onOpenCommodityBreakdown,
    this.currentOrders,
    this.labourCallbacks,
    this.canEditLabour = false,
  });

  final Game displayGame;
  final Player player;
  final Map<String, int> initialDesiredOutput;
  final Map<String, int> netDeltasByCommodity;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;
  final VoidCallback? onOpenCommodityBreakdown;
  final Orders? currentOrders;
  final ProductionLabourCallbacks? labourCallbacks;
  final bool canEditLabour;

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
  bool canEditLabour = false,
  double width = 800,
  double height = 500,
}) {
  final displayGame = gameOverride ?? productionPanelTestGameFor(player);
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
  return buildAppShell(
    viewport: Size(width, height),
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    child: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: ProductionPanelTestWrapper(
          displayGame: displayGame,
          player: player,
          initialDesiredOutput: desiredOutputByRecipe,
          netDeltasByCommodity: netDeltasByCommodity,
          onDesiredOutputChanged: onDesiredOutputChanged ?? (_) {},
          onOpenCommodityBreakdown: onOpenCommodityBreakdown,
          currentOrders: currentOrders,
          labourCallbacks: labourCallbacks,
          canEditLabour: canEditLabour,
        ),
      ),
    ),
  );
}
