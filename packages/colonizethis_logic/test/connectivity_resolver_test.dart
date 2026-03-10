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

    group('blockade', () {
      test('blockaded port province excluded from connectivity', () {
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
          blockadedPortProvincesByPlayerId: {'pl1': {'newWorld|p2'}},
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), true);
        expect(connected.contains('newWorld|p2|0|0'), false);
      });

      test('capital province blockaded: no sea connectivity', () {
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
          blockadedPortProvincesByPlayerId: {'pl1': {'oldWorld|p1'}},
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), true);
        expect(connected.contains('newWorld|p2|0|0'), false);
      });

      test('computeBlockadedPortProvincesByPlayer same-region: fleet in OW blockades OW port when at war', () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
          ],
          edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ]),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                inPortAtProvinceId: null,
                regionId: ow,
                mission: FleetMission.blockade,
                targetProvinceId: '$ow|p2',
              ),
            ],
          ),
          players: [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            Player(id: 'p2', displayName: 'France', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p2', state: RelationState.atWar),
          ],
        );
        final blockaded = computeBlockadedPortProvincesByPlayer(game, topology);
        expect(blockaded['pl1'], contains('oldWorld|p2'));
        expect(blockaded['p2'], isEmpty);
      });

      test('computeBlockadedPortProvincesByPlayer cross-region: fleet in OW blockades NW port when at war', () {
        const ow = 'oldWorld';
        const nw = 'newWorld';
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'n1', regionId: nw, type: TopologyNodeType.province),
            TopologyNode(id: 'sea_ow', regionId: ow, type: TopologyNodeType.seaZone),
          ],
          edges: [TopologyEdge(id1: 'sea_ow', id2: 'n1')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            ]),
            newWorld: RegionData(provinces: [
              Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1'),
            ]),
            fleets: [
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea_ow',
                inPortAtProvinceId: null,
                regionId: ow,
                mission: FleetMission.blockade,
                targetProvinceId: '$nw|n1',
              ),
            ],
          ),
          players: [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            Player(id: 'p2', displayName: 'France', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p2', state: RelationState.atWar),
          ],
        );
        final blockaded = computeBlockadedPortProvincesByPlayer(game, topology);
        expect(blockaded['pl1'], contains('newWorld|n1'));
        expect(blockaded['p2'], isEmpty);
      });

      test('computeBlockadedPortProvincesByPlayer cross-region: fleet in NW blockades OW port when at war', () {
        const ow = 'oldWorld';
        const nw = 'newWorld';
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'sea_nw', regionId: nw, type: TopologyNodeType.seaZone),
          ],
          edges: [TopologyEdge(id1: 'sea_nw', id2: 'p2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ]),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea_nw',
                inPortAtProvinceId: null,
                regionId: nw,
                mission: FleetMission.blockade,
                targetProvinceId: '$ow|p2',
              ),
            ],
          ),
          players: [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            Player(id: 'p2', displayName: 'France', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p2', state: RelationState.atWar),
          ],
        );
        final blockaded = computeBlockadedPortProvincesByPlayer(game, topology);
        expect(blockaded['pl1'], contains('oldWorld|p2'));
      });

      test('computeBlockadedPortProvincesByPlayer only at-war blockader counts: peace fleet does not add province', () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
            TopologyNode(id: 'sea2', regionId: ow, type: TopologyNodeType.seaZone),
          ],
          edges: [TopologyEdge(id1: 'sea1', id2: 'p2'), TopologyEdge(id1: 'sea2', id2: 'p2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ]),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                inPortAtProvinceId: null,
                regionId: ow,
                mission: FleetMission.blockade,
                targetProvinceId: '$ow|p2',
              ),
              Fleet(
                id: 'fleet_p3',
                ownerId: 'p3',
                seaZoneId: 'sea2',
                inPortAtProvinceId: null,
                regionId: ow,
                mission: FleetMission.blockade,
                targetProvinceId: '$ow|p2',
              ),
            ],
          ),
          players: [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            Player(id: 'p2', displayName: 'France', isHuman: true),
            Player(id: 'p3', displayName: 'England', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p2', state: RelationState.atWar),
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p3', state: RelationState.atPeace),
          ],
        );
        final blockaded = computeBlockadedPortProvincesByPlayer(game, topology);
        expect(blockaded['pl1'], contains('oldWorld|p2'));
        expect(blockaded['pl1']!.length, 1);
      });

      test('computeBlockadedPortProvincesByPlayer returns empty when at peace', () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
          ],
          edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ]),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                inPortAtProvinceId: null,
                regionId: ow,
                mission: FleetMission.blockade,
                targetProvinceId: '$ow|p2',
              ),
            ],
          ),
          players: [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            Player(id: 'p2', displayName: 'France', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p2', state: RelationState.atPeace),
          ],
        );
        final blockaded = computeBlockadedPortProvincesByPlayer(game, topology);
        expect(blockaded['pl1'], isEmpty);
        expect(blockaded['p2'], isEmpty);
      });

      test('computeBlockadedPortProvincesByPlayer ignores fleet without targetProvinceId', () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
          ],
          edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ]),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                inPortAtProvinceId: null,
                regionId: ow,
                mission: FleetMission.blockade,
                targetProvinceId: null,
              ),
            ],
          ),
          players: [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            Player(id: 'p2', displayName: 'France', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p2', state: RelationState.atWar),
          ],
        );
        final blockaded = computeBlockadedPortProvincesByPlayer(game, topology);
        expect(blockaded['pl1'], isEmpty);
      });

      test('computeBlockadedPortProvincesByPlayer ignores non-blockade missions', () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
          ],
          edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ]),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                inPortAtProvinceId: null,
                regionId: ow,
                mission: FleetMission.patrol,
                targetProvinceId: '$ow|p2',
              ),
            ],
          ),
          players: [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            Player(id: 'p2', displayName: 'France', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p2', state: RelationState.atWar),
          ],
        );
        final blockaded = computeBlockadedPortProvincesByPlayer(game, topology);
        expect(blockaded['pl1'], isEmpty);
      });

      test('computeBlockadedPortProvincesByPlayer returns multiple provinces when two enemies blockade', () {
        const ow = 'oldWorld';
        const nw = 'newWorld';
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'n1', regionId: nw, type: TopologyNodeType.province),
            TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
            TopologyNode(id: 'sea2', regionId: nw, type: TopologyNodeType.seaZone),
          ],
          edges: [TopologyEdge(id1: 'sea1', id2: 'p2'), TopologyEdge(id1: 'sea2', id2: 'n1')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ]),
            newWorld: RegionData(provinces: [
              Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1'),
            ]),
            fleets: [
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                inPortAtProvinceId: null,
                regionId: ow,
                mission: FleetMission.blockade,
                targetProvinceId: '$ow|p2',
              ),
              Fleet(
                id: 'fleet_p3',
                ownerId: 'p3',
                seaZoneId: 'sea2',
                inPortAtProvinceId: null,
                regionId: nw,
                mission: FleetMission.blockade,
                targetProvinceId: '$nw|n1',
              ),
            ],
          ),
          players: [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            Player(id: 'p2', displayName: 'France', isHuman: true),
            Player(id: 'p3', displayName: 'England', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p2', state: RelationState.atWar),
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p3', state: RelationState.atWar),
          ],
        );
        final blockaded = computeBlockadedPortProvincesByPlayer(game, topology);
        expect(blockaded['pl1'], containsAll(['oldWorld|p2', 'newWorld|n1']));
        expect(blockaded['pl1']!.length, 2);
      });

      test('resolveConnectivity uses game fleets and diplomacy when blockadedPortProvincesByPlayerId not passed', () {
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
            fleets: [
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea2',
                regionId: nw,
                mission: FleetMission.blockade,
                targetProvinceId: '$nw|p2',
              ),
            ],
          ),
          players: [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true, capitalProvinceId: '$ow|p1', capitalTile: cap),
            Player(id: 'p2', displayName: 'France', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(factionId1: 'pl1', factionId2: 'p2', state: RelationState.atWar),
          ],
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
        expect(connected.contains('newWorld|p2|0|0'), false);
      });

      test('same-region two ports: blockaded port excluded, other port and capital connected', () {
        final grid = [
          ['p1', 'p1', 'p2', 'p2'],
          ['p1', 'p1', 'p2', 'p2'],
        ];
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
            TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
            TopologyNode(id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'sea2'),
            TopologyEdge(id1: 'sea1', id2: 'sea2'),
          ],
        );
        const ow = 'oldWorld';
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|0|0', 4)
            .setRoadLevel('oldWorld|p1|1|0', 4)
            .setRoadLevel('oldWorld|p2|2|0', 4)
            .setRoadLevel('oldWorld|p2|3|0', 4);
        final ports = {
          '$ow|p1|sea1': 'oldWorld|p1|0|0',
          '$ow|p2|sea2': 'oldWorld|p2|2|0',
        };
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
            portsByProvinceSeaboard: ports,
          ),
          players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true, capitalProvinceId: '$ow|p1', capitalTile: cap)],
        );
        final result = resolveConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': TileMapResult(width: 4, height: 2, grid: grid)},
          topology: topology,
          blockadedPortProvincesByPlayerId: {'pl1': {'oldWorld|p2'}},
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), true);
        expect(connected.contains('oldWorld|p1|1|0'), true);
        expect(connected.contains('oldWorld|p2|2|0'), false);
        expect(connected.contains('oldWorld|p2|3|0'), false);
      });

      test('capital not on seaboard: land-connected port blockaded still excluded', () {
        final grid = [
          ['p1', 'p2'],
          ['p1', 'p2'],
        ];
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          ],
          edges: [],
        );
        const ow = 'oldWorld';
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|0|0', 1)
            .setRoadLevel('oldWorld|p1|1|0', 1)
            .setRoadLevel('oldWorld|p2|1|0', 4)
            .setRoadLevel('oldWorld|p2|1|1', 4);
        final ports = {'$ow|p2|dummy': 'oldWorld|p2|1|0'};
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
            portsByProvinceSeaboard: ports,
          ),
          players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true, capitalProvinceId: '$ow|p1', capitalTile: cap)],
        );
        final resultNoBlockade = resolveConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': TileMapResult(width: 2, height: 2, grid: grid)},
          topology: topology,
        );
        expect(resultNoBlockade['pl1']!.connected.contains('oldWorld|p2|1|0'), true);

        final resultBlockade = resolveConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': TileMapResult(width: 2, height: 2, grid: grid)},
          topology: topology,
          blockadedPortProvincesByPlayerId: {'pl1': {'oldWorld|p2'}},
        );
        expect(resultBlockade['pl1']!.connected.contains('oldWorld|p2|1|0'), false);
        expect(resultBlockade['pl1']!.connected.contains('oldWorld|p1|0|0'), true);
      });
    });
  });
}
