import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group('WorldState mapBothRegions', () {
    test('invokes update for old then new with stable region ids', () {
      const p = Province(
        id: 'oldWorld|P1',
        regionId: kRegionOldWorld,
        ownerId: 'o',
      );
      const ow = RegionData(provinces: [p], units: const []);
      const nw = RegionData(provinces: const [], units: const []);
      final ws = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: ow,
        newWorld: nw,
      );

      final seen = <String>[];
      final next = ws.mapBothRegions((regionId, region) {
        seen.add(regionId);
        if (regionId == kRegionOldWorld) {
          return RegionData(
            provinces: [region.provinces.single.copyWith(ownerId: 'x')],
            units: region.units,
          );
        }
        return region;
      });

      expect(seen, [kRegionOldWorld, kRegionNewWorld]);
      expect(next.oldWorld.provinces.single.ownerId, 'x');
      expect(next.newWorld, nw);
    });
  });

  group('WorldState mapBothRegionUnits', () {
    test('maps units in both regions independently', () {
      final u1 = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'a',
        tileKey: 'oldWorld|P1|0|0',
        locationProvinceId: 'oldWorld|P1',
      );
      final u2 = Unit(
        id: 'u2',
        type: kUnitTypeExplorer,
        ownerId: 'a',
        tileKey: 'newWorld|P2|0|0',
        locationProvinceId: 'newWorld|P2',
      );
      final ws = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: RegionData(units: [u1]),
        newWorld: RegionData(units: [u2]),
      );

      final next = ws.mapBothRegionUnits((regionId, units) {
        if (regionId == kRegionOldWorld) {
          return [units.single.copyWith(ownerId: 'b')];
        }
        return units;
      });

      expect(next.oldWorld.units.single.ownerId, 'b');
      expect(next.newWorld.units.single.ownerId, 'a');
    });
  });
}
