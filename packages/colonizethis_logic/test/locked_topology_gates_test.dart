import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

MapTopology _pathLandmass({
  required String prefix,
  required int size,
  required int seaBoundProvinceCount,
}) {
  assert(seaBoundProvinceCount >= 1);
  assert(seaBoundProvinceCount <= size);
  final nodes = <TopologyNode>[];
  final edges = <TopologyEdge>[];
  for (var i = 0; i < size; i++) {
    nodes.add(
      TopologyNode(
        id: '$prefix$i',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    );
  }
  for (var i = 0; i < size - 1; i++) {
    edges.add(TopologyEdge(id1: '$prefix$i', id2: '${prefix}${i + 1}'));
  }
  for (var s = 0; s < seaBoundProvinceCount; s++) {
    final seaId = '${prefix}sea$s';
    nodes.add(
      TopologyNode(
        id: seaId,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    );
    edges.add(TopologyEdge(id1: '$prefix$s', id2: seaId));
  }
  return MapTopology(nodes: nodes, edges: edges);
}

MapTopology _mergeTopologies(List<MapTopology> parts) {
  final nodes = <TopologyNode>[];
  final edges = <TopologyEdge>[];
  for (final p in parts) {
    nodes.addAll(p.nodes);
    edges.addAll(p.edges);
  }
  return MapTopology(nodes: nodes, edges: edges);
}

Map<String, Set<String>> _ppNeighboursFromTopology(MapTopology topology) =>
    provincePpNeighbours(topology);

void main() {
  group('locked_topology_gates', () {
    test('provincePpNeighbours ignores non-province nodes and sea edges', () {
      final topo = MapTopology(
        nodes: [
          const TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [const TopologyEdge(id1: 'p1', id2: 's1')],
      );
      expect(provincePpNeighbours(topo), {'p1': <String>{}});
    });

    test('ppLandComponentSizesSorted returns sorted multiset', () {
      final topo = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'a',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'b',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'c',
            regionId: 'oldWorld',
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
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'b',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      expect(oldWorldPartitionMatchesLockedProfile(topo), false);
      expect(newWorldPartitionMatchesLockedProfile(topo), false);
    });

    test(
      'oldWorldPartitionMatchesLockedProfile true for four path landmasses',
      () {
        final topo = _mergeTopologies([
          _pathLandmass(prefix: 'O1', size: 17, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'O2', size: 17, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'O3', size: 13, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'O4', size: 13, seaBoundProvinceCount: 1),
        ]);
        expect(oldWorldPartitionMatchesLockedProfile(topo), true);
      },
    );

    test(
      'newWorldPartitionMatchesLockedProfile true for four path landmasses',
      () {
        final topo = _mergeTopologies([
          _pathLandmass(prefix: 'N1', size: 9, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'N2', size: 9, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'N3', size: 6, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'N4', size: 6, seaBoundProvinceCount: 1),
        ]);
        expect(newWorldPartitionMatchesLockedProfile(topo), true);
      },
    );

    test(
      'lockedOldWorldRoleFeasibilityHolds passes for four feasible landmasses',
      () {
        final parts = [
          _pathLandmass(prefix: 'A', size: 17, seaBoundProvinceCount: 2),
          _pathLandmass(prefix: 'B', size: 17, seaBoundProvinceCount: 2),
          _pathLandmass(prefix: 'C', size: 13, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'D', size: 13, seaBoundProvinceCount: 1),
        ];
        final topo = _mergeTopologies(parts);
        final nbr = _ppNeighboursFromTopology(topo);
        expect(
          lockedOldWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          true,
        );
      },
    );

    test(
      'lockedOldWorldRoleFeasibilityHolds fails when not four landmasses',
      () {
        final topo = _mergeTopologies([
          _pathLandmass(prefix: 'A', size: 13, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'B', size: 13, seaBoundProvinceCount: 1),
        ]);
        final nbr = _ppNeighboursFromTopology(topo);
        expect(
          lockedOldWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          false,
        );
      },
    );

    test(
      'lockedOldWorldRoleFeasibilityHolds fails when landmass too small',
      () {
        final topo = _mergeTopologies([
          _pathLandmass(prefix: 'A', size: 17, seaBoundProvinceCount: 2),
          _pathLandmass(prefix: 'B', size: 17, seaBoundProvinceCount: 2),
          _pathLandmass(prefix: 'C', size: 13, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'D', size: 12, seaBoundProvinceCount: 1),
        ]);
        final nbr = _ppNeighboursFromTopology(topo);
        expect(
          lockedOldWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          false,
        );
      },
    );

    test(
      'lockedOldWorldRoleFeasibilityHolds fails when sea-bound count too low',
      () {
        final topo = _mergeTopologies([
          _pathLandmass(prefix: 'A', size: 17, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'B', size: 17, seaBoundProvinceCount: 2),
          _pathLandmass(prefix: 'C', size: 13, seaBoundProvinceCount: 1),
          _pathLandmass(prefix: 'D', size: 13, seaBoundProvinceCount: 1),
        ]);
        final nbr = _ppNeighboursFromTopology(topo);
        expect(
          lockedOldWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          false,
        );
      },
    );

    test(
      'lockedNewWorldRoleFeasibilityHolds passes for 9/9/6/6 with enough sea',
      () {
        final parts = [
          _pathLandmass(prefix: 'W', size: 9, seaBoundProvinceCount: 3),
          _pathLandmass(prefix: 'X', size: 9, seaBoundProvinceCount: 3),
          _pathLandmass(prefix: 'Y', size: 6, seaBoundProvinceCount: 2),
          _pathLandmass(prefix: 'Z', size: 6, seaBoundProvinceCount: 2),
        ];
        final topo = _mergeTopologies(parts);
        final nbr = _ppNeighboursFromTopology(topo);
        expect(
          lockedNewWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          true,
        );
      },
    );

    test(
      'lockedNewWorldRoleFeasibilityHolds fails on wrong component sizes',
      () {
        final topo = _mergeTopologies([
          _pathLandmass(prefix: 'W', size: 8, seaBoundProvinceCount: 2),
          _pathLandmass(prefix: 'X', size: 9, seaBoundProvinceCount: 3),
          _pathLandmass(prefix: 'Y', size: 6, seaBoundProvinceCount: 2),
          _pathLandmass(prefix: 'Z', size: 7, seaBoundProvinceCount: 2),
        ]);
        final nbr = _ppNeighboursFromTopology(topo);
        expect(
          lockedNewWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          false,
        );
      },
    );

    test(
      'lockedNewWorldRoleFeasibilityHolds fails when sea-bound tribes need unmet',
      () {
        final topo = _mergeTopologies([
          _pathLandmass(prefix: 'W', size: 9, seaBoundProvinceCount: 2),
          _pathLandmass(prefix: 'X', size: 9, seaBoundProvinceCount: 3),
          _pathLandmass(prefix: 'Y', size: 6, seaBoundProvinceCount: 2),
          _pathLandmass(prefix: 'Z', size: 6, seaBoundProvinceCount: 2),
        ]);
        final nbr = _ppNeighboursFromTopology(topo);
        expect(
          lockedNewWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          false,
        );
      },
    );
  });
}
