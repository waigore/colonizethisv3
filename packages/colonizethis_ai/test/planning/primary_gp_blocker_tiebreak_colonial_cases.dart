// primaryColonialGpBlocker tiebreak cases (Refs #4602 Slice D).

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/primary_gp_blocker_tiebreak_test_support.dart';

void registerPrimaryColonialGpBlockerTiebreakCases() {
  group('primaryColonialGpBlocker tiebreak', () {
    test('2-vs-2 split: gp2 wins when its sorted provinces appear first', () {
      // Mirror of the OW tiebreak case for the NW colonial blocker. gp2 owns
      // the first two invadable NW provinces in sorted order; gp3 owns the
      // remaining two. The COLONIAL blocker-preservation set keeps the war
      // with gp2 intact and peaces gp3 (when both are at war).
      final game = primaryGpBlockerTiebreakGameForNwBlocker(const [
        Province(
          id: 'newWorld|a1',
          regionId: 'newWorld',
          ownerId: kPrimaryGpBlockerTiebreakGp2,
        ),
        Province(
          id: 'newWorld|a2',
          regionId: 'newWorld',
          ownerId: kPrimaryGpBlockerTiebreakGp2,
        ),
        Province(
          id: 'newWorld|b1',
          regionId: 'newWorld',
          ownerId: kPrimaryGpBlockerTiebreakGp3,
        ),
        Province(
          id: 'newWorld|b2',
          regionId: 'newWorld',
          ownerId: kPrimaryGpBlockerTiebreakGp3,
        ),
      ]);
      final snapshot = primaryGpBlockerTiebreakColonialSnapshotForNw(
        invadableNw: const [
          'newWorld|a1',
          'newWorld|a2',
          'newWorld|b1',
          'newWorld|b2',
        ],
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        kPrimaryGpBlockerTiebreakGp2,
        reason:
            'Equal-count plurality must resolve by first-iterated-province '
            'order over `invadableNewWorldProvinceIdsSorted`. A refactor '
            'switching strict `>` to `>=` would flip this to gp3 and '
            'silently shift COLONIAL peace-preservation onto the wrong GP.',
      );
    });

    test('2-vs-2 split: gp3 wins when its sorted provinces appear first', () {
      // Symmetric inversion to confirm the tiebreak is genuinely
      // first-iterated-province driven, not a factionId-ascending bias.
      final game = primaryGpBlockerTiebreakGameForNwBlocker(const [
        Province(
          id: 'newWorld|a1',
          regionId: 'newWorld',
          ownerId: kPrimaryGpBlockerTiebreakGp3,
        ),
        Province(
          id: 'newWorld|a2',
          regionId: 'newWorld',
          ownerId: kPrimaryGpBlockerTiebreakGp3,
        ),
        Province(
          id: 'newWorld|b1',
          regionId: 'newWorld',
          ownerId: kPrimaryGpBlockerTiebreakGp2,
        ),
        Province(
          id: 'newWorld|b2',
          regionId: 'newWorld',
          ownerId: kPrimaryGpBlockerTiebreakGp2,
        ),
      ]);
      final snapshot = primaryGpBlockerTiebreakColonialSnapshotForNw(
        invadableNw: const [
          'newWorld|a1',
          'newWorld|a2',
          'newWorld|b1',
          'newWorld|b2',
        ],
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        kPrimaryGpBlockerTiebreakGp3,
      );
    });

    test(
      '3-way 2-2-2 tie: first GP in sorted order wins deterministically',
      () {
        final game = primaryGpBlockerTiebreakGameForNwBlocker(const [
          Province(
            id: 'newWorld|a1',
            regionId: 'newWorld',
            ownerId: kPrimaryGpBlockerTiebreakGp2,
          ),
          Province(
            id: 'newWorld|a2',
            regionId: 'newWorld',
            ownerId: kPrimaryGpBlockerTiebreakGp2,
          ),
          Province(
            id: 'newWorld|b1',
            regionId: 'newWorld',
            ownerId: kPrimaryGpBlockerTiebreakGp3,
          ),
          Province(
            id: 'newWorld|b2',
            regionId: 'newWorld',
            ownerId: kPrimaryGpBlockerTiebreakGp3,
          ),
          Province(
            id: 'newWorld|c1',
            regionId: 'newWorld',
            ownerId: kPrimaryGpBlockerTiebreakGp4,
          ),
          Province(
            id: 'newWorld|c2',
            regionId: 'newWorld',
            ownerId: kPrimaryGpBlockerTiebreakGp4,
          ),
        ]);
        final snapshot = primaryGpBlockerTiebreakColonialSnapshotForNw(
          invadableNw: const [
            'newWorld|a1',
            'newWorld|a2',
            'newWorld|b1',
            'newWorld|b2',
            'newWorld|c1',
            'newWorld|c2',
          ],
        );
        final first = primaryColonialGpBlocker(game: game, snapshot: snapshot);
        final second = primaryColonialGpBlocker(game: game, snapshot: snapshot);
        expect(first, kPrimaryGpBlockerTiebreakGp2);
        expect(
          second,
          kPrimaryGpBlockerTiebreakGp2,
          reason: 'Determinism guard (must-have #7).',
        );
      },
    );

    test('large-N many-province scenario: plurality winner is stable', () {
      // 30-invadable-NW fixture stresses the linearized scan path (the
      // previous quadratic implementation traversed 30 * 30 = 900 inner
      // iterations; the refactored version visits each province twice).
      // The plurality GP must remain gp3 with 15 owned invadable NW
      // provinces against gp2's 10 and gp4's 5.
      final provinces = <Province>[
        for (var i = 0; i < 10; i++)
          Province(
            id: 'newWorld|gp2_$i',
            regionId: 'newWorld',
            ownerId: kPrimaryGpBlockerTiebreakGp2,
          ),
        for (var i = 0; i < 15; i++)
          Province(
            id: 'newWorld|gp3_$i',
            regionId: 'newWorld',
            ownerId: kPrimaryGpBlockerTiebreakGp3,
          ),
        for (var i = 0; i < 5; i++)
          Province(
            id: 'newWorld|gp4_$i',
            regionId: 'newWorld',
            ownerId: kPrimaryGpBlockerTiebreakGp4,
          ),
      ];
      final game = primaryGpBlockerTiebreakGameForNwBlocker(provinces);
      final invadable = [for (final p in provinces) p.id]..sort();
      final snapshot = primaryGpBlockerTiebreakColonialSnapshotForNw(
        invadableNw: invadable,
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        kPrimaryGpBlockerTiebreakGp3,
        reason:
            'Strict plurality (15 > 10 > 5) must continue to resolve to gp3 '
            'after the quadratic-to-linear refactor. A regression that '
            'tallied counts incorrectly (e.g. counting tribe-owned or '
            'unowned provinces, or skipping the strict `>` update) would '
            'shift the winner.',
      );
    });
  });
}
