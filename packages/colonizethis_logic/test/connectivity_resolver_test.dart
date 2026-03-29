import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('ConnectivityResolver', () {
    test('no roads: capital and adjacent tiles connected', () {
      // 3x3 grid, one province "p1", capital at (1,1). Spec: adjacent to capital is connected.
      final grid = [
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ];
      final tileMap = TileMapResult(width: 3, height: 3, grid: grid);
      final topology = MapTopology(
        nodes: [TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province)],
        edges: [],
      );
      const ow = 'oldWorld';
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 1, y: 1);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: '$ow|p1',
        capitalTile: cap,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: [player],
      );
      final result = resolveConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );
      expect(result['pl1'], isNotNull);
      final connected = result['pl1']!.connected;
      expect(connected.length, 5);
      expect(connected.contains('oldWorld|p1|1|1'), true);
      expect(connected.contains('oldWorld|p1|0|1'), true);
      expect(connected.contains('oldWorld|p1|2|1'), true);
      expect(connected.contains('oldWorld|p1|1|0'), true);
      expect(connected.contains('oldWorld|p1|1|2'), true);
    });

    test('road extends connectivity beyond capital-adjacent', () {
      // Capital at (1,1); road chain to (0,0). Without road to (0,0), (0,0) not connected.
      final grid = [
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ];
      final tileMap = TileMapResult(width: 3, height: 3, grid: grid);
      final topology = MapTopology(
        nodes: [TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province)],
        edges: [],
      );
      const ow = 'oldWorld';
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 1, y: 1);
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|1|1', 1)
          .setRoadLevel('oldWorld|p1|0|1', 1)
          .setRoadLevel('oldWorld|p1|0|0', 1);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: '$ow|p1',
        capitalTile: cap,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final result = resolveConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );
      final connected = result['pl1']!.connected;
      expect(connected.contains('oldWorld|p1|1|1'), true);
      expect(connected.contains('oldWorld|p1|0|1'), true);
      expect(connected.contains('oldWorld|p1|0|0'), true);
      expect(connected.length, greaterThanOrEqualTo(6));
    });

    test('player without capital gets empty set', () {
      const ow = 'oldWorld';
      final grid = [['p1']];
      final tileMap = TileMapResult(width: 1, height: 1, grid: grid);
      final topology = MapTopology(
        nodes: [TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province)],
        edges: [],
      );
      final player = Player(id: 'pl1', displayName: 'Spain', isHuman: true);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: [player],
      );
      final result = resolveConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );
      expect(result['pl1']!.connected, isEmpty);
    });

    test('overseas province with port connected via sea', () {
      // Old World: p1 (capital at 0,0), port at 1,0. New World: p2, port at 0,0. Sea zone "sea1".
      final oldGrid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final newGrid = [
        ['p2', 'p2'],
        ['p2', 'p2'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p2', id2: 'sea1'),
        ],
      );
      const ow = 'oldWorld', nw = 'newWorld';
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|0|0', 4)
          .setRoadLevel('oldWorld|p1|1|0', 4)
          .setRoadLevel('newWorld|p2|0|0', 4);
      final ports = {
        '$ow|p1|sea1': 'oldWorld|p1|1|0',
        '$nw|p2|sea1': 'newWorld|p2|0|0',
      };
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: '$ow|p1',
        capitalTile: cap,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          ]),
          newWorld: RegionData(provinces: [
            Province(id: '$nw|p2', regionId: nw, ownerId: 'pl1'),
          ]),
          tileState: tileState,
          portsByProvinceSeaboard: ports,
        ),
        players: [player],
      );
      final result = resolveConnectivity(
        game: game,
        tileMapByRegion: {
          'oldWorld': TileMapResult(width: 2, height: 2, grid: oldGrid),
          'newWorld': TileMapResult(width: 2, height: 2, grid: newGrid),
        },
        topology: topology,
      );
      final connected = result['pl1']!.connected;
      expect(connected.contains('oldWorld|p1|0|0'), true);
      expect(connected.contains('oldWorld|p1|1|0'), true);
      expect(connected.contains('newWorld|p2|0|0'), true);
      expect(connected.length, greaterThanOrEqualTo(3));
    });

    test('capital not on seaboard: only ports reachable by road from capital connected', () {
      // OW: p1 inland capital at (1,1), port at (0,0) (coastal), road (0,0)-(1,0)-(1,1). NW: p2 with port at (0,0).
      // Capital not on seaboard → no sea-path; overseas p2 port should not be connected.
      final oldGrid = [
        ['p1', 'sea1'],
        ['p1', 'p1'],
      ];
      final newGrid = [
        ['p2', 'sea2'],
        ['p2', 'p2'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p2', id2: 'sea2'),
        ],
      );
      const ow = 'oldWorld', nw = 'newWorld';
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 1, y: 1);
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|1|1', 1)
          .setRoadLevel('oldWorld|p1|0|0', 4)
          .setRoadLevel('oldWorld|p1|1|0', 1)
          .setRoadLevel('newWorld|p2|0|0', 4);
      final ports = {
        '$ow|p1|sea1': 'oldWorld|p1|0|0',
        '$nw|p2|sea2': 'newWorld|p2|0|0',
      };
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1')]),
          newWorld: RegionData(provinces: [Province(id: '$nw|p2', regionId: nw, ownerId: 'pl1')]),
          tileState: tileState,
          portsByProvinceSeaboard: ports,
        ),
        players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true, capitalProvinceId: '$ow|p1', capitalTile: cap)],
      );
      final result = resolveConnectivity(
        game: game,
        tileMapByRegion: {
          'oldWorld': TileMapResult(width: 2, height: 2, grid: oldGrid),
          'newWorld': TileMapResult(width: 2, height: 2, grid: newGrid),
        },
        topology: topology,
      );
      final connected = result['pl1']!.connected;
      expect(connected.contains('oldWorld|p1|1|1'), true);
      expect(connected.contains('oldWorld|p1|0|0'), true);
      expect(connected.contains('newWorld|p2|0|0'), false);
    });

    test('sea path multi-zone: S1–S2 edge, capital on S1, overseas port on S2 connected', () {
      final oldGrid = [['p1', 'p1'], ['p1', 'p1']];
      final newGrid = [['p2', 'p2'], ['p2', 'p2']];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p2', id2: 'sea2'),
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
      );
      const ow = 'oldWorld', nw = 'newWorld';
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|0|0', 4)
          .setRoadLevel('newWorld|p2|0|0', 4);
      final ports = {
        '$ow|p1|sea1': 'oldWorld|p1|0|0',
        '$nw|p2|sea2': 'newWorld|p2|0|0',
      };
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1')]),
          newWorld: RegionData(provinces: [Province(id: '$nw|p2', regionId: nw, ownerId: 'pl1')]),
          tileState: tileState,
          portsByProvinceSeaboard: ports,
        ),
        players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true, capitalProvinceId: '$ow|p1', capitalTile: cap)],
      );
      final result = resolveConnectivity(
        game: game,
        tileMapByRegion: {
          'oldWorld': TileMapResult(width: 2, height: 2, grid: oldGrid),
          'newWorld': TileMapResult(width: 2, height: 2, grid: newGrid),
        },
        topology: topology,
      );
      final connected = result['pl1']!.connected;
      expect(connected.contains('oldWorld|p1|0|0'), true);
      expect(connected.contains('newWorld|p2|0|0'), true);
    });

    test('severed road: losing province on path to capital removes tiles beyond it', () {
      const ow = 'oldWorld';
      final grid = [
        ['p1', 'p2', 'p3'],
        ['p1', 'p2', 'p3'],
      ];
      final tileMap = TileMapResult(width: 3, height: 2, grid: grid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p3', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setRoadLevel('oldWorld|p1|1|0', 1)
          .setRoadLevel('oldWorld|p2|1|0', 1)
          .setRoadLevel('oldWorld|p2|2|0', 1)
          .setRoadLevel('oldWorld|p3|2|0', 1);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p3', regionId: ow, ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [
          Player(id: 'pl1', displayName: 'Spain', isHuman: true, capitalProvinceId: '$ow|p1', capitalTile: cap),
        ],
      );
      final tileMapByRegion = {'oldWorld': tileMap};
      var result = resolveConnectivity(game: game, tileMapByRegion: tileMapByRegion, topology: topology);
      expect(result['pl1']!.connected.contains('oldWorld|p3|2|0'), true);

      final gameP2Lost = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'other'),
            Province(id: '$ow|p3', regionId: ow, ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [
          Player(id: 'pl1', displayName: 'Spain', isHuman: true, capitalProvinceId: '$ow|p1', capitalTile: cap),
        ],
      );
      result = resolveConnectivity(game: gameP2Lost, tileMapByRegion: tileMapByRegion, topology: topology);
      expect(result['pl1']!.connected.contains('oldWorld|p3|2|0'), false);

      final gameP2Restored = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p3', regionId: ow, ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [
          Player(id: 'pl1', displayName: 'Spain', isHuman: true, capitalProvinceId: '$ow|p1', capitalTile: cap),
        ],
      );
      result = resolveConnectivity(game: gameP2Restored, tileMapByRegion: tileMapByRegion, topology: topology);
      expect(result['pl1']!.connected.contains('oldWorld|p3|2|0'), true);
    });

    test('changing townTileKey alone does not change connectivity', () {
      const ow = 'oldWorld';
      final grid = [
        ['p1', 'p2', 'p2'],
        ['p1', 'p2', 'p2'],
      ];
      final tileMap = TileMapResult(width: 3, height: 2, grid: grid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setRoadLevel('oldWorld|p2|1|0', 1)
          .setRoadLevel('oldWorld|p2|2|0', 1)
          .setRoadLevel('oldWorld|p2|2|1', 1);

      final gameTownA = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(
              id: '$ow|p1',
              regionId: ow,
              ownerId: 'pl1',
              townTileKey: 'oldWorld|p1|0|0',
            ),
            Province(
              id: '$ow|p2',
              regionId: ow,
              ownerId: 'pl1',
              townTileKey: 'oldWorld|p2|1|0',
            ),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
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

      final gameTownB = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(
              id: '$ow|p1',
              regionId: ow,
              ownerId: 'pl1',
              townTileKey: 'oldWorld|p1|1|1',
            ),
            Province(
              id: '$ow|p2',
              regionId: ow,
              ownerId: 'pl1',
              townTileKey: 'oldWorld|p2|2|1',
            ),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
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

      final resultA = resolveConnectivity(
        game: gameTownA,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );
      final resultB = resolveConnectivity(
        game: gameTownB,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );

      // Road/Town rules: Town-rule closure can differ when only townTileKey moves;
      // road-rule set must stay aligned for the same roads/capital.
      expect(
        resultA['pl1']!.connectedByRoadRule,
        equals(resultB['pl1']!.connectedByRoadRule),
      );
      expect(
        resultA['pl1']!.pathTransportCap,
        equals(resultB['pl1']!.pathTransportCap),
      );
    });
  });
}
