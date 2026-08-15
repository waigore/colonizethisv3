import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Home Army lookup for MAP20001 detach-then-move/invade (Refs #4407).
Army? humanHomeArmy(Game game, String humanPlayerId) {
  for (final army in game.worldState.armies) {
    if (army.ownerId == humanPlayerId && army.isHomeArmy) {
      return army;
    }
  }
  return null;
}

/// Cheap occupancy: capital Home Army has ≥1 regiment.
bool homeArmyHasRegiments(Game game, String humanPlayerId) {
  final home = humanHomeArmy(game, humanPlayerId);
  return home != null && home.regimentUnitIds.isNotEmpty;
}

/// Cheap Invade/Move detach clause: non-empty Home Army land-adjacent
/// (same region) to [targetFullProvinceId]. Does not read the picker cache.
bool homeArmyDetachInvadeCheap({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required String targetFullProvinceId,
}) {
  final home = humanHomeArmy(game, humanPlayerId);
  if (home == null || home.regimentUnitIds.isEmpty) return false;
  final homeRegion = ProvinceId.regionIdFrom(home.stationedProvinceId);
  final targetRegion = ProvinceId.regionIdFrom(targetFullProvinceId);
  if (homeRegion != targetRegion) return false;
  final targetLocal = ProvinceId.localIdFrom(targetFullProvinceId);
  final homeLocal = ProvinceId.localIdFrom(home.stationedProvinceId);
  return neighborProvinceIdsInRegion(
    topology,
    targetRegion,
    targetLocal,
  ).contains(homeLocal);
}

/// Overlay taps with enablement but no field-army ids use detach-then-move.
bool usesHomeArmyDetachFlow({
  required bool enabled,
  required List<String> eligibleArmyIds,
}) {
  return enabled && eligibleArmyIds.isEmpty;
}
