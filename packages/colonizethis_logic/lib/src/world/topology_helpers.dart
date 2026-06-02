import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../utils/expando_index.dart';

/// Topology helpers shared by movement and connectivity. SPEC/game/map-topology.md.
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

final ExpandoIndex<MapTopology, bool> _topologyUsesPrefixedIdsCache =
    ExpandoIndex<MapTopology, bool>(
      'topology.usesPrefixedIds',
      (topology) => topology.nodes.any((n) => n.id.contains('|')),
    );

/// Outer cache for per-`(MapTopology, regionId)` subgraphs. The inner
/// `Map<String, MapTopology>` is built lazily and entries are filled
/// progressively by [topologyForRegion]; the [ExpandoIndex] only guarantees
/// the outer holder exists per topology instance.
final ExpandoIndex<MapTopology, Map<String, MapTopology>>
_topologyByRegionSubgraphCache =
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

/// Sea zones reachable from [startSeaZoneIds] by following S–S edges in [topology].
/// SPEC/game/map-topology.md, capital-and-connectivity § Sea paths.
///
/// When [onDequeue] is set, it is invoked once per BFS dequeue (connectivity hot-path
/// metrics in `connectivity_resolver.dart`).
Set<String> seaZonesReachableBySeaPath(
  MapTopology topology,
  Set<String> startSeaZoneIds, {
  void Function()? onDequeue,
}) {
  final seaZoneIds = seaZoneNodeIds(topology);
  final neighbours = <String, Set<String>>{};
  for (final e in topology.edges) {
    final a = e.id1;
    final b = e.id2;
    if (seaZoneIds.contains(a) && seaZoneIds.contains(b)) {
      neighbours.putIfAbsent(a, () => {}).add(b);
      neighbours.putIfAbsent(b, () => {}).add(a);
    }
  }
  final reachable = Set<String>.from(startSeaZoneIds);
  final queue = Queue<String>()..addAll(startSeaZoneIds);
  while (queue.isNotEmpty) {
    final z = queue.removeFirst();
    onDequeue?.call();
    for (final n in neighbours[z] ?? {}) {
      if (reachable.contains(n)) continue;
      reachable.add(n);
      queue.add(n);
    }
  }
  return reachable;
}

/// Sea zone ids adjacent to province [provinceNodeId] in topology (P–S edges).
Set<String> seaZonesAdjacentToProvince(
  MapTopology topology,
  String provinceNodeId,
) {
  final seaZoneIds = seaZoneNodeIds(topology);
  final out = <String>{};
  for (final edge in topology.edges) {
    if (edge.id1 != provinceNodeId && edge.id2 != provinceNodeId) continue;
    final other = edge.id1 == provinceNodeId ? edge.id2 : edge.id1;
    if (seaZoneIds.contains(other)) out.add(other);
  }
  return out;
}

/// All node ids directly adjacent to [nodeId] in [topology] regardless of node
/// type. Order matches a single forward pass over `topology.edges`, mirroring
/// the inline first-match / single-pass scans previously duplicated across
/// world resolvers (naval retreat lookup, single-shot adjacency probes).
/// Refs #2560.
List<String> nodesAdjacentTo(MapTopology topology, String nodeId) {
  final out = <String>[];
  for (final e in topology.edges) {
    if (e.id1 == nodeId) {
      out.add(e.id2);
    } else if (e.id2 == nodeId) {
      out.add(e.id1);
    }
  }
  return out;
}

/// Region-scoped topology for [regionId]. Returns [topologyByRegion]`[regionId]`
/// when provided and non-null; otherwise computes a subgraph of [base] limited
/// to nodes (and their connecting edges) tagged with that region. The subgraph
/// result is cached per `(base, regionId)` so repeated callers do not re-scan
/// `base.nodes`/`base.edges`. Returns an empty topology when the base contains
/// no nodes for [regionId]. Refs #2560.
MapTopology topologyForRegion(
  MapTopology base,
  String regionId, {
  Map<String, MapTopology>? topologyByRegion,
}) {
  final override = topologyByRegion?[regionId];
  if (override != null) return override;
  final byRegion = _topologyByRegionSubgraphCache.get(base);
  final hit = byRegion[regionId];
  if (hit != null) return hit;
  final regionNodes = <TopologyNode>[];
  final regionNodeIds = <String>{};
  for (final n in base.nodes) {
    if (n.regionId != regionId) continue;
    regionNodes.add(n);
    regionNodeIds.add(n.id);
  }
  if (regionNodes.isEmpty) {
    return const MapTopology(nodes: [], edges: []);
  }
  final regionEdges = [
    for (final e in base.edges)
      if (regionNodeIds.contains(e.id1) && regionNodeIds.contains(e.id2)) e,
  ];
  final subgraph = MapTopology(nodes: regionNodes, edges: regionEdges);
  byRegion.putIfAbsent(regionId, () => subgraph);
  return subgraph;
}
