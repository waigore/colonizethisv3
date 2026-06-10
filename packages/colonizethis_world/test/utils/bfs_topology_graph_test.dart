import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/utils/graph_traversal.dart';
import 'package:colonizethis_world/src/world/topology_helpers.dart';
import 'package:colonizethis_test/test.dart';

/// Phase 2 of #3403: canonical topology-graph BFS shared by the sea-reachability
/// planners. These tests exercise [bfsTopologyGraph] directly (the visitor
/// hooks, expansion rules, and determinism) independent of the sea-reachable
/// wrappers, plus a couple of negative cases.
TopologyNode _prov(String id, {String regionId = 'oldWorld'}) =>
    TopologyNode(id: id, regionId: regionId, type: TopologyNodeType.province);

TopologyNode _sea(String id, {String regionId = 'oldWorld'}) =>
    TopologyNode(id: id, regionId: regionId, type: TopologyNodeType.seaZone);

void main() {
  group('bfsTopologyGraph (Refs #3403 Phase 2)', () {
    test('fires onForeignProvinceDiscovered once at shortest distance', () {
      // enemy reachable directly (1) and via a sea detour (2). FIFO BFS must
      // discover it first via the direct edge -> distance 1, and only once.
      final topology = MapTopology(
        nodes: [_prov('own'), _prov('enemy'), _sea('sea')],
        edges: const [
          TopologyEdge(id1: 'own', id2: 'enemy'),
          TopologyEdge(id1: 'own', id2: 'sea'),
          TopologyEdge(id1: 'sea', id2: 'enemy'),
        ],
      );
      final foreign = <String, int>{};
      var foreignCalls = 0;
      bfsTopologyGraph(
        sourceIds: const {'own'},
        nodeType: topologyNodeTypeById(topology),
        adjacency: topologyAdjacency(topology),
        isExpandableProvince: (id) => id == 'own',
        isForeignProvince: (id) => id == 'enemy',
        onForeignProvinceDiscovered: (id, d) {
          foreignCalls++;
          foreign[id] = d;
        },
      );

      expect(foreign, {'enemy': 1});
      expect(foreignCalls, 1, reason: 'discovered exactly once (first reach)');
    });

    test('does not expand through a foreign province', () {
      final topology = MapTopology(
        nodes: [_prov('own'), _prov('enemy'), _prov('beyond')],
        edges: const [
          TopologyEdge(id1: 'own', id2: 'enemy'),
          TopologyEdge(id1: 'enemy', id2: 'beyond'),
        ],
      );
      final foreign = <String>{};
      bfsTopologyGraph(
        sourceIds: const {'own'},
        nodeType: topologyNodeTypeById(topology),
        adjacency: topologyAdjacency(topology),
        isExpandableProvince: (id) => id == 'own',
        isForeignProvince: (id) => id == 'enemy' || id == 'beyond',
        onForeignProvinceDiscovered: (id, _) => foreign.add(id),
      );
      // `beyond` sits behind the foreign `enemy`, which is never expanded.
      expect(foreign, {'enemy'});
    });

    test('emits onProvinceVisited/onSeaVisited once per expanded node', () {
      final topology = MapTopology(
        nodes: [_prov('own'), _sea('sea'), _prov('ally'), _prov('enemy')],
        edges: const [
          TopologyEdge(id1: 'own', id2: 'sea'),
          TopologyEdge(id1: 'sea', id2: 'ally'),
          TopologyEdge(id1: 'ally', id2: 'enemy'),
        ],
      );
      final provinceVisits = <String, int>{};
      final seaVisits = <String, int>{};
      final foreign = <String, int>{};
      bfsTopologyGraph(
        sourceIds: const {'own'},
        nodeType: topologyNodeTypeById(topology),
        adjacency: topologyAdjacency(topology),
        // own + ally are both expandable (owned territory).
        isExpandableProvince: (id) => id == 'own' || id == 'ally',
        isForeignProvince: (id) => id == 'enemy',
        onProvinceVisited: (id, d) => provinceVisits[id] = d,
        onSeaVisited: (id, d) => seaVisits[id] = d,
        onForeignProvinceDiscovered: (id, d) => foreign[id] = d,
      );

      // Seeds are not re-reported via onProvinceVisited.
      expect(provinceVisits, {'ally': 2});
      expect(seaVisits, {'sea': 1});
      expect(foreign, {'enemy': 3});
    });

    test('ignores unknown neighbour ids missing from the node-type map', () {
      // Adjacency references a node id absent from the topology node set.
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'own',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [TopologyEdge(id1: 'own', id2: 'ghost')],
      );
      final foreign = <String>{};
      bfsTopologyGraph(
        sourceIds: const {'own'},
        nodeType: topologyNodeTypeById(topology),
        adjacency: topologyAdjacency(topology),
        isExpandableProvince: (id) => id == 'own',
        isForeignProvince: (_) => true,
        onForeignProvinceDiscovered: (id, _) => foreign.add(id),
      );
      // `ghost` has no node type -> skipped, never collected.
      expect(foreign, isEmpty);
    });

    test('empty source set yields no traversal', () {
      final topology = MapTopology(
        nodes: [_prov('own'), _prov('enemy')],
        edges: const [TopologyEdge(id1: 'own', id2: 'enemy')],
      );
      final foreign = <String>{};
      bfsTopologyGraph(
        sourceIds: const <String>{},
        nodeType: topologyNodeTypeById(topology),
        adjacency: topologyAdjacency(topology),
        isExpandableProvince: (_) => true,
        isForeignProvince: (_) => true,
        onForeignProvinceDiscovered: (id, _) => foreign.add(id),
      );
      expect(foreign, isEmpty);
    });
  });

  group('topology graph index caches (Refs #3403 Phase 2)', () {
    final topology = MapTopology(
      nodes: [_prov('own'), _sea('sea'), _prov('enemy')],
      edges: const [
        TopologyEdge(id1: 'own', id2: 'sea'),
        TopologyEdge(id1: 'sea', id2: 'enemy'),
      ],
    );

    test('topologyNodeTypeById returns same unmodifiable instance', () {
      final first = topologyNodeTypeById(topology);
      final second = topologyNodeTypeById(topology);
      expect(identical(first, second), isTrue);
      expect(first['sea'], TopologyNodeType.seaZone);
      expect(first['own'], TopologyNodeType.province);
      expect(
        () => first['x'] = TopologyNodeType.province,
        throwsUnsupportedError,
      );
    });

    test('topologyAdjacency is cached, unmodifiable, and edge-ordered', () {
      final first = topologyAdjacency(topology);
      final second = topologyAdjacency(topology);
      expect(identical(first, second), isTrue);
      expect(first['sea'], {'own', 'enemy'});
      // Insertion order follows topology.edges (own-sea then sea-enemy).
      expect(first['sea']!.toList(), ['own', 'enemy']);
      expect(() => first['own']!.add('z'), throwsUnsupportedError);
      expect(() => first['z'] = {'a'}, throwsUnsupportedError);
    });

    test('seaZoneAdjacency only contains S–S edges and is cached', () {
      final withSeaLink = MapTopology(
        nodes: [_sea('s1'), _sea('s2'), _prov('p1')],
        edges: const [
          TopologyEdge(id1: 's1', id2: 's2'),
          TopologyEdge(id1: 'p1', id2: 's1'),
        ],
      );
      final first = seaZoneAdjacency(withSeaLink);
      final second = seaZoneAdjacency(withSeaLink);
      expect(identical(first, second), isTrue);
      expect(first['s1'], {'s2'});
      // Province neighbour is excluded from the sea-only adjacency.
      expect(first['s1']!.contains('p1'), isFalse);
      expect(first.containsKey('p1'), isFalse);
    });

    test('separate topology instances do not share cached indexes', () {
      final other = MapTopology(nodes: [_prov('a')], edges: const []);
      expect(
        identical(topologyAdjacency(topology), topologyAdjacency(other)),
        isFalse,
      );
    });
  });
}
