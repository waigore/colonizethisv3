import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show homeFleetIdFor, GamePlayerLookup;

/// Capital identity match for Home Fleet transfer sources (Refs #4625).
bool provinceIdMatchesCapital(String provinceId, String capitalProvinceId) {
  return _capitalIdSet(capitalProvinceId).contains(provinceId);
}

Set<String> _capitalIdSet(String capitalProvinceId) {
  final capRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
  final capLocalId = ProvinceId.localIdFrom(capitalProvinceId);
  return {capitalProvinceId, capLocalId, '$capRegionId|$capLocalId'};
}

/// True when [sourceSeaZoneId] shares a topology S–P edge with the capital.
bool seaZoneAdjacentToCapital({
  required MapTopology topology,
  required String sourceSeaZoneId,
  required String sourceRegionId,
  required String capitalProvinceId,
}) {
  final sourceSeaLocal = prefixedIdLocalSegment(sourceSeaZoneId);
  final sourceSeaPrefixed = prefixedIdHasDelimiter(sourceSeaZoneId)
      ? sourceSeaZoneId
      : '$sourceRegionId|$sourceSeaZoneId';
  final seas = {sourceSeaZoneId, sourceSeaLocal, sourceSeaPrefixed};
  final caps = _capitalIdSet(capitalProvinceId);
  for (final edge in topology.edges) {
    final aSea = seas.contains(edge.id1);
    final bSea = seas.contains(edge.id2);
    final aCap = caps.contains(edge.id1);
    final bCap = caps.contains(edge.id2);
    if ((aSea && bCap) || (bSea && aCap)) return true;
  }
  return false;
}

/// Join-Home-Fleet location gate (in port at capital or at sea adjacent).
bool isEligibleHomeTransferSourceFleet({
  required Fleet sourceFleet,
  required String humanPlayerId,
  required String capitalProvinceId,
  required MapTopology topology,
}) {
  if (sourceFleet.ownerId != humanPlayerId ||
      sourceFleet.id == homeFleetIdFor(humanPlayerId) ||
      sourceFleet.ships.isEmpty) {
    return false;
  }
  if (!sourceFleet.isAtSea) {
    final inPortId = sourceFleet.inPortAtProvinceId;
    return inPortId != null &&
        provinceIdMatchesCapital(inPortId, capitalProvinceId);
  }
  final seaZoneId = sourceFleet.seaZoneId;
  if (seaZoneId == null || seaZoneId.isEmpty) return false;
  return seaZoneAdjacentToCapital(
    topology: topology,
    sourceSeaZoneId: seaZoneId,
    sourceRegionId: sourceFleet.regionId,
    capitalProvinceId: capitalProvinceId,
  );
}

bool _fleetOccupiesSeaDisplay(Fleet fleet, String displayId) {
  if (!fleet.isAtSea) return false;
  if (fleet.seaZoneId != prefixedIdLocalSegment(displayId)) return false;
  final regionId = prefixedIdRegionSegment(displayId);
  return regionId == null || fleet.regionId == regionId;
}

/// Eligible sea-going sources for MAP20001 Transfer at [displayId].
List<Fleet> overlayTransferToHomeSourceFleets({
  required Game game,
  required String humanPlayerId,
  required String displayId,
  required bool isSeaZone,
  required MapTopology topology,
}) {
  final capitalProvinceId = game.playerById(humanPlayerId)?.capitalProvinceId;
  if (capitalProvinceId == null) return const [];
  final out = <Fleet>[];
  for (final fleet in game.worldState.fleets) {
    if (!isEligibleHomeTransferSourceFleet(
      sourceFleet: fleet,
      humanPlayerId: humanPlayerId,
      capitalProvinceId: capitalProvinceId,
      topology: topology,
    )) {
      continue;
    }
    final inPort = fleet.inPortAtProvinceId;
    final match = isSeaZone
        ? _fleetOccupiesSeaDisplay(fleet, displayId)
        : inPort != null && provinceIdMatchesCapital(inPort, displayId);
    if (match) out.add(fleet);
  }
  out.sort((a, b) => a.id.compareTo(b.id));
  return out;
}
