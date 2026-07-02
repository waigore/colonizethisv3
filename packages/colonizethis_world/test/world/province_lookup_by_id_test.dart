// ignore_for_file: deprecated_member_use

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/province_owner_cache.dart';
import 'package:colonizethis_world/src/world_constants.dart'
    show kRegionNewWorld, kRegionOldWorld;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import '../world_test_support/province_lookup_test_support.dart';

void main() {
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

  group(
    'WorldStateProvinceLookup.mutableProvinceListsByRegion '
    '(Refs #2836 AC 5)',
    () {
      test('returns both regions keyed by canonical region ids', () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2Owned],
          newProvinces: [pNew1Gp1, pNew2],
        );

        final result = ws.mutableProvinceListsByRegion();

        expect(result.keys.toSet(), {kRegionOldWorld, kRegionNewWorld});
        expect(result[kRegionOldWorld], [pOld1, pOld2Owned]);
        expect(result[kRegionNewWorld], [pNew1Gp1, pNew2]);
      });

      test('returns empty lists for empty regions', () {
        final ws = makeWorld();

        final result = ws.mutableProvinceListsByRegion();

        expect(result[kRegionOldWorld], isEmpty);
        expect(result[kRegionNewWorld], isEmpty);
      });

      test(
        'returned lists are independent copies — mutating does not change '
        'source WorldState',
        () {
          final ws = makeWorld(
            oldProvinces: [pOld1, pOld2Owned],
            newProvinces: [pNew1Gp1],
          );

          final result = ws.mutableProvinceListsByRegion();
          result[kRegionOldWorld]!.clear();
          result[kRegionNewWorld]!.add(pNew2);

          expect(ws.oldWorld.provinces, [pOld1, pOld2Owned]);
          expect(ws.newWorld.provinces, [pNew1Gp1]);
        },
      );

      test(
        'two successive calls produce independent list copies (no shared '
        'mutable state between calls)',
        () {
          final ws = makeWorld(
            oldProvinces: [pOld1, pOld2Owned],
            newProvinces: [pNew1Gp1],
          );

          final first = ws.mutableProvinceListsByRegion();
          final second = ws.mutableProvinceListsByRegion();

          expect(
            identical(first[kRegionOldWorld], second[kRegionOldWorld]),
            isFalse,
          );
          expect(
            identical(first[kRegionNewWorld], second[kRegionNewWorld]),
            isFalse,
          );

          first[kRegionOldWorld]!.add(pOld1);
          expect(second[kRegionOldWorld], [pOld1, pOld2Owned]);
        },
      );
    },
  );

  group('WorldStateProvinceLookup.regionsInOrder (Refs #3710)', () {
    test('yields old world first, then new world, with their region data', () {
      final ws = makeWorld(oldProvinces: [pOld1], newProvinces: [pNew1Gp2]);

      final entries = ws.regionsInOrder.toList();

      expect(entries.map((e) => e.regionId), [
        kRegionOldWorld,
        kRegionNewWorld,
      ]);
      expect(identical(entries[0].region, ws.oldWorld), isTrue);
      expect(identical(entries[1].region, ws.newWorld), isTrue);
    });

    test('still yields both regions when one has no provinces', () {
      final ws = makeWorld(oldProvinces: [pOld1]);

      final entries = ws.regionsInOrder.toList();

      expect(entries.map((e) => e.regionId), [
        kRegionOldWorld,
        kRegionNewWorld,
      ]);
      expect(entries[1].region.provinces, isEmpty);
    });
  });

  group('cross-region traversal stays consistent with regionsInOrder', () {
    test(
      'allProvinces equals regionsInOrder province concatenation '
      '(old-then-new)',
      () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2Bare],
          newProvinces: [pNew1Gp2],
        );

        final viaRegions = [
          for (final entry in ws.regionsInOrder) ...entry.region.provinces,
        ];

        expect(ws.allProvinces().toList(), viaRegions);
        expect(allProvinces(ws).toList(), viaRegions);
        expect(ws.allProvinces().toList(), [pOld1, pOld2Bare, pNew1Gp2]);
      },
    );

    test('forEachRegion visits regions in regionsInOrder order', () {
      final ws = makeWorld(oldProvinces: [pOld1], newProvinces: [pNew1Gp2]);

      final seen = <String>[];
      ws.forEachRegion((regionId, _) => seen.add(regionId));

      expect(seen, ws.regionsInOrder.map((e) => e.regionId).toList());
      expect(seen, [kRegionOldWorld, kRegionNewWorld]);
    });
  });

}
