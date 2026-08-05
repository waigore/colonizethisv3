import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'support/suggestion/order_suggestion_core_fixtures.dart';

void main() {
  group('civilian_work_affordance', () {
    test('previewWorkOrderAffordAtTile reports shortfall after pending work', () {
      final s = OscDualBuilderGrainTiles();
      final lowStockGame = s.game().copyWith(
        players: [
          s.player.copyWith(stockpile: oscLumberCastIronStockpile(amount: 1)),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          OscIds.playerId: [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: s.tileA,
            ),
          ],
        },
      );
      final preview = previewWorkOrderAffordAtTile(
        game: lowStockGame,
        playerId: OscIds.playerId,
        currentOrders: orders,
        workTarget: kWorkTargetBuildImprovement,
        targetTileKey: s.tileB,
      );
      expect(preview.materialCosts, isNotNull);
      expect(preview.canAfford, isFalse);
      expect(preview.materialShortfalls, isNotEmpty);
    });

    test('previewPendingWorkOrderAfford marks second order unaffordable', () {
      final s = OscDualBuilderGrainTiles();
      final lowStockGame = s.game().copyWith(
        players: [
          s.player.copyWith(stockpile: oscLumberCastIronStockpile(amount: 1)),
        ],
      );
      final orderA = WorkOrder(
        unitId: 'b1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: s.tileA,
      );
      final orderB = WorkOrder(
        unitId: 'b2',
        target: kWorkTargetBuildImprovement,
        targetTileKey: s.tileB,
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          OscIds.playerId: [orderA, orderB],
        },
      );
      final first = previewPendingWorkOrderAfford(
        game: lowStockGame,
        playerId: OscIds.playerId,
        currentOrders: orders,
        pendingOrder: orderA,
      );
      final second = previewPendingWorkOrderAfford(
        game: lowStockGame,
        playerId: OscIds.playerId,
        currentOrders: orders,
        pendingOrder: orderB,
      );
      expect(first.canAfford, isTrue);
      expect(second.canAfford, isFalse);
      expect(second.materialShortfalls, isNotEmpty);
    });

    test('free targets skip cost preview', () {
      final s = OscDualBuilderGrainTiles();
      final preview = previewWorkOrderAffordAtTile(
        game: s.game(),
        playerId: OscIds.playerId,
        currentOrders: const Orders(),
        workTarget: kWorkTargetExplore,
        targetTileKey: s.tileA,
      );
      expect(preview.hasCostPreview, isFalse);
      expect(preview.canAfford, isTrue);
    });
  });
}
