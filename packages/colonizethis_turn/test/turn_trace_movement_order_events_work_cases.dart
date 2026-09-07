// Work-order trace cases for turn_trace_movement_order_events_test
// (Refs #4740 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/turn_resolver_test_harness.dart';
import 'support/turn_trace_order_events_test_support.dart';

const _ow = turnTestOldWorldRegionId;
const _p1 = '$_ow|P1';
const _p2 = '$_ow|P2';

void registerTurnTraceMovementWorkOrderCases() {
  test('runtime records bundled work move applied event payload', () {
    final runtime = TurnTraceRuntime();
    runtime.handleBundledWorkMoveTrace(
      playerId: 'p1',
      order: const WorkOrder(
        unitId: 'u1',
        target: 'build_farm',
        targetTileKey: '$_p2|2|2',
      ),
      applied: true,
      destinationProvinceId: _p2,
      destinationTileKey: '$_p2|2|2',
    );

    final event = runtime.snapshotPhaseOrderEvents().single;
    expect(event.eventType, 'bundled_work_move_applied');
    expect(event.orderId, 'work:p1:u1:build_farm');
    expect(event.payload?['destinationProvinceId'], _p2);
    expect(event.payload?['destinationTileKey'], '$_p2|2|2');
  });

  test('full pipeline build_work phase includes work order trace events', () {
    final topology = MapTopology(
      nodes: const [
        TopologyNode(id: _p1, regionId: _ow, type: TopologyNodeType.province),
      ],
      edges: const [],
    );
    final game = Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [Province(id: _p1, regionId: _ow, ownerId: 'p1')],
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeEngineer,
              ownerId: 'p1',
              locationProvinceId: _p1,
              tileKey: '$_p1|0|0',
            ),
          ],
        ),
        newWorld: const RegionData(),
        tileKeysByRegionAndProvince: const {
          _ow: {
            _p1: ['$_p1|0|0'],
          },
        },
      ),
      players: const [
        Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
          stockpile: Stockpile(quantities: {'wood': 100}),
        ),
      ],
    );
    final orders = Orders(
      workOrdersByPlayerId: const {
        'p1': [
          WorkOrder(
            unitId: 'u1',
            target: kWorkTargetBuildRoad,
            targetTileKey: '$_p1|0|0',
          ),
        ],
      },
    );
    final buildWorkTrace = runTurnTracePhaseForOrders(
      game: game,
      topology: topology,
      orders: orders,
      phaseId: TurnPhase.buildWork.name,
      runtime: TurnTraceRuntime(),
    );
    expect(
      buildWorkTrace.orderEvents.map((event) => event.eventType),
      contains('work_order_skipped'),
    );
    expect(
      buildWorkTrace.orderEvents.map((event) => event.orderId),
      contains('work:p1:u1:build_road'),
    );
  });
}
