// Feedstock-bootstrap castIron/lumber waiver assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_cost_calculator.dart';
import 'package:colonizethis_test/test.dart';

import 'work_order_cost_calculator_feedstock_bootstrap_fixtures.dart';

/// Pins for [workOrderCostCalculatorFeedstockBootstrapScenarios] rows.
enum WorkOrderCostCalculatorFeedstockBootstrapTarget {
  omitsCastIronLumberOnly,
  keepsFullCostWhenCastIronAffordable,
  keepsFullCostNonFeedstock,
  omitsLumberAndCastIronNeitherInput,
  doesNotWaiveLumberWhenCastIronAffordable,
}

void runWorkOrderCostCalculatorFeedstockBootstrapExpectation(
  WorkOrderCostCalculatorFeedstockBootstrapTarget target,
) {
  switch (target) {
    case WorkOrderCostCalculatorFeedstockBootstrapTarget.omitsCastIronLumberOnly:
      final game = twoPlayerFeedstockGateGame(
        supplierStockpile: const Stockpile(quantities: {'lumber': 2}),
      );
      expect(
        feedstockExtractionResourceIdsForPlayer(
          game,
          feedstockBootstrapSupplierId,
        ),
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
      final cost = WorkOrderCostCalculator(game, playerId: feedstockBootstrapSupplierId)
          .calculateCost(
            kWorkTargetBuildImprovement,
            feedstockBootstrapIronTile,
            improvementLevel: 0,
          );
      expect(cost, equals({CommodityCatalog.lumber.id: 1}));

    case WorkOrderCostCalculatorFeedstockBootstrapTarget
        .keepsFullCostWhenCastIronAffordable:
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
      final cost = WorkOrderCostCalculator(game, playerId: feedstockBootstrapSupplierId)
          .calculateCost(
            kWorkTargetBuildImprovement,
            feedstockBootstrapIronTile,
            improvementLevel: 0,
          );
      expect(cost![CommodityCatalog.lumber.id], 1);
      expect(cost[CommodityCatalog.castIron.id], 1);

    case WorkOrderCostCalculatorFeedstockBootstrapTarget.keepsFullCostNonFeedstock:
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
      final cost = WorkOrderCostCalculator(game, playerId: feedstockBootstrapSupplierId)
          .calculateCost(
            kWorkTargetBuildImprovement,
            feedstockBootstrapGrainTile,
            improvementLevel: 0,
          );
      expect(cost![CommodityCatalog.castIron.id], 1);

    case WorkOrderCostCalculatorFeedstockBootstrapTarget
        .omitsLumberAndCastIronNeitherInput:
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
      final cost = WorkOrderCostCalculator(game, playerId: feedstockBootstrapSupplierId)
          .calculateCost(
            kWorkTargetBuildImprovement,
            feedstockBootstrapTimberTile,
            improvementLevel: 0,
          );
      expect(cost, isEmpty);

    case WorkOrderCostCalculatorFeedstockBootstrapTarget
        .doesNotWaiveLumberWhenCastIronAffordable:
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
      final cost = WorkOrderCostCalculator(game, playerId: feedstockBootstrapSupplierId)
          .calculateCost(
            kWorkTargetBuildImprovement,
            feedstockBootstrapTimberTile,
            improvementLevel: 0,
          );
      expect(cost![CommodityCatalog.lumber.id], 1);
      expect(cost[CommodityCatalog.castIron.id], 1);
  }
}
