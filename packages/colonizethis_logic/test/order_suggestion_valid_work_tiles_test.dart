import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
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
