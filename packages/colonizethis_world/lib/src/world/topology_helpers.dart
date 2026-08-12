import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/utils/graph_traversal.dart';

import 'topology_helpers_cache.dart';

export 'topology_helpers_cache.dart';

/// Topology query/BFS helpers shared by movement and connectivity.
/// SPEC/game/map-topology.md.
///
/// Index/cache construction lives in [topology_helpers_cache.dart]; this library
/// owns sea-path BFS, coastal adjacency probes, and region subgraph extraction.

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
  return breadthFirstReachableInSubgraph<String>(
    startSeaZoneIds,
    seaZoneAdjacency(topology),
    seaZoneNodeIds(topology),
    onDequeue: onDequeue,
  );
}

/// Sea zone ids adjacent to province [provinceNodeId] in topology (P–S edges).
///
/// Prefer [seaZoneIdsAdjacentToProvince] for prefixed province ids and
/// region-scoped resolution.
Set<String> seaZonesAdjacentToProvince(
  MapTopology topology,
  String provinceNodeId,
) {
  return seaZoneIdsAdjacentToProvince(topology, provinceNodeId);
}

/// True when [edgeEndpoint] is the same province topology node as [provinceId]
/// for [regionId]. Handles combined topologies where edges use prefixed ids
/// (`regionId|localId`) while orders/state may still use the local id.
bool _topologyProvinceEndpointMatches(
  String edgeEndpoint,
  String provinceId,
  String? regionId,
) {
  if (edgeEndpoint == provinceId) return true;
  if (regionId == null) return false;
  if (ProvinceId.isPrefixed(provinceId)) {
    if (!ProvinceId.isPrefixed(edgeEndpoint)) {
      return ProvinceId.regionIdFrom(provinceId) == regionId &&
          ProvinceId.localIdFrom(provinceId) == edgeEndpoint;
    }
  } else if (ProvinceId.isPrefixed(edgeEndpoint)) {
    return ProvinceId.regionIdFrom(edgeEndpoint) == regionId &&
        ProvinceId.localIdFrom(edgeEndpoint) == provinceId;
  }
  return false;
}

/// Sea zone ids that share an edge with province [provinceId] (coastal P–S
/// edges), optionally restricted to [regionId] per
/// SPEC/game/world-model-identity.md (region-scoped lookup). Accepts local or
/// prefixed (`regionId|localId`) province ids.
Set<String> seaZoneIdsAdjacentToProvince(
  MapTopology topology,
  String provinceId, {
  String? regionId,
}) {
  String localProvinceId = provinceId;
  if (provinceId.contains('|')) {
    final parts = provinceId.split('|');
    localProvinceId = parts.length > 1
        ? parts.sublist(1).join('|')
        : provinceId;
  }
  final nodeById = topologyNodesById(topology);
  final out = <String>{};
  for (final e in topology.edges) {
    final id1 = e.id1, id2 = e.id2;
    String? prov;
    if (id1 == localProvinceId ||
        id1 == provinceId ||
        _topologyProvinceEndpointMatches(id1, provinceId, regionId)) {
      prov = id1;
    } else if (id2 == localProvinceId ||
        id2 == provinceId ||
        _topologyProvinceEndpointMatches(id2, provinceId, regionId)) {
      prov = id2;
    }
    if (prov == null) continue;
    final other = id1 == prov ? id2 : id1;
    final node = nodeById[other];
    if (node == null || node.type != TopologyNodeType.seaZone) continue;
    // When [regionId] is set, disambiguate duplicate local province ids (e.g. OW/NW
    // both `p1`) by requiring the coastal sea zone to belong to that region.
    if (regionId != null && node.regionId != regionId) continue;
    out.add(other);
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
  final byRegion = topologyByRegionSubgraphCache.get(base);
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
