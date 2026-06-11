import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'naval_resolution_helpers.dart';

// Per-order naval-move handlers (dock / at-sea) and the reachability gate for
// naval resolution (Refs #3290 Phase-0 file-split, #3416 part-of -> explicit
// library). This is a proper library imported by `naval_resolution.dart`; the
// shared helpers ([NavalMoveOutcome], [fleetIndexById]) come from
// `naval_resolution_helpers.dart`. The public handlers below stay unexported
// from the package barrel, so the public API is unchanged.

bool _navalMoveDestinationIsReachable({
  required MapTopology topology,
  required Fleet fleet,
  required String destZoneId,
}) {
  if (fleet.isAtSea) {
    final cur = fleet.seaZoneId;
    if (cur == null) return false;
    if (cur == destZoneId) return true;
    return isAdjacentSeaSeaZone(topology, cur, destZoneId);
  }
  final inPortProvinceId = fleet.inPortAtProvinceId;
  if (inPortProvinceId == null) return false;
  final rl = regionAndLocalProvinceForFleetInPort(
    inPortProvinceId,
    fleet.regionId,
  );
  final provinceNodeId = provinceTopologyNodeId(
    topology,
    rl.localId,
    rl.regionId,
  );
  if (provinceNodeId == null) return false;
  return seaZonesAdjacentToProvince(
    topology,
    provinceNodeId,
  ).contains(destZoneId);
}

NavalMoveOutcome applyDockNavalMoveOrder({
  required Game game,
  required MapTopology topology,
  required List<Fleet> fleets,
  required Map<String, Fleet> fleetById,
  required Map<String, int> fleetIndexById,
  required String playerId,
  required String homeFleetId,
  required Fleet fleet,
  required NavalMoveOrder order,
  required Map<String, Map<String, String>> visibilityByTile,
}) {
  final portProvinceId = order.destinationPortProvinceId!;
  if (!fleet.isAtSea || fleet.seaZoneId == null) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      fleetIndexById: fleetIndexById,
      visibilityByTile: visibilityByTile,
    );
  }
  final fullProvinceId = toFullProvinceId(fleet.regionId, portProvinceId);
  final province = game.worldState.tryGetProvince(fullProvinceId);
  if (province == null || province.ownerId != playerId) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      fleetIndexById: fleetIndexById,
      visibilityByTile: visibilityByTile,
    );
  }
  final adjacentSeaZones = seaZoneIdsAdjacentToProvince(
    topology,
    fullProvinceId,
  );
  if (!adjacentSeaZones.contains(fleet.seaZoneId)) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      fleetIndexById: fleetIndexById,
      visibilityByTile: visibilityByTile,
    );
  }

  var nextVis = revealProvinceTilesForPlayer(
    game,
    visibilityByTile,
    playerId,
    fullProvinceId,
  );

  if (dockOrderTargetsPlayerCapital(game, playerId, fullProvinceId)) {
    final homeFleet = fleetById[homeFleetId];
    if (homeFleet == null) {
      return (
        fleets: fleets,
        fleetById: fleetById,
        fleetIndexById: fleetIndexById,
        visibilityByTile: nextVis,
      );
    }
    final updatedHome = Fleet(
      id: homeFleet.id,
      ownerId: homeFleet.ownerId,
      seaZoneId: null,
      inPortAtProvinceId: homeFleet.inPortAtProvinceId,
      regionId: homeFleet.regionId,
      ships: [...homeFleet.ships, ...fleet.ships],
      mission: FleetMission.none,
      targetPortId: null,
      targetProvinceId: null,
    );
    // Single-pass list build (Refs #2394): avoids intermediate lazy chains from
    // `.where` / `.map` when merging a docking fleet into the capital home fleet.
    final nextFleets = <Fleet>[
      for (final f in fleets)
        if (f.id != fleet.id) f.id == homeFleetId ? updatedHome : f,
    ];
    final nextFleetIndexById = buildFleetIndexById(nextFleets);
    fleetById[homeFleetId] = updatedHome;
    fleetById.remove(fleet.id);
    return (
      fleets: nextFleets,
      fleetById: fleetById,
      fleetIndexById: nextFleetIndexById,
      visibilityByTile: nextVis,
    );
  }

  final portRegionId = ProvinceId.regionIdFrom(fullProvinceId);
  final newFleet = Fleet(
    id: fleet.id,
    ownerId: fleet.ownerId,
    seaZoneId: null,
    inPortAtProvinceId: fullProvinceId,
    regionId: portRegionId,
    ships: fleet.ships,
    mission: FleetMission.none,
    targetPortId: null,
    targetProvinceId: null,
  );
  var replacedDockFleet = false;
  final nextFleets = <Fleet>[];
  for (final f in fleets) {
    if (f.id == fleet.id) {
      nextFleets.add(newFleet);
      replacedDockFleet = true;
    } else {
      nextFleets.add(f);
    }
  }
  if (replacedDockFleet) {
    fleetById[fleet.id] = newFleet;
    return (
      fleets: nextFleets,
      fleetById: fleetById,
      fleetIndexById: fleetIndexById,
      visibilityByTile: nextVis,
    );
  }
  return (
    fleets: fleets,
    fleetById: fleetById,
    fleetIndexById: fleetIndexById,
    visibilityByTile: nextVis,
  );
}

