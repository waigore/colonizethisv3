// Faction ownership predicate case bodies for
// `planning_invadable_owners_predicate_cases.dart`.

import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_invadable_owners_test_support.dart';

void registerPlanningInvadableOwnersPredicateFactionCases() {
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
