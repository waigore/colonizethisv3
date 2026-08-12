import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_world/src/utils/expando_index.dart';

/// Expando index/cache construction for topology helpers.
/// SPEC/game/map-topology.md.
///
/// `MapTopology` is immutable (const constructor, final fields), so per-topology
/// node-id partitions are cached via [ExpandoIndex] keyed on the topology
/// instance. Cached sets are returned as `UnmodifiableSetView` so callers
/// cannot mutate the cached entry and so leak read-only semantics across call
/// sites (`packages/colonizethis_logic` hot paths: connectivity, naval moves,
/// fog). Cache entries are garbage-collected together with their topology.

Set<String> _computeProvinceNodeIds(MapTopology topology) {
  final out = <String>{};
  for (final n in topology.nodes) {
    if (n.type == TopologyNodeType.province) out.add(n.id);
  }
  return UnmodifiableSetView<String>(out);
}

Set<String> _computeSeaZoneNodeIds(MapTopology topology) {
  final out = <String>{};
  for (final n in topology.nodes) {
    if (n.type == TopologyNodeType.seaZone) out.add(n.id);
  }
  return UnmodifiableSetView<String>(out);
}

Map<String, TopologyNodeType> _computeNodeTypeById(MapTopology topology) {
  final out = <String, TopologyNodeType>{
    for (final n in topology.nodes) n.id: n.type,
  };
  return Map<String, TopologyNodeType>.unmodifiable(out);
}

Map<String, Set<String>> _computeAdjacency(MapTopology topology) {
  final mutable = <String, Set<String>>{};
  for (final e in topology.edges) {
    mutable.putIfAbsent(e.id1, () => <String>{}).add(e.id2);
    mutable.putIfAbsent(e.id2, () => <String>{}).add(e.id1);
  }
  return Map<String, Set<String>>.unmodifiable({
    for (final entry in mutable.entries)
      entry.key: UnmodifiableSetView<String>(entry.value),
  });
}

Map<String, Set<String>> _computeSeaZoneAdjacency(MapTopology topology) {
  final seaZoneIds = seaZoneNodeIds(topology);
  final mutable = <String, Set<String>>{};
  for (final e in topology.edges) {
    if (!seaZoneIds.contains(e.id1) || !seaZoneIds.contains(e.id2)) continue;
    mutable.putIfAbsent(e.id1, () => <String>{}).add(e.id2);
    mutable.putIfAbsent(e.id2, () => <String>{}).add(e.id1);
  }
  return Map<String, Set<String>>.unmodifiable({
    for (final entry in mutable.entries)
      entry.key: UnmodifiableSetView<String>(entry.value),
  });
}

Map<String, Set<String>> _computeProvinceNodeIdsByRegion(MapTopology topology) {
  final mutable = <String, Set<String>>{};
  for (final n in topology.nodes) {
    if (n.type != TopologyNodeType.province) continue;
    mutable.putIfAbsent(n.regionId, () => <String>{}).add(n.id);
  }
  return {
    for (final entry in mutable.entries)
      entry.key: UnmodifiableSetView<String>(entry.value),
  };
}

Map<String, TopologyNode> _computeNodesById(MapTopology topology) {
  final out = <String, TopologyNode>{};
  for (final n in topology.nodes) {
    out[n.id] = n;
  }
  return out;
}

final ExpandoIndex<MapTopology, Set<String>> _provinceNodeIdsCache =
    ExpandoIndex<MapTopology, Set<String>>(
      'topology.provinceNodeIds',
      _computeProvinceNodeIds,
    );

final ExpandoIndex<MapTopology, Map<String, Set<String>>>
_provinceNodeIdsByRegionCache =
    ExpandoIndex<MapTopology, Map<String, Set<String>>>(
      'topology.provinceNodeIdsByRegion',
      _computeProvinceNodeIdsByRegion,
    );

final ExpandoIndex<MapTopology, Set<String>> _seaZoneNodeIdsCache =
    ExpandoIndex<MapTopology, Set<String>>(
      'topology.seaZoneNodeIds',
      _computeSeaZoneNodeIds,
    );

final ExpandoIndex<MapTopology, Map<String, TopologyNodeType>>
_nodeTypeByIdCache = ExpandoIndex<MapTopology, Map<String, TopologyNodeType>>(
  'topology.nodeTypeById',
  _computeNodeTypeById,
);

