import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/src/gen/topology_inference.dart';

void main() {
  group('inferTopologyFromTileMap', () {
    test('infers provinces and sea zones from grid', () {
      final result = TileMapResult(
        width: 3,
        height: 2,
        grid: [
          ['p1', 'p1', 's1'],
          ['p2', 'p2', 's1'],
        ],
      );
      final topology = inferTopologyFromTileMap(result, 'oldWorld');
      final provinceIds = topology.nodes
          .where((n) => n.type == TopologyNodeType.province)
          .map((n) => n.id)
          .toSet();
      final seaIds = topology.nodes
          .where((n) => n.type == TopologyNodeType.seaZone)
          .map((n) => n.id)
          .toSet();
      expect(provinceIds, equals({'p1', 'p2'}));
      expect(seaIds, equals({'s1'}));
      expect(topology.nodes.every((n) => n.regionId == 'oldWorld'), isTrue);
    });

    test('infers edges from adjacency pairs', () {
      final result = TileMapResult(
        width: 3,
        height: 2,
        grid: [
          ['p1', 'p1', 's1'],
          ['p2', 'p2', 's1'],
        ],
      );
      final topology = inferTopologyFromTileMap(result, 'oldWorld');
      final edgeSet = <String>{};
      for (final e in topology.edges) {
        final key = e.id1.compareTo(e.id2) < 0 ? '${e.id1}|${e.id2}' : '${e.id2}|${e.id1}';
        edgeSet.add(key);
      }
      expect(edgeSet.contains('p1|p2'), isTrue);
      expect(edgeSet.contains('p1|s1'), isTrue);
      expect(edgeSet.contains('p2|s1'), isTrue);
    });
  });
}

