import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

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
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
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
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
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
}
