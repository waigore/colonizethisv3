import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';

/// Town-rule worklist / port-map resolveConnectivity pins ported from logic (Refs #4090).
void main() {
  group('ConnectivityResolver town-rule worklist', () {
    test(
      'multi-province owner with several towns completes (no redundant town enqueue)',
      () {
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
            .setRoadLevel('oldWorld|p1|2|0', 1)
            .setRoadLevel('oldWorld|p2|1|0', 1)
            .setRoadLevel('oldWorld|p2|2|0', 1)
            .setRoadLevel('oldWorld|p3|2|0', 1);
        final player = Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: '$ow|p1',
          capitalTile: cap,
        );
        final game = ordersPhaseGame(
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
            Province(
              id: '$ow|p3',
              regionId: ow,
              ownerId: 'pl1',
              townTileKey: 'oldWorld|p3|2|0',
            ),
          ],
          tileState: tileState,
          players: [player],
        );
        final result = resolveConnectivity(
          game: game,
          tileMapByRegion: {ow: tileMap},
          topology: topology,
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), isTrue);
        expect(connected.contains('oldWorld|p3|2|0'), isTrue);
        expect(connected.length, greaterThanOrEqualTo(6));
      },
    );

    test('many port registry entries reuse single port map per player resolve', () {
      const ow = 'oldWorld';
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final tileMap = tileMapFromGrid(grid);
      final topology = topologyFromGraph(
        nodes: [TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province)],
        edges: [],
      );
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
      final ports = <String, String>{
        for (var i = 0; i < 40; i++) '$ow|p1|sea$i': 'oldWorld|p1|1|0',
      };
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setRoadLevel('oldWorld|p1|1|0', 1);
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
        portsByProvinceSeaboard: ports,
        players: [player],
      );
      final result = resolveConnectivity(
        game: game,
        tileMapByRegion: {ow: tileMap},
        topology: topology,
      );
      expect(result['pl1']!.connected.contains('oldWorld|p1|1|0'), isTrue);
    });
  });
}
