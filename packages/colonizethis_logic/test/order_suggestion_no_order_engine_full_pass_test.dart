import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('Suggestion enumeration skips OrderEngine full-pass (Refs #2237)', () {
    tearDown(() {
      setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(false);
    });

    test('suggestBuildOrders does not invoke validatePlayerOrdersWithContext', () {
      setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(true);

      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        capitalProvinceId: '$ow|p1',
        workerPool: const WorkerPool(peasants: 2),
        treasury: 500,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
          units: const [],
        ),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );
      final view = buildPlayerView(game, topology, playerId);

      suggestBuildOrders(view, game, topology, const Orders());

      expect(
        orderEngineValidatePlayerOrdersWithContextInvocationCountForTests,
        0,
        reason:
            'Build suggestions must use incremental candidate validation, not '
            'OrderEngine full-pass per candidate (Refs #2237 AC2).',
      );
    });

    test('OrderEngine add-with-context still invokes full validation', () {
      setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(true);

      const playerId = 'p1';
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: playerId),
              Province(id: '$ow|P2', regionId: ow, ownerId: playerId),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeBuilder,
                ownerId: playerId,
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [Player(id: playerId, displayName: 'P1', isHuman: true)],
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
        ],
        edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
      );

      final engine = OrderEngine();
      engine.addMoveOrderWithContext(
        game,
        topology,
        playerId,
        const MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0'),
      );

      expect(
        orderEngineValidatePlayerOrdersWithContextInvocationCountForTests,
        greaterThan(0),
      );
    });
  });
}
