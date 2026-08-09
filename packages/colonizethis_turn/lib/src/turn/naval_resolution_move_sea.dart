import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'naval_move_destination.dart';
import 'naval_resolution_helpers.dart';

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
  if (!navalMoveDestinationIsReachable(
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
