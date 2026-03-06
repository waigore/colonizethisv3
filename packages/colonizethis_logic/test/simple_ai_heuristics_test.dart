import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
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
    test('returns empty Orders when player not in game', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
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
            units: const [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                provinceId: 'oldWorld|P1',
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
            units: const [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                provinceId: '$ow|P1',
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
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor', capitalProvinceId: 'M1'),
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
        expect(m.destinationProvinceId, isNot('$ow|M1'),
            reason: 'move to Minor province should be filtered when no relation');
      }
    });

    test('filters out move to province of faction at peace (diplomacy filter)', () {
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
            units: const [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                provinceId: '$ow|P1',
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
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
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
        expect(m.destinationProvinceId, isNot('$ow|P2'),
            reason: 'move to gp2 province should be filtered when at peace');
      }
    });

    test('can generate research order when only research suggestions available', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'gp1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'AI',
            isHuman: false,
            capitalProvinceId: 'oldWorld|P1',
            capitalTile: CapitalTile(regionId: ow, provinceId: 'P1', x: 0, y: 0),
          ),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: {'gp1': 123},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );
      expect(orders.researchOrdersByPlayerId['gp1'], isNotNull);
    });

    test('can generate work order when only work suggestions available', () {
      const ow = 'oldWorld';
      const tileKey = '$ow|P1|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'gp1'),
            ],
            units: const [
              Unit(
                id: 'u1',
                type: 'Explorer',
                ownerId: 'gp1',
                provinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {tileKey: 'fogged'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {'$ow|P1': [tileKey]},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: const {'gp1': 1},
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );
      final works = orders.workOrdersByPlayerId['gp1'] ?? const [];
      expect(works, isNotEmpty);
    });

    test('can generate build order when only build suggestions available', () {
      const ow = 'oldWorld';
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'gp1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'AI',
            isHuman: false,
            capitalProvinceId: '$ow|P1',
            stockpile: stockpile,
            workerPool: const WorkerPool(peasants: 3),
            treasury: econ.buildTreasuryCost + 100,
          ),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: const {'gp1': 7},
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );
      final builds = orders.buildUnitOrdersByPlayerId['gp1'] ?? const [];
      expect(builds, isNotEmpty);
    });

    test('diplomacy filter works when Province has local id (full id used for lookup)', () {
      // Game state may store Province.id as local id (e.g. P2). Order suggestion
      // emits full province id (oldWorld|P2). Owner map must key by full id.
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'P2', regionId: ow, ownerId: 'gp2'),
            ],
            units: const [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                provinceId: '$ow|P1',
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
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
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
        expect(m.destinationProvinceId, isNot('$ow|P2'),
            reason: 'owner lookup by full id must drop move to GP at peace');
      }
    });

    test('does not mutate game', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: ow, ownerId: 'gp1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final turnBefore = game.worldState.turnState.turnNumber;
      final playersLengthBefore = game.players.length;
      generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );
      expect(game.worldState.turnState.turnNumber, equals(turnBefore));
      expect(game.players.length, equals(playersLengthBefore));
    });

    test('includes newWorld provinces in province owner map', () {
      const nw = 'newWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: '$nw|N1', regionId: nw, ownerId: 'gp1'),
            ],
            units: const [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                provinceId: '$nw|N1',
              ),
            ],
          ),
          playerVisibilityByTile: const {
            'gp1': {'newWorld|N1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'N1', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );
      expect(orders, isNotNull);
      expect(orders.diplomaticOrdersByPlayerId, isEmpty);
    });
  });
}
