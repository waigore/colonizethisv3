import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'naval_resolution_helpers.dart';

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
