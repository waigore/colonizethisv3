import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('turn trace movement order events', () {
    test(
      'applyCivilianTileMoveOrdersToWorldRegions invokes trace for applied move',
      () {
        const ow = 'oldWorld';
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
                Province(id: 'oldWorld|P2', regionId: ow, ownerId: 'p1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: kUnitTypeMerchant,
                  ownerId: 'p1',
                  locationProvinceId: 'oldWorld|P1',
                  tileKey: 'oldWorld|P1|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        const order = MoveOrder(
          unitId: 'u1',
          destinationTileKey: 'oldWorld|P2|3|3',
        );
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
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'oldWorld|P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|P2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'oldWorld|P1', id2: 'oldWorld|P2')],
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
                Province(id: 'oldWorld|P2', regionId: ow, ownerId: 'p1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: kUnitTypeMerchant,
                  ownerId: 'p1',
                  locationProvinceId: 'oldWorld|P1',
                  tileKey: 'oldWorld|P1|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final orders = Orders(
          moveOrdersByPlayerId: {
            'p1': [
              const MoveOrder(
                unitId: 'u1',
                destinationTileKey: 'oldWorld|P2|0|0',
              ),
            ],
          },
        );
        final traces = <TurnTracePhaseTrace>[];
        final runtime = TurnTraceRuntime();
        resolveTurnForGameWithConfig(
          game: game,
          config: TurnResolverConfig(
            topology: topology,
            orders: orders,
            onTurnTracePhase: traces.add,
            turnTraceRuntime: runtime,
          ),
        );

        final movementTrace = traces.firstWhere(
          (t) => t.phaseId == TurnPhase.movement.name,
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
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'oldWorld|P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|P2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'oldWorld|P1', id2: 'oldWorld|P2')],
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
                Province(id: 'oldWorld|P2', regionId: ow, ownerId: 'p1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: kUnitTypeMerchant,
                  ownerId: 'p1',
                  locationProvinceId: 'oldWorld|P1',
                  tileKey: 'oldWorld|P1|0|0',
                ),
                Unit(
                  id: 'u2',
                  type: kUnitTypeMerchant,
                  ownerId: 'p1',
                  locationProvinceId: 'oldWorld|P1',
                  tileKey: 'oldWorld|P1|1|1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: const {
              ow: {
                'oldWorld|P2': ['oldWorld|P2|2|2'],
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'u1',
                target: 'build_farm',
                targetTileKey: 'oldWorld|P2|2|2',
              ),
              const WorkOrder(
                unitId: 'u2',
                target: kWorkTargetExplore,
                targetTileKey: 'oldWorld|P1|1|1',
              ),
            ],
          },
        );
        final traces = <TurnTracePhaseTrace>[];
        final runtime = TurnTraceRuntime();
        resolveTurnForGameWithConfig(
          game: game,
          config: TurnResolverConfig(
            topology: topology,
            orders: orders,
            onTurnTracePhase: traces.add,
            turnTraceRuntime: runtime,
          ),
        );

        final movementTrace = traces.firstWhere(
          (t) => t.phaseId == TurnPhase.movement.name,
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
          targetTileKey: 'oldWorld|P2|2|2',
        ),
        applied: true,
        destinationProvinceId: 'oldWorld|P2',
        destinationTileKey: 'oldWorld|P2|2|2',
      );

      final event = runtime.snapshotPhaseOrderEvents().single;
      expect(event.eventType, 'bundled_work_move_applied');
      expect(event.orderId, 'work:p1:u1:build_farm');
      expect(event.payload?['destinationProvinceId'], 'oldWorld|P2');
      expect(event.payload?['destinationTileKey'], 'oldWorld|P2|2|2');
    });

    test('full pipeline build_work phase includes work order trace events', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeEngineer,
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              'oldWorld|P1': ['oldWorld|P1|0|0'],
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
              targetTileKey: 'oldWorld|P1|0|0',
            ),
          ],
        },
      );
      final traces = <TurnTracePhaseTrace>[];
      final runtime = TurnTraceRuntime();
      resolveTurnForGameWithConfig(
        game: game,
        config: TurnResolverConfig(
          topology: topology,
          orders: orders,
          onTurnTracePhase: traces.add,
          turnTraceRuntime: runtime,
        ),
      );

      final buildWorkTrace = traces.firstWhere(
        (t) => t.phaseId == TurnPhase.buildWork.name,
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
