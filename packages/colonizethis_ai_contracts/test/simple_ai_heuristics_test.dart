import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/src/ai/simple_ai_heuristics.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
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
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        globalGameSeed: 50,
      );

      final seedWithFallback = turnSeedForPlayer(
        game,
        'gp1',
        1,
        fallbackAiSeed: 777,
      );
      expect(seedWithFallback, isNonZero);
      final seedWithoutFallback = turnSeedForPlayer(game, 'gp1', 1);
      expect(seedWithoutFallback, isNonZero);
      expect(
        seedWithFallback,
        equals(turnSeedForPlayer(game, 'gp1', 1, fallbackAiSeed: 777)),
      );
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
    test('returns empty Orders when player not in game', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'AI', isHuman: false)],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'nonexistent',
        12345,
      );
      expect(orders.moveOrdersByPlayerId, isEmpty);
      expect(orders.workOrdersByPlayerId, isEmpty);
      expect(orders.buildUnitOrdersByPlayerId, isEmpty);
      expect(orders.researchOrdersByPlayerId, isEmpty);
    });

    test('returns only valid orders for player', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'gp2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|P1',
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
        // At war so that attacking move into gp2 province is rules-legal
        // per SPEC/game/diplomacy.md and OrderEngine movement validation.
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atWar,
          ),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: {'gp1': 42},
      );

      const topology = MapTopology(
        nodes: [
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
        edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
      );

      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );

      expect(orders.armyMoveOrdersByPlayerId['gp1'], isNotNull);
      for (final m in orders.armyMoveOrdersByPlayerId['gp1']!) {
        expect(m.armyId, contains('gp1'));
        expect(m.destinationProvinceId, anyOf('oldWorld|P1', 'oldWorld|P2'));
      }
    });

    test('filters out move to Minor nation province when no relation', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'gp1'),
              Province(id: '$ow|M1', regionId: ow, ownerId: 'minor1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|M1|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [Player(id: 'gp1', displayName: 'AI', isHuman: false)],
        minorNations: const [
          MinorNation(
            id: 'minor1',
            displayName: 'Minor',
            capitalProvinceId: 'M1',
          ),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: {'gp1': 42},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'M1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [TopologyEdge(id1: 'P1', id2: 'M1')],
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );
      final moves = orders.moveOrdersByPlayerId['gp1'] ?? [];
      for (final m in moves) {
        expect(
          Unit.provinceIdFromTileKey(m.destinationTileKey),
          isNot('$ow|M1'),
          reason: 'move to Minor province should be filtered when no relation',
        );
      }
    });

    test(
      'filters out move to province of faction at peace (diplomacy filter)',
      () {
        const ow = 'oldWorld';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'gp1'),
                Province(id: '$ow|P2', regionId: ow, ownerId: 'gp2'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'gp1',
                  locationProvinceId: '$ow|P1',
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
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              state: RelationState.atPeace,
            ),
          ],
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
        final orders = generateOrdersWithSimpleHeuristics(
          game,
          topology,
          'gp1',
          turnSeedForPlayer(game, 'gp1', 1),
        );
        final moves = orders.moveOrdersByPlayerId['gp1'] ?? [];
        for (final m in moves) {
          expect(
            Unit.provinceIdFromTileKey(m.destinationTileKey),
            isNot('$ow|P2'),
            reason:
                'validator/occupancy should not target gp2 for this fixture',
          );
        }
      },
    );

  });
}
