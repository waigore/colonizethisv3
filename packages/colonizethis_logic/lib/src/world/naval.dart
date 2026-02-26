import 'package:colonizethis_data/colonizethis_data.dart';

import '../constants.dart';

/// Naval movement helpers. SPEC/program/naval-movement-resolution.md.

/// True if there is an edge between [fromSeaZoneId] and [toSeaZoneId] (S<->S or P<->S).
bool isAdjacentSeaZone(
  MapTopology topology,
  String fromSeaZoneId,
  String toSeaZoneId,
) {
  if (fromSeaZoneId == toSeaZoneId) return false;
  for (final e in topology.edges) {
    if ((e.id1 == fromSeaZoneId && e.id2 == toSeaZoneId) ||
        (e.id1 == toSeaZoneId && e.id2 == fromSeaZoneId)) {
      return true;
    }
  }
  return false;
}

/// First sea zone id adjacent to [seaZoneId], or null if none. Used for naval retreat.
String? firstAdjacentSeaZone(MapTopology topology, String seaZoneId) {
  for (final e in topology.edges) {
    if (e.id1 == seaZoneId) return e.id2;
    if (e.id2 == seaZoneId) return e.id1;
  }
  return null;
}

/// First sea zone id adjacent to [provinceId], or null if none. Used for home fleet and build_port.
///
/// [provinceId] is the local province id (e.g. p1). When [regionId] is provided, lookup is
/// region-scoped per SPEC/game/world-model-identity.md (required for multi-region world).
/// When [regionId] is null, uses first matching node (single-region or legacy).
String? seaZoneIdForProvince(MapTopology topology, String provinceId, {String? regionId}) {
  if (regionId != null) {
    final nodesByRegionAndId = <String, Map<String, TopologyNode>>{};
    for (final n in topology.nodes) {
      nodesByRegionAndId.putIfAbsent(n.regionId, () => {})[n.id] = n;
    }
    final regionNodes = nodesByRegionAndId[regionId];
    if (regionNodes == null) return null;
    final provinceNode = regionNodes[provinceId];
    if (provinceNode == null || provinceNode.type != TopologyNodeType.province) return null;
    for (final e in topology.edges) {
      if (e.id1 != provinceId && e.id2 != provinceId) continue;
      final other = e.id1 == provinceId ? e.id2 : e.id1;
      final otherNode = regionNodes[other];
      if (otherNode?.type == TopologyNodeType.seaZone) return other;
    }
    return null;
  }
  final nodesById = {for (final n in topology.nodes) n.id: n};
  for (final e in topology.edges) {
    if (e.id1 != provinceId && e.id2 != provinceId) continue;
    final other = e.id1 == provinceId ? e.id2 : e.id1;
    if (nodesById[other]?.type == TopologyNodeType.seaZone) return other;
  }
  return null;
}

/// Province ids that share an edge with [seaZoneId] (coastal provinces).
Set<String> provinceIdsAdjacentToSeaZone(MapTopology topology, String seaZoneId) {
  final nodesById = {for (final n in topology.nodes) n.id: n};
  final out = <String>{};
  for (final e in topology.edges) {
    final otherId = e.id1 == seaZoneId ? e.id2 : (e.id2 == seaZoneId ? e.id1 : null);
    if (otherId != null && nodesById[otherId]?.type == TopologyNodeType.province) {
      out.add(otherId);
    }
  }
  return out;
}

/// Region id for a sea zone (from topology node). Defaults to oldWorld if not found.
String regionIdForSeaZone(MapTopology topology, String seaZoneId) {
  final list = topology.nodes.where((n) => n.id == seaZoneId).toList();
  return list.isNotEmpty ? list.first.regionId : kRegionOldWorld;
}
