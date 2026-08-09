import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Human-assignable naval missions for player UI (v1). Excludes
/// `join_home_fleet` and [FleetMission.none].
const Set<FleetMission> kHumanAssignableNavalMissions = {
  FleetMission.patrol,
  FleetMission.defend,
  FleetMission.blockade,
  FleetMission.beachhead,
};

bool isProvinceOwnedByFactionAtWarWith({
  required Game game,
  required String playerId,
  required String fullProvinceId,
}) {
  final province = game.worldState.tryGetProvince(fullProvinceId);
  final ownerId = province?.ownerId;
  if (province == null || ownerId == null || ownerId.isEmpty) {
    return false;
  }
  if (ownerId == playerId) return false;
  final rel = getRelation(game, playerId, ownerId);
  return rel?.atWar == true;
}

/// Coastal provinces adjacent to [fleet]'s current sea zone that are owned by
/// factions at war with [playerId]. Returns full prefixed province ids sorted
/// lexicographically for deterministic UI ordering.
List<String> hostileCoastalProvinceTargetsForFleet({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Fleet fleet,
}) {
  if (!fleet.isAtSea || fleet.seaZoneId == null) return const [];
  final regionId = fleet.regionId;
  final adjacentLocalIds = provinceIdsAdjacentToSeaZone(
    topology,
    fleet.seaZoneId!,
    regionId: regionId,
  );
  final out = <String>[];
  for (final localOrFull in adjacentLocalIds) {
    final fullProvinceId = ProvinceId.isPrefixed(localOrFull)
        ? localOrFull
        : ProvinceId.full(regionId, localOrFull);
    if (isProvinceOwnedByFactionAtWarWith(
      game: game,
      playerId: playerId,
      fullProvinceId: fullProvinceId,
    )) {
      out.add(fullProvinceId);
    }
  }
  out.sort();
  return out;
}

bool isLegalBlockadeTargetForFleet({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Fleet fleet,
  required String targetProvinceId,
}) {
  return hostileCoastalProvinceTargetsForFleet(
    game: game,
    topology: topology,
    playerId: playerId,
    fleet: fleet,
  ).contains(targetProvinceId);
}

bool isLegalBeachheadTargetForFleet({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Fleet fleet,
  required String targetProvinceId,
}) {
  return isLegalBlockadeTargetForFleet(
    game: game,
    topology: topology,
    playerId: playerId,
    fleet: fleet,
    targetProvinceId: targetProvinceId,
  );
}
