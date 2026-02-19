import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

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
      expect(result['pl1']!.length, 5);
      expect(result['pl1']!.contains('oldWorld|p1|1|1'), true);
      expect(result['pl1']!.contains('oldWorld|p1|0|1'), true);
      expect(result['pl1']!.contains('oldWorld|p1|2|1'), true);
      expect(result['pl1']!.contains('oldWorld|p1|1|0'), true);
      expect(result['pl1']!.contains('oldWorld|p1|1|2'), true);
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
      expect(result['pl1']!.contains('oldWorld|p1|1|1'), true);
      expect(result['pl1']!.contains('oldWorld|p1|0|1'), true);
      expect(result['pl1']!.contains('oldWorld|p1|0|0'), true);
      expect(result['pl1']!.length, greaterThanOrEqualTo(6));
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
      expect(result['pl1'], isEmpty);
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
      expect(result['pl1']!.contains('oldWorld|p1|0|0'), true);
      expect(result['pl1']!.contains('oldWorld|p1|1|0'), true);
      expect(result['pl1']!.contains('newWorld|p2|0|0'), true);
      expect(result['pl1']!.length, greaterThanOrEqualTo(3));
    });
  });
}
