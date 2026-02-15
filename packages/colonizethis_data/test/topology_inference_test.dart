import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:test/test.dart';

void main() {
  group('inferTopologyFromTileMap', () {
    test('infers nodes and edges from a simple grid', () {
      final result = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 'p2'],
          ['p1', 's1'],
        ],
      );
      final topology =
          inferTopologyFromTileMap(result, 'oldWorld', 's1');
      expect(topology.nodes.length, 3);
      expect(
        topology.nodes.map((n) => n.id).toSet(),
        {'p1', 'p2', 's1'},
      );
      expect(
        topology.nodes.singleWhere((n) => n.id == 's1').type,
        TopologyNodeType.seaZone,
      );
      expect(
        topology.nodes.where((n) => n.type == TopologyNodeType.province).length,
        2,
      );
      expect(topology.edges.length, 3);
      final pairKeys = topology.edges
          .map((e) => e.id1.compareTo(e.id2) < 0 ? '${e.id1}|${e.id2}' : '${e.id2}|${e.id1}')
          .toSet();
      expect(pairKeys, contains('p1|p2'));
      expect(pairKeys, contains('p1|s1'));
      expect(pairKeys, contains('p2|s1'));
    });

    test('classifies sea zone by id', () {
      final result = TileMapResult(
        width: 1,
        height: 1,
        grid: [['s1']],
      );
      final topology =
          inferTopologyFromTileMap(result, 'newWorld', 's1');
      expect(topology.nodes.length, 1);
      expect(topology.nodes.single.type, TopologyNodeType.seaZone);
      expect(topology.edges.length, 0);
    });

    test('classifies provinces for non-sea ids', () {
      final result = TileMapResult(
        width: 2,
        height: 1,
        grid: [['p1', 'p2']],
      );
      final topology =
          inferTopologyFromTileMap(result, 'oldWorld', 's1');
      expect(topology.nodes.length, 2);
      expect(topology.nodes.every((n) => n.type == TopologyNodeType.province),
          isTrue);
      expect(topology.edges.length, 1);
      expect(topology.edges.single.id1, 'p1');
      expect(topology.edges.single.id2, 'p2');
    });

    test('classifies multiple sea zones s1 and s2, infers S-S edge when adjacent', () {
      final result = TileMapResult(
        width: 3,
        height: 1,
        grid: [['p1', 's1', 's2']],
      );
      final topology =
          inferTopologyFromTileMap(result, 'oldWorld', 's1');
      expect(topology.nodes.length, 3);
      expect(
        topology.nodes.singleWhere((n) => n.id == 's1').type,
        TopologyNodeType.seaZone,
      );
      expect(
        topology.nodes.singleWhere((n) => n.id == 's2').type,
        TopologyNodeType.seaZone,
      );
      final pairKeys = topology.edges
          .map((e) => e.id1.compareTo(e.id2) < 0 ? '${e.id1}|${e.id2}' : '${e.id2}|${e.id1}')
          .toSet();
      expect(pairKeys, contains('s1|s2'));
      expect(pairKeys, contains('p1|s1'));
    });
  });
}
