import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval.dart';
import 'province_lookup.dart';

/// Returns the owning player id of [fleet.targetProvinceId] when this fleet
/// contributes a valid blockade according to SPEC/game/capital-and-connectivity.
///
/// Null means the fleet does not create a valid blockade target in this step.
String? blockadedProvinceOwnerIdForFleet({
  required Fleet fleet,
  required WorldState worldState,
  required MapTopology topology,
  required bool Function(String attackerFactionId, String defenderFactionId)
  areFactionsAtWar,
}) {
  if (fleet.mission != FleetMission.blockade) return null;
  if (!fleet.isAtSea || fleet.seaZoneId == null) return null;

  final targetProvinceId = fleet.targetProvinceId;
  if (targetProvinceId == null || targetProvinceId.isEmpty) return null;
  if (!ProvinceId.isPrefixed(targetProvinceId)) return null;

  final adjacentSeaZones = seaZoneIdsAdjacentToProvince(
    topology,
    targetProvinceId,
  );
  if (!adjacentSeaZones.contains(fleet.seaZoneId)) return null;

  final province = worldState.tryGetProvince(targetProvinceId);
  final ownerId = province?.ownerId;
  if (ownerId == null) return null;

  if (!areFactionsAtWar(fleet.ownerId, ownerId)) return null;
  return ownerId;
}
