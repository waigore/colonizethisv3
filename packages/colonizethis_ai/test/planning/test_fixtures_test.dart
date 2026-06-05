import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

void main() {
  group('cheapestRegimentBuildCost', () {
    test('returns the minimum RegimentEconomyCatalog buildTreasuryCost', () {
      var expected = 999999999;
      for (final econ in RegimentEconomyCatalog.byId.values) {
        if (econ.buildTreasuryCost < expected) {
          expected = econ.buildTreasuryCost;
        }
      }
      expect(cheapestRegimentBuildCost(), expected);
    });
  });

  group('homeArmyWithRegiments', () {
    test('default stationing uses gp1_a province', () {
      final army = homeArmyWithRegiments('gp1', 3);
      expect(army.ownerId, 'gp1');
      expect(army.regionId, kOldWorldRegionId);
      expect(army.stationedProvinceId, kTestHomeArmyStationedProvinceGp1A);
      expect(army.regimentUnitIds, ['reg_gp1_0', 'reg_gp1_1', 'reg_gp1_2']);
    });

    test('capital stationing helper preserves owner-specific province', () {
      final army = homeArmyWithRegimentsAtCapital('gp2', 2);
      expect(army.stationedProvinceId, 'oldWorld|capital_gp2');
      expect(army.regimentUnitIds, ['reg_gp2_0', 'reg_gp2_1']);
    });
  });
}
