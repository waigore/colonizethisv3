import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/utils/expando_index.dart';
import 'sea_zone_identity.dart';
import 'topology_helpers.dart';

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

/// True if there is an edge between [fromSeaZoneId] and [toSeaZoneId] (S<->S or P<->S).
bool isAdjacentSeaZone(
  MapTopology topology,
  String fromSeaZoneId,
  String toSeaZoneId,
) {
  if (fromSeaZoneId == toSeaZoneId) return false;
  final neighbors = topologyAdjacency(topology)[fromSeaZoneId];
  return neighbors?.contains(toSeaZoneId) ?? false;
}

/// True when both ids are **sea-zone** topology nodes sharing an undirected edge (S–S only).
/// At-sea fleet moves use this; undock uses [seaZoneIdsAdjacentToProvince].
bool isAdjacentSeaSeaZone(
  MapTopology topology,
  String seaZoneIdA,
  String seaZoneIdB,
) {
  final seas = seaZoneNodeIds(topology);
  if (!seas.contains(seaZoneIdA) || !seas.contains(seaZoneIdB)) return false;
  if (seaZoneIdA == seaZoneIdB) return false;
  final neighbors = seaZoneAdjacency(topology)[seaZoneIdA];
  return neighbors?.contains(seaZoneIdB) ?? false;
}

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

/// Neighbors of [currentSeaZoneId] along **S–S** edges only, sorted.
List<String> adjacentSeaZoneIdsSeaOnly(
  MapTopology topology,
  String currentSeaZoneId,
) {
  final seas = seaZoneNodeIds(topology);
  if (!seas.contains(currentSeaZoneId)) return const [];
  final neighbors = seaZoneAdjacency(topology)[currentSeaZoneId];
  if (neighbors == null || neighbors.isEmpty) return const [];
  return neighbors.toList()..sort();
}

/// True when [seaZoneId] has at least one S–S edge to a sea zone in another
/// region (warp-zone membership in combined topology).
bool isWarpZoneSeaZone(MapTopology topology, String seaZoneId) {
  final sourceRegion = regionIdForSeaZone(topology, seaZoneId);
  if (sourceRegion == null) return false;
  final seaZoneIds = seaZoneNodeIds(topology);
  if (!seaZoneIds.contains(seaZoneId)) return false;
  final neighbors = seaZoneAdjacency(topology)[seaZoneId];
  if (neighbors == null) return false;
  for (final other in neighbors) {
    final otherRegion = regionIdForSeaZone(topology, other);
    if (otherRegion != null && otherRegion != sourceRegion) return true;
  }
  return false;
}

/// One-hop naval **topology** destinations: S–S and S–P when at sea; P–S undock when in port.
/// Province ids match topology endpoints (local or prefixed); resolve world [Province] in the UI.
class NavalMoveTopologyPicks {
  const NavalMoveTopologyPicks({
    required this.adjacentSeaZoneIds,
    required this.adjacentProvinceIdsForDock,
  });

  final List<String> adjacentSeaZoneIds;
  final List<String> adjacentProvinceIdsForDock;

  int get totalCount =>
      adjacentSeaZoneIds.length + adjacentProvinceIdsForDock.length;
}

/// Legal adjacent nodes for the Move fleet dialog and validation (same graph rules).
NavalMoveTopologyPicks navalMoveTopologyPicksForFleet({
  required MapTopology topology,
  required Fleet fleet,
}) {
  if (fleet.isAtSea && fleet.seaZoneId != null) {
    final z = fleet.seaZoneId!;
    final seaList = adjacentSeaZoneIdsSeaOnly(topology, z);
    final rz = regionIdForSeaZone(topology, z) ?? fleet.regionId;
    final dockSet = provinceIdsAdjacentToSeaZone(topology, z, regionId: rz);
    final dockList = dockSet.toList()..sort();
    return NavalMoveTopologyPicks(
      adjacentSeaZoneIds: seaList,
      adjacentProvinceIdsForDock: dockList,
    );
  }
  final inPort = fleet.inPortAtProvinceId;
  if (inPort != null) {
    final rl = regionAndLocalProvinceForFleetInPort(inPort, fleet.regionId);
    final provinceNodeId = provinceTopologyNodeId(
      topology,
      rl.localId,
      rl.regionId,
    );
    if (provinceNodeId == null) {
      return const NavalMoveTopologyPicks(
        adjacentSeaZoneIds: [],
        adjacentProvinceIdsForDock: [],
      );
    }
    final undock = seaZoneIdsAdjacentToProvince(
      topology,
      rl.localId,
      regionId: rl.regionId,
    ).toList()
      ..sort();
    return NavalMoveTopologyPicks(
      adjacentSeaZoneIds: undock,
      adjacentProvinceIdsForDock: [],
    );
  }
  return const NavalMoveTopologyPicks(
    adjacentSeaZoneIds: [],
    adjacentProvinceIdsForDock: [],
  );
}

