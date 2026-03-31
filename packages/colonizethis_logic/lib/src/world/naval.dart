import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Naval movement helpers. SPEC/program/naval-movement-resolution.md.

/// True when a dock order targeting [dockFullProvinceId] is the player's capital;
/// such a move merges into the Home Fleet. SPEC/game/ships-and-naval.md § Home Fleet.
bool dockOrderTargetsPlayerCapital(
  Game game,
  String playerId,
  String dockFullProvinceId,
) {
  String? cap;
  for (final p in game.players) {
    if (p.id == playerId) {
      cap = p.capitalProvinceId;
      break;
    }
  }
  if (cap == null || cap.isEmpty) return false;
  if (ProvinceId.isPrefixed(cap)) return cap == dockFullProvinceId;
  return ProvinceId.full(ProvinceId.regionIdFrom(dockFullProvinceId), cap) ==
      dockFullProvinceId;
}

/// Home fleet id convention for a Great Power. SPEC/game/ships-and-naval.md.
String homeFleetIdFor(String playerId) => 'fleet_$playerId';

/// Region and local province id for a fleet in port ([inPortAtProvinceId]).
/// Prefixed ids use [ProvinceId]; legacy unprefixed ids use [fleetRegionId].
/// SPEC/game/world-model-identity.md.
({String regionId, String localId}) regionAndLocalProvinceForFleetInPort(
  String inPortProvinceId,
  String fleetRegionId,
) {
  if (ProvinceId.isPrefixed(inPortProvinceId)) {
    return (
      regionId: ProvinceId.regionIdFrom(inPortProvinceId),
      localId: ProvinceId.localIdFrom(inPortProvinceId),
    );
  }
  return (regionId: fleetRegionId, localId: inPortProvinceId);
}

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

/// Province ids that share an edge with [seaZoneId] (coastal provinces), optionally
/// restricted to [regionId] per SPEC/game/world-model-identity.md (region-scoped lookup).
/// When [regionId] is null, uses the destination sea zone's region from topology when
/// unique; when the sea zone is not found or ambiguous, returns empty.
Set<String> provinceIdsAdjacentToSeaZone(
  MapTopology topology,
  String seaZoneId, {
  String? regionId,
}) {
  final nodesByRegionAndId = <String, Map<String, TopologyNode>>{};
  for (final n in topology.nodes) {
    nodesByRegionAndId.putIfAbsent(n.regionId, () => {})[n.id] = n;
  }
  String? effectiveRegion = regionId;
  if (effectiveRegion == null) {
    final seaNodes = topology.nodes.where((n) => n.id == seaZoneId).toList();
    effectiveRegion = seaNodes.isNotEmpty ? seaNodes.first.regionId : null;
  }
  if (effectiveRegion == null) return {};
  final regionNodes = nodesByRegionAndId[effectiveRegion];
  if (regionNodes == null) return {};
  final out = <String>{};
  for (final e in topology.edges) {
    final otherId = e.id1 == seaZoneId ? e.id2 : (e.id2 == seaZoneId ? e.id1 : null);
    if (otherId != null) {
      final node = regionNodes[otherId];
      if (node != null && node.type == TopologyNodeType.province) out.add(otherId);
    }
  }
  return out;
}

/// Region id for a sea zone (from topology node). Returns null when not found;
/// callers must not infer region by defaulting (SPEC/game/world-model-identity.md).
String? regionIdForSeaZone(MapTopology topology, String seaZoneId) {
  final list = topology.nodes.where((n) => n.id == seaZoneId).toList();
  return list.isNotEmpty ? list.first.regionId : null;
}

/// Sea zone ids that share an edge with [provinceId] (P↔S). [provinceId] may be
/// prefixed (regionId|localId) or local; when [regionId] is provided, lookup is region-scoped.
/// Cross-region edges (e.g. province in OW, sea zone in NW) are included.
Set<String> seaZoneIdsAdjacentToProvince(
  MapTopology topology,
  String provinceId, {
  String? regionId,
}) {
  String localProvinceId = provinceId;
  if (provinceId.contains('|')) {
    final parts = provinceId.split('|');
    localProvinceId = parts.length > 1 ? parts.sublist(1).join('|') : provinceId;
  }
  final nodeById = {for (final n in topology.nodes) n.id: n};
  final out = <String>{};
  for (final e in topology.edges) {
    final id1 = e.id1, id2 = e.id2;
    final prov = (id1 == localProvinceId || id1 == provinceId) ? id1 : ((id2 == localProvinceId || id2 == provinceId) ? id2 : null);
    if (prov == null) continue;
    final other = id1 == prov ? id2 : id1;
    final node = nodeById[other];
    if (node != null && node.type == TopologyNodeType.seaZone) out.add(other);
  }
  return out;
}

/// Fleets in port at [provinceId]. Per SPEC/game/ships-and-naval.md: in port =
/// fleet attached to that province ([inPortAtProvinceId] equals province id).
/// [provinceId] must be prefixed (regionId|localId) when world is multi-region.
List<Fleet> fleetsInPortAtProvince(WorldState worldState, String provinceId) {
  final normalized = provinceId.contains('|') ? provinceId : 'oldWorld|$provinceId';
  return worldState.fleets
      .where((f) => f.inPortAtProvinceId == normalized)
      .toList();
}
