import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';

/// GP road/town resolveConnectivity cases ported from logic (Refs #4090).
void main() {
  group('ConnectivityResolver road/town', () {
    test('no roads: capital and adjacent tiles connected', () {
      // 3x3 grid, one province "p1", capital at (1,1). Spec: adjacent to capital is connected.
      final grid = [
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ];
      final tileMap = tileMapFromGrid(grid);
      final topology = topologyFromGraph(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
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
      final game = ordersPhaseGame(
        oldWorldProvinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
        ],
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
      final tileMap = tileMapFromGrid(grid);
      final topology = topologyFromGraph(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
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
      final game = ordersPhaseGame(
        oldWorldProvinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
        ],
        tileState: tileState,
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
      final grid = [
        ['p1'],
      ];
      final tileMap = tileMapFromGrid(grid);
      final topology = topologyFromGraph(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final player = Player(id: 'pl1', displayName: 'Spain', isHuman: true);
      final game = ordersPhaseGame(
        oldWorldProvinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
        ],
        players: [player],
      );
      final result = resolveConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );
      expect(result['pl1']!.connected, isEmpty);
    });

    test('severed road: losing province on path to capital removes tiles beyond it', () {
      const ow = 'oldWorld';
      final grid = [
        ['p1', 'p2', 'p3'],
        ['p1', 'p2', 'p3'],
      ];
      final tileMap = tileMapFromGrid(grid);
      final topology = topologyFromGraph(
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
      final players = [
        Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: '$ow|p1',
          capitalTile: cap,
        ),
      ];
      final game = ordersPhaseGame(
        oldWorldProvinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
          Province(id: '$ow|p3', regionId: ow, ownerId: 'pl1'),
        ],
        tileState: tileState,
        players: players,
      );
      final tileMapByRegion = {'oldWorld': tileMap};
      var result = resolveConnectivity(
        game: game,
        tileMapByRegion: tileMapByRegion,
        topology: topology,
      );
      expect(result['pl1']!.connected.contains('oldWorld|p3|2|0'), true);

      final gameP2Lost = ordersPhaseGame(
        oldWorldProvinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          Province(id: '$ow|p2', regionId: ow, ownerId: 'other'),
          Province(id: '$ow|p3', regionId: ow, ownerId: 'pl1'),
        ],
        tileState: tileState,
        players: players,
      );
      result = resolveConnectivity(
        game: gameP2Lost,
        tileMapByRegion: tileMapByRegion,
        topology: topology,
      );
      expect(result['pl1']!.connected.contains('oldWorld|p3|2|0'), false);

      final gameP2Restored = ordersPhaseGame(
        oldWorldProvinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
          Province(id: '$ow|p3', regionId: ow, ownerId: 'pl1'),
        ],
        tileState: tileState,
        players: players,
      );
      result = resolveConnectivity(
        game: gameP2Restored,
        tileMapByRegion: tileMapByRegion,
        topology: topology,
      );
      expect(result['pl1']!.connected.contains('oldWorld|p3|2|0'), true);
    });

    test('changing townTileKey alone does not change connectivity', () {
      const ow = 'oldWorld';
      final grid = [
        ['p1', 'p2', 'p2'],
        ['p1', 'p2', 'p2'],
      ];
      final tileMap = tileMapFromGrid(grid);
      final topology = topologyFromGraph(
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
      final players = [
        Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: '$ow|p1',
          capitalTile: cap,
        ),
      ];

      final gameTownA = ordersPhaseGame(
        oldWorldProvinces: [
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
        ],
        tileState: tileState,
        players: players,
      );

      final gameTownB = ordersPhaseGame(
        oldWorldProvinces: [
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
        ],
        tileState: tileState,
        players: players,
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