NavalMoveOutcome applySeaNavalMoveOrder({
  required Game game,
  required MapTopology topology,
  required List<Fleet> fleets,
  required Map<String, Fleet> fleetById,
  required Map<String, int> fleetIndexById,
  required String playerId,
  required Fleet fleet,
  required NavalMoveOrder order,
  required Map<String, Map<String, String>> visibilityByTile,
}) {
  final destZoneId = order.destinationSeaZoneId;
  if (destZoneId == null || destZoneId.isEmpty) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      fleetIndexById: fleetIndexById,
      visibilityByTile: visibilityByTile,
    );
  }
  if (!seaZoneNodeIds(topology).contains(destZoneId)) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      fleetIndexById: fleetIndexById,
      visibilityByTile: visibilityByTile,
    );
  }
  if (!_navalMoveDestinationIsReachable(
    topology: topology,
    fleet: fleet,
    destZoneId: destZoneId,
  )) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      fleetIndexById: fleetIndexById,
      visibilityByTile: visibilityByTile,
    );
  }

  final destRegionId = regionIdForSeaZone(topology, destZoneId);
  final newFleet = Fleet(
    id: fleet.id,
    ownerId: fleet.ownerId,
    seaZoneId: destZoneId,
    inPortAtProvinceId: null,
    regionId: destRegionId ?? fleet.regionId,
    ships: fleet.ships,
    mission: FleetMission.none,
    targetPortId: null,
    targetProvinceId: null,
  );
  var nextFleets = fleets;
  var replacedAtSea = false;
  final rebuiltAtSea = <Fleet>[];
  for (final f in fleets) {
    if (f.id == fleet.id) {
      rebuiltAtSea.add(newFleet);
      replacedAtSea = true;
    } else {
      rebuiltAtSea.add(f);
    }
  }
  if (replacedAtSea) {
    nextFleets = rebuiltAtSea;
    fleetById[fleet.id] = newFleet;
  }

  var nextVis = visibilityByTile;
  if (destRegionId != null) {
    nextVis = revealTilesAfterMoveToSeaZone(
      game: game,
      topology: topology,
      visibilityByTile: nextVis,
      playerId: playerId,
      destRegionId: destRegionId,
      destZoneId: destZoneId,
    );
  }
  return (
    fleets: nextFleets,
    fleetById: fleetById,
    fleetIndexById: fleetIndexById,
    visibilityByTile: nextVis,
  );
}
