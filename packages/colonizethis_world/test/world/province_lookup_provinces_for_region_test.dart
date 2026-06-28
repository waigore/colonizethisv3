import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  final pOld1 = Province(
    id: 'oldWorld|P1',
    regionId: kRegionOldWorld,
    ownerId: 'gp1',
  );
  final pOld2 = Province(
    id: 'oldWorld|P2',
    regionId: kRegionOldWorld,
    ownerId: 'gp2',
  );
  final pNew1 = Province(
    id: 'newWorld|P3',
    regionId: kRegionNewWorld,
    ownerId: 'gp1',
  );

  WorldState makeWorld({
    List<Province> oldProvinces = const [],
    List<Province> newProvinces = const [],
  }) {
    return TestFixtures.worldStateAtOrdersPhase(
      turnNumber: 0,
      oldWorld: RegionData(provinces: oldProvinces),
      newWorld: RegionData(provinces: newProvinces),
    );
  }

  group('WorldStateProvinceLookup.provincesForRegion (Refs #2836 AC 5)', () {
    test(
      'returns Old World provinces only when regionId == kRegionOldWorld',
      () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2],
          newProvinces: [pNew1],
        );

        final result = ws.provincesForRegion(kRegionOldWorld).toList();

        expect(result, [pOld1, pOld2]);
      },
    );

    test(
      'returns New World provinces only when regionId == kRegionNewWorld',
      () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2],
          newProvinces: [pNew1],
        );

        final result = ws.provincesForRegion(kRegionNewWorld).toList();

        expect(result, [pNew1]);
      },
    );

    test('returns an empty iterable when the region is unknown', () {
      final ws = makeWorld(
        oldProvinces: [pOld1, pOld2],
        newProvinces: [pNew1],
      );

      final result = ws.provincesForRegion('mars').toList();

      expect(result, isEmpty);
    });

    test('returns an empty iterable for an empty regionId', () {
      final ws = makeWorld(oldProvinces: [pOld1]);

      final result = ws.provincesForRegion('').toList();

      expect(result, isEmpty);
    });

    test('returns an empty iterable for a region with no provinces', () {
      final ws = makeWorld(oldProvinces: [pOld1]);

      final result = ws.provincesForRegion(kRegionNewWorld).toList();

      expect(result, isEmpty);
    });

    test('returns the same Iterable contents on repeated reads', () {
      final ws = makeWorld(oldProvinces: [pOld1, pOld2]);

      final first = ws.provincesForRegion(kRegionOldWorld).toList();
      final second = ws.provincesForRegion(kRegionOldWorld).toList();

      expect(first, second);
    });
  });
}
