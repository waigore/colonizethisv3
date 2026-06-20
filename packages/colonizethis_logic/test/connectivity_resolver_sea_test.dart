import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('ConnectivityResolver sea/port', () {
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
  });
}
