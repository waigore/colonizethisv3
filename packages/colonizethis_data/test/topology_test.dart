import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('TopologyNode', () {
    test('fromJson/toJson round-trip province', () {
      const n = TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      );
      final n2 = TopologyNode.fromJson(n.toJson());
      expect(n2.id, 'p1');
      expect(n2.regionId, 'oldWorld');
      expect(n2.type, TopologyNodeType.province);
    });
    test('fromJson/toJson round-trip seaZone', () {
      const n = TopologyNode(
        id: 's1',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      );
      final n2 = TopologyNode.fromJson(n.toJson());
      expect(n2.type, TopologyNodeType.seaZone);
    });
  });

  group('MapTopology', () {
    test('fromJson/toJson round-trip', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(id: 's1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [
          const TopologyEdge(id1: 'p1', id2: 'p2'),
          const TopologyEdge(id1: 'p1', id2: 's1'),
        ],
      );
      final json = topology.toJson();
      final topology2 = MapTopology.fromJson(json);
      expect(topology2.nodes.length, 3);
      expect(topology2.edges.length, 2);
      expect(topology2.edges.any((e) => (e.id1 == 'p1' && e.id2 == 'p2') || (e.id1 == 'p2' && e.id2 == 'p1')), isTrue);
      expect(topology2.edges.any((e) => (e.id1 == 'p1' && e.id2 == 's1') || (e.id1 == 's1' && e.id2 == 'p1')), isTrue);
    });
    test('fromJson with list-style edges', () {
      final json = {
        'nodes': [
          {'id': 'p1', 'regionId': 'oldWorld', 'type': 'province'},
          {'id': 'p2', 'regionId': 'oldWorld', 'type': 'province'},
        ],
        'edges': [
          ['p1', 'p2'],
        ],
      };
      final topology = MapTopology.fromJson(json);
      expect(topology.nodes.length, 2);
      expect(topology.edges.length, 1);
      expect(topology.edges[0].id1, 'p1');
      expect(topology.edges[0].id2, 'p2');
    });
  });
}
