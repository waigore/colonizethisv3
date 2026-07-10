// Compact OrderEngine civilian move XOR work assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_civilian_move_xor_work_fixtures.dart';

/// Pins for [orderEngineCivilianMoveXorWorkScenarios] rows.
enum OrderEngineCivilianMoveXorWorkTarget {
  rejectsWorkWhenMoveExists,
  mergedDraftMoveThenWork,
}

void runOrderEngineCivilianMoveXorWorkExpectation(
  OrderEngineCivilianMoveXorWorkTarget target,
) {
  final game = ocmxwExplorerOnP1Game();
  final topology = ocmxwTwoProvinceTopology();
  switch (target) {
    case OrderEngineCivilianMoveXorWorkTarget.rejectsWorkWhenMoveExists:
      final engine = OrderEngine();
      final moveRes = engine.addMoveOrderWithContext(
        game,
        topology,
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: ocmxwTileB),
      );
      expect(moveRes.isAccepted, isTrue, reason: moveRes.reason);
      final workResult = engine.addWorkOrderWithContext(
        game,
        topology,
        'p1',
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: ocmxwExploreTargetTile,
        ),
      );
      expect(workResult.isAccepted, isFalse);
      expect(workResult.reason, kReasonCivilianMoveXorWorkOrder);

    case OrderEngineCivilianMoveXorWorkTarget.mergedDraftMoveThenWork:
      final engine = OrderEngine(
        initialOrders: Orders(
          moveOrdersByPlayerId: {
            'p1': [
              const MoveOrder(unitId: 'u1', destinationTileKey: ocmxwTileB),
            ],
          },
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetExplore,
                targetTileKey: ocmxwExploreTargetTile,
              ),
            ],
          },
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.first.isAccepted, isTrue);
      expect(results.last.isAccepted, isFalse);
      expect(results.last.reason, kReasonCivilianMoveXorWorkOrder);
  }
}
