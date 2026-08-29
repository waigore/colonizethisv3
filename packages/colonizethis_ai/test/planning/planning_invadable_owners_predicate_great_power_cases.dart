// Great-power predicate case bodies for `planning_invadable_owners_predicate_cases.dart`.

import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_invadable_owners_test_support.dart';

void registerPlanningInvadableOwnersPredicateGreatPowerCases() {
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
}
