import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

void main() {
  group('generateTopology', () {
    test('single province single continent produces one P and one S with P-S edge', () {
      final t = generateTopology(TopologyGeneratorParams(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'oldWorld',
        seed: 42,
      ));
      expect(t.nodes.length, 2);
      expect(t.nodes.any((n) => n.id == 'p1' && n.type == TopologyNodeType.province), isTrue);
      expect(t.nodes.any((n) => n.id == 's1' && n.type == TopologyNodeType.seaZone), isTrue);
      expect(t.nodes.every((n) => n.regionId == 'oldWorld'), isTrue);
      expect(t.edges.any((e) => (e.id1 == 'p1' && e.id2 == 's1') || (e.id1 == 's1' && e.id2 == 'p1')), isTrue);
    });

    test('six provinces two continents produces connected continents and coastal edges', () {
      final t = generateTopology(TopologyGeneratorParams(
        numProvinces: 6,
        numContinents: 2,
        regionId: 'newWorld',
        seed: 1,
      ));
      expect(t.nodes.length, 7); // p1..p6 + s1
      final provinceIds = t.nodes.where((n) => n.type == TopologyNodeType.province).map((n) => n.id).toSet();
      expect(provinceIds, equals({'p1', 'p2', 'p3', 'p4', 'p5', 'p6'}));
      expect(t.nodes.every((n) => n.regionId == 'newWorld'), isTrue);

      final edgeSet = <String>{};
      for (final e in t.edges) {
        edgeSet.add(e.id1.compareTo(e.id2) < 0 ? '${e.id1}|${e.id2}' : '${e.id2}|${e.id1}');
      }
      // Continent 0: p1-p2-p3, coast p1 and p3. Continent 1: p4-p5-p6, coast p4 and p6
      expect(edgeSet.contains('p1|p2'), isTrue);
      expect(edgeSet.contains('p2|p3'), isTrue);
      expect(edgeSet.contains('p4|p5'), isTrue);
      expect(edgeSet.contains('p5|p6'), isTrue);
      expect(edgeSet.contains('p1|s1'), isTrue);
      expect(edgeSet.contains('p3|s1'), isTrue);
      expect(edgeSet.contains('p4|s1'), isTrue);
      expect(edgeSet.contains('p6|s1'), isTrue);
      // No cross-continent P-P
      expect(edgeSet.contains('p3|p4'), isFalse);
    });

    test('every province has at least one edge', () {
      final t = generateTopology(TopologyGeneratorParams(
        numProvinces: 10,
        numContinents: 3,
        seed: 99,
      ));
      final provinceIds = t.nodes.where((n) => n.type == TopologyNodeType.province).map((n) => n.id).toSet();
      for (final pid in provinceIds) {
        final hasEdge = t.edges.any((e) => e.id1 == pid || e.id2 == pid);
        expect(hasEdge, isTrue, reason: 'province $pid should have at least one edge');
      }
    });

    test('all edge ids reference existing nodes', () {
      final t = generateTopology(TopologyGeneratorParams(
        numProvinces: 5,
        numContinents: 2,
        seed: 0,
      ));
      final nodeIds = t.nodes.map((n) => n.id).toSet();
      for (final e in t.edges) {
        expect(nodeIds.contains(e.id1), isTrue);
        expect(nodeIds.contains(e.id2), isTrue);
      }
    });
  });
}

