import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';

/// GP sea/port resolveConnectivity cases ported from logic (Refs #4090).

void registerConnectivityResolverGpSeaExtraCases() {
  group('ConnectivityResolver sea/port extra', () {
    test(
      'sea path multi-zone: S1–S2 edge, capital on S1, overseas port on S2 connected',
      () {
        final oldGrid = [
          ['p1', 'p1'],
          ['p1', 'p1'],
        ];
        final newGrid = [
          ['p2', 'p2'],
          ['p2', 'p2'],
        ];
        final topology = topologyFromGraph(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
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
        final game = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          ],
          newWorldProvinces: [
            Province(id: '$nw|p2', regionId: nw, ownerId: 'pl1'),
          ],
          tileState: tileState,
          portsByProvinceSeaboard: ports,
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
        final result = resolveConnectivity(
          game: game,
          tileMapByRegion: {
            'oldWorld': tileMapFromGrid(oldGrid),
            'newWorld': tileMapFromGrid(newGrid),
          },
          topology: topology,
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), true);
        expect(connected.contains('newWorld|p2|0|0'), true);
      },
    );
  });
}
