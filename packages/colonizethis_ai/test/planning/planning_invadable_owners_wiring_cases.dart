// Case bodies for `planning_invadable_owners_test.dart` (Refs #4310 Slice D).
// Pins invadable minor-owner collector and at-war blocker gate.

import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_ai/src/util/faction_query.dart'
    show isMinorFaction;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_invadable_owners_test_support.dart';

void registerPlanningInvadableOwnersWiringCases() {
  group('addInvadableProvinceMinorOwnersNotAtWar (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';
    const String pC = 'provC';
    const String minor2 = 'minor2';

    test('collects minor owners of invadable provinces not already at war', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: planningInvadableOwnersGameWithTwoMinors(),
        snapshot: planningInvadableOwnersCollectorSnapshot([pA, pB], const []),
        provinceOwner: const {
          pA: planningInvadableOwnersMinor1,
          pB: minor2,
        },
        into: into,
      );
      expect(into, <String>{planningInvadableOwnersMinor1, minor2});
    });

    test('skips minors already at war', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: planningInvadableOwnersGameWithTwoMinors(),
        snapshot: planningInvadableOwnersCollectorSnapshot(
          [pA, pB],
          [planningInvadableOwnersMinor1],
        ),
        provinceOwner: const {
          pA: planningInvadableOwnersMinor1,
          pB: minor2,
        },
        into: into,
      );
      expect(into, <String>{minor2});
    });

    test('skips Great-Power, tribe, and unowned invadable provinces', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: planningInvadableOwnersGameWithTwoMinors(),
        snapshot: planningInvadableOwnersCollectorSnapshot(
          [pA, pB, pC],
          const [],
        ),
        // pA: GP, pB: tribe, pC: absent from the owner map (null lookup).
        provinceOwner: const {
          pA: planningInvadableOwnersGp1,
          pB: planningInvadableOwnersTribe1,
        },
        into: into,
      );
      expect(into, isEmpty);
    });

    test('adds nothing when there are no invadable provinces', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: planningInvadableOwnersGameWithTwoMinors(),
        snapshot: planningInvadableOwnersCollectorSnapshot(const [], const []),
        provinceOwner: const {pA: planningInvadableOwnersMinor1},
        into: into,
      );
      expect(into, isEmpty);
    });

    test('preserves pre-seeded entries and de-duplicates via set', () {
      // Mirrors the plateau decider seeding adjacent-owner candidates first.
      final into = <String>{planningInvadableOwnersMinor1};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: planningInvadableOwnersGameWithTwoMinors(),
        snapshot: planningInvadableOwnersCollectorSnapshot([pA, pB], const []),
        provinceOwner: const {
          pA: planningInvadableOwnersMinor1,
          pB: minor2,
        },
        into: into,
      );
      expect(into, <String>{planningInvadableOwnersMinor1, minor2});
    });

    test('agrees with the inline collector loop it replaces (equivalence)', () {
      final game = planningInvadableOwnersGameWithTwoMinors();
      for (final atWar in <List<String>>[
        const [],
        [planningInvadableOwnersMinor1],
        [planningInvadableOwnersMinor1, minor2],
      ]) {
        for (final owner in <Map<String, String>>[
          const {},
          const {
            pA: planningInvadableOwnersMinor1,
            pB: minor2,
          },
          const {pA: planningInvadableOwnersGp1, pB: minor2},
          const {
            pA: planningInvadableOwnersTribe1,
            pB: planningInvadableOwnersMinor1,
          },
        ]) {
          final snap = planningInvadableOwnersCollectorSnapshot([pA, pB], atWar);
          final viaHelper = <String>{};
          addInvadableProvinceMinorOwnersNotAtWar(
            game: game,
            snapshot: snap,
            provinceOwner: owner,
            into: viaHelper,
          );
          final viaInline = <String>{};
          for (final pid in snap.conquest.invadableProvinceIdsSorted) {
            final o = owner[pid];
            if (o == null ||
                !isMinorFaction(game, o) ||
                snap.threats.atWarWith.contains(o)) {
              continue;
            }
            viaInline.add(o);
          }
          expect(
            viaHelper,
            viaInline,
            reason: 'mismatch for atWar=$atWar owner=$owner',
          );
        }
      }
    });
  });

  group('orderTargetIsAtWarInvadableBlocker (Refs #3717)', () {
    const Player gp = Player(
      id: planningInvadableOwnersGp2,
      displayName: 'GP2',
      isHuman: false,
    );

    test('true when target is the at-war primary invadable GP blocker', () {
      expect(
        orderTargetIsAtWarInvadableBlocker(
          targetGp: gp,
          snapshot: planningInvadableOwnersSnapshotAtWar(
            const [planningInvadableOwnersGp2],
          ),
          targetFactionId: planningInvadableOwnersGp2,
          invadableBlocker: planningInvadableOwnersGp2,
        ),
        isTrue,
      );
    });

    test('false when the target is not a Great Power (targetGp null)', () {
      expect(
        orderTargetIsAtWarInvadableBlocker(
          targetGp: null,
          snapshot: planningInvadableOwnersSnapshotAtWar(
            const [planningInvadableOwnersGp2],
          ),
          targetFactionId: planningInvadableOwnersGp2,
          invadableBlocker: planningInvadableOwnersGp2,
        ),
        isFalse,
      );
    });

    test('false when there is no primary invadable blocker', () {
      expect(
        orderTargetIsAtWarInvadableBlocker(
          targetGp: gp,
          snapshot: planningInvadableOwnersSnapshotAtWar(
            const [planningInvadableOwnersGp2],
          ),
          targetFactionId: planningInvadableOwnersGp2,
          invadableBlocker: null,
        ),
        isFalse,
      );
    });

    test('false when the order target is not the blocker', () {
      expect(
        orderTargetIsAtWarInvadableBlocker(
          targetGp: gp,
          snapshot: planningInvadableOwnersSnapshotAtWar(
            const [planningInvadableOwnersGp2, planningInvadableOwnersGp3],
          ),
          targetFactionId: planningInvadableOwnersGp2,
          invadableBlocker: planningInvadableOwnersGp3,
        ),
        isFalse,
      );
    });

    test('false when the blocker target is not currently at war', () {
      expect(
        orderTargetIsAtWarInvadableBlocker(
          targetGp: gp,
          snapshot: planningInvadableOwnersSnapshotAtWar(
            const [planningInvadableOwnersGp3],
          ),
          targetFactionId: planningInvadableOwnersGp2,
          invadableBlocker: planningInvadableOwnersGp2,
        ),
        isFalse,
      );
    });
  });
}
