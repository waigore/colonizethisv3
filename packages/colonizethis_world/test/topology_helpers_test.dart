import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/world/topology_helpers.dart';
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

  group('nodesAdjacentTo (Refs #2560)', () {
    test('returns all adjacent node ids regardless of node type', () {
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea3',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
          TopologyEdge(id1: 'sea3', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'sea1'),
        ],
      );

      // Sea-zone seed: returns both adjacent sea zones and an adjacent
      // province, mirroring the naval-retreat probe semantics that the
      // previous private `_adjacentSeaZones` provided.
      final adjFromSea1 = nodesAdjacentTo(topology, 'sea1');
      expect(adjFromSea1, containsAll(<String>['sea2', 'sea3', 'p1']));
      expect(adjFromSea1.length, 3);

      // Province seed: returns the sea zone neighbour via the P–S edge.
      expect(nodesAdjacentTo(topology, 'p1'), equals(<String>['sea1']));

      // Unknown node id: empty.
      expect(nodesAdjacentTo(topology, 'missing'), isEmpty);
    });

    test('order follows topology.edges insertion order', () {
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'a',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'b',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'c',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'a', id2: 'b'),
          TopologyEdge(id1: 'c', id2: 'a'),
        ],
      );

      // Single forward pass over edges keeps the order callers historically
      // relied on for the "first acceptable neighbour" probe.
      expect(nodesAdjacentTo(topology, 'a'), equals(<String>['b', 'c']));
    });
  });

  group('topology node id caches (Refs #2316 P2 #15)', () {
    // Per-topology Expando caches: hot-path callers (connectivity, naval,
    // fog) reuse the same set/map instance across calls. Behaviour must be
    // unchanged; only allocation churn is removed.

    test('provinceNodeIds returns the same Set instance on repeat calls', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );

      final first = provinceNodeIds(topology);
      final second = provinceNodeIds(topology);

      expect(identical(first, second), isTrue);
      expect(first, containsAll(<String>['p1', 'p2']));
    });

    test('seaZoneNodeIds returns the same Set instance on repeat calls', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );

      final first = seaZoneNodeIds(topology);
      final second = seaZoneNodeIds(topology);

      expect(identical(first, second), isTrue);
      expect(first, containsAll(<String>['sea1', 'sea2']));
    });

    test(
      'provinceNodeIdsForRegion returns the same Set instance for repeat region lookups',
      () {
        final topology = MapTopology(
          nodes: const [
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
          ],
          edges: const [],
        );

        final firstOw = provinceNodeIdsForRegion(topology, 'oldWorld');
        final secondOw = provinceNodeIdsForRegion(topology, 'oldWorld');
        final firstNw = provinceNodeIdsForRegion(topology, 'newWorld');

        expect(identical(firstOw, secondOw), isTrue);
        expect(firstOw, equals(<String>{'p1'}));
        expect(firstNw, equals(<String>{'p2'}));
      },
    );

    test(
      'provinceNodeIdsForRegion returns the same empty set sentinel for unknown regions',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );

        final missing = provinceNodeIdsForRegion(topology, 'unknown');
        expect(missing, isEmpty);
        // Lookup must not poison the cache: known regions stay populated.
        expect(
          provinceNodeIdsForRegion(topology, 'oldWorld'),
          containsAll(<String>['p1']),
        );
      },
    );

    test('cached province node sets are read-only', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );

      final cached = provinceNodeIds(topology);
      expect(() => cached.add('p2'), throwsUnsupportedError);
    });

    test('separate MapTopology instances do not share cached results', () {
      final t1 = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final t2 = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p2',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );

      expect(provinceNodeIds(t1), equals(<String>{'p1'}));
      expect(provinceNodeIds(t2), equals(<String>{'p2'}));
      expect(identical(provinceNodeIds(t1), provinceNodeIds(t2)), isFalse);
    });
  });
}

