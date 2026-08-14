import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'economy_stockpile_preview_work_orders_cases.dart';
import 'support/economy_stockpile_preview_test_support.dart';

/// Stockpile preview for production panel. SPEC/ui/production-panel.md,
/// SPEC/game/stockpiles-and-production.md.
void main() {
  suppressLogsForTests();

  group('previewStockpilePhaseDeltasByCommodityForPlayer', () {
    test('unknown player yields empty maps per phase', () {
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile(),
      );
      final game = TestFixtures.singlePlayerGame(player);
      final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'missing',
      );
      for (final m in phases.values) {
        expect(m, isEmpty);
      }
    });
  });

  group('previewStockpileNetDeltaByCommodityForPlayer', () {
    test(
      'pending build_improvement work orders deduct in pending build phase',
      () {
        final game = workOrdersPreviewGame(
          improvementLevel: 0,
          stockpile: workOrdersLumberIronStockpile(10),
        );
        final currentOrders = economyPreviewSingleWorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
        );
        final delta = previewStockpileNetDeltaByCommodityForPlayer(
          game: game,
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(currentOrders: currentOrders),
        );
        final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
          game: game,
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(currentOrders: currentOrders),
        );
        expect(delta[CommodityCatalog.lumber.id], -1);
        expect(delta[CommodityCatalog.castIron.id], -1);
        expect(
          phases[EconomyPreviewStockpilePhase
              .pendingBuildCosts]![CommodityCatalog.lumber.id],
          -1,
        );
        expect(
          phases[EconomyPreviewStockpilePhase
              .pendingBuildCosts]![CommodityCatalog.castIron.id],
          -1,
        );
        expectPhaseDeltasSumToNet(
          game: game,
          playerId: 'p1',
          currentOrders: currentOrders,
        );
      },
    );

    test(
      'build_improvement preview uses improvement level for material cost',
      () {
        final game = workOrdersPreviewGame(
          improvementLevel: 1,
          stockpile: workOrdersLumberIronStockpile(10),
        );
        final currentOrders = economyPreviewSingleWorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
        );
        final delta = previewStockpileNetDeltaByCommodityForPlayer(
          game: game,
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(currentOrders: currentOrders),
        );
        expect(delta[CommodityCatalog.lumber.id], -4);
        expect(delta[CommodityCatalog.castIron.id], -4);
      },
    );

    test('build_improvement preview skips busy unit or unaffordable cost', () {
      final ordersBusy = economyPreviewSingleWorkOrder(
        unitId: 'b1',
        target: kWorkTargetBuildImprovement,
      );
      expect(
        previewStockpileNetDeltaByCommodityForPlayer(
          game: workOrdersBusyBuilderGame(),
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(currentOrders: ordersBusy),
        ),
        isEmpty,
      );

      final ordersPoorCost = economyPreviewSingleWorkOrder(
        unitId: 'b2',
        target: kWorkTargetBuildImprovement,
      );
      expect(
        previewStockpileNetDeltaByCommodityForPlayer(
          game: workOrdersUnaffordableUpgradeGame(),
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(currentOrders: ordersPoorCost),
        ),
        isEmpty,
      );
    });

    test('build_improvement preview skips disallowed unit type', () {
      final currentOrders = economyPreviewSingleWorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildImprovement,
      );
      expect(
        previewStockpileNetDeltaByCommodityForPlayer(
          game: workOrdersDisallowedUnitTypeGame(),
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(currentOrders: currentOrders),
        ),
        isEmpty,
      );
    });
  });
}
