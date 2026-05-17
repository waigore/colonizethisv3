import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/src/tile_map_topology_helpers.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('seaZoneIdsFromTopology', () {
    test('returns only sea zone node ids', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
            id: 'p1',
            regionId: 'r1',
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 's1',
            regionId: 'r1',
            type: TopologyNodeType.seaZone,
          ),
          const TopologyNode(
            id: 's2',
            regionId: 'r1',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      expect(seaZoneIdsFromTopology(topology), {'s1', 's2'});
    });
  });
}
