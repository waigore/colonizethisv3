import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

void main() {
  group('validateTileMapTopology', () {
    test('grid missing required adjacency yields missing non-empty', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'p1', regionId: 'r1', type: TopologyNodeType.province),
          const TopologyNode(id: 'p2', regionId: 'r1', type: TopologyNodeType.province),
          const TopologyNode(id: 's1', regionId: 'r1', type: TopologyNodeType.seaZone),
        ],
        edges: [
          const TopologyEdge(id1: 'p1', id2: 'p2'),
          const TopologyEdge(id1: 'p1', id2: 's1'),
          const TopologyEdge(id1: 'p2', id2: 's1'),
        ],
      );
      final grid = [
        ['p1', 'p1', 's1'],
        ['p1', 'p1', 's1'],
        ['s1', 's1', 's1'],
      ];
      final result = TileMapResult(width: 3, height: 3, grid: grid);
      final validation = validateTileMapTopology(topology, result);
      expect(validation.missing, contains('p1|p2'));
      expect(validation.hasIssues, isTrue);
    });
  });
}

