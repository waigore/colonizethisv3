import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('CapitalChoice', () {
    test('isProvinceSeaBound true when P-S edge exists', () {
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      expect(isProvinceSeaBound(topology, 'p1'), true);
      expect(isProvinceSeaBound(topology, 'sea1'), false);
    });

    test('setCapital updates player and auto-builds port on coastal capital', () {
      final grid = [
        ['p1', 'sea1'],
        ['p1', 'p1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'pl1', displayName: 'Spain', isHuman: true),
        ],
      );
      final next = setCapital(
        game: game,
        playerId: 'pl1',
        provinceId: 'p1',
        tile: CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
        topology: topology,
        tileMapByRegion: {
          'oldWorld': TileMapResult(width: 2, height: 2, grid: grid),
        },
      );
      expect(next.players.single.capitalProvinceId, 'p1');
      expect(next.players.single.capitalTile?.x, 0);
      expect(next.players.single.capitalTile?.y, 0);
      expect(next.worldState.portsByProvinceSeaboard['p1|sea1'], 'oldWorld|p1|0|0');
      expect(next.worldState.tileState.roadLevel('oldWorld|p1|0|0'), 4);
    });

    test('pickCapitalForFaction returns sea-bound province and valid tile', () {
      final grid = [
        ['p1', 'sea1'],
        ['p2', 'p1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p2', id2: 'p1'),
        ],
      );
      final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
      // p1 is sea-bound, p2 is not. Owned = [p2, p1]; after sort sea-bound = [p1].
      final (provinceId, tile) = pickCapitalForFaction(
        ['p2', 'p1'],
        'oldWorld',
        topology,
        tileMap,
      );
      expect(provinceId, 'p1');
      expect(tile.regionId, 'oldWorld');
      expect(tile.provinceId, 'p1');
      expect(tile.x, 0);
      expect(tile.y, 0);
    });

    test('pickCapitalForFaction throws when no sea-bound province (requireSeaBound: true)', () {
      final grid = [
        ['p1', 'p2'],
        ['p2', 'p2'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
      expect(
        () => pickCapitalForFaction(['p1', 'p2'], 'oldWorld', topology, tileMap),
        throwsArgumentError,
      );
    });

    test('pickCapitalForFaction with requireSeaBound: false returns first province when none sea-bound', () {
      final grid = [
        ['p1', 'p2'],
        ['p2', 'p2'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
      final (provinceId, tile) = pickCapitalForFaction(
        ['p2', 'p1'],
        'oldWorld',
        topology,
        tileMap,
        requireSeaBound: false,
      );
      expect(provinceId, 'p1');
      expect(tile.regionId, 'oldWorld');
      expect(tile.provinceId, 'p1');
    });

    test('setCapitalForMinorNation updates minor and WorldState port/road', () {
      final grid = [
        ['p1', 'sea1'],
        ['p1', 'p1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'min1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: const [],
        minorNations: [MinorNation(id: 'min1', displayName: 'Portugal')],
      );
      final next = setCapitalForMinorNation(
        game: game,
        minorId: 'min1',
        provinceId: 'p1',
        tile: const CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
        topology: topology,
        tileMapByRegion: {'oldWorld': TileMapResult(width: 2, height: 2, grid: grid)},
      );
      expect(next.minorNations.single.capitalProvinceId, 'p1');
      expect(next.minorNations.single.capitalTile?.x, 0);
      expect(next.worldState.portsByProvinceSeaboard['p1|sea1'], 'oldWorld|p1|0|0');
      expect(next.worldState.tileState.roadLevel('oldWorld|p1|0|0'), 4);
    });

    test('setCapitalForTribe updates tribe and WorldState port/road', () {
      final grid = [
        ['nw1', 'sea1'],
        ['nw1', 'nw1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [
            Province(id: 'nw1', regionId: 'newWorld', ownerId: 'tribe1'),
          ]),
        ),
        players: const [],
        tribes: [Tribe(id: 'tribe1', displayName: 'Aztec')],
      );
      final next = setCapitalForTribe(
        game: game,
        tribeId: 'tribe1',
        provinceId: 'nw1',
        tile: const CapitalTile(regionId: 'newWorld', provinceId: 'nw1', x: 0, y: 0),
        topology: topology,
        tileMapByRegion: {'newWorld': TileMapResult(width: 2, height: 2, grid: grid)},
      );
      expect(next.tribes.single.capitalProvinceId, 'nw1');
      expect(next.tribes.single.capitalTile?.regionId, 'newWorld');
      expect(next.worldState.portsByProvinceSeaboard['nw1|sea1'], 'newWorld|nw1|0|0');
    });

    test('setCapitalForMinorNation succeeds with inland province, no port/road applied', () {
      final grid = [
        ['p1', 'p2'],
        ['p2', 'p2'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'min1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: const [],
        minorNations: [MinorNation(id: 'min1', displayName: 'Inland Minor')],
      );
      final next = setCapitalForMinorNation(
        game: game,
        minorId: 'min1',
        provinceId: 'p1',
        tile: const CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
        topology: topology,
        tileMapByRegion: {'oldWorld': TileMapResult(width: 2, height: 2, grid: grid)},
      );
      expect(next.minorNations.single.capitalProvinceId, 'p1');
      expect(next.minorNations.single.capitalTile?.x, 0);
      expect(next.worldState.portsByProvinceSeaboard.isEmpty, true);
    });

    test('setCapitalForTribe succeeds with inland province, no port/road applied', () {
      final grid = [
        ['nw1', 'nw2'],
        ['nw2', 'nw2'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'nw2', regionId: 'newWorld', type: TopologyNodeType.province),
        ],
        edges: [TopologyEdge(id1: 'nw1', id2: 'nw2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [
            Province(id: 'nw1', regionId: 'newWorld', ownerId: 'tribe1'),
          ]),
        ),
        players: const [],
        tribes: [Tribe(id: 'tribe1', displayName: 'Inland Tribe')],
      );
      final next = setCapitalForTribe(
        game: game,
        tribeId: 'tribe1',
        provinceId: 'nw1',
        tile: const CapitalTile(regionId: 'newWorld', provinceId: 'nw1', x: 0, y: 0),
        topology: topology,
        tileMapByRegion: {'newWorld': TileMapResult(width: 2, height: 2, grid: grid)},
      );
      expect(next.tribes.single.capitalProvinceId, 'nw1');
      expect(next.tribes.single.capitalTile?.regionId, 'newWorld');
      expect(next.worldState.portsByProvinceSeaboard.isEmpty, true);
    });

    test('init road path: inland capital + port 2+ steps away → every tile on shortest path has road', () {
      // 3x2: p1 with sea on right; capital inland at (1,1). Nearest coastal is (1,0). Path (1,0)→(1,1) gets road.
      final grid = [
        ['p1', 'p1', 'sea1'],
        ['p1', 'p1', 'p1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      final tileMapByRegion = {'oldWorld': TileMapResult(width: 3, height: 2, grid: grid)};
      final next = setCapital(
        game: game,
        playerId: 'pl1',
        provinceId: 'oldWorld|p1',
        tile: const CapitalTile(regionId: 'oldWorld', provinceId: 'oldWorld|p1', x: 1, y: 1),
        topology: topology,
        tileMapByRegion: tileMapByRegion,
      );
      expect(next.players.single.capitalProvinceId, 'oldWorld|p1');
      final ts = next.worldState.tileState;
      expect(ts.roadLevel('oldWorld|p1|1|1'), 1);
      expect(ts.roadLevel('oldWorld|p1|1|0'), 4);
      expect(ts.roadLevel('oldWorld|p1|1|1'), 1);
    });

    test('setCapitalForReassignment allows inland capital and applies port/road when sea-bound', () {
      final grid = [
        ['p1', 'sea1'],
        ['p1', 'p1'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      final next = setCapitalForReassignment(
        game: game,
        playerId: 'pl1',
        provinceId: 'oldWorld|p1',
        tile: const CapitalTile(regionId: 'oldWorld', provinceId: 'oldWorld|p1', x: 0, y: 0),
        topology: topology,
        tileMapByRegion: {'oldWorld': TileMapResult(width: 2, height: 2, grid: grid)},
      );
      expect(next.players.single.capitalProvinceId, 'oldWorld|p1');
      expect(next.worldState.tileState.roadLevel('oldWorld|p1|0|0'), 4);
    });
  });
}
