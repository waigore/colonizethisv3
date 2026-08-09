// Parity between MAP assign and Development panel affordance entrypoints (Refs #4281).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_core_fixtures.dart';

({Game game, Orders orders, String tileA, String tileB}) _lowStockBuildImprovementFixture() {
  final s = OscDualBuilderGrainTiles();
  final game = s.game().copyWith(
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
  return (game: game, orders: orders, tileA: s.tileA, tileB: s.tileB);
}

void _expectStockpileProjectionParity() {
  final fixture = _lowStockBuildImprovementFixture();
  final mapProjection = projectPlayerResourcesAfterPendingWork(
    game: fixture.game,
    playerId: OscIds.playerId,
    currentOrders: fixture.orders,
  );
  final panelStockpile = effectiveStockpileAfterPendingDevelopmentMaterialWork(
    game: fixture.game,
    playerId: OscIds.playerId,
    currentOrders: fixture.orders,
  );
  expect(panelStockpile, mapProjection.stockpile);
}

void _expectCanAffordParity() {
  final fixture = _lowStockBuildImprovementFixture();
  final preview = previewWorkOrderAffordAtTile(
    game: fixture.game,
    playerId: OscIds.playerId,
    currentOrders: fixture.orders,
    workTarget: kWorkTargetBuildImprovement,
    targetTileKey: fixture.tileB,
  );
  final canAfford = canAffordDevelopmentWorkOrder(
    game: fixture.game,
    playerId: OscIds.playerId,
    currentOrders: fixture.orders,
    workTarget: kWorkTargetBuildImprovement,
    targetTileKey: fixture.tileB,
  );
  expect(canAfford, preview.canAfford);
}

void main() {
  runLabeledScenarioGroup(
    'work_order_affordance_projection parity',
    [
      rs(
        'stockpile projection matches between MAP and development panel',
        _expectStockpileProjectionParity,
      ),
      rs(
        'build_improvement canAfford matches previewWorkOrderAffordAtTile',
        _expectCanAffordParity,
      ),
    ],
    runRunnableScenario,
  );
}
