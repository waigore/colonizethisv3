import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('CapitalChoice', () {
    test('isProvinceSeaBound true when P-S edge exists', () {
      final topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      expect(isProvinceSeaBound(topology, 'p1'), true);
      expect(isProvinceSeaBound(topology, 'sea1'), false);
    });

    test(
      'setCapital updates player and auto-builds port on coastal capital',
      () {
        final grid = [
          ['p1', 'sea1'],
          ['p1', 'p1'],
        ];
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
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
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
        );
        final next = setCapital(
          game: game,
          playerId: 'pl1',
          provinceId: 'oldWorld|p1',
          tile: CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
          topology: topology,
          tileMapByRegion: {
            'oldWorld': TileMapResult(width: 2, height: 2, grid: grid),
          },
        );
        expect(next.players.single.capitalProvinceId, 'oldWorld|p1');
        expect(next.players.single.capitalTile?.x, 0);
        expect(next.players.single.capitalTile?.y, 0);
        expect(
          next.worldState.portsByProvinceSeaboard['oldWorld|p1|sea1'],
          'oldWorld|p1|0|0',
        );
        expect(next.worldState.tileState.roadLevel('oldWorld|p1|0|0'), 4);
      },
    );

    test('pickCapitalForFaction returns sea-bound province and valid tile', () {
      final grid = [
        ['p1', 'sea1'],
        ['p2', 'p1'],
      ];
      final topology = MapTopology(
        nodes: [
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
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p2', id2: 'p1'),
        ],
      );
      final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
      // p1 is sea-bound, p2 is not. Owned = [p2, p1]; after sort sea-bound = [p1].
      final (provinceId, tile) = pickCapitalForFaction(
        ['oldWorld|p2', 'oldWorld|p1'],
        'oldWorld',
        topology,
        tileMap,
      );
      expect(provinceId, 'oldWorld|p1');
      expect(tile.regionId, 'oldWorld');
      expect(tile.provinceId, 'oldWorld|p1');
      expect(tile.x, 0);
      expect(tile.y, 0);
    });

    test(
      'pickCapitalForFaction throws when no sea-bound province (requireSeaBound: true)',
      () {
        final grid = [
          ['p1', 'p2'],
          ['p2', 'p2'],
        ];
        final topology = MapTopology(
          nodes: [
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
          edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
        );
        final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
        expect(
          () => pickCapitalForFaction(
            ['oldWorld|p1', 'oldWorld|p2'],
            'oldWorld',
            topology,
            tileMap,
          ),
          throwsA(
            isA<NoSeaBoundCapitalProvinceException>().having(
              (e) => e.code,
              'code',
              'no_sea_bound_capital_province',
            ),
          ),
        );
      },
    );

    test(
      'pickCapitalForFaction with requireSeaBound: false returns first province when none sea-bound',
      () {
        final grid = [
          ['p1', 'p2'],
          ['p2', 'p2'],
        ];
        final topology = MapTopology(
          nodes: [
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
          edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
        );
        final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
        final (provinceId, tile) = pickCapitalForFaction(
          ['oldWorld|p2', 'oldWorld|p1'],
          'oldWorld',
          topology,
          tileMap,
          requireSeaBound: false,
        );
        expect(provinceId, 'oldWorld|p1');
        expect(tile.regionId, 'oldWorld');
        expect(tile.provinceId, 'oldWorld|p1');
      },
    );

    test(
      'pickCapitalForFaction for GP uses coastal Class C when Class A is empty',
      () {
        // p1 is sea-bound. (0,1) is Class B. (1,1) is Class C coastal (adjacent to sea and p2).
        final grid = [
          ['p1', 'p2', 'sea1'],
          ['p1', 'p1', 'sea1'],
        ];
        final topology = MapTopology(
          nodes: [
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
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p1', id2: 'p2'),
          ],
        );
        final tileMap = TileMapResult(width: 3, height: 2, grid: grid);
        final (provinceId, tile) = pickCapitalForFaction(
          ['oldWorld|p1'],
          'oldWorld',
          topology,
          tileMap,
        );
        expect(provinceId, 'oldWorld|p1');
        expect(tile.provinceId, 'oldWorld|p1');
        expect(tile.x, 1);
        expect(tile.y, 1);
      },
    );

    test('pickCapitalForFaction for GP throws when no coastal tile exists', () {
      // Contrived invalid map: province is marked sea-bound in topology but tile map has no coastal p1 tile.
      final grid = [
        ['p1', 'p1', 'p2'],
        ['p1', 'p1', 'p2'],
      ];
      final topology = MapTopology(
        nodes: [
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
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'p2'),
        ],
      );
      final tileMap = TileMapResult(width: 3, height: 2, grid: grid);
      expect(
        () => pickCapitalForFaction(
          ['oldWorld|p1'],
          'oldWorld',
          topology,
          tileMap,
        ),
        throwsA(
          isA<NoCoastalCapitalTileForGpException>()
              .having((e) => e.code, 'code', 'no_coastal_capital_tile_for_gp')
              .having(
                (e) => e.message,
                'message',
                contains('No coastal tile found'),
              ),
        ),
      );
    });

    test('setCapitalForMinorNation updates minor and WorldState port/road', () {
      final grid = [
        ['p1', 'sea1'],
        ['p1', 'p1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'min1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [],
        minorNations: [MinorNation(id: 'min1', displayName: 'Portugal')],
      );
      final next = setCapitalForMinorNation(
        game: game,
        minorId: 'min1',
        provinceId: 'oldWorld|p1',
        tile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
        topology: topology,
        tileMapByRegion: {
          'oldWorld': TileMapResult(width: 2, height: 2, grid: grid),
        },
      );
      expect(next.minorNations.single.capitalProvinceId, 'oldWorld|p1');
      expect(next.minorNations.single.capitalTile?.x, 0);
      expect(
        next.worldState.portsByProvinceSeaboard['oldWorld|p1|sea1'],
        'oldWorld|p1|0|0',
      );
      expect(next.worldState.tileState.roadLevel('oldWorld|p1|0|0'), 4);
    });

    test('setCapitalForTribe updates tribe and WorldState port/road', () {
      final grid = [
        ['nw1', 'sea1'],
        ['nw1', 'nw1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'nw1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              Province(
                id: 'newWorld|nw1',
                regionId: 'newWorld',
                ownerId: 'tribe1',
              ),
            ],
          ),
        ),
        players: const [],
        tribes: [Tribe(id: 'tribe1', displayName: 'Aztec')],
      );
      final next = setCapitalForTribe(
        game: game,
        tribeId: 'tribe1',
        provinceId: 'newWorld|nw1',
        tile: const CapitalTile(
          regionId: 'newWorld',
          provinceId: 'newWorld|nw1',
          x: 0,
          y: 0,
        ),
        topology: topology,
        tileMapByRegion: {
          'newWorld': TileMapResult(width: 2, height: 2, grid: grid),
        },
      );
      expect(next.tribes.single.capitalProvinceId, 'newWorld|nw1');
      expect(next.tribes.single.capitalTile?.regionId, 'newWorld');
      expect(
        next.worldState.portsByProvinceSeaboard['newWorld|nw1|sea1'],
        'newWorld|nw1|0|0',
      );
    });

    test(
      'setCapitalForMinorNation succeeds with inland province, no port/road applied',
      () {
        final grid = [
          ['p1', 'p2'],
          ['p2', 'p2'],
        ];
        final topology = MapTopology(
          nodes: [
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
          edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 0, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'min1',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [],
          minorNations: [MinorNation(id: 'min1', displayName: 'Inland Minor')],
        );
        final next = setCapitalForMinorNation(
          game: game,
          minorId: 'min1',
          provinceId: 'oldWorld|p1',
          tile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
          topology: topology,
          tileMapByRegion: {
            'oldWorld': TileMapResult(width: 2, height: 2, grid: grid),
          },
        );
        expect(next.minorNations.single.capitalProvinceId, 'oldWorld|p1');
        expect(next.minorNations.single.capitalTile?.x, 0);
        expect(next.worldState.portsByProvinceSeaboard.isEmpty, true);
      },
    );

    test(
      'setCapitalForTribe succeeds with inland province, no port/road applied',
      () {
        final grid = [
          ['nw1', 'nw2'],
          ['nw2', 'nw2'],
        ];
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'nw2',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'nw2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 0, phase: TurnPhase.orders),
            oldWorld: const RegionData(),
            newWorld: RegionData(
              provinces: [
                Province(
                  id: 'newWorld|nw1',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
          ),
          players: const [],
          tribes: [Tribe(id: 'tribe1', displayName: 'Inland Tribe')],
        );
        final next = setCapitalForTribe(
          game: game,
          tribeId: 'tribe1',
          provinceId: 'newWorld|nw1',
          tile: const CapitalTile(
            regionId: 'newWorld',
            provinceId: 'newWorld|nw1',
            x: 0,
            y: 0,
          ),
          topology: topology,
          tileMapByRegion: {
            'newWorld': TileMapResult(width: 2, height: 2, grid: grid),
          },
        );
        expect(next.tribes.single.capitalProvinceId, 'newWorld|nw1');
        expect(next.tribes.single.capitalTile?.regionId, 'newWorld');
        expect(next.worldState.portsByProvinceSeaboard.isEmpty, true);
      },
    );

    test(
      'init road path: inland capital + port 2+ steps away → every tile on shortest path has road',
      () {
        // 3x2: p1 with sea on right; capital inland at (1,1). Nearest coastal is (1,0). Path (1,0)→(1,1) gets road.
        final grid = [
          ['p1', 'p1', 'sea1'],
          ['p1', 'p1', 'p1'],
        ];
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 0, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'pl1',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
        );
        final tileMapByRegion = {
          'oldWorld': TileMapResult(width: 3, height: 2, grid: grid),
        };
        final next = setCapital(
          game: game,
          playerId: 'pl1',
          provinceId: 'oldWorld|p1',
          tile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 1,
            y: 1,
          ),
          topology: topology,
          tileMapByRegion: tileMapByRegion,
        );
        expect(next.players.single.capitalProvinceId, 'oldWorld|p1');
        final ts = next.worldState.tileState;
        expect(ts.roadLevel('oldWorld|p1|1|1'), 1);
        expect(ts.roadLevel('oldWorld|p1|1|0'), 4);
        expect(ts.roadLevel('oldWorld|p1|1|1'), 1);
      },
    );

    test(
      'setCapitalForReassignment updates player capital only; no port/road changes',
      () {
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
                ),
              ],
            ),
            newWorld: const RegionData(),
            portsByProvinceSeaboard: const {
              'oldWorld|p1|sea1': 'oldWorld|p1|0|0',
            },
          ),
          players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
        );
        final next = setCapitalForReassignment(
          game: game,
          playerId: 'pl1',
          provinceId: 'oldWorld|p1',
          tile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 1,
            y: 1,
          ),
        );
        expect(next.players.single.capitalProvinceId, 'oldWorld|p1');
        expect(next.players.single.capitalTile!.x, 1);
        expect(next.players.single.capitalTile!.y, 1);
        expect(
          next.worldState.portsByProvinceSeaboard,
          game.worldState.portsByProvinceSeaboard,
        );
        expect(next.worldState.tileState, game.worldState.tileState);
      },
    );

    test(
      'pickCapitalProvinceIdForReassignment prefers seaboard by sorted id',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'pA',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'pB',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'pA', id2: 'sea1')],
        );
        final id = pickCapitalProvinceIdForReassignment([
          'oldWorld|pB',
          'oldWorld|pA',
        ], topology);
        expect(id, 'oldWorld|pA');
      },
    );

    test('pickCapitalProvinceIdForReassignment inland when no seaboard', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'pA',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'pB',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final id = pickCapitalProvinceIdForReassignment([
        'oldWorld|pB',
        'oldWorld|pA',
      ], topology);
      expect(id, 'oldWorld|pA');
    });

    test('setCapital creates one port entry per adjacent sea zone', () {
      final grid = [
        ['sea1', 'p1', 'sea2'],
        ['p1', 'p1', 'p1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'sea2'),
        ],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      final next = setCapital(
        game: game,
        playerId: 'pl1',
        provinceId: 'oldWorld|p1',
        tile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 1,
          y: 0,
        ),
        topology: topology,
        tileMapByRegion: {
          'oldWorld': TileMapResult(width: 3, height: 2, grid: grid),
        },
      );
      final ports = next.worldState.portsByProvinceSeaboard;
      expect(ports['oldWorld|p1|sea1'], 'oldWorld|p1|1|0');
      expect(ports['oldWorld|p1|sea2'], 'oldWorld|p1|1|0');
      expect(ports.keys.where((k) => k.startsWith('oldWorld|p1|')).length, 2);
    });

    test('setCapital builds seaboard-specific inland ports and road paths', () {
      final grid = [
        ['sea1', 'p1', 'p1', 'sea2'],
        ['p1', 'p1', 'p1', 'p1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'sea2'),
        ],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      final next = setCapital(
        game: game,
        playerId: 'pl1',
        provinceId: 'oldWorld|p1',
        tile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 1,
          y: 1,
        ),
        topology: topology,
        tileMapByRegion: {
          'oldWorld': TileMapResult(width: 4, height: 2, grid: grid),
        },
      );
      final ports = next.worldState.portsByProvinceSeaboard;
      expect(ports['oldWorld|p1|sea1'], 'oldWorld|p1|1|0');
      expect(ports['oldWorld|p1|sea2'], 'oldWorld|p1|2|0');
      final tileState = next.worldState.tileState;
      expect(tileState.roadLevel('oldWorld|p1|1|0'), 4);
      expect(tileState.roadLevel('oldWorld|p1|2|0'), 4);
      expect(tileState.roadLevel('oldWorld|p1|1|1'), 1);
      expect(tileState.roadLevel('oldWorld|p1|2|1'), 1);
    });

    test('classifyCapitalTile returns class A for coastal non-border tile', () {
      final grid = [
        ['p1', 'sea1'],
        ['p1', 'p1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
      final tileClass = classifyCapitalTile(
        x: 0,
        y: 0,
        tileMap: tileMap,
        topology: topology,
        localProvinceId: 'p1',
      );
      expect(tileClass, CapitalTileClass.a);
    });

    test(
      'classifyCapitalTile returns class B for interior non-border tile',
      () {
        final grid = [
          ['sea1', 'sea1', 'sea1', 'sea1', 'sea1'],
          ['sea1', 'p1', 'p1', 'p1', 'sea1'],
          ['sea1', 'p1', 'p1', 'p1', 'sea1'],
          ['sea1', 'p1', 'p1', 'p1', 'sea1'],
          ['sea1', 'sea1', 'sea1', 'sea1', 'sea1'],
        ];
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
        );
        final tileMap = TileMapResult(width: 5, height: 5, grid: grid);
        final tileClass = classifyCapitalTile(
          x: 2,
          y: 2,
          tileMap: tileMap,
          topology: topology,
          localProvinceId: 'p1',
        );
        expect(tileClass, CapitalTileClass.b);
      },
    );

    test(
      'classifyCapitalTile returns class C for tile bordering another province',
      () {
        final grid = [
          ['p1', 'p2'],
          ['sea1', 'sea1'],
        ];
        final topology = MapTopology(
          nodes: [
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
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'p2'),
            TopologyEdge(id1: 'p1', id2: 'sea1'),
          ],
        );
        final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
        final tileClass = classifyCapitalTile(
          x: 0,
          y: 0,
          tileMap: tileMap,
          topology: topology,
          localProvinceId: 'p1',
        );
        expect(tileClass, CapitalTileClass.c);
      },
    );
  });
}
