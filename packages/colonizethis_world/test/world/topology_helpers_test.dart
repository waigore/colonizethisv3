import 'package:colonizethis_world/src/world/topology_helpers.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';

void main() {
  group('provinceNodeIds / provinceNodeIdsForRegion', () {
    test('return province ids by topology and region', () {
      final topology = topologyGraphNodes(
        nodes: [
          provinceRow('oldWorld', 'p1'),
          provinceRow('oldWorld', 'p2'),
          provinceRow('newWorld', 'p3'),
          seaRow('oldWorld', 'sea1'),
        ],
      );
      final all = provinceNodeIds(topology);
      expect(all, containsAll(<String>['p1', 'p2', 'p3']));
      expect(all.contains('sea1'), isFalse);
      expect(
        provinceNodeIdsForRegion(topology, 'oldWorld'),
        containsAll(['p1', 'p2']),
      );
      expect(
        provinceNodeIdsForRegion(topology, 'oldWorld').contains('p3'),
        isFalse,
      );
      expect(provinceNodeIdsForRegion(topology, 'newWorld'), contains('p3'));
      expect(
        provinceNodeIdsForRegion(topology, 'newWorld').contains('p1'),
        isFalse,
      );
    });
  });

  group('topologyUsesPrefixedIds', () {
    test('is true when any node id is prefixed', () {
      expect(
        topologyUsesPrefixedIds(
          topologyFromGraph(nodes: [prefixedProvinceNode('oldWorld|p1')]),
        ),
        isTrue,
      );
      expect(
        topologyUsesPrefixedIds(
          provinceSeaZoneTopology(
            regionId: 'oldWorld',
            provinceLocalId: 'p1',
            seaZoneId: 'sea1',
          ),
        ),
        isFalse,
      );
    });
  });

  group('seaZoneNodeIds / seaZonesReachableBySeaPath', () {
    test('returns all sea zones and BFS over S–S edges', () {
      final topology = topologyGraph(
        regionId: 'oldWorld',
        provinces: const ['p1'],
        seas: const ['sea1', 'sea2', 'sea3'],
        edges: const [('sea1', 'sea2'), ('sea2', 'sea3'), ('p1', 'sea1')],
      );
      final seas = seaZoneNodeIds(topology);
      expect(seas, containsAll(<String>['sea1', 'sea2', 'sea3']));
      expect(seas.contains('p1'), isFalse);
      final reachable = seaZonesReachableBySeaPath(topology, {'sea1'});
      expect(reachable, containsAll(<String>['sea1', 'sea2', 'sea3']));
      expect(reachable.contains('p1'), isFalse);
    });
  });

  group('seaZonesAdjacentToProvince', () {
    test('returns sea zones touching a province via P–S edges only', () {
      final topology = topologyGraph(
        regionId: 'oldWorld',
        provinces: const ['p1', 'p2'],
        seas: const ['sea1', 'sea2', 'sea3'],
        edges: const [
          ('p1', 'sea1'),
          ('sea2', 'p1'),
          ('p2', 'sea3'),
          ('sea1', 'sea2'),
        ],
      );
      final p1Adj = seaZonesAdjacentToProvince(topology, 'p1');
      final p2Adj = seaZonesAdjacentToProvince(topology, 'p2');
      expect(p1Adj, containsAll(<String>['sea1', 'sea2']));
      expect(p1Adj.contains('sea3'), isFalse);
      expect(p2Adj, contains('sea3'));
      expect(p2Adj.contains('sea1'), isFalse);
    });
  });

  group('nodesAdjacentTo (Refs #2560)', () {
    test('returns all adjacent node ids regardless of node type', () {
      final topology = topologyGraph(
        regionId: 'oldWorld',
        provinces: const ['p1'],
        seas: const ['sea1', 'sea2', 'sea3'],
        edges: const [('sea1', 'sea2'), ('sea3', 'sea1'), ('p1', 'sea1')],
      );
      expect(
        nodesAdjacentTo(topology, 'sea1'),
        containsAll(['sea2', 'sea3', 'p1']),
      );
      expect(nodesAdjacentTo(topology, 'sea1').length, 3);
      expect(nodesAdjacentTo(topology, 'p1'), equals(<String>['sea1']));
      expect(nodesAdjacentTo(topology, 'missing'), isEmpty);
    });

    test('order follows topology.edges insertion order', () {
      final topology = topologyGraph(
        regionId: 'oldWorld',
        seas: const ['a', 'b', 'c'],
        edges: const [('a', 'b'), ('c', 'a')],
      );
      expect(nodesAdjacentTo(topology, 'a'), equals(<String>['b', 'c']));
    });
  });

  group('topology node id caches (Refs #2316 P2 #15)', () {
    test('provinceNodeIds returns the same Set instance on repeat calls', () {
      final topology = topologyGraph(
        regionId: 'oldWorld',
        provinces: const ['p1', 'p2'],
        seas: const ['sea1'],
      );
      expect(
        identical(provinceNodeIds(topology), provinceNodeIds(topology)),
        isTrue,
      );
      expect(provinceNodeIds(topology), containsAll(<String>['p1', 'p2']));
    });

    test('seaZoneNodeIds returns the same Set instance on repeat calls', () {
      final topology = topologyGraph(
        regionId: 'oldWorld',
        seas: const ['sea1', 'sea2'],
      );
      expect(
        identical(seaZoneNodeIds(topology), seaZoneNodeIds(topology)),
        isTrue,
      );
      expect(seaZoneNodeIds(topology), containsAll(<String>['sea1', 'sea2']));
    });

    test(
      'provinceNodeIdsForRegion returns the same Set for repeat region lookups',
      () {
        final topology = topologyGraphNodes(
          nodes: [provinceRow('oldWorld', 'p1'), provinceRow('newWorld', 'p2')],
        );
        expect(
          identical(
            provinceNodeIdsForRegion(topology, 'oldWorld'),
            provinceNodeIdsForRegion(topology, 'oldWorld'),
          ),
          isTrue,
        );
        expect(
          provinceNodeIdsForRegion(topology, 'oldWorld'),
          equals(<String>{'p1'}),
        );
        expect(
          provinceNodeIdsForRegion(topology, 'newWorld'),
          equals(<String>{'p2'}),
        );
      },
    );

    test('provinceNodeIdsForRegion returns empty set for unknown regions', () {
      final topology = topologyGraph(
        regionId: 'oldWorld',
        provinces: const ['p1'],
      );
      expect(provinceNodeIdsForRegion(topology, 'unknown'), isEmpty);
      expect(
        provinceNodeIdsForRegion(topology, 'oldWorld'),
        containsAll(['p1']),
      );
    });

    test('cached province node sets are read-only', () {
      final cached = provinceNodeIds(
        singleProvinceTopology(regionId: 'oldWorld', provinceLocalId: 'p1'),
      );
      expect(() => cached.add('p2'), throwsUnsupportedError);
    });

    test('separate MapTopology instances do not share cached results', () {
      final t1 = singleProvinceTopology(
        regionId: 'oldWorld',
        provinceLocalId: 'p1',
      );
      final t2 = singleProvinceTopology(
        regionId: 'newWorld',
        provinceLocalId: 'p2',
      );
      expect(provinceNodeIds(t1), equals(<String>{'p1'}));
      expect(provinceNodeIds(t2), equals(<String>{'p2'}));
      expect(identical(provinceNodeIds(t1), provinceNodeIds(t2)), isFalse);
    });
  });
}
