import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show homeFleetIdFor, GamePlayerLookup;

/// Capital identity match for Home Fleet transfer sources (Refs #4625).
bool provinceIdMatchesCapital(String provinceId, String capitalProvinceId) {
  if (provinceId == capitalProvinceId) return true;
  final capRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
  final capLocalId = ProvinceId.localIdFrom(capitalProvinceId);
  return provinceId == capLocalId || provinceId == '$capRegionId|$capLocalId';
}

/// True when [sourceSeaZoneId] shares a topology S–P edge with the capital.
bool seaZoneAdjacentToCapital({
  required MapTopology topology,
  required String sourceSeaZoneId,
  required String sourceRegionId,
  required String capitalProvinceId,
}) {
  final capRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
  final capLocalId = ProvinceId.localIdFrom(capitalProvinceId);
  final sourceSeaLocal = prefixedIdLocalSegment(sourceSeaZoneId);
  final sourceSeaPrefixed = prefixedIdHasDelimiter(sourceSeaZoneId)
      ? sourceSeaZoneId
      : '$sourceRegionId|$sourceSeaZoneId';
  final sourceSeaCandidates = <String>{
    sourceSeaZoneId,
    sourceSeaLocal,
    sourceSeaPrefixed,
  };
  final capitalCandidates = <String>{
    capitalProvinceId,
    capLocalId,
    '$capRegionId|$capLocalId',
  };
  for (final edge in topology.edges) {
    final a = edge.id1;
    final b = edge.id2;
    final aIsSea = sourceSeaCandidates.contains(a);
    final bIsSea = sourceSeaCandidates.contains(b);
    final aIsCap = capitalCandidates.contains(a);
    final bIsCap = capitalCandidates.contains(b);
    if ((aIsSea && bIsCap) || (bIsSea && aIsCap)) {
      return true;
    }
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
  if (sourceFleet.ownerId != humanPlayerId) return false;
  if (sourceFleet.id == homeFleetIdFor(humanPlayerId)) return false;
  if (sourceFleet.ships.isEmpty) return false;
  if (!sourceFleet.isAtSea) {
    final inPortId = sourceFleet.inPortAtProvinceId;
    if (inPortId == null) return false;
    return provinceIdMatchesCapital(inPortId, capitalProvinceId);
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
  final localSea = prefixedIdLocalSegment(displayId);
  final regionId = prefixedIdRegionSegment(displayId);
  if (!fleet.isAtSea) return false;
  if (fleet.seaZoneId != localSea) return false;
  if (regionId == null) return true;
  return fleet.regionId == regionId;
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
    if (isSeaZone) {
      if (_fleetOccupiesSeaDisplay(fleet, displayId)) out.add(fleet);
    } else if (fleet.inPortAtProvinceId != null &&
        provinceIdMatchesCapital(fleet.inPortAtProvinceId!, displayId)) {
      out.add(fleet);
    }
  }
  out.sort((a, b) => a.id.compareTo(b.id));
  return out;
}
