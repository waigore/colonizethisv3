import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';

void main() {
  group('topologyGraph DSL (Refs #3968)', () {
    test('builds single-region province–sea graph from tables', () {
      final topology = topologyGraph(
        regionId: kWorldTestOw,
        provinces: ['p1'],
        seas: ['s1'],
        edges: [('p1', 's1')],
      );

      expect(topology.nodes, hasLength(2));
      expect(
        topology.nodes.singleWhere((n) => n.id == 'p1').type,
        TopologyNodeType.province,
      );
      expect(
        topology.nodes.singleWhere((n) => n.id == 's1').type,
        TopologyNodeType.seaZone,
      );
      expect(topology.edges, hasLength(1));
      expect(topology.edges.single.id1, 'p1');
      expect(topology.edges.single.id2, 's1');
    });

    test('builds multi-region graph from node rows', () {
      final topology = topologyGraphNodes(
        nodes: [
          provinceRow(kWorldTestOw, 'p1'),
          seaRow(kWorldTestNw, 's2'),
        ],
        edges: [('p1', 's2')],
      );

      expect(topology.nodes.map((n) => n.regionId).toSet(), {
        kWorldTestOw,
        kWorldTestNw,
      });
      expect(topology.edges.single.id1, 'p1');
      expect(topology.edges.single.id2, 's2');
    });

    test('negative: empty tables yield empty topology', () {
      final topology = topologyGraph(regionId: kWorldTestOw);
      expect(topology.nodes, isEmpty);
      expect(topology.edges, isEmpty);
    });
  });
}
