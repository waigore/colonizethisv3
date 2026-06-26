import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Default [homeArmyWithRegiments] stationed province for the fixed GP-province
/// pattern used by dispatch / priority-weight / NW-suppression tests.
const String kTestHomeArmyStationedProvinceGp1A = 'oldWorld|gp1_a';

/// Cheapest [RegimentEconomyCatalog] build cost; mirrors planner treasury gates.
int cheapestRegimentBuildCost() {
  var min = 999999999;
  for (final econ in RegimentEconomyCatalog.byId.values) {
    if (econ.buildTreasuryCost < min) {
      min = econ.buildTreasuryCost;
    }
  }
  return min;
}

/// Home Army with [regimentCount] dummy regiment ids; matches the walk in
/// `regimentCountForPlayer`.
///
/// Default [stationedProvinceId] is [kTestHomeArmyStationedProvinceGp1A].
/// Expand/colonial planner tests that station at the owner capital should pass
/// [stationedProvinceId: testHomeArmyCapitalProvinceId(ownerId)] or call
/// [homeArmyWithRegimentsAtCapital].
Army homeArmyWithRegiments(
  String ownerId,
  int regimentCount, {
  String regionId = kOldWorldRegionId,
  String? stationedProvinceId,
}) {
  return Army(
    id: 'home_army:$ownerId',
    ownerId: ownerId,
    regionId: regionId,
    stationedProvinceId:
        stationedProvinceId ?? kTestHomeArmyStationedProvinceGp1A,
    isHomeArmy: true,
    regimentUnitIds: <String>[
      for (var i = 0; i < regimentCount; i++) 'reg_${ownerId}_$i',
    ],
  );
}

/// Capital-stationed variant used by expand/colonial phase planner tests.
String testHomeArmyCapitalProvinceId(String ownerId) =>
    'oldWorld|capital_$ownerId';

Army homeArmyWithRegimentsAtCapital(String ownerId, int regimentCount) {
  return homeArmyWithRegiments(
    ownerId,
    regimentCount,
    stationedProvinceId: testHomeArmyCapitalProvinceId(ownerId),
  );
}
