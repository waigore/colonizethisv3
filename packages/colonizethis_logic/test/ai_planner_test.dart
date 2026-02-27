import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('isAiControlled', () {
    test('uses explicit aiControlByGpId when present', () {
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
        aiControlByGpId: const {'gp1': true},
      );

      expect(isAiControlled(game, 'gp1'), isTrue);
    });

    test('falls back to !isHuman when no explicit entry', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );

      expect(isAiControlled(game, 'gp1'), isFalse);
      expect(isAiControlled(game, 'gp2'), isTrue);
    });
  });

  group('generateOrdersForGame', () {
    MapTopology _simpleTopology() {
      return const MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );
    }

    Game _baseGame() {
      return Game(
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
              'oldWorld|P2|0|0': 'fogged',
            },
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI GP', isHuman: false),
          Player(id: 'gp2', displayName: 'Human GP', isHuman: true),
        ],
        globalGameSeed: 123,
        aiSeedByGpId: const {'gp1': 999},
      );
    }

    test('does not attack factions at peace or Minors without war', () {
      final game = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'minor1'),
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
              'oldWorld|P2|0|0': 'fogged',
            },
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI GP', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        globalGameSeed: 123,
        aiSeedByGpId: const {'gp1': 999},
      );

      final orders = generateOrdersForGame(game, _simpleTopology());
      final moves = orders.moveOrdersByPlayerId['gp1'] ?? const [];
      // AI should not emit attacks against Minor1 because there is no war relation.
      expect(
        moves.where((m) => m.destinationProvinceId == 'P2'),
        isEmpty,
      );
    });

    test('is deterministic for same game and seeds', () {
      final game = _baseGame();
      final topology = _simpleTopology();

      final o1 = generateOrdersForGame(game, topology);
      final o2 = generateOrdersForGame(game, topology);
      expect(o1, equals(o2));
    });

    test('generateOrdersForPlayer returns empty for human player', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: const [
            Province(id: 'P1', regionId: 'oldWorld', ownerId: 'gp1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
        ],
      );
      final orders = generateOrdersForPlayer(game, _simpleTopology(), 'gp1');
      expect(orders, equals(const Orders()));
    });

    test('generateOrdersForGameFullAI aggregates orders including naval and diplo', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: const [
              Unit(id: 'u1', type: 'grenadiers', ownerId: 'gp1', provinceId: 'P1'),
            ],
          ),
          newWorld: const RegionData(),
          fleets: const [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
            ),
          ],
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 1,
        aiSeedByGpId: const {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [],
      );
      final orders = generateOrdersForGameFullAI(game, topology);
      expect(orders.moveOrdersByPlayerId, isNotNull);
      expect(orders.buildUnitOrdersByPlayerId, isNotNull);
      expect(orders.researchOrdersByPlayerId, isNotNull);
      expect(orders.navalMoveOrdersByPlayerId, isNotNull);
      expect(orders.navalMissionOrdersByPlayerId, isNotNull);
      expect(orders.diplomaticOrdersByPlayerId, isNotNull);
      expect(
        orders.researchOrdersByPlayerId['gp1'],
        isNotEmpty,
        reason: 'full AI should produce at least research when no capital',
      );
    });

    test('generateOrdersForGameFullAI preserves naval mission orders from per-player AI', () {
      // Regression for gap #1: naval mission orders must be aggregated, not dropped.
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: const [
              Unit(id: 'u1', type: 'grenadiers', ownerId: 'gp1', provinceId: 'P1'),
            ],
          ),
          newWorld: const RegionData(),
          fleets: const [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
            ),
          ],
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 1,
        aiSeedByGpId: const {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [],
      );
      final singleOrders = generateOrdersForPlayerFullAI(game, topology, 'gp1');
      final gameOrders = generateOrdersForGameFullAI(game, topology);
      expect(
        gameOrders.navalMissionOrdersByPlayerId['gp1'],
        equals(singleOrders.navalMissionOrdersByPlayerId['gp1']),
        reason: 'full-AI aggregation must include naval mission orders (SPEC gap #1)',
      );
      expect(
        gameOrders.navalMoveOrdersByPlayerId['gp1'],
        equals(singleOrders.navalMoveOrdersByPlayerId['gp1']),
        reason: 'full-AI aggregation must include naval move orders',
      );
    });
  });
}

