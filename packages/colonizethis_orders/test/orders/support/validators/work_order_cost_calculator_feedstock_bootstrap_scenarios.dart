// Table-driven feedstock-bootstrap waiver scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_cost_calculator.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'work_order_cost_calculator_feedstock_bootstrap_fixtures.dart';

void woccfbRunOmitsCastIronLumberOnly() {
  final game = twoPlayerFeedstockGateGame(
    supplierStockpile: const Stockpile(quantities: {'lumber': 2}),
  );
  expect(
    feedstockExtractionResourceIdsForPlayer(game, feedstockBootstrapSupplierId),
    contains('iron'),
  );
  expect(
    feedstockBootstrapBuildImprovementCastIronWaived(
      game,
      feedstockBootstrapSupplierId,
      feedstockBootstrapIronTile,
    ),
    isTrue,
  );
  final cost =
      WorkOrderCostCalculator(
        game,
        playerId: feedstockBootstrapSupplierId,
      ).calculateCost(
        kWorkTargetBuildImprovement,
        feedstockBootstrapIronTile,
        improvementLevel: 0,
      );
  expect(cost, equals({CommodityCatalog.lumber.id: 1}));
}

void woccfbRunKeepsFullCostWhenCastIronAffordable() {
  final game = twoPlayerFeedstockGateGame(
    supplierStockpile: const Stockpile(
      quantities: {'lumber': 2, 'castIron': 1},
    ),
  );
  expect(
    feedstockBootstrapBuildImprovementCastIronWaived(
      game,
      feedstockBootstrapSupplierId,
      feedstockBootstrapIronTile,
    ),
    isFalse,
  );
  final cost =
      WorkOrderCostCalculator(
        game,
        playerId: feedstockBootstrapSupplierId,
      ).calculateCost(
        kWorkTargetBuildImprovement,
        feedstockBootstrapIronTile,
        improvementLevel: 0,
      );
  expect(cost![CommodityCatalog.lumber.id], 1);
  expect(cost[CommodityCatalog.castIron.id], 1);
}

void woccfbRunKeepsFullCostNonFeedstock() {
  final game = twoPlayerFeedstockGateGame(
    supplierStockpile: const Stockpile(quantities: {'lumber': 2}),
  );
  expect(
    feedstockBootstrapBuildImprovementCastIronWaived(
      game,
      feedstockBootstrapSupplierId,
      feedstockBootstrapGrainTile,
    ),
    isFalse,
  );
  final cost =
      WorkOrderCostCalculator(
        game,
        playerId: feedstockBootstrapSupplierId,
      ).calculateCost(
        kWorkTargetBuildImprovement,
        feedstockBootstrapGrainTile,
        improvementLevel: 0,
      );
  expect(cost![CommodityCatalog.castIron.id], 1);
}

void woccfbRunOmitsLumberAndCastIronNeitherInput() {
  final game = twoPlayerFeedstockGateGame(
    supplierStockpile: Stockpile.empty,
    sellerStockpile: Stockpile.empty,
  );
  expect(
    feedstockBootstrapBuildImprovementLumberWaived(
      game,
      feedstockBootstrapSupplierId,
      feedstockBootstrapTimberTile,
    ),
    isTrue,
  );
  expect(
    feedstockBootstrapBuildImprovementCastIronWaived(
      game,
      feedstockBootstrapSupplierId,
      feedstockBootstrapTimberTile,
    ),
    isFalse,
  );
  final cost =
      WorkOrderCostCalculator(
        game,
        playerId: feedstockBootstrapSupplierId,
      ).calculateCost(
        kWorkTargetBuildImprovement,
        feedstockBootstrapTimberTile,
        improvementLevel: 0,
      );
  expect(cost, isEmpty);
}

void woccfbRunDoesNotWaiveLumberWhenCastIronAffordable() {
  final game = twoPlayerFeedstockGateGame(
    supplierStockpile: const Stockpile(quantities: {'castIron': 1}),
  );
  expect(
    feedstockBootstrapBuildImprovementLumberWaived(
      game,
      feedstockBootstrapSupplierId,
      feedstockBootstrapTimberTile,
    ),
    isFalse,
  );
  final cost =
      WorkOrderCostCalculator(
        game,
        playerId: feedstockBootstrapSupplierId,
      ).calculateCost(
        kWorkTargetBuildImprovement,
        feedstockBootstrapTimberTile,
        improvementLevel: 0,
      );
  expect(cost![CommodityCatalog.lumber.id], 1);
  expect(cost[CommodityCatalog.castIron.id], 1);
}

List<RunnableScenario>
workOrderCostCalculatorFeedstockBootstrapScenarios() => const [
  rs('omits castIron for unimproved feedstock tile when gate active and '
        'stockpile has lumber only', woccfbRunOmitsCastIronLumberOnly),
  rs('keeps full cost when castIron is already affordable (negative control)', woccfbRunKeepsFullCostWhenCastIronAffordable),
  rs('keeps full cost on non-feedstock tile while gate active (negative control)', woccfbRunKeepsFullCostNonFeedstock),
  rs('omits lumber and castIron for unimproved feedstock tile when gate active '
        'and stockpile has neither input (Refs #2847 lumber bootstrap)', woccfbRunOmitsLumberAndCastIronNeitherInput),
  rs('does not waive lumber when castIron is already affordable (negative control)', woccfbRunDoesNotWaiveLumberWhenCastIronAffordable),
];