final ExpandoIndex<MapTopology, Map<String, Set<String>>> _adjacencyCache =
    ExpandoIndex<MapTopology, Map<String, Set<String>>>(
      'topology.adjacency',
      _computeAdjacency,
    );

final ExpandoIndex<MapTopology, Map<String, Set<String>>>
_seaZoneAdjacencyCache = ExpandoIndex<MapTopology, Map<String, Set<String>>>(
  'topology.seaZoneAdjacency',
  _computeSeaZoneAdjacency,
);

final ExpandoIndex<MapTopology, bool> _topologyUsesPrefixedIdsCache =
    ExpandoIndex<MapTopology, bool>(
      'topology.usesPrefixedIds',
      (topology) => topology.nodes.any((n) => n.id.contains('|')),
    );

final ExpandoIndex<MapTopology, Map<String, TopologyNode>> _nodesByIdCache =
    ExpandoIndex<MapTopology, Map<String, TopologyNode>>(
      'topology.nodesById',
      _computeNodesById,
    );

/// Outer cache for per-`(MapTopology, regionId)` subgraphs. The inner
/// `Map<String, MapTopology>` is built lazily and entries are filled
/// progressively by [topologyForRegion]; the [ExpandoIndex] only guarantees
/// the outer holder exists per topology instance.
final ExpandoIndex<MapTopology, Map<String, MapTopology>>
topologyByRegionSubgraphCache =
    ExpandoIndex<MapTopology, Map<String, MapTopology>>(
      'topology.byRegionSubgraph',
      (_) => <String, MapTopology>{},
    );

/// All province node ids in [topology]. Cached per topology instance; the
/// returned set is unmodifiable.
Set<String> provinceNodeIds(MapTopology topology) =>
    _provinceNodeIdsCache.get(topology);

/// Province node ids in [regionId] in [topology]. Cached per topology instance;
/// the returned set is unmodifiable. Returns an empty set when no provinces
/// exist for the region.
Set<String> provinceNodeIdsForRegion(MapTopology topology, String regionId) {
  final byRegion = _provinceNodeIdsByRegionCache.get(topology);
  return byRegion[regionId] ?? const <String>{};
}

/// True when any topology node id uses prefixed form (regionId|localId).
bool topologyUsesPrefixedIds(MapTopology topology) =>
    _topologyUsesPrefixedIdsCache.get(topology);

/// All sea zone node ids in [topology]. Cached per topology instance; the
/// returned set is unmodifiable.
Set<String> seaZoneNodeIds(MapTopology topology) =>
    _seaZoneNodeIdsCache.get(topology);

/// Node id -> [TopologyNodeType] for every node in [topology]. Cached per
/// topology instance; the returned map is unmodifiable. Shared by topology-graph
/// BFS so hot paths avoid rebuilding the type index per call (Refs #3403
/// Phase 2).
Map<String, TopologyNodeType> topologyNodeTypeById(MapTopology topology) =>
    _nodeTypeByIdCache.get(topology);

/// Full undirected adjacency (`nodeId -> neighbour ids`) for every edge in
/// [topology], regardless of node type. Cached per topology instance; the outer
/// map and each neighbour set are unmodifiable. Neighbour-set iteration follows
/// `topology.edges` insertion order so BFS over this index stays deterministic
/// (Refs #3403 Phase 2).
Map<String, Set<String>> topologyAdjacency(MapTopology topology) =>
    _adjacencyCache.get(topology);

/// Undirected adjacency restricted to sea-zone-to-sea-zone (S–S) edges. Cached
/// per topology instance; unmodifiable. Backs sea-path BFS (Refs #3403 Phase 2).
Map<String, Set<String>> seaZoneAdjacency(MapTopology topology) =>
    _seaZoneAdjacencyCache.get(topology);

/// All topology nodes keyed by node id, cached per immutable topology instance.
///
/// Hot-path naval/connectivity/fog callers reuse the same `Map` instance across
/// calls so per-province loops avoid the O(nodes) rebuild cost every iteration.
/// The returned map is treated as read-only by callers.
Map<String, TopologyNode> topologyNodesById(MapTopology topology) =>
    _nodesByIdCache.get(topology);
