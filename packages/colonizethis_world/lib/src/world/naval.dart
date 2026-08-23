import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../game_player_lookup.dart';
import '../world_constants.dart';
import 'topology_helpers.dart';
import 'topology_identity.dart';

// Re-export topology identity so existing `naval.dart` / barrel importers keep
// resolving graph-identity helpers after the Refs #3968 move out of this file.
export 'topology_identity.dart';

/// Naval movement helpers. SPEC/program/naval-movement-resolution.md.

/// True when a dock order targeting [dockFullProvinceId] is the player's capital;
/// such a move merges into the Home Fleet. SPEC/game/ships-and-naval.md § Home Fleet.
bool dockOrderTargetsPlayerCapital(
  Game game,
  String playerId,
  String dockFullProvinceId,
) {
  final cap = game.playerById(playerId)?.capitalProvinceId;
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
    ).toList()..sort();
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
  final adjacent = seaZoneIdsAdjacentToProvince(
    topology,
    provinceId,
    regionId: regionId,
  );
  if (adjacent.isEmpty) return null;
  final nodeTypes = topologyNodeTypeById(topology);
  final probeIds = <String>{
    provinceId,
    if (regionId != null && !ProvinceId.isPrefixed(provinceId))
      ProvinceId.full(regionId, provinceId),
  };
  for (final probeId in probeIds) {
    for (final neighborId in nodesAdjacentTo(topology, probeId)) {
      if (adjacent.contains(neighborId) &&
          nodeTypes[neighborId] == TopologyNodeType.seaZone) {
        return neighborId;
      }
    }
  }
  return adjacent.first;
}

/// Fleets in port at [provinceId]. Per SPEC/game/ships-and-naval.md: in port =
/// fleet attached to that province ([inPortAtProvinceId] equals province id).
/// [provinceId] must be prefixed (regionId|localId) when world is multi-region.
List<Fleet> fleetsInPortAtProvince(WorldState worldState, String provinceId) {
  final normalized = provinceId.contains('|')
      ? provinceId
      : '$kRegionOldWorld|$provinceId';
  return worldState.fleets
      .where((f) => f.inPortAtProvinceId == normalized)
      .toList();
}
