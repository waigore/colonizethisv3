import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  final uOld1 = Unit(
    id: 'u-old-1',
    type: kUnitTypeExplorer,
    ownerId: 'p1',
    locationProvinceId: 'oldWorld|P1',
    tileKey: 'oldWorld|P1|0|0',
  );
  final uOld2 = Unit(
    id: 'u-old-2',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: 'oldWorld|P1',
    tileKey: 'oldWorld|P1|0|1',
  );
  final uNew1 = Unit(
    id: 'u-new-1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: 'newWorld|P2',
    tileKey: 'newWorld|P2|0|0',
  );
  final uNew2 = Unit(
    id: 'u-new-2',
    type: kUnitTypeExplorer,
    ownerId: 'p2',
    locationProvinceId: 'newWorld|P3',
    tileKey: 'newWorld|P3|0|0',
  );

  WorldState makeWorld({
    List<Unit> oldUnits = const [],
    List<Unit> newUnits = const [],
  }) {
    return TestFixtures.worldStateAtOrdersPhase(
      turnNumber: 0,
      oldWorld: RegionData(units: oldUnits),
      newWorld: RegionData(units: newUnits),
    );
  }

  group(
    'WorldStateUnitLookup.mutableUnitListsByRegion (Refs #2836 AC 5)',
    () {
      test('returns both regions keyed by canonical region ids', () {
        final ws = makeWorld(oldUnits: [uOld1, uOld2], newUnits: [uNew1]);

        final result = ws.mutableUnitListsByRegion();

        expect(result.keys.toSet(), {kRegionOldWorld, kRegionNewWorld});
        expect(result[kRegionOldWorld], [uOld1, uOld2]);
        expect(result[kRegionNewWorld], [uNew1]);
      });

      test('returns empty lists for empty regions', () {
        final ws = makeWorld();

        final result = ws.mutableUnitListsByRegion();

        expect(result[kRegionOldWorld], isEmpty);
        expect(result[kRegionNewWorld], isEmpty);
      });

      test(
        'returned lists are independent copies — mutating does not change '
        'source WorldState',
        () {
          final ws = makeWorld(
            oldUnits: [uOld1, uOld2],
            newUnits: [uNew1],
          );

          final result = ws.mutableUnitListsByRegion();
          result[kRegionOldWorld]!.removeLast();
          result[kRegionNewWorld]!.add(uNew2);

          expect(ws.oldWorld.units, [uOld1, uOld2]);
          expect(ws.newWorld.units, [uNew1]);
        },
      );

      test(
        'two successive calls produce independent list copies (no shared '
        'mutable state between calls)',
        () {
          final ws = makeWorld(
            oldUnits: [uOld1, uOld2],
            newUnits: [uNew1],
          );

          final first = ws.mutableUnitListsByRegion();
          final second = ws.mutableUnitListsByRegion();

          expect(
            identical(first[kRegionOldWorld], second[kRegionOldWorld]),
            isFalse,
          );
          expect(
            identical(first[kRegionNewWorld], second[kRegionNewWorld]),
            isFalse,
          );

          first[kRegionOldWorld]!.add(uOld1);
          expect(second[kRegionOldWorld], [uOld1, uOld2]);
        },
      );
    },
  );
}
