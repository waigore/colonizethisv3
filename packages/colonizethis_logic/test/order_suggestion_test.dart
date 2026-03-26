import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Order suggestion', () {
    test('suggestMoveOrders only returns moves that pass validation', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'Test GP',
        isHuman: false,
      );

      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final p2 = Province(id: '$ow|p2', regionId: ow);

      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p1|0|0': 'fullyVisible',
            'oldWorld|p2|0|0': 'fogged',
          },
        },
      );

      final game = Game(id: 'g1', worldState: world, players: [player]);

      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
      );

      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestMoveOrders(
        view,
        game,
        topology,
        const Orders(),
      );

      expect(suggestions.length, 1);
      expect(suggestions.first.unitId, 'u1');
      expect(suggestions.first.destinationProvinceId, 'oldWorld|p2');
    });

    test(
      'suggestMoveOrders throws when source province has unknown visibility',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = const Player(
          id: playerId,
          displayName: 'Test GP',
          isHuman: false,
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
        final unit = Unit(
          id: 'u1',
          type: 'Explorer',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
        );
        // No visibility for p1: source province unknown → game raises.
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
          newWorld: const RegionData(),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
        );
        final view = buildPlayerView(game, topology, playerId);
        expect(
          () => suggestMoveOrders(view, game, topology, const Orders()),
          throwsStateError,
        );
      },
    );

    test(
      'move suggestions use unit locationProvinceId (tileKey-derived for civilians)',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = const Player(
          id: playerId,
          displayName: 'Test GP',
          isHuman: false,
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
        final p3 = Province(id: '$ow|p3', regionId: ow, ownerId: playerId);
        // Civilian in p2 by tileKey; provinceId can differ (e.g. legacy). Source = locationProvinceId = p2.
        final unit = Unit(
          id: 'u1',
          type: 'Explorer',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: 'oldWorld|p2|0|0',
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1, p2, p3], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|p2|0|0': 'fullyVisible',
              'oldWorld|p3|0|0': 'fogged',
            },
          },
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
        // p2 adjacent to p3 only (so suggested moves are from p2 → p3, not from p1).
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p3',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p2', id2: 'p3')],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestMoveOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(suggestions.length, 1);
        expect(suggestions.first.unitId, 'u1');
        expect(suggestions.first.destinationProvinceId, 'oldWorld|p3');
        // Move is from p2 (unit's location province), not p1. Unit with tileKey uses compound id.
        expect(view.ownUnitsById['u1']!.locationProvinceId, 'oldWorld|p2');
      },
    );

    test('no explore suggestion when province unknown', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );
      // No visibility: p1 unknown, so explore not suggested.
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions.where((o) => o.target == 'explore'), isEmpty);
    });

    test('no prospect suggestion when province not at least fogged', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: 'tribe1');
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );
      // p1 only revealed (not fogged) — prospect requires fogged or better.
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {'oldWorld|p1|0|0': 'revealed'},
        },
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions.where((o) => o.target == 'prospect'), isEmpty);
    });

    test('prospect suggestion when province fogged and tiles in province', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );
      const tileKey = 'oldWorld|p1|0|0';
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {tileKey: 'fogged'},
        },
        resourceByTileKey: const {tileKey: 'iron'},
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': [tileKey],
          },
        },
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions.where((o) => o.target == 'prospect'), isNotEmpty);
      expect(
        suggestions.firstWhere((o) => o.target == 'prospect').targetTileKey,
        tileKey,
      );
    });

    test('work suggestions for worker use unit id; targets may be any valid tile', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 500,
        stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {'oldWorld|p1|0|0': 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': ['oldWorld|p1|0|0'],
          },
        },
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      // All suggested work orders are for u1, which is in p1; no order targets another province.
      for (final o in suggestions) {
        expect(o.unitId, 'u1');
        final u = view.ownUnitsById[o.unitId];
        expect(u, isNotNull);
        expect(u!.locationProvinceId, 'oldWorld|p1');
      }
    });

    test(
      'suggestWorkOrders includes build_improvement when first province tile '
      'has no resource but a later tile does',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const tileNoResource = 'oldWorld|p1|0|0';
        const tileWithResource = 'oldWorld|p1|1|0';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final unit = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileNoResource,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {
              tileNoResource: 'fullyVisible',
              tileWithResource: 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [tileNoResource, tileWithResource],
            },
          },
          resourceByTileKey: {tileWithResource: 'grain'},
          tileState: TileMapState(improvementByTile: {tileWithResource: 0}),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final buildImp = suggestions.where((o) => o.target == 'build_improvement');
        expect(buildImp, isNotEmpty);
        expect(
          buildImp.first.targetTileKey,
          tileWithResource,
          reason: 'should pick first valid tile, not the empty-resource tile',
        );
      },
    );

    test(
      'suggestWorkOrders includes build_improvement on another owned province '
      'when the builder’s province has no valid resource tile',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const tileP1 = 'oldWorld|p1|0|0';
        const tileP2 = 'oldWorld|p2|0|0';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
        final unit = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileP1,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {tileP1: 'fullyVisible', tileP2: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [tileP1],
              '$ow|p2': [tileP2],
            },
          },
          resourceByTileKey: {tileP2: 'grain'},
          tileState: TileMapState(improvementByTile: {tileP2: 0}),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final buildImp = suggestions.where((o) => o.target == 'build_improvement');
        expect(buildImp, isNotEmpty);
        expect(buildImp.first.targetTileKey, tileP2);
      },
    );

    test(
      'suggestWorkOrders second Builder skips tile reserved by another Builder '
      'pending work order',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const tileA = 'oldWorld|p1|0|0';
        const tileB = 'oldWorld|p1|1|0';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final b1 = Unit(
          id: 'b1',
          type: 'Builder',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileA,
        );
        final b2 = Unit(
          id: 'b2',
          type: 'Builder',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileA,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [b1, b2]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [tileA, tileB],
            },
          },
          resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
          tileState: TileMapState(
            improvementByTile: {tileA: 0, tileB: 0},
          ),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final orders = Orders(
          workOrdersByPlayerId: {
            playerId: [
              WorkOrder(
                unitId: 'b1',
                target: 'build_improvement',
                targetTileKey: tileA,
              ),
            ],
          },
        );
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          orders,
        );
        final b2Build = suggestions
            .where((o) => o.unitId == 'b2' && o.target == 'build_improvement')
            .toList();
        expect(b2Build, isNotEmpty);
        expect(b2Build.first.targetTileKey, tileB);
      },
    );

    test(
      'getValidWorkOrderTileKeysWithVisibility excludes tile reserved by '
      'another unit pending order',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const tileA = 'oldWorld|p1|0|0';
        const tileB = 'oldWorld|p1|1|0';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final b1 = Unit(
          id: 'b1',
          type: 'Builder',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileA,
        );
        final b2 = Unit(
          id: 'b2',
          type: 'Builder',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileA,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [b1, b2]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [tileA, tileB],
            },
          },
          resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
          tileState: TileMapState(
            improvementByTile: {tileA: 0, tileB: 0},
          ),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
        final topology = const MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, playerId);
        final orders = Orders(
          workOrdersByPlayerId: {
            playerId: [
              WorkOrder(
                unitId: 'b1',
                target: 'build_improvement',
                targetTileKey: tileA,
              ),
            ],
          },
        );
        final validB2 = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'b2',
          workTarget: 'build_improvement',
          currentOrders: orders,
        );
        expect(validB2, isNot(contains(tileA)));
        expect(validB2, contains(tileB));
      },
    );

    test('suggestBuildOrders returns list', () {
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
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestBuildOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions, isA<List<BuildUnitOrder>>());
    });

    test('suggestBuildOrders returns ship when affordable', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final affordableShipTreasury =
          ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost;
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 2)
          .applyDelta(CommodityCatalog.fabric.id, 2);
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        capitalProvinceId: '$ow|p1',
        workerPool: const WorkerPool(peasants: 1),
        treasury: affordableShipTreasury,
        stockpile: stockpile,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestBuildOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final shipTypes = suggestions
          .where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType))
          .toList();
      expect(
        shipTypes,
        isNotEmpty,
        reason:
            'suggestBuildOrders should include ships when player has capital, treasury and stockpile for fluyte/carrack',
      );
    });

    test(
      'suggestBuildOrders can return both regiment and ship when both affordable',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final affordableBothTreasury =
            ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost + 1000;
        final stockpile = const Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 5)
            .applyDelta(CommodityCatalog.fabric.id, 5)
            .applyDelta(CommodityCatalog.castIron.id, 5);
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          capitalProvinceId: '$ow|p1',
          workerPool: const WorkerPool(peasants: 2, apprentices: 1),
          treasury: affordableBothTreasury,
          stockpile: stockpile,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestBuildOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final hasRegiment = suggestions.any(
          (o) => RegimentEconomyCatalog.byId.containsKey(o.unitType),
        );
        final hasShip = suggestions.any(
          (o) => ShipEconomyCatalog.byId.containsKey(o.unitType),
        );
        expect(
          hasRegiment,
          isTrue,
          reason: 'should suggest regiments when affordable',
        );
        expect(hasShip, isTrue, reason: 'should suggest ships when affordable');
      },
    );

    test('suggestResearchOrders returns list', () {
      const playerId = 'gp1';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 1000,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(nodes: const [], edges: const []);
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestResearchOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions, isA<List<ResearchOrder>>());
    });

    test('suggestNavalMoveOrders returns list', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        fleets: [
          Fleet(
            id: 'fleet_gp1',
            ownerId: playerId,
            seaZoneId: 'sea1',
            regionId: ow,
            shipTypeIds: ['fluyte'],
          ),
        ],
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestNavalMoveOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions, isA<List<NavalMoveOrder>>());
    });

    test('counter_spy work suggested for Spy in owned province with tiles', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      const tileKey = 'oldWorld|p1|0|0';
      final unit = Unit(
        id: 'u1',
        type: 'Spy',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {tileKey: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': [tileKey],
          },
        },
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions.where((o) => o.target == 'counter_spy'), isNotEmpty);
    });

    test(
      'purchase_land work suggested for Merchant when minor province has resource tile',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );
        final ownProvince = Province(
          id: '$ow|p1',
          regionId: ow,
          ownerId: playerId,
        );
        final minorProvince = Province(
          id: '$ow|minor1',
          regionId: ow,
          ownerId: 'minor1',
        );
        const tileKey = 'oldWorld|minor1|0|0';
        final unit = Unit(
          id: 'u1',
          type: 'Merchant',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [ownProvince, minorProvince],
            units: [unit],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|p1|0|0': 'fullyVisible',
              tileKey: 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
              '$ow|minor1': [tileKey],
            },
          },
          resourceByTileKey: {tileKey: 'grain'},
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'minor1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          suggestions.where((o) => o.target == 'purchase_land'),
          isNotEmpty,
        );
      },
    );

    test('suggestNavalMissionOrders returns list', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        fleets: [
          Fleet(
            id: 'fleet_gp1',
            ownerId: playerId,
            seaZoneId: 'sea1',
            regionId: ow,
            shipTypeIds: ['fluyte'],
          ),
        ],
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestNavalMissionOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions, isA<List<NavalMissionOrder>>());
    });
  });

  group('filterMoveOrdersByDiplomacy and getProvinceOwnerMap', () {
    test('getProvinceOwnerMap returns owner by full province id', () {
      const ow = 'oldWorld';
      final p1 = Province(id: 'p1', regionId: ow, ownerId: 'gp1');
      final p2 = Province(id: 'p2', regionId: ow, ownerId: 'gp2');
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1, p2], units: []),
        newWorld: const RegionData(),
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
      );
      final map = getProvinceOwnerMap(game);
      expect(map['oldWorld|p1'], 'gp1');
      expect(map['oldWorld|p2'], 'gp2');
    });

    test('getProvinceOwnerMap includes newWorld provinces', () {
      const nw = 'newWorld';
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: RegionData(
          provinces: [
            Province(id: 'newWorld|n1', regionId: nw, ownerId: 'gp1'),
            Province(id: 'newWorld|n2', regionId: nw, ownerId: 'gp2'),
          ],
          units: [],
        ),
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
      );
      final map = getProvinceOwnerMap(game);
      expect(map['newWorld|n1'], 'gp1');
      expect(map['newWorld|n2'], 'gp2');
    });

    test('filterMoveOrdersByDiplomacy drops move to at-peace faction', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = [
        MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|p2'),
      ];
      final filtered = filterMoveOrdersByDiplomacy(game, 'gp1', orders);
      expect(
        filtered,
        isEmpty,
        reason: 'move to gp2 at peace should be dropped',
      );
    });

    test('filterMoveOrdersByDiplomacy keeps move to at-war faction', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 0,
            state: RelationState.atWar,
          ),
        ],
      );
      final orders = [
        MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|p2'),
      ];
      final filtered = filterMoveOrdersByDiplomacy(game, 'gp1', orders);
      expect(filtered.length, 1);
      expect(filtered.first.destinationProvinceId, 'oldWorld|p2');
    });
  });

  group('getValidWorkOrderTileKeys', () {
    test('returns empty for unknown unit id', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final valid = getValidWorkOrderTileKeys(
        game,
        topology,
        playerId,
        'no-such-unit',
        'explore',
        const Orders(),
      );
      expect(valid, isEmpty);
    });

    test('returns empty when workTarget not allowed for unit type', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final valid = getValidWorkOrderTileKeys(
        game,
        topology,
        playerId,
        'u1',
        'build_improvement',
        const Orders(),
      );
      expect(valid, isEmpty);
    });

    test('returns empty for unknown unit id with visibility', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, playerId);
      final valid = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'no-such-unit',
        workTarget: 'explore',
        currentOrders: const Orders(),
      );
      expect(valid, isEmpty);
    });

    test(
      'returns empty when workTarget not allowed for unit type with visibility',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final unit = Unit(
          id: 'u1',
          type: 'Explorer',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: 'oldWorld|p1|0|0',
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                '$ow|p1': ['oldWorld|p1|0|0'],
              },
            },
          ),
          players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
        );
        final topology = const MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, playerId);
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: 'build_improvement',
          currentOrders: const Orders(),
        );
        expect(valid, isEmpty);
      },
    );

    test('filters by visibility before order engine validation', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final unit = Unit(
        id: 'u1',
        type: 'Colonist',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
              '$ow|p2': ['oldWorld|p2|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
      );
      final topology = const MapTopology(nodes: [], edges: []);

      final viewWithFullVisibility = buildPlayerView(game, topology, playerId);

      final validWithVisibility = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: viewWithFullVisibility,
        unitId: 'u1',
        workTarget: 'build_improvement',
        currentOrders: const Orders(),
      );

      final validWithoutVisibility = getValidWorkOrderTileKeys(
        game,
        topology,
        playerId,
        'u1',
        'build_improvement',
        const Orders(),
      );

      expect(validWithVisibility.length, validWithoutVisibility.length);
    });

    test('build_improvement returns only controlled tiles with resources', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const tileWithResource = 'oldWorld|p1|0|0';
      const tileWithoutResource = 'oldWorld|p1|1|0';
      const foreignTileWithResource = 'oldWorld|p2|0|0';

      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: tileWithResource,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'other'),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [tileWithResource, tileWithoutResource],
              '$ow|p2': [foreignTileWithResource],
            },
          },
          resourceByTileKey: {
            tileWithResource: 'grain',
            foreignTileWithResource: 'iron',
          },
          // Set up visibility for the player's provinces (fully visible)
          playerVisibilityByTile: {
            playerId: {
              tileWithResource: 'fullyVisible',
              tileWithoutResource: 'fullyVisible',
              foreignTileWithResource: 'fullyVisible',
            },
          },
          // Set up tile state with improvement level for the tile
          tileState: TileMapState(improvementByTile: {tileWithResource: 0}),
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            // Need lumber and cast iron for build_improvement
            stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
          ),
          Player(id: 'other', displayName: 'Other', isHuman: false),
        ],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, playerId);

      final valid = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'u1',
        workTarget: 'build_improvement',
        currentOrders: const Orders(),
      );

      // Only tileWithResource (owned province, has resource) should be valid
      expect(valid.contains(tileWithResource), isTrue);
      // tileWithoutResource has no resource
      expect(valid.contains(tileWithoutResource), isFalse);
      // foreignTileWithResource is in unowned province
      expect(valid.contains(foreignTileWithResource), isFalse);
    });

    test('build_improvement includes purchased tiles with resources', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const purchasedTileWithResource = 'oldWorld|p2|0|0';
      const unpurchasedTileWithResource = 'oldWorld|p2|1|0';

      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'minor1'),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
              '$ow|p2': [
                purchasedTileWithResource,
                unpurchasedTileWithResource,
              ],
            },
          },
          resourceByTileKey: {
            purchasedTileWithResource: 'grain',
            unpurchasedTileWithResource: 'grain',
          },
          purchasedTilesByTileKey: {
            purchasedTileWithResource: playerId,
            // unpurchasedTileWithResource not purchased
          },
          playerVisibilityByTile: {
            playerId: {
              'oldWorld|p1|0|0': 'fullyVisible',
              purchasedTileWithResource: 'fullyVisible',
              unpurchasedTileWithResource: 'fullyVisible',
            },
          },
          tileState: TileMapState(
            improvementByTile: {purchasedTileWithResource: 0},
          ),
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
          ),
        ],
        minorNations: [MinorNation(id: 'minor1', displayName: 'Minor')],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, playerId);

      final valid = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'u1',
        workTarget: 'build_improvement',
        currentOrders: const Orders(),
      );

      // Purchased tile should be valid
      expect(valid.contains(purchasedTileWithResource), isTrue);
      // Unpurchased tile should not be valid
      expect(valid.contains(unpurchasedTileWithResource), isFalse);
    });

    test('build_improvement excludes sea zone tiles', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const landTile = 'oldWorld|p1|0|0';
      // Sea zone tiles use just the sea zone id as province key (not prefixed)
      const seaZoneId = 's1';

      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: landTile,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [landTile],
              // Sea zone uses non-prefixed id
              seaZoneId: ['$ow|$seaZoneId|0|0'],
            },
          },
          resourceByTileKey: {
            landTile: 'grain',
            '$ow|$seaZoneId|0|0': 'fish', // Hypothetical sea resource
          },
          playerVisibilityByTile: {
            playerId: {
              landTile: 'fullyVisible',
              '$ow|$seaZoneId|0|0': 'fullyVisible',
            },
          },
          tileState: TileMapState(improvementByTile: {landTile: 0}),
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
          ),
        ],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, playerId);

      final valid = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'u1',
        workTarget: 'build_improvement',
        currentOrders: const Orders(),
      );

      // Only land tile should be valid
      expect(valid.contains(landTile), isTrue);
      // Sea zone tile should be excluded even if it has resource
      expect(valid.contains('$ow|$seaZoneId|0|0'), isFalse);
    });

    test(
      'getValidWorkOrderTileKeysWithVisibility prospect excludes non-mineral '
      'and already prospected',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const provinceId = '$ow|p1';
        const grassTile = 'oldWorld|p1|0|0';
        const ironTile = 'oldWorld|p1|1|0';
        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final tribe = const Tribe(id: 'tribe1', displayName: 'T');
        final p1 = Province(id: provinceId, regionId: ow, ownerId: 'tribe1');
        final unit = Unit(
          id: 'u1',
          type: 'Explorer',
          ownerId: playerId,
          locationProvinceId: provinceId,
          tileKey: grassTile,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              grassTile: 'fogged',
              ironTile: 'fogged',
            },
          },
          resourceByTileKey: const {
            grassTile: 'grain',
            ironTile: 'iron',
          },
          playerProspectedTiles: const {
            playerId: {ironTile},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              provinceId: [grassTile, ironTile],
            },
          },
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          tribes: [tribe],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: 'prospect',
          currentOrders: const Orders(),
        );
        expect(valid.contains(grassTile), isFalse);
        expect(valid.contains(ironTile), isFalse);
      },
    );

    test(
      'getValidWorkOrderTileKeysWithVisibility prospect includes eligible tile',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const provinceId = '$ow|p1';
        const ironTile = 'oldWorld|p1|0|0';
        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final tribe = const Tribe(id: 'tribe1', displayName: 'T');
        final p1 = Province(id: provinceId, regionId: ow, ownerId: 'tribe1');
        final unit = Unit(
          id: 'u1',
          type: 'Explorer',
          ownerId: playerId,
          locationProvinceId: provinceId,
          tileKey: ironTile,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {ironTile: 'fogged'},
          },
          resourceByTileKey: const {ironTile: 'iron'},
          tileKeysByRegionAndProvince: {
            ow: {
              provinceId: [ironTile],
            },
          },
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          tribes: [tribe],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: 'prospect',
          currentOrders: const Orders(),
        );
        expect(valid, contains(ironTile));
      },
    );

    test('suggestMoveOrders excludes moves to other Great Power provinces', () {
      const playerId = 'gp1';
      const otherGpId = 'gp2';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'Test GP',
        isHuman: false,
      );
      final otherGp = const Player(
        id: otherGpId,
        displayName: 'Other GP',
        isHuman: false,
      );

      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: otherGpId);

      // Civilian unit (Builder) - cannot enter other GP territory
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p1|0|0': 'fullyVisible',
            'oldWorld|p2|0|0': 'fullyVisible',
          },
        },
      );

      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player, otherGp],
      );

      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
      );

      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestMoveOrders(
        view,
        game,
        topology,
        const Orders(),
      );

      // Builder should NOT get a move suggestion to p2 (other GP's province)
      expect(
        suggestions.where((m) => m.destinationProvinceId == 'oldWorld|p2'),
        isEmpty,
      );
    });

    test('suggestWorkOrders suggests steal_tech for Spy in foreign capital', () {
      const playerId = 'gp1';
      const otherGpId = 'gp2';
      const ow = 'oldWorld';

      final player = Player(
        id: playerId,
        displayName: 'GP1',
        isHuman: false,
        techUnlocked: {}, // No tech
      );
      final otherGp = Player(
        id: otherGpId,
        displayName: 'GP2',
        isHuman: false,
        capitalProvinceId: '$ow|gp2_cap',
        techUnlocked: {'some_tech': true}, // Has tech that GP1 lacks
      );

      final spyProvince = Province(
        id: '$ow|spy_loc',
        regionId: ow,
        ownerId: playerId,
      );
      final otherGpCapital = Province(
        id: '$ow|gp2_cap',
        regionId: ow,
        ownerId: otherGpId,
      );

      final spy = Unit(
        id: 'spy1',
        type: 'Spy',
        ownerId: playerId,
        locationProvinceId: '$ow|spy_loc',
        tileKey: 'oldWorld|spy_loc|0|0',
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [spyProvince, otherGpCapital],
          units: [spy],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|spy_loc|0|0': 'fullyVisible',
            'oldWorld|gp2_cap|0|0': 'fullyVisible',
          },
        },
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|spy_loc': ['oldWorld|spy_loc|0|0'],
            '$ow|gp2_cap': ['oldWorld|gp2_cap|0|0'],
          },
        },
      );

      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player, otherGp],
      );

      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'spy_loc',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'gp2_cap',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );

      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );

      // Spy should have steal_tech work order suggested targeting other GP's capital
      expect(suggestions.where((o) => o.target == 'steal_tech'), isNotEmpty);
    });

    test(
      'suggestWorkOrders sorts by targetTileKey when unitId and target match',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';

        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );

        // Province with multiple resource tiles for same work target
        final province = Province(
          id: '$ow|p1',
          regionId: ow,
          ownerId: playerId,
        );

        final builder = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: 'oldWorld|p1|0|0',
        );

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [province], units: [builder]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|p1|0|0': 'fullyVisible',
              'oldWorld|p1|1|0': 'fullyVisible',
              'oldWorld|p1|2|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [
                'oldWorld|p1|0|0',
                'oldWorld|p1|1|0',
                'oldWorld|p1|2|0',
              ],
            },
          },
          resourceByTileKey: {
            'oldWorld|p1|0|0': 'grain',
            'oldWorld|p1|1|0': 'grain',
            'oldWorld|p1|2|0': 'grain',
          },
          tileState: TileMapState(
            improvementByTile: {
              'oldWorld|p1|0|0': 0,
              'oldWorld|p1|1|0': 0,
              'oldWorld|p1|2|0': 0,
            },
          ),
        );

        final game = Game(id: 'g1', worldState: world, players: [player]);

        final topology = const MapTopology(
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
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );

        // Should have multiple build_improvement suggestions for different tiles
        final buildSuggestions = suggestions
            .where((o) => o.target == 'build_improvement')
            .toList();

        // If multiple tiles are suggested, they should be sorted by targetTileKey
        if (buildSuggestions.length > 1) {
          for (int i = 0; i < buildSuggestions.length - 1; i++) {
            expect(
              buildSuggestions[i].targetTileKey.compareTo(
                buildSuggestions[i + 1].targetTileKey,
              ),
              lessThanOrEqualTo(0),
            );
          }
        }
      },
    );

    test(
      'suggestWorkOrders excludes targets from existing work orders for same unit',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';

        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );

        final province = Province(
          id: '$ow|p1',
          regionId: ow,
          ownerId: playerId,
        );

        final builder = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: 'oldWorld|p1|0|0',
        );

        // Existing work order for build_improvement
        final existingOrder = WorkOrder(
          unitId: 'u1',
          target: 'build_improvement',
          targetTileKey: 'oldWorld|p1|0|0',
        );

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [province], units: [builder]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|p1|0|0': 'fullyVisible',
              'oldWorld|p1|1|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
            },
          },
          resourceByTileKey: {
            'oldWorld|p1|0|0': 'grain',
            'oldWorld|p1|1|0': 'grain',
          },
          tileState: TileMapState(
            improvementByTile: {'oldWorld|p1|0|0': 0, 'oldWorld|p1|1|0': 0},
          ),
        );

        final game = Game(id: 'g1', worldState: world, players: [player]);

        final topology = const MapTopology(
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
        final currentOrders = Orders(
          workOrdersByPlayerId: {
            playerId: [existingOrder],
          },
        );
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          currentOrders,
        );

        // Should not suggest build_improvement for the tile that already has a work order
        final buildSuggestions = suggestions
            .where(
              (o) =>
                  o.target == 'build_improvement' &&
                  o.targetTileKey == 'oldWorld|p1|0|0',
            )
            .toList();

        expect(buildSuggestions, isEmpty);
      },
    );
  });
}
