import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/utils/expando_index.dart';
import 'sea_zone_identity.dart';
import 'topology_helpers.dart';

/// Pure topology identity helpers shared by fog, coastal visibility, and naval
/// movement (Refs #3968). Kept out of `naval.dart` so non-fleet callers do not
/// import a naval-named module for graph identity lookups.

/// Indexes [topology] nodes by region id, then by node id (province/sea endpoints).
///
/// Result is cached per topology instance; the topology is treated as immutable
/// (`MapTopology` const constructor + final fields). Hot-path callers such as
/// `seaZoneIdForProvince`, `provinceIdsAdjacentToSeaZone`, and
/// `provinceTopologyNodeId` reuse the same `Map` instance across calls so
/// per-province naval-move/fog/connectivity loops avoid the O(nodes) rebuild
/// cost every iteration.
Map<String, Map<String, TopologyNode>> indexTopologyNodesByRegion(
  MapTopology topology,
) => _nodesByRegionAndIdCache.get(topology);

Map<String, Map<String, TopologyNode>> _computeNodesByRegionAndId(
  MapTopology topology,
) {
  final nodesByRegionAndId = <String, Map<String, TopologyNode>>{};
  for (final n in topology.nodes) {
    nodesByRegionAndId.putIfAbsent(n.regionId, () => {})[n.id] = n;
  }
  return nodesByRegionAndId;
}

final ExpandoIndex<MapTopology, Map<String, Map<String, TopologyNode>>>
_nodesByRegionAndIdCache =
    ExpandoIndex<MapTopology, Map<String, Map<String, TopologyNode>>>(
      'topology.nodesByRegionAndId',
      _computeNodesByRegionAndId,
    );

/// Topology node id for [provinceId] in [regionId] (matches [MapTopology] edge endpoints).
/// [provinceId] is the same form as for [seaZoneIdForProvince] (local or prefixed).
String? provinceTopologyNodeId(
  MapTopology topology,
  String provinceId,
  String regionId,
) {
  final regionNodes = indexTopologyNodesByRegion(topology)[regionId];
  if (regionNodes == null) return null;
  final primaryProvinceKey = ProvinceId.isPrefixed(provinceId)
      ? provinceId
      : ProvinceId.full(regionId, provinceId);
  var provinceNode = regionNodes[primaryProvinceKey];
  if (provinceNode == null && !ProvinceId.isPrefixed(provinceId)) {
    provinceNode = regionNodes[provinceId];
  }
  if (provinceNode == null || provinceNode.type != TopologyNodeType.province) {
    return null;
  }
  return provinceNode.id;
}

/// Province ids that share an edge with [seaZoneId] (coastal provinces), optionally
/// restricted to [regionId] per SPEC/game/world-model-identity.md (region-scoped lookup).
/// When [regionId] is null, uses the destination sea zone's region from topology when
/// unique; when the sea zone is not found or ambiguous, returns empty.
Set<String> provinceIdsAdjacentToSeaZone(
  MapTopology topology,
  String seaZoneId, {
  String? regionId,
}) {
  final nodesByRegionAndId = indexTopologyNodesByRegion(topology);
  String? effectiveRegion = regionId;
  if (effectiveRegion == null) {
    final resolved = regionIdForSeaZone(topology, seaZoneId);
    effectiveRegion = resolved;
  }
  if (effectiveRegion == null) return {};
  final regionNodes = nodesByRegionAndId[effectiveRegion];
  if (regionNodes == null) return {};
  final canonicalSeaZoneId = canonicalizeSeaZoneId(
    regionId: effectiveRegion,
    seaZoneId: seaZoneId,
  );
  final nodeTypes = topologyNodeTypeById(topology);
  final out = <String>{};
  for (final probeId in [
    canonicalSeaZoneId,
    if (canonicalSeaZoneId != seaZoneId) seaZoneId,
  ]) {
    for (final neighborId in nodesAdjacentTo(topology, probeId)) {
      if (!regionNodes.containsKey(neighborId)) continue;
      if (nodeTypes[neighborId] == TopologyNodeType.province) {
        out.add(neighborId);
      }
    }
  }
  return out;
}

/// Region id for a sea zone (from topology node). Returns null when not found;
/// callers must not infer region by defaulting (SPEC/game/world-model-identity.md).
String? regionIdForSeaZone(MapTopology topology, String seaZoneId) {
  for (final n in topology.nodes) {
    if (n.id == seaZoneId) {
      return n.regionId;
    }
  }
  if (isCanonicalSeaZoneId(seaZoneId)) return null;
  TopologyNode? soleLocal;
  for (final n in topology.nodes) {
    if (n.type != TopologyNodeType.seaZone) continue;
    if (!isCanonicalSeaZoneId(n.id)) continue;
    if (canonicalizeSeaZoneId(regionId: n.regionId, seaZoneId: seaZoneId) !=
        n.id) {
      continue;
    }
    if (soleLocal == null) {
      soleLocal = n;
    } else {
      return null;
    }
  }
  return soleLocal?.regionId;
}
