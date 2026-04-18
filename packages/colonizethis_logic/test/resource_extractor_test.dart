import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:logger/logger.dart';

void main() {
  group('ResourceExtractor', () {
    test('stub connectivity: land totals and tech cap applied', () {
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final resourceGrid = [
        [Resource.grain, Resource.timber],
        [Resource.iron, null],
      ];
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: grid,
        resourceGrid: resourceGrid,
      );
      final cap = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 3)
          .setImprovement('oldWorld|p1|1|0', 2)
          .setImprovement('oldWorld|p1|0|1', 4)
          .setRoadLevel('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|1|0', 1)
          .setRoadLevel('oldWorld|p1|0|1', 0);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: cap,
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final connectivity = {
        'pl1': ConnectivityResult(
          connected: {'oldWorld|p1|0|0', 'oldWorld|p1|1|0', 'oldWorld|p1|0|1'},
        ),
      };
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivity,
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1'], isNotNull);
      final tot = result['pl1']!;
      expect(tot.overseas, isEmpty);
      expect(tot.land['grain'], 2);
      expect(tot.land['timber'], 1);
      expect(tot.land['iron'], isNull);
    });

    test('effective extraction capped by transport level', () {
      final grid = [
        ['p1'],
      ];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [
          [Resource.grain],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 4)
          .setRoadLevel('oldWorld|p1|0|0', 1);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['grain'], 1);
    });

    test('effective extraction capped by player tech cap when improvement and '
        'transport are high', () {
      final grid = [
        ['p1'],
      ];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [
          [Resource.grain],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 4)
          .setRoadLevel('oldWorld|p1|0|0', 4);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final resultCap2 = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
        },
        techCapForPlayer: (_) => 2,
      );
      expect(resultCap2['pl1']!.land['grain'], 2);

      final resultCap3 = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
        },
        techCapForPlayer: (_) => 3,
      );
      expect(resultCap3['pl1']!.land['grain'], 3);
    });

    test(
      'tech cap from extractionCapForUnlocked matches turn_resolver wiring',
      () {
        final grid = [
          ['p1'],
        ];
        final tileMap = TileMapResult(
          width: 1,
          height: 1,
          grid: grid,
          resourceGrid: [
            [Resource.grain],
          ],
        );
        final tileState = TileMapState()
            .setImprovement('oldWorld|p1|0|0', 4)
            .setRoadLevel('oldWorld|p1|0|0', 4);
        final player = Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
          techUnlocked: {'saw_mill': true, 'seed_drill': true},
        );
        final game = Game(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 0,
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'pl1',
                  townDevelopmentLevel: 4,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: [player],
        );
        final result = computeExtraction(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          connectivityResult: {
            'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
          },
          techCapForPlayer: (playerId) {
            final p = game.playerById(playerId);
            return extractionCapForUnlocked(p?.techUnlocked);
          },
        );
        expect(extractionCapForUnlocked(player.techUnlocked), 3);
        expect(result['pl1']!.land['grain'], 3);
      },
    );

    test('extracts wool and copper when present on tile map', () {
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final resourceGrid = [
        [Resource.wool, Resource.copper],
        [Resource.timber, Resource.iron],
      ];
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: grid,
        resourceGrid: resourceGrid,
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 1)
          .setImprovement('oldWorld|p1|1|0', 1)
          .setImprovement('oldWorld|p1|0|1', 1)
          .setImprovement('oldWorld|p1|1|1', 1)
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setRoadLevel('oldWorld|p1|1|0', 1)
          .setRoadLevel('oldWorld|p1|0|1', 1)
          .setRoadLevel('oldWorld|p1|1|1', 1);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final connectedTiles = {
        'oldWorld|p1|0|0',
        'oldWorld|p1|1|0',
        'oldWorld|p1|0|1',
        'oldWorld|p1|1|1',
      };
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
          playerProspectedTiles: {'pl1': connectedTiles},
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(connected: connectedTiles),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['wool'], 1);
      expect(result['pl1']!.land['copper'], 1);
      expect(result['pl1']!.land['timber'], 1);
      expect(result['pl1']!.land['iron'], 1);
    });

    test('mineral tiles without prospected are excluded from extraction', () {
      final grid = [
        ['p1'],
      ];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [
          [Resource.iron],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|0|0', 2);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['iron'], isNull);
      expect(result['pl1']!.land, isEmpty);
    });

    test('mineral from prospected tile counts in land', () {
      final grid = [
        ['p1'],
      ];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [
          [Resource.iron],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|0|0', 2);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
          playerProspectedTiles: {
            'pl1': {'oldWorld|p1|0|0'},
          },
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['iron'], 2);
    });

    test('effective extraction capped by province townDevelopmentLevel', () {
      final grid = [
        ['p1'],
      ];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [
          [Resource.grain],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 4)
          .setRoadLevel('oldWorld|p1|0|0', 4);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['grain'], 1);
    });

    test('town-rule-only + non-port: townDevelopmentLevel does NOT cap yield', () {
      final grid = [
        ['p1', 'p1', 'p1'],
        ['p1', 'p2', 'p2'],
        ['p1', 'p2', 'p2'],
      ];
      final resourceGrid = [
        [null, null, null],
        [null, Resource.grain, null],
        [null, null, null],
      ];
      final tileMap = TileMapResult(
        width: 3,
        height: 3,
        grid: grid,
        resourceGrid: resourceGrid,
      );
      final cap = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setImprovement('oldWorld|p2|1|1', 4)
          .setRoadLevel('oldWorld|p2|1|1', 0);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: cap,
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townTileKey: 'oldWorld|p1|0|0',
                townDevelopmentLevel: 4,
              ),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townTileKey: 'oldWorld|p2|1|0',
                townDevelopmentLevel: 2,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final tileKey = 'oldWorld|p2|1|1';
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(
            connected: {tileKey},
            pathTransportCap: {tileKey: 4},
            connectedByRoadRule: const {},
          ),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(
        result['pl1']!.land['grain'],
        4,
        reason:
            'town-rule-only tile with non-port town; townDevelopmentLevel=2 must NOT cap '
            'yield of 4 (SPEC/game/extraction-and-improvements.md § Extraction formula)',
      );
    });

    test('town-rule-only + port: townDevelopmentLevel DOES cap yield', () {
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p2'],
      ];
      final resourceGrid = [
        [null, null],
        [null, Resource.grain],
      ];
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: grid,
        resourceGrid: resourceGrid,
      );
      final cap = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setImprovement('oldWorld|p2|1|1', 4)
          .setRoadLevel('oldWorld|p2|1|1', 0);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: cap,
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townTileKey: 'oldWorld|p1|0|0',
                townDevelopmentLevel: 4,
              ),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townTileKey: 'oldWorld|p2|0|1',
                townDevelopmentLevel: 2,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
          portsByProvinceSeaboard: {'oldWorld|p2|sea1': 'oldWorld|p2|0|1'},
        ),
        players: [player],
      );
      final tileKey = 'oldWorld|p2|1|1';
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(
            connected: {tileKey},
            pathTransportCap: {tileKey: 4},
            connectedByRoadRule: const {},
          ),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(
        result['pl1']!.land['grain'],
        2,
        reason:
            'town-rule-only tile with port town; townDevelopmentLevel=2 caps yield to 2 '
            '(SPEC/game/extraction-and-improvements.md § Extraction formula)',
      );
    });

    test('overseas totals when connected tile in different region', () {
      final gridNw = [
        ['n1'],
      ];
      final tileMapNw = TileMapResult(
        width: 1,
        height: 1,
        grid: gridNw,
        resourceGrid: [
          [Resource.sugarCane],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('newWorld|n1|0|0', 1)
          .setRoadLevel('newWorld|n1|0|0', 1);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'pl1'),
            ],
          ),
          tileState: tileState,
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {
          'oldWorld': TileMapResult(
            width: 1,
            height: 1,
            grid: [
              ['p1'],
            ],
            resourceGrid: [
              [null],
            ],
          ),
          'newWorld': tileMapNw,
        },
        connectivityResult: {
          'pl1': ConnectivityResult(connected: {'newWorld|n1|0|0'}),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.overseas['sugarCane'], 1);
      expect(result['pl1']!.land, isEmpty);
    });

    test(
      'blockaded overseas port: connectivity excludes tile so overseas extraction zero',
      () {
        final oldGrid = [
          ['p1', 'p1'],
          ['p1', 'p1'],
        ];
        final newGrid = [
          ['n1', 'n1'],
          ['n1', 'n1'],
        ];
        final tileMapOw = TileMapResult(
          width: 2,
          height: 2,
          grid: oldGrid,
          resourceGrid: [
            [null, null],
            [null, null],
          ],
        );
        final tileMapNw = TileMapResult(
          width: 2,
          height: 2,
          grid: newGrid,
          resourceGrid: [
            [Resource.sugarCane, Resource.sugarCane],
            [null, null],
          ],
        );
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'n1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'n1', id2: 'sea2'),
            TopologyEdge(id1: 'sea1', id2: 'sea2'),
          ],
        );
        const ow = 'oldWorld', nw = 'newWorld';
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
        final tileState = TileMapState()
            .setImprovement('newWorld|n1|0|0', 1)
            .setImprovement('newWorld|n1|1|0', 1)
            .setRoadLevel('oldWorld|p1|0|0', 4)
            .setRoadLevel('newWorld|n1|0|0', 4)
            .setRoadLevel('newWorld|n1|1|0', 4);
        final ports = {
          '$ow|p1|sea1': 'oldWorld|p1|0|0',
          '$nw|n1|sea2': 'newWorld|n1|0|0',
        };
        final game = Game(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 0,
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: '$ow|p1',
                  regionId: ow,
                  ownerId: 'pl1',
                  townDevelopmentLevel: 4,
                ),
              ],
            ),
            newWorld: RegionData(
              provinces: [
                Province(
                  id: '$nw|n1',
                  regionId: nw,
                  ownerId: 'pl1',
                  townDevelopmentLevel: 4,
                ),
              ],
            ),
            tileState: tileState,
            portsByProvinceSeaboard: ports,
          ),
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );
        final connectivityBlockaded = resolveConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
          topology: topology,
          blockadedPortProvincesByPlayerId: {
            'pl1': {'newWorld|n1'},
          },
        );
        final resultBlockaded = computeExtraction(
          game: game,
          tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
          connectivityResult: connectivityBlockaded,
          techCapForPlayer: (_) => 4,
        );
        expect(resultBlockaded['pl1']!.overseas, isEmpty);
        expect(resultBlockaded['pl1']!.land, isEmpty);

        final connectivityOpen = resolveConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
          topology: topology,
        );
        final resultOpen = computeExtraction(
          game: game,
          tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
          connectivityResult: connectivityOpen,
          techCapForPlayer: (_) => 4,
        );
        expect(resultOpen['pl1']!.overseas['sugarCane'] ?? 0, greaterThan(0));
      },
    );

    test('effective yield capped by min transport level along path to capital', () {
      // SPEC: effective yield = min(production, tech cap, town dev, min transport along path).
      // When pathTransportCap is provided, it caps yield (e.g. path with road-1 segment → cap 1).
      final grid = [
        ['p1'],
      ];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [
          [Resource.grain],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 3)
          .setRoadLevel('oldWorld|p1|0|0', 3);
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [
          Player(
            id: 'pl1',
            displayName: 'Spain',
            isHuman: true,
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final connectivity = resolveConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        ),
      );
      expect(connectivity['pl1']!.pathTransportCap['oldWorld|p1|0|0'], 3);
      final resultWithPathCap = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(
            connected: {'oldWorld|p1|0|0'},
            pathTransportCap: {'oldWorld|p1|0|0': 1},
          ),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(resultWithPathCap['pl1']!.land['grain'], 1);
    });

    test(
      'returns empty ExtractionTotals when player has no connected tiles',
      () {
        final player = Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
        );
        final game = Game(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 0,
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'pl1',
                  townDevelopmentLevel: 4,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [player],
        );
        final result = computeExtraction(
          game: game,
          tileMapByRegion: const {},
          connectivityResult: {'pl1': ConnectivityResult(connected: {})},
          techCapForPlayer: (_) => 4,
        );
        expect(result['pl1']!.land, isEmpty);
        expect(result['pl1']!.overseas, isEmpty);
      },
    );

    test(
      'skips connected tile and logs when province missing from region (world-model)',
      () {
        final captured = <LogEvent>[];
        void listener(LogEvent e) => captured.add(e);
        Logger.addLogListener(listener);
        addTearDown(() {
          Logger.removeLogListener(listener);
          captured.clear();
        });
        Logger.level = Level.error;
        addTearDown(() => Logger.level = Level.off);

        final grid = [
          ['p1'],
        ];
        final tileMap = TileMapResult(
          width: 1,
          height: 1,
          grid: grid,
          resourceGrid: [
            [Resource.grain],
          ],
        );
        final tileState = TileMapState()
            .setImprovement('oldWorld|p1|0|0', 2)
            .setRoadLevel('oldWorld|p1|0|0', 2);
        final player = Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
        );
        final game = Game(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 0,
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: const RegionData(provinces: []),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: [player],
        );
        final result = computeExtraction(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          connectivityResult: {
            'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
          },
          techCapForPlayer: (_) => 4,
        );
        expect(result['pl1']!.land['grain'], isNull);
        expect(
          captured.any(
            (e) => e.message.contains('extraction province missing'),
          ),
          isTrue,
        );
      },
    );

    test('capital tile grain bonus is unconditional on connectivity', () {
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: const {},
        connectivityResult: {'pl1': const ConnectivityResult(connected: {})},
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['grain'], 5);
      expect(result['pl1']!.overseas, isEmpty);
    });

    test(
      'tile extraction contribution excludes aggregate capital grain bonus',
      () {
        final tileMap = TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['p1'],
          ],
          resourceGrid: const [
            [Resource.grain],
          ],
        );
        final player = Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
        );
        final game = Game(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 5,
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'pl1',
                  townDevelopmentLevel: 4,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileState: TileMapState()
                .setImprovement('oldWorld|p1|0|0', 1)
                .setRoadLevel('oldWorld|p1|0|0', 1),
          ),
          players: [player],
        );
        final connected = {'oldWorld|p1|0|0'};
        final contribution = computeTileExtractionContributionForPlayer(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          player: player,
          tileKey: 'oldWorld|p1|0|0',
          connectedTileKeys: connected,
          pathTransportCap: const {},
          connectedByRoadRule: connected,
          portTileKeys: const {},
          prospectedTileKeys: connected,
          capitalRegionId: 'oldWorld',
          techCapForPlayer: (_) => 4,
        );
        expect(contribution, isNotNull);
        expect(contribution!.commodityId, 'grain');
        expect(contribution.units, 1);
      },
    );

    test('tile extraction contribution is null for disconnected tile', () {
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['p1'],
        ],
        resourceGrid: const [
          [Resource.grain],
        ],
      );
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: TileMapState(),
        ),
        players: [player],
      );
      final contribution = computeTileExtractionContributionForPlayer(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        player: player,
        tileKey: 'oldWorld|p1|0|0',
        connectedTileKeys: const {},
        pathTransportCap: const {},
        connectedByRoadRule: const {},
        portTileKeys: const {},
        prospectedTileKeys: const {},
        capitalRegionId: 'oldWorld',
        techCapForPlayer: (_) => 4,
      );
      expect(contribution, isNull);
    });
  });
}
