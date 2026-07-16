import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/turn_resolver_test_harness.dart';
import 'support/turn_trace_order_events_test_support.dart';

const _ow = turnTestOldWorldRegionId;
const _p1 = '$_ow|P1';
const _p2 = '$_ow|P2';

MapTopology _twoProvinceTopology() =>
    twoAdjacentOldWorldProvinceTopology(id1: _p1, id2: _p2);

Game _civilianTwoProvinceGame({
  required List<Unit> units,
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
}) => Game(
  id: 'g',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: const [
        Province(id: _p1, regionId: _ow, ownerId: 'p1'),
        Province(id: _p2, regionId: _ow, ownerId: 'p1'),
      ],
      units: units,
    ),
    newWorld: const RegionData(),
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
  ),
  players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
);

void main() {
  group('turn trace movement order events', () {
    test(
      'applyCivilianTileMoveOrdersToWorldRegions invokes trace for applied move',
      () {
        final game = _civilianTwoProvinceGame(
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeMerchant,
              ownerId: 'p1',
              locationProvinceId: _p1,
              tileKey: '$_p1|0|0',
            ),
          ],
        );
        const order = MoveOrder(unitId: 'u1', destinationTileKey: '$_p2|3|3');
        final runtime = TurnTraceRuntime();
        applyCivilianTileMoveOrdersToWorldRegions(game, const {
          'p1': [order],
        }, onCivilianMoveOrderTrace: runtime.handleCivilianMoveOrderTrace);

        final events = runtime.snapshotPhaseOrderEvents();
        expect(events, hasLength(1));
        expect(events.single.eventType, 'civilian_move_applied');
        expect(events.single.orderId, 'move:p1:u1');
        expect(events.single.sequence, 0);
      },
    );

    test(
      'full pipeline movement phase includes civilian move order events',
      () {
        final topology = _twoProvinceTopology();
        final game = _civilianTwoProvinceGame(
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeMerchant,
              ownerId: 'p1',
              locationProvinceId: _p1,
              tileKey: '$_p1|0|0',
            ),
          ],
        );
        final orders = Orders(
          moveOrdersByPlayerId: {
            'p1': [
              const MoveOrder(unitId: 'u1', destinationTileKey: '$_p2|0|0'),
            ],
          },
        );
        final movementTrace = runMovementTraceForOrders(
          game: game,
          topology: topology,
          orders: orders,
          runtime: TurnTraceRuntime(),
        );
        expect(movementTrace.orderEvents, isNotEmpty);
        expect(
          movementTrace.orderEvents.map((e) => e.eventType),
          contains('civilian_move_applied'),
        );
      },
    );

    test(
      'bundled work move trace records skipped attempts in movement phase',
      () {
        final topology = _twoProvinceTopology();
        final game = _civilianTwoProvinceGame(
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeMerchant,
              ownerId: 'p1',
              locationProvinceId: _p1,
              tileKey: '$_p1|0|0',
            ),
            Unit(
              id: 'u2',
              type: kUnitTypeMerchant,
              ownerId: 'p1',
              locationProvinceId: _p1,
              tileKey: '$_p1|1|1',
            ),
          ],
          tileKeysByRegionAndProvince: const {
            _ow: {
              _p2: ['$_p2|2|2'],
            },
          },
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'u1',
                target: 'build_farm',
                targetTileKey: '$_p2|2|2',
              ),
              const WorkOrder(
                unitId: 'u2',
                target: kWorkTargetExplore,
                targetTileKey: '$_p1|1|1',
              ),
            ],
          },
        );
        final movementTrace = runMovementTraceForOrders(
          game: game,
          topology: topology,
          orders: orders,
          runtime: TurnTraceRuntime(),
        );
        expect(
          movementTrace.orderEvents.map((event) => event.eventType),
          contains('bundled_work_move_skipped'),
        );
      },
    );

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
  });
}
