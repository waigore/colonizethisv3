import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';

import '../world_test_support/unit_lookup_test_support.dart';

void main() {
group('WorldStateUnitLookup.tryGetUnitById', () {
    final uOld = Unit(
      id: 'u-old',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: 'oldWorld|P1',
      tileKey: 'oldWorld|P1|0|0',
    );
    final uNew = Unit(
      id: 'u-new',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: 'newWorld|P2',
      tileKey: 'newWorld|P2|0|0',
    );

    test('returns unit from old world when present', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: [uOld]),
        newWorld: const RegionData(),
      );
      expect(ws.tryGetUnitById('u-old'), uOld);
    });

    test('returns unit from new world when not in old world', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: const RegionData(),
        newWorld: RegionData(units: [uNew]),
      );
      expect(ws.tryGetUnitById('u-new'), uNew);
    });

    test('returns null when id is absent', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: [uOld]),
        newWorld: RegionData(units: [uNew]),
      );
      expect(ws.tryGetUnitById('none'), isNull);
    });

    test('prefers old world when both lists contain the same id', () {
      final inOld = Unit(
        id: 'dup',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: 'oldWorld|P1|0|0',
      );
      final inNew = Unit(
        id: 'dup',
        type: kUnitTypeBuilder,
        ownerId: 'p2',
        locationProvinceId: 'newWorld|P2',
        tileKey: 'newWorld|P2|0|0',
      );
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: [inOld]),
        newWorld: RegionData(units: [inNew]),
      );
      expect(ws.tryGetUnitById('dup')!.type, kUnitTypeExplorer);
    });

    test('500+ units per region matches linear old-then-new scan (AC-3)', () {
      const n = 520;
      final oldUnits = List<Unit>.generate(
        n,
        (i) => Unit(
          id: 'old-$i',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: 'oldWorld|P1',
          tileKey: 'oldWorld|P1|0|0',
        ),
      );
      final newUnits = List<Unit>.generate(
        n,
        (i) => Unit(
          id: 'new-$i',
          type: kUnitTypeBuilder,
          ownerId: 'p2',
          locationProvinceId: 'newWorld|P2',
          tileKey: 'newWorld|P2|0|0',
        ),
      );
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: oldUnits),
        newWorld: RegionData(units: newUnits),
      );

      Unit? linearLookup(String unitId) {
        for (final u in ws.oldWorld.units) {
          if (u.id == unitId) return u;
        }
        for (final u in ws.newWorld.units) {
          if (u.id == unitId) return u;
        }
        return null;
      }

      for (var i = 0; i < n; i++) {
        final id = 'old-$i';
        expect(ws.tryGetUnitById(id), same(linearLookup(id)));
      }
      for (var i = 0; i < n; i++) {
        final id = 'new-$i';
        expect(ws.tryGetUnitById(id), same(linearLookup(id)));
      }
      expect(ws.tryGetUnitById('missing'), isNull);
    });
  });

}
