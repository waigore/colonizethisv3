import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/world/topology_helpers.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('topologyForRegion (Refs #2560)', () {
    test('returns override when topologyByRegion provides one', () {
      const base = MapTopology(nodes: [], edges: []);
      const override = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );

      final got = topologyForRegion(
        base,
        'oldWorld',
        topologyByRegion: const {'oldWorld': override},
      );

      expect(identical(got, override), isTrue);
    });

    test(
      'computes region subgraph and caches per (topology, regionId)',
      () {
        final base = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'newWorld|p9',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|sea1'),
            TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2'),
            // Cross-region edge: must be excluded from per-region subgraph.
            TopologyEdge(id1: 'oldWorld|p1', id2: 'newWorld|p9'),
          ],
        );

        final ow = topologyForRegion(base, 'oldWorld');
        expect(ow.nodes.map((n) => n.id), [
          'oldWorld|p1',
          'oldWorld|p2',
          'oldWorld|sea1',
        ]);
        expect(ow.edges.length, 2);
        expect(
          ow.edges.any(
            (e) => e.id1 == 'oldWorld|p1' && e.id2 == 'oldWorld|sea1',
          ),
          isTrue,
        );
        expect(
          ow.edges.any((e) => e.id2 == 'newWorld|p9'),
          isFalse,
        );

        final second = topologyForRegion(base, 'oldWorld');
        expect(identical(ow, second), isTrue);

        final nw = topologyForRegion(base, 'newWorld');
        expect(nw.nodes.map((n) => n.id), ['newWorld|p9']);
        expect(nw.edges, isEmpty);
      },
    );

    test('returns empty topology when region has no nodes', () {
      const base = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );

      final missing = topologyForRegion(base, 'unknownRegion');
      expect(missing.nodes, isEmpty);
      expect(missing.edges, isEmpty);
    });

    test('override takes precedence over cached subgraph', () {
      final base = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );

      final computed = topologyForRegion(base, 'oldWorld');
      const override = MapTopology(nodes: [], edges: []);
      final overridden = topologyForRegion(
        base,
        'oldWorld',
        topologyByRegion: const {'oldWorld': override},
      );

      expect(identical(overridden, override), isTrue);
      expect(identical(overridden, computed), isFalse);
    });
  });
}
