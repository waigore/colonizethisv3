import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('turnSeedForPlayer', () {
    test('uses aiSeedByGpId when present', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
        ],
        globalGameSeed: 100,
        aiSeedByGpId: {'gp1': 999},
      );

      final seed = turnSeedForPlayer(game, 'gp1', 5);
      expect(seed, isNonZero);
      final seedAgain = turnSeedForPlayer(game, 'gp1', 5);
      expect(seed, equals(seedAgain));
    });

    test('uses fallbackAiSeed when aiSeedByGpId missing for player', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        ],
        globalGameSeed: 50,
      );

      final seedWithFallback = turnSeedForPlayer(game, 'gp1', 1, fallbackAiSeed: 777);
      expect(seedWithFallback, isNonZero);
      final seedWithoutFallback = turnSeedForPlayer(game, 'gp1', 1);
      expect(seedWithoutFallback, isNonZero);
      expect(seedWithFallback, equals(turnSeedForPlayer(game, 'gp1', 1, fallbackAiSeed: 777)));
    });

    test('different turn or player produces different seed', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: {'gp1': 1, 'gp2': 2},
      );

      final s1 = turnSeedForPlayer(game, 'gp1', 1);
      final s2 = turnSeedForPlayer(game, 'gp1', 2);
      final s3 = turnSeedForPlayer(game, 'gp2', 1);
      expect(s1, isNot(equals(s2)));
      expect(s1, isNot(equals(s3)));
    });
  });

  group('generateOrdersWithSimpleHeuristics', () {
    test('returns only valid orders for player', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'gp2'),
            ],
            units: const [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                provinceId: 'P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
          Player(id: 'gp2', displayName: 'Other', isHuman: true),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: {'gp1': 42},
      );

      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );

      expect(orders.moveOrdersByPlayerId['gp1'], isNotNull);
      for (final m in orders.moveOrdersByPlayerId['gp1']!) {
        expect(m.unitId, equals('u1'));
        expect(m.destinationProvinceId, anyOf('oldWorld|P1', 'oldWorld|P2'));
      }
    });

  });
}
