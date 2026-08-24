import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'support/locked_topology_path_landmass.dart';

void main() {
  group('locked_topology_gates', () {
    test('provincePpNeighbours ignores non-province nodes and sea edges', () {
      final topo = MapTopology(
        nodes: [
          const TopologyNode(
            id: 'p1',
            regionId: kOldWorldRegionId,
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 's1',
            regionId: kOldWorldRegionId,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [const TopologyEdge(id1: 'p1', id2: 's1')],
      );
      expect(provincePpNeighbours(topo), {'p1': <String>{}});
    });

    test('landmassesSortedDesc orders by size desc then min province id', () {
      final topo = lockedTopologyMerge([
        lockedTopologyPathLandmass(
          prefix: 'B',
          size: 2,
          seaBoundProvinceCount: 1,
        ),
        lockedTopologyPathLandmass(
          prefix: 'A',
          size: 3,
          seaBoundProvinceCount: 1,
        ),
        lockedTopologyPathLandmass(
          prefix: 'C',
          size: 2,
          seaBoundProvinceCount: 1,
        ),
      ]);
      final nbr = provincePpNeighbours(topo);
      final landmasses = landmassesSortedDesc(nbr);
      expect(landmasses.map((lm) => lm.size).toList(), [3, 2, 2]);
      // Equal-size landmasses break ties on the lexicographically-min id.
      expect(
        landmasses[1].minProvinceId.compareTo(landmasses[2].minProvinceId) < 0,
        true,
      );
    });

    test('pushUnvisitedPpNeighbors skips visited and pushes the rest', () {
      final neighbours = <String, Set<String>>{
        'a': {'b', 'c'},
        'b': {'a'},
        'c': {'a'},
      };
      final stack = <String>[];
      // Negative: a visited neighbour must not be re-pushed.
      pushUnvisitedPpNeighbors('a', neighbours, {'b'}, stack);
      expect(stack, ['c']);
    });

    test('ppLandComponentSizesSorted returns sorted multiset', () {
      final topo = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'a',
            regionId: kOldWorldRegionId,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'b',
            regionId: kOldWorldRegionId,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'c',
            regionId: kOldWorldRegionId,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'a', id2: 'b')],
      );
      expect(ppLandComponentSizesSorted(topo), [1, 2]);
    });

    test('partition matchers compare against locked multisets', () {
      final topo = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'a',
            regionId: kOldWorldRegionId,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'b',
            regionId: kOldWorldRegionId,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      expect(oldWorldPartitionMatchesLockedProfile(topo), false);
      expect(newWorldPartitionMatchesLockedProfile(topo), false);
    });
  });
}
