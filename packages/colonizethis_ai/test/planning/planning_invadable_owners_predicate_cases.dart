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
}
