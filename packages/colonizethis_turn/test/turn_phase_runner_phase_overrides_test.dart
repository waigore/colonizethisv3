import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

void main() {
  test(
    'resolveTurnForGameWithConfig merges phaseHandlerOverrides over defaults',
    () {
      var customOrdersPhaseRuns = 0;
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );

      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        turnNumber: 0,
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'Regiment',
              ownerId: 'p1',
              locationProvinceId: '$ow|P1',
            ),
          ],
        ),
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0')],
        },
      );

      final result = resolveTurnForGameWithConfig(
        game: game,
        config: TurnResolverConfig(
          topology: topology,
          orders: orders,
          extractedByPlayerId: const {
            'p1': {'grain': 3},
          },
          defaultAssignments: const [],
          phaseHandlerOverrides: {
            TurnPhase.orders: (acc, config, turn) {
              customOrdersPhaseRuns++;
              return TurnPhaseStepContinue(acc);
            },
          },
        ),
      );

      expect(customOrdersPhaseRuns, 1);
      final next = requireTurnResolutionComplete(result);
      expect(next.worldState.turnState.turnNumber, 1);
      expect(
        next.worldState.oldWorld.units.single.locationProvinceId,
        'oldWorld|P2',
      );
    },
  );

  test('phase progress callback emits start and end markers', () {
    final topology = MapTopology(
      nodes: const [
        TopologyNode(
          id: 'P1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: const [],
    );
    final game = TestFixtures.minimalGame(
      id: 'g1',
      turnNumber: 0,
      players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      oldWorld: RegionData(
        provinces: [Province(id: 'oldWorld|P1', regionId: 'oldWorld')],
      ),
    );
    final events = <(TurnPhase, TurnPhaseProgressMarker)>[];
    resolveTurnForGameWithConfig(
      game: game,
      config: TurnResolverConfig(
        topology: topology,
        orders: const Orders(),
        onPhaseProgress: (phase, marker) => events.add((phase, marker)),
      ),
    );

    expect(events.isNotEmpty, isTrue);
    expect(events.first.$2, TurnPhaseProgressMarker.start);
    expect(events.last.$2, TurnPhaseProgressMarker.end);
  });

  test('phase trace callback emits before and after snapshots per phase', () {
    final topology = MapTopology(
      nodes: const [
        TopologyNode(
          id: 'P1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: const [],
    );
    final game = TestFixtures.minimalGame(
      id: 'g1',
      turnNumber: 0,
      players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      oldWorld: RegionData(
        provinces: [Province(id: 'oldWorld|P1', regionId: 'oldWorld')],
      ),
    );
    final traces = <TurnTracePhaseTrace>[];

    resolveTurnForGameWithConfig(
      game: game,
      config: TurnResolverConfig(
        topology: topology,
        orders: const Orders(),
        onTurnTracePhase: traces.add,
      ),
    );

    expect(traces, isNotEmpty);
    expect(traces.first.phaseId, TurnPhase.orders.name);
    expect(traces.first.beforeState, isNotEmpty);
    expect(traces.first.afterState, isNotEmpty);
    expect(traces.first.orderEvents, isEmpty);
    expect(traces.last.phaseId, TurnPhase.endOfTurn.name);
    expect(traces.last.afterState['worldState'], isA<Map<String, dynamic>>());
  });
}
