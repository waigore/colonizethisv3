import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';

import '../world_test_support/unit_lookup_test_support.dart';

void main() {
  group('WorldStateUnitLookup.tryGetRegionIdForUnit', () {
    final uOld = Unit(
      id: 'r-old',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: 'oldWorld|P1',
      tileKey: 'oldWorld|P1|0|0',
    );
    final uNew = Unit(
      id: 'r-new',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: 'newWorld|P2',
      tileKey: 'newWorld|P2|0|0',
    );

    test('returns oldWorld when unit list is in old world', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: [uOld]),
        newWorld: const RegionData(),
      );
      expect(ws.tryGetRegionIdForUnit(uOld), kRegionOldWorld);
    });

    test('returns newWorld when unit is only in new world', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: const RegionData(),
        newWorld: RegionData(units: [uNew]),
      );
      expect(ws.tryGetRegionIdForUnit(uNew), kRegionNewWorld);
    });

    test('returns null when unit id is in neither region', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      expect(ws.tryGetRegionIdForUnit(uOld), isNull);
    });

    test('prefers old world when same id exists in both regions', () {
      final a = Unit(
        id: 'same',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: 'oldWorld|P1|0|0',
      );
      final b = Unit(
        id: 'same',
        type: kUnitTypeBuilder,
        ownerId: 'p2',
        locationProvinceId: 'newWorld|P2',
        tileKey: 'newWorld|P2|0|0',
      );
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: [a]),
        newWorld: RegionData(units: [b]),
      );
      expect(ws.tryGetRegionIdForUnit(b), kRegionOldWorld);
    });
  });

}
