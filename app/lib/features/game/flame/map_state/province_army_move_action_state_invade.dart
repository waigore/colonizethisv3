import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'province_army_move_home_army.dart';

/// Cheap Invade visibility predicate (topology + army stationing only).
bool invadeConceivableCheap({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required String targetFullProvinceId,
}) {
  final regionId = ProvinceId.regionIdFrom(targetFullProvinceId);
  final localId = ProvinceId.localIdFrom(targetFullProvinceId);
  final fieldInRegion = <Army>[
    for (final army in game.worldState.armies)
      if (army.ownerId == humanPlayerId &&
          !army.isHomeArmy &&
          army.regimentUnitIds.isNotEmpty &&
          ProvinceId.regionIdFrom(army.stationedProvinceId) == regionId)
        army,
  ];
  final neighborLocals = neighborProvinceIdsInRegion(
    topology,
    regionId,
    localId,
  ).toSet();
  for (final army in fieldInRegion) {
    final hostLocal = ProvinceId.localIdFrom(army.stationedProvinceId);
    if (neighborLocals.contains(hostLocal)) return true;
  }
  return homeArmyDetachInvadeCheap(
    game: game,
    topology: topology,
    humanPlayerId: humanPlayerId,
    targetFullProvinceId: targetFullProvinceId,
  );
}

bool hasInvasionOwnerSemantics(Game game, String ownerId) {
  if (ownerId.isEmpty) return false;
  if (game.playerById(ownerId) != null) return true;
  for (final m in game.minorNations) {
    if (m.id == ownerId) return true;
  }
  for (final t in game.tribes) {
    if (t.id == ownerId) return true;
  }
  return false;
}
