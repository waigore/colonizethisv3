// Case bodies for `planning_invadable_owners_test.dart` (Refs #4310 Slice D).
// Pins invadable frontier ownership predicates and faction scans.

import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_invadable_owners_test_support.dart';

void registerPlanningInvadableOwnersPredicateCases() {
  group('anyInvadableProvinceOwnedByMinor (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';

    test('true when an invadable province is owned by a minor nation', () {
      final game = planningInvadableOwnersGameWithGps();
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: planningInvadableOwnersMinor1},
        ),
        isTrue,
      );
    });

    test('false when invadable provinces are owned only by GPs / tribes', () {
      final game = planningInvadableOwnersGameWithGps();
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA, pB]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {
            pA: planningInvadableOwnersGp2,
            pB: planningInvadableOwnersTribe1,
          },
        ),
        isFalse,
      );
    });

    test('false when an invadable province owner is absent from the map', () {
      // Unowned / not-yet-mapped invadable province: lookup is null, no match.
      final game = planningInvadableOwnersGameWithGps();
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {},
        ),
        isFalse,
      );
    });

    test('false when there are no invadable provinces', () {
      final game = planningInvadableOwnersGameWithGps();
      final snapshot = planningInvadableOwnersSnapshotWithInvadable(const []);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: planningInvadableOwnersMinor1},
        ),
        isFalse,
      );
    });

    test('true when only a non-first invadable province is minor-owned', () {
      // The .any short-circuit must still find a minor owner that is not the
      // first scanned entry (GP first, minor second) -> deterministic true.
      final game = planningInvadableOwnersGameWithGps();
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA, pB]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {
            pA: planningInvadableOwnersGp2,
            pB: planningInvadableOwnersMinor1,
          },
        ),
        isTrue,
      );
    });
  });

  group('anyInvadableProvinceOwnedByGreatPower (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';

    test('true when an invadable province is owned by a Great Power', () {
      final game = planningInvadableOwnersGameWithGps();
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: planningInvadableOwnersGp2},
        ),
        isTrue,
      );
    });

    test(
      'false when invadable provinces are owned only by minors / tribes',
      () {
        final game = planningInvadableOwnersGameWithGps();
        final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA, pB]);
        expect(
          anyInvadableProvinceOwnedByGreatPower(
            game: game,
            snapshot: snapshot,
            provinceOwner: const {
              pA: planningInvadableOwnersMinor1,
              pB: planningInvadableOwnersTribe1,
            },
          ),
          isFalse,
        );
      },
    );

    test('false when an invadable province owner is absent from the map', () {
      // Unowned / not-yet-mapped invadable province: `?? ''` -> playerById null.
      final game = planningInvadableOwnersGameWithGps();
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {},
        ),
        isFalse,
      );
    });

    test('false when there are no invadable provinces', () {
      final game = planningInvadableOwnersGameWithGps();
      final snapshot = planningInvadableOwnersSnapshotWithInvadable(const []);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: planningInvadableOwnersGp2},
        ),
        isFalse,
      );
    });

    test('true when only a non-first invadable province is GP-owned', () {
      // The .any short-circuit must still find a GP owner that is not the
      // first scanned entry (minor first, GP second) -> deterministic true.
      final game = planningInvadableOwnersGameWithGps();
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA, pB]);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {
            pA: planningInvadableOwnersMinor1,
            pB: planningInvadableOwnersGp2,
          },
        ),
        isTrue,
      );
    });
  });

  group('factionOwnsInvadableOldWorldProvince (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';

    test('true when the faction owns an invadable province', () {
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {pA: planningInvadableOwnersGp2},
          factionId: planningInvadableOwnersGp2,
        ),
        isTrue,
      );
    });

    test('false when invadable provinces are owned by other factions', () {
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA, pB]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {
            pA: planningInvadableOwnersGp3,
            pB: planningInvadableOwnersMinor1,
          },
          factionId: planningInvadableOwnersGp2,
        ),
        isFalse,
      );
    });

    test('false when the owner lookup is absent from the map', () {
      // Unowned / not-yet-mapped invadable province: lookup is null, no match.
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {},
          factionId: planningInvadableOwnersGp2,
        ),
        isFalse,
      );
    });

    test('false when there are no invadable provinces', () {
      final snapshot = planningInvadableOwnersSnapshotWithInvadable(const []);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {pA: planningInvadableOwnersGp2},
          factionId: planningInvadableOwnersGp2,
        ),
        isFalse,
      );
    });

    test('true when only a non-first invadable province is faction-owned', () {
      // The .any short-circuit must still find the faction owner that is not
      // the first scanned entry (other GP first, target second) -> true.
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA, pB]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {
            pA: planningInvadableOwnersGp3,
            pB: planningInvadableOwnersGp2,
          },
          factionId: planningInvadableOwnersGp2,
        ),
        isTrue,
      );
    });

    test('agrees with the inline scan it replaces (equivalence)', () {
      final snapshot = planningInvadableOwnersSnapshotWithInvadable([pA, pB]);
      for (final owner in <Map<String, String>>[
        const {},
        const {pA: planningInvadableOwnersGp2},
        const {pA: planningInvadableOwnersGp3, pB: planningInvadableOwnersGp2},
        const {pA: planningInvadableOwnersGp3, pB: planningInvadableOwnersMinor1},
      ]) {
        expect(
          factionOwnsInvadableOldWorldProvince(
            snapshot: snapshot,
            provinceOwner: owner,
            factionId: planningInvadableOwnersGp2,
          ),
          snapshot.conquest.invadableProvinceIdsSorted.any(
            (pid) => owner[pid] == planningInvadableOwnersGp2,
          ),
          reason: 'mismatch for provinceOwner=$owner',
        );
      }
    });
  });
}