/// First sea zone id adjacent to [seaZoneId], or null if none. Used for naval retreat.
String? firstAdjacentSeaZone(MapTopology topology, String seaZoneId) {
  final neighbors = nodesAdjacentTo(topology, seaZoneId);
  if (neighbors.isEmpty) return null;
  return neighbors.first;
}

String? _otherTopologyEdgeEndpoint(TopologyEdge e, String endpoint) {
  if (e.id1 == endpoint) return e.id2;
  if (e.id2 == endpoint) return e.id1;
  return null;
}

String? _seaZoneIdForProvinceInRegionTopology(
  MapTopology topology,
  String regionId,
  String provinceId,
  Map<String, TopologyNode> regionNodes,
) {
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
  for (final e in topology.edges) {
    final String? other;
    if (e.id1 == primaryProvinceKey || e.id2 == primaryProvinceKey) {
      other = _otherTopologyEdgeEndpoint(e, primaryProvinceKey);
    } else if (!ProvinceId.isPrefixed(provinceId) &&
        (e.id1 == provinceId || e.id2 == provinceId)) {
      other = _otherTopologyEdgeEndpoint(e, provinceId);
    } else {
      continue;
    }
    final otherNode = regionNodes[other];
    if (otherNode?.type == TopologyNodeType.seaZone) return other;
  }
  return null;
}

/// First sea zone id adjacent to [provinceId], or null if none. Used for home fleet and build_port.
///
/// [provinceId] is usually the **local** province id (e.g. `p1`). When [provinceId] is already
/// prefixed (`regionId|localId`), it is used as-is for lookup. When [regionId] is provided,
/// lookup is region-scoped per SPEC/game/world-model-identity.md.
///
/// Supports both **per-region** topology (node/edge ids are local) and **combined** topology
/// from [buildCombinedTopology] (prefixed node/edge ids). SPEC/program/map-data.md.
/// When [regionId] is null, uses first matching node (single-region or legacy).
String? seaZoneIdForProvince(
  MapTopology topology,
  String provinceId, {
  String? regionId,
}) {
  if (regionId != null) {
    final regionNodes = indexTopologyNodesByRegion(topology)[regionId];
    if (regionNodes == null) return null;
    return _seaZoneIdForProvinceInRegionTopology(
      topology,
      regionId,
      provinceId,
      regionNodes,
    );
  }
  final nodesById = topologyNodesById(topology);
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
  final out = <String>{};
  for (final e in topology.edges) {
    final node1 = regionNodes[e.id1];
    final node2 = regionNodes[e.id2];
    // Reveal adjacency is region-bounded for the destination sea-zone region.
    if (node1 == null || node2 == null) continue;

    String? adjacentProvinceNodeId;
    if (node1.type == TopologyNodeType.seaZone &&
        node2.type == TopologyNodeType.province &&
        canonicalizeSeaZoneId(regionId: effectiveRegion, seaZoneId: node1.id) ==
            canonicalSeaZoneId) {
      adjacentProvinceNodeId = node2.id;
    } else if (node2.type == TopologyNodeType.seaZone &&
        node1.type == TopologyNodeType.province &&
        canonicalizeSeaZoneId(regionId: effectiveRegion, seaZoneId: node2.id) ==
            canonicalSeaZoneId) {
      adjacentProvinceNodeId = node1.id;
    }

    if (adjacentProvinceNodeId != null) {
      out.add(adjacentProvinceNodeId);
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

/// Fleets in port at [provinceId]. Per SPEC/game/ships-and-naval.md: in port =
/// fleet attached to that province ([inPortAtProvinceId] equals province id).
/// [provinceId] must be prefixed (regionId|localId) when world is multi-region.
List<Fleet> fleetsInPortAtProvince(WorldState worldState, String provinceId) {
  final normalized = provinceId.contains('|')
      ? provinceId
      : 'oldWorld|$provinceId';
  return worldState.fleets
      .where((f) => f.inPortAtProvinceId == normalized)
      .toList();
}
