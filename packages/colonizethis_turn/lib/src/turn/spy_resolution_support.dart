import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

int counterEspionageKillBonusPercent(
  String territoryOwnerId,
  Set<String> counterEspGpIds,
) {
  if (!counterEspGpIds.contains(territoryOwnerId)) return 0;
  return spyCounterEspionageKillBoostPercent;
}

Set<String> greatPowersWithEmpireWideCounterEspionage(Game game) {
  return {
    for (final p in game.players)
      if (playerRunsCounterEspionage(game, p.id)) p.id,
  };
}

bool playerRunsCounterEspionage(Game game, String playerId) {
  for (final u in game.worldState.allUnitsById.values) {
    if (u.ownerId != playerId) continue;
    if (!isSpyUnit(u.type)) continue;
    if (u.currentWork?.workTarget == kWorkTargetCounterSpy) return true;
  }
  return false;
}

Map<String, int> garrisonRegimentCountByProvince(Game game) {
  final counts = <String, int>{};
  for (final army in game.worldState.armies) {
    final provinceId = army.stationedProvinceId;
    if (provinceId.isEmpty) continue;
    counts[provinceId] =
        (counts[provinceId] ?? 0) + army.regimentUnitIds.length;
  }
  return counts;
}

Game gameWithSpyUnits(Game game, Map<String, Unit> unitsById) {
  final oldUnits = <Unit>[];
  final newUnits = <Unit>[];
  for (final u in unitsById.values) {
    if (ProvinceId.regionIdFrom(u.locationProvinceId) == kRegionOldWorld) {
      oldUnits.add(u);
    } else {
      newUnits.add(u);
    }
  }
  return game.updateWorldState(
    (ws) => ws.copyWith(
      oldWorld: RegionData(provinces: ws.oldWorld.provinces, units: oldUnits),
      newWorld: RegionData(provinces: ws.newWorld.provinces, units: newUnits),
    ),
  );
}
