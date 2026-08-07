// Parity between MAP assign and Development panel affordance entrypoints (Refs #4281).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'support/suggestion/order_suggestion_core_fixtures.dart';

void main() {
  group('work_order_affordance_projection parity', () {
    test('stockpile projection matches between MAP and development panel', () {
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

      final mapProjection = projectPlayerResourcesAfterPendingWork(
        game: lowStockGame,
        playerId: OscIds.playerId,
        currentOrders: orders,
      );
      final panelStockpile =
          effectiveStockpileAfterPendingDevelopmentMaterialWork(
        game: lowStockGame,
        playerId: OscIds.playerId,
        currentOrders: orders,
      );

      expect(panelStockpile, mapProjection.stockpile);
    });

    test('build_improvement canAfford matches previewWorkOrderAffordAtTile', () {
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
      final canAfford = canAffordDevelopmentWorkOrder(
        game: lowStockGame,
        playerId: OscIds.playerId,
        currentOrders: orders,
        workTarget: kWorkTargetBuildImprovement,
        targetTileKey: s.tileB,
      );

      expect(canAfford, preview.canAfford);
    });
  });
}
