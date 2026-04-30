part of 'order_suggestion_valid_work_tiles_test.dart';

void _defineTests() {
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
        kWorkTargetExplore,
        const Orders(),
      );
      expect(valid, isEmpty);
    });

    test('returns empty when workTarget not allowed for unit type', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
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
        kWorkTargetBuildImprovement,
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
        workTarget: kWorkTargetExplore,
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
          type: kUnitTypeExplorer,
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
          workTarget: kWorkTargetBuildImprovement,
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
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );

      final validWithoutVisibility = getValidWorkOrderTileKeys(
        game,
        topology,
        playerId,
        'u1',
        kWorkTargetBuildImprovement,
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
        type: kUnitTypeBuilder,
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
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );

      // Only tileWithResource (owned province, has resource) should be valid
      expect(valid.contains(tileWithResource), isTrue);
      // tileWithoutResource has no resource
      expect(valid.contains(tileWithoutResource), isFalse);
      // foreignTileWithResource is in unowned province
      expect(valid.contains(foreignTileWithResource), isFalse);
    });

    test('build_improvement excludes owned mineral tile until prospected; '
        'includes after prospected', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const grainTile = 'oldWorld|p1|0|0';
      const ironTile = 'oldWorld|p1|1|0';

      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: grainTile,
      );
      WorldState worldForProspected(Map<String, Set<String>> prospected) {
        return WorldState(
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
              '$ow|p1': [grainTile, ironTile],
            },
          },
          resourceByTileKey: {grainTile: 'grain', ironTile: 'iron'},
          playerVisibilityByTile: {
            playerId: {grainTile: 'fullyVisible', ironTile: 'fullyVisible'},
          },
          tileState: TileMapState(
            improvementByTile: {grainTile: 0, ironTile: 0},
          ),
          playerProspectedTiles: prospected,
        );
      }

      final topology = const MapTopology(nodes: [], edges: []);
      final stockpile = Stockpile(quantities: {'lumber': 10, 'castIron': 10});

      final gameUnprospected = Game(
        id: 'g1',
        worldState: worldForProspected(const {}),
        players: [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            stockpile: stockpile,
          ),
        ],
      );
      final viewUnprospected = buildPlayerView(
        gameUnprospected,
        topology,
        playerId,
      );
      final validUnprospected = getValidWorkOrderTileKeysWithVisibility(
        game: gameUnprospected,
        topology: topology,
        view: viewUnprospected,
        unitId: 'u1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );
      expect(validUnprospected.contains(grainTile), isTrue);
      expect(validUnprospected.contains(ironTile), isFalse);

      final gameProspected = Game(
        id: 'g2',
        worldState: worldForProspected({
          playerId: {ironTile},
        }),
        players: [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            stockpile: stockpile,
          ),
        ],
      );
      final viewProspected = buildPlayerView(
        gameProspected,
        topology,
        playerId,
      );
      final validProspected = getValidWorkOrderTileKeysWithVisibility(
        game: gameProspected,
        topology: topology,
        view: viewProspected,
        unitId: 'u1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );
      expect(validProspected.contains(grainTile), isTrue);
      expect(validProspected.contains(ironTile), isTrue);
    });

    test('build_improvement includes purchased tiles with resources', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const purchasedTileWithResource = 'oldWorld|p2|0|0';
      const unpurchasedTileWithResource = 'oldWorld|p2|1|0';

      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
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
        workTarget: kWorkTargetBuildImprovement,
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
        type: kUnitTypeBuilder,
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
        workTarget: kWorkTargetBuildImprovement,
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
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: provinceId,
          tileKey: grassTile,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {grassTile: 'fogged', ironTile: 'fogged'},
          },
          resourceByTileKey: const {grassTile: 'grain', ironTile: 'iron'},
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
          workTarget: kWorkTargetProspect,
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
          type: kUnitTypeExplorer,
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
          workTarget: kWorkTargetProspect,
          currentOrders: const Orders(),
        );
        expect(valid, contains(ironTile));
      },
    );

    test(
      'getValidWorkOrderTileKeysWithVisibility prospect excludes wool on hills '
      'when tile map marks hills (terrain-only eligibility must not apply)',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const provinceId = '$ow|p1';
        const woolTile = 'oldWorld|p1|0|0';
        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final tribe = const Tribe(id: 'tribe1', displayName: 'T');
        final p1 = Province(id: provinceId, regionId: ow, ownerId: 'tribe1');
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: provinceId,
          tileKey: woolTile,
        );
        final tileMapByRegion = <String, TileMapResult>{
          ow: TileMapResult(
            width: 1,
            height: 1,
            grid: const [
              ['p1'],
            ],
            terrainGrid: const [
              [TerrainType.hills],
            ],
            resourceGrid: const [
              [Resource.wool],
            ],
          ),
        };
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {woolTile: 'fogged'},
          },
          resourceByTileKey: const {woolTile: 'wool'},
          tileKeysByRegionAndProvince: {
            ow: {
              provinceId: [woolTile],
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
          workTarget: kWorkTargetProspect,
          currentOrders: const Orders(),
          tileMapByRegion: tileMapByRegion,
        );
        expect(valid.contains(woolTile), isFalse);
      },
    );

    test(
      'getValidWorkOrderTileKeysWithVisibility explore only scans partially revealed provinces',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const partialProvince = '$ow|p_partial';
        const fullProvince = '$ow|p_full';
        const unknownProvince = '$ow|p_unknown';
        const partialKnownTile = 'oldWorld|p_partial|0|0';
        const partialUnknownTile = 'oldWorld|p_partial|1|0';
        const fullTile = 'oldWorld|p_full|0|0';
        const unknownTile = 'oldWorld|p_unknown|0|0';

        final explorer = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: partialProvince,
          tileKey: partialKnownTile,
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: partialProvince, regionId: ow, ownerId: 'tribe1'),
                Province(id: fullProvince, regionId: ow, ownerId: 'tribe1'),
                Province(id: unknownProvince, regionId: ow, ownerId: 'tribe1'),
              ],
              units: [explorer],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                partialProvince: [partialKnownTile, partialUnknownTile],
                fullProvince: [fullTile],
                unknownProvince: [unknownTile],
              },
            },
            playerVisibilityByTile: const {
              playerId: {
                partialKnownTile: 'fogged',
                fullTile: 'fullyVisible',
                unknownTile: 'unknown',
              },
            },
          ),
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
        );
        final topology = const MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, playerId);

        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: kWorkTargetExplore,
          currentOrders: const Orders(),
        );

        expect(valid, contains(partialKnownTile));
        expect(valid, isNot(contains(fullTile)));
        expect(valid, isNot(contains(unknownTile)));
      },
    );

    test(
      'getValidWorkOrderTileKeysWithVisibility explore remains under one second on large map fixture',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const provinceCount = 120;
        const tilesPerProvince = 12;
        final byProvince = <String, List<String>>{};
        final visibility = <String, String>{};
        final provinces = <Province>[];

        for (var p = 0; p < provinceCount; p++) {
          final provinceId = '$ow|p$p';
          provinces.add(
            Province(id: provinceId, regionId: ow, ownerId: 'tribe1'),
          );
          final tiles = <String>[];
          for (var t = 0; t < tilesPerProvince; t++) {
            final tileKey = '$ow|p$p|$t|0';
            tiles.add(tileKey);
            if (p.isEven && t == 0) {
              visibility[tileKey] = 'fogged';
            } else if (p.isEven && t == 1) {
              visibility[tileKey] = 'unknown';
            } else {
              visibility[tileKey] = 'unknown';
            }
          }
          byProvince[provinceId] = tiles;
        }

        final startTile = '$ow|p0|0|0';
        final explorer = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: '$ow|p0',
          tileKey: startTile,
        );
        final game = Game(
          id: 'g-latency',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(provinces: provinces, units: [explorer]),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {ow: byProvince},
            playerVisibilityByTile: {playerId: visibility},
          ),
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
        );
        final topology = const MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, playerId);

        final sw = Stopwatch()..start();
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: kWorkTargetExplore,
          currentOrders: const Orders(),
        );
        sw.stop();

        expect(valid, isNotEmpty);
        expect(sw.elapsedMilliseconds, lessThan(1000));
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
        type: kUnitTypeBuilder,
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
        suggestions.where(
          (m) =>
              Unit.provinceIdFromTileKey(m.destinationTileKey) == 'oldWorld|p2',
        ),
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
        type: kUnitTypeSpy,
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
      expect(suggestions.where((o) => o.target == kWorkTargetStealTech), isNotEmpty);
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
          type: kUnitTypeBuilder,
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
            .where((o) => o.target == kWorkTargetBuildImprovement)
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
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: 'oldWorld|p1|0|0',
        );

        // Existing work order for build_improvement
        final existingOrder = WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildImprovement,
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
                  o.target == kWorkTargetBuildImprovement &&
                  o.targetTileKey == 'oldWorld|p1|0|0',
            )
            .toList();

        expect(buildSuggestions, isEmpty);
      },
    );

    test(
      'suggestWorkOrders explore includes partially revealed province when first sorted entry tile is unknown but later tile is fogged',
      () {
        const playerId = 'gp1';
        const nw = 'newWorld';
        const provHome = '$nw|home';
        const provTarget = '$nw|tribe1';
        final tileHome = '$nw|home|0|0';
        final t0 = '$nw|tribe1|0|0';
        final t1 = '$nw|tribe1|1|0';

        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final tribe = const Tribe(id: 'tribe1', displayName: 'T');
        final pHome = Province(id: provHome, regionId: nw, ownerId: playerId);
        final pTarget = Province(
          id: provTarget,
          regionId: nw,
          ownerId: 'tribe1',
        );
        final explorer = Unit(
          id: 'ex1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
          tileKeysByRegionAndProvince: {
            nw: {
              provHome: [tileHome],
              provTarget: [t0, t1],
            },
          },
          playerVisibilityByTile: {
            playerId: {tileHome: 'fullyVisible', t0: 'unknown', t1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916e1',
          worldState: world,
          players: [player],
          tribes: [tribe],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'home',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'tribe1',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'home', id2: 'tribe1')],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final explore = suggestions
            .where((o) => o.target == kWorkTargetExplore)
            .toList();
        expect(explore, isNotEmpty);
        expect(
          explore.any(
            (o) => Unit.provinceIdFromTileKey(o.targetTileKey) == provTarget,
          ),
          isTrue,
        );
      },
    );

    test(
      'suggestWorkOrders explore excludes partially revealed province when no bundled entry tile passes move validation',
      () {
        const playerId = 'gp1';
        const nw = 'newWorld';
        const provHome = '$nw|home';
        const provTarget = '$nw|gp2p';
        final tileHome = '$nw|home|0|0';
        final t0 = '$nw|gp2p|0|0';
        final t1 = '$nw|gp2p|1|0';

        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final gp2 = const Player(id: 'gp2', displayName: 'P2', isHuman: false);
        final pHome = Province(id: provHome, regionId: nw, ownerId: playerId);
        final pTarget = Province(id: provTarget, regionId: nw, ownerId: 'gp2');
        final explorer = Unit(
          id: 'ex1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
          tileKeysByRegionAndProvince: {
            nw: {
              provHome: [tileHome],
              provTarget: [t0, t1],
            },
          },
          playerVisibilityByTile: {
            playerId: {tileHome: 'fullyVisible', t0: 'unknown', t1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916e2',
          worldState: world,
          players: [player, gp2],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'home',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'gp2p',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'home', id2: 'gp2p')],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          suggestions.where(
            (o) =>
                o.target == kWorkTargetExplore &&
                Unit.provinceIdFromTileKey(o.targetTileKey) == provTarget,
          ),
          isEmpty,
        );
      },
    );

    test(
      'suggestWorkOrders prospect includes mineral tile in partially revealed province when first sorted entry tile is unknown',
      () {
        const playerId = 'gp1';
        const nw = 'newWorld';
        const provHome = '$nw|home';
        const provTarget = '$nw|tribe1';
        final tileHome = '$nw|home|0|0';
        final t0 = '$nw|tribe1|0|0';
        final t1 = '$nw|tribe1|1|0';

        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final tribe = const Tribe(id: 'tribe1', displayName: 'T');
        final pHome = Province(id: provHome, regionId: nw, ownerId: playerId);
        final pTarget = Province(
          id: provTarget,
          regionId: nw,
          ownerId: 'tribe1',
        );
        final explorer = Unit(
          id: 'ex1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
          tileKeysByRegionAndProvince: {
            nw: {
              provHome: [tileHome],
              provTarget: [t0, t1],
            },
          },
          resourceByTileKey: {t0: 'grain', t1: 'iron'},
          playerVisibilityByTile: {
            playerId: {tileHome: 'fullyVisible', t0: 'unknown', t1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916p1',
          worldState: world,
          players: [player],
          tribes: [tribe],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'home',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'tribe1',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'home', id2: 'tribe1')],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final prospect = suggestions
            .where((o) => o.target == kWorkTargetProspect)
            .toList();
        expect(prospect, isNotEmpty);
        expect(prospect.any((o) => o.targetTileKey == t1), isTrue);
      },
    );

    test(
      'suggestWorkOrders prospect excludes partially revealed province when only non-eligible or already prospected mineral tiles remain',
      () {
        const playerId = 'gp1';
        const nw = 'newWorld';
        const provHome = '$nw|home';
        const provTarget = '$nw|tribe1';
        final tileHome = '$nw|home|0|0';
        final t0 = '$nw|tribe1|0|0';
        final t1 = '$nw|tribe1|1|0';

        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final tribe = const Tribe(id: 'tribe1', displayName: 'T');
        final pHome = Province(id: provHome, regionId: nw, ownerId: playerId);
        final pTarget = Province(
          id: provTarget,
          regionId: nw,
          ownerId: 'tribe1',
        );
        final explorer = Unit(
          id: 'ex1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
          tileKeysByRegionAndProvince: {
            nw: {
              provHome: [tileHome],
              provTarget: [t0, t1],
            },
          },
          resourceByTileKey: {t0: 'grain', t1: 'iron'},
          playerProspectedTiles: {
            playerId: {t1},
          },
          playerVisibilityByTile: {
            playerId: {tileHome: 'fullyVisible', t0: 'unknown', t1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916p2',
          worldState: world,
          players: [player],
          tribes: [tribe],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'home',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'tribe1',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'home', id2: 'tribe1')],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          suggestions.where((o) => o.target == kWorkTargetProspect),
          isEmpty,
        );
      },
    );

    test(
      'suggestWorkOrders purchase_land includes target in partially revealed minor or tribe province when embassy and diplomacy gates pass',
      () {
        const playerId = 'gp1';
        const nw = 'newWorld';
        const provOwn = '$nw|own';
        const provMinor = '$nw|m1';
        final tileOwn = '$nw|own|0|0';
        final m0 = '$nw|m1|0|0';
        final m1 = '$nw|m1|1|0';

        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );
        final pOwn = Province(id: provOwn, regionId: nw, ownerId: playerId);
        final pMinor = Province(id: provMinor, regionId: nw, ownerId: 'minor1');
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeMerchant,
          ownerId: playerId,
          locationProvinceId: provOwn,
          tileKey: tileOwn,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pOwn, pMinor], units: [unit]),
          tileKeysByRegionAndProvince: {
            nw: {
              provOwn: [tileOwn],
              provMinor: [m0, m1],
            },
          },
          resourceByTileKey: {m1: 'grain'},
          playerVisibilityByTile: {
            playerId: {tileOwn: 'fullyVisible', m0: 'unknown', m1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916pl1',
          worldState: world,
          players: [player],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: playerId,
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'own',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'm1',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'own', id2: 'm1')],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          suggestions.where(
            (o) =>
                o.target == kWorkTargetPurchaseLand &&
                Unit.provinceIdFromTileKey(o.targetTileKey) == provMinor,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'suggestWorkOrders purchase_land excludes partially revealed target when embassy or diplomacy preconditions fail',
      () {
        const playerId = 'gp1';
        const nw = 'newWorld';
        const provOwn = '$nw|own';
        const provMinor = '$nw|m1';
        final tileOwn = '$nw|own|0|0';
        final m0 = '$nw|m1|0|0';
        final m1 = '$nw|m1|1|0';

        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );
        final pOwn = Province(id: provOwn, regionId: nw, ownerId: playerId);
        final pMinor = Province(id: provMinor, regionId: nw, ownerId: 'minor1');
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeMerchant,
          ownerId: playerId,
          locationProvinceId: provOwn,
          tileKey: tileOwn,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pOwn, pMinor], units: [unit]),
          tileKeysByRegionAndProvince: {
            nw: {
              provOwn: [tileOwn],
              provMinor: [m0, m1],
            },
          },
          resourceByTileKey: {m1: 'grain'},
          playerVisibilityByTile: {
            playerId: {tileOwn: 'fullyVisible', m0: 'unknown', m1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916pl2',
          worldState: world,
          players: [player],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'own',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'm1',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'own', id2: 'm1')],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          suggestions.where(
            (o) =>
                o.target == kWorkTargetPurchaseLand &&
                Unit.provinceIdFromTileKey(o.targetTileKey) == provMinor,
          ),
          isEmpty,
        );
      },
    );
  });
}
