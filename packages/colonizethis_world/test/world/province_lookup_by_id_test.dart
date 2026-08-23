// ignore_for_file: deprecated_member_use

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/province_lookup_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'province_lookup_by_id_region_cases.dart';

void main() {
  _province_lookup_by_id_testTests();
}

void _province_lookup_by_id_testTests() {
  group('WorldStateProvinceLookup.allProvincesById (Refs #2836 item 4)', () {
    test('contains provinces from both regions keyed by id', () {
      final ws = makeWorld(oldProvinces: [pOld], newProvinces: [pNew]);

      expect(ws.allProvincesById.length, 2);
      expect(ws.allProvincesById['oldWorld|P1'], pOld);
      expect(ws.allProvincesById['newWorld|P2'], pNew);
    });

    test('prefers old-world province when both regions share an id', () {
      final dupOld = Province(
        id: 'dup',
        regionId: kRegionOldWorld,
        ownerId: 'gp1',
      );
      final dupNew = Province(
        id: 'dup',
        regionId: kRegionNewWorld,
        ownerId: 'gp2',
      );
      final ws = makeWorld(oldProvinces: [dupOld], newProvinces: [dupNew]);

      expect(ws.allProvincesById['dup']!.ownerId, 'gp1');
    });

    test(
      'returns the identical map across repeated reads for one WorldState',
      () {
        final ws = makeWorld(oldProvinces: [pOld], newProvinces: [pNew]);

        final first = ws.allProvincesById;
        final second = ws.allProvincesById;

        expect(identical(first, second), isTrue);
      },
    );

    test('different WorldState copies receive their own cached map', () {
      final wsA = makeWorld(oldProvinces: [pOld], newProvinces: [pNew]);
      final wsB = wsA.copyWith(turnState: turn);

      expect(identical(wsA.allProvincesById, wsB.allProvincesById), isFalse);
    });

    test('mutation of returned map throws UnsupportedError', () {
      final ws = makeWorld(oldProvinces: [pOld]);

      expect(
        () => ws.allProvincesById['oldWorld|P1'] = pOld,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('empty regions yield empty map', () {
      final ws = makeWorld();

      expect(ws.allProvincesById, isEmpty);
    });
  });

  group('WorldStateProvinceLookup.provincesForRegion (Refs #2836 AC 5)', () {
    test(
      'returns Old World provinces only when regionId == kRegionOldWorld',
      () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2Owned],
          newProvinces: [pNew1Gp1],
        );

        final result = ws.provincesForRegion(kRegionOldWorld).toList();

        expect(result, [pOld1, pOld2Owned]);
      },
    );

    test(
      'returns New World provinces only when regionId == kRegionNewWorld',
      () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2Owned],
          newProvinces: [pNew1Gp1],
        );

        final result = ws.provincesForRegion(kRegionNewWorld).toList();

        expect(result, [pNew1Gp1]);
      },
    );

    test('returns an empty iterable when the region is unknown', () {
      final ws = makeWorld(
        oldProvinces: [pOld1, pOld2Owned],
        newProvinces: [pNew1Gp1],
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
      final ws = makeWorld(oldProvinces: [pOld1, pOld2Owned]);

      final first = ws.provincesForRegion(kRegionOldWorld).toList();
      final second = ws.provincesForRegion(kRegionOldWorld).toList();

      expect(first, second);
    });
  });

  registerProvinceLookupByIdRegionCases();
}
