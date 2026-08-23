import 'package:colonizethis_models/colonizethis_models.dart';

/// Visibility/enablement for MAP20001 Military Combine (Refs #4610).
class ProvinceArmyCombineActionState {
  const ProvinceArmyCombineActionState({
    required this.show,
    required this.enabled,
    required this.hasPendingMarch,
    required this.armyIds,
  });

  static const hidden = ProvinceArmyCombineActionState(
    show: false,
    enabled: false,
    hasPendingMarch: false,
    armyIds: <String>[],
  );

  final bool show;
  final bool enabled;
  final bool hasPendingMarch;
  final List<String> armyIds;
}

/// Human-owned armies stationed in [provinceId], sorted by id.
List<Army> humanArmiesInProvince({
  required Game game,
  required String humanPlayerId,
  required String provinceId,
}) {
  final out = <Army>[
    for (final army in game.worldState.armies)
      if (army.ownerId == humanPlayerId &&
          army.stationedProvinceId == provinceId)
        army,
  ]..sort((a, b) => a.id.compareTo(b.id));
  return out;
}

bool armySetHasPendingLandMarch({
  required Game game,
  required Orders draftOrders,
  required String humanPlayerId,
  required List<Army> armies,
}) {
  if (armies.isEmpty) return false;
  final armyIds = {for (final a in armies) a.id};
  final regimentIds = <String>{for (final a in armies) ...a.regimentUnitIds};
  for (final o
      in draftOrders.armyMoveOrdersByPlayerId[humanPlayerId] ?? const []) {
    if (armyIds.contains(o.armyId)) return true;
  }
  if (regimentIds.isEmpty) return false;
  for (final o in draftOrders.moveOrdersByPlayerId[humanPlayerId] ?? const []) {
    if (regimentIds.contains(o.unitId)) return true;
  }
  return false;
}

ProvinceArmyCombineActionState computeProvinceArmyCombineActionState({
  required Game game,
  required String humanPlayerId,
  required String provinceId,
  required Orders draftOrders,
  required bool showsFullMilitaryIntel,
  required bool isSeaZoneContext,
  required bool canMutateViaUi,
}) {
  if (!canMutateViaUi || isSeaZoneContext || !showsFullMilitaryIntel) {
    return ProvinceArmyCombineActionState.hidden;
  }
  final armies = humanArmiesInProvince(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
  );
  if (armies.length < 2) {
    return ProvinceArmyCombineActionState.hidden;
  }
  final ids = [for (final a in armies) a.id];
  final pending = armySetHasPendingLandMarch(
    game: game,
    draftOrders: draftOrders,
    humanPlayerId: humanPlayerId,
    armies: armies,
  );
  return ProvinceArmyCombineActionState(
    show: true,
    enabled: !pending,
    hasPendingMarch: pending,
    armyIds: ids,
  );
}

Army overlayCombineSurvivor(List<Army> armies) {
  for (final a in armies) {
    if (a.isHomeArmy) return a;
  }
  final sorted = [...armies]..sort((a, b) => a.id.compareTo(b.id));
  return sorted.first;
}
