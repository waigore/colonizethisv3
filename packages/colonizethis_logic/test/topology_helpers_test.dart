import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/world/topology_helpers.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('provinceNodeIds / provinceNodeIdsForRegion', () {
    test('return province ids by topology and region', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p3', regionId: nw, type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: [],
      );

      final all = provinceNodeIds(topology);
      expect(all, containsAll(<String>['p1', 'p2', 'p3']));
      expect(all.contains('sea1'), isFalse);

      final owProvinces = provinceNodeIdsForRegion(topology, ow);
      final nwProvinces = provinceNodeIdsForRegion(topology, nw);

      expect(owProvinces, containsAll(<String>['p1', 'p2']));
      expect(owProvinces.contains('p3'), isFalse);
      expect(nwProvinces, contains('p3'));
      expect(nwProvinces.contains('p1'), isFalse);
    });
  });

  group('topologyUsesPrefixedIds', () {
    test('is true when any node id is prefixed', () {
      const topologyWithPrefixed = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [],
      );

      const topologyWithoutPrefixed = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [],
      );

      expect(topologyUsesPrefixedIds(topologyWithPrefixed), isTrue);
      expect(topologyUsesPrefixedIds(topologyWithoutPrefixed), isFalse);
    });
  });

  group('seaZoneNodeIds / seaZonesReachableBySeaPath', () {
    test('returns all sea zones and BFS over S–S edges', () {
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea3', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
          TopologyEdge(id1: 'sea2', id2: 'sea3'),
          // Province edge should be ignored by sea path logic.
          TopologyEdge(id1: 'p1', id2: 'sea1'),
        ],
      );

      final seas = seaZoneNodeIds(topology);
      expect(seas, containsAll(<String>['sea1', 'sea2', 'sea3']));
      expect(seas.contains('p1'), isFalse);

      final reachableFromSea1 = seaZonesReachableBySeaPath(topology, {'sea1'});
      expect(reachableFromSea1, containsAll(<String>['sea1', 'sea2', 'sea3']));
      // Province node must not appear in reachable set.
      expect(reachableFromSea1.contains('p1'), isFalse);
    });
  });

  group('seaZonesAdjacentToProvince', () {
    test('returns sea zones touching a province via P–S edges only', () {
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea3', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [
          // p1 touches sea1 and sea2
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'sea2', id2: 'p1'),
          // p2 touches sea3 only
          TopologyEdge(id1: 'p2', id2: 'sea3'),
          // sea-sea edge should not affect adjacency sets
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
      );

      final p1Adj = seaZonesAdjacentToProvince(topology, 'p1');
      final p2Adj = seaZonesAdjacentToProvince(topology, 'p2');

      expect(p1Adj, containsAll(<String>['sea1', 'sea2']));
      expect(p1Adj.contains('sea3'), isFalse);

      expect(p2Adj, contains('sea3'));
      expect(p2Adj.contains('sea1'), isFalse);
      expect(p2Adj.contains('sea2'), isFalse);
    });
  });
}

