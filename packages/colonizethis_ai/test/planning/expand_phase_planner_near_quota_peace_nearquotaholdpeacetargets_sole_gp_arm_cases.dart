// nearQuotaHoldPeaceTargets — sole-GP arm (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_default_start_near_quota_peace_support.dart';

void registerNearQuotaPeaceNearquotaholdpeacetargetsSoleGpArmCases() {
  group('nearQuotaHoldPeaceTargets — sole-GP arm', () {
    test(
      'sole GP mutual-plateau on GP-only frontier with no minor pivot peaces lone GP',
      () {
        // gp_own=8, gp_a=8 → mutual-plateau peer (|partner-own| <= 1,
        // both stalled below quota). Only invadable OW is gp_a's →
        // GP-only frontier. No OW minors → !hasUninvadedOldWorldMinor.
        // Canonical helper returns the unsorted single-GP list.
        final game = buildDefaultStartNearQuotaExpandPeaceGame(
          owOwners: const {defaultStartPeaceGpOwn: 8, defaultStartPeaceGpA: 8},
          atWarPartners: const [defaultStartPeaceGpA],
        );
        final snapshot = defaultStartPeaceSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
          atWarWith: const [defaultStartPeaceGpA],
          invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
        );
        expect(
          nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
          const [defaultStartPeaceGpA],
          reason:
              'The mutual-plateau sole-GP carve-out peaces the lone GP '
              'when the war is a stalemate on a GP-only invadable '
              'frontier with no remaining OW minor pivot.',
        );
      },
    );

    test('sole GP blocker with no minor pivot holds the war open', () {
      // gp_own=8, gp_a=10 (not mutual-plateau peer because |10-8|>1),
      // no minor on the map → hasUninvadedOldWorldMinor=false. gp_a
      // owns the only invadable OW (GP-only frontier). Sole GP at war
      // is the blocker; minor pivot is absent so the
      // sole-GP-blocker hold-open guard fires and the canonical helper
      // returns const [] — keep fighting the blocker.
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {defaultStartPeaceGpOwn: 8, defaultStartPeaceGpA: 10},
        atWarPartners: const [defaultStartPeaceGpA],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [defaultStartPeaceGpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'When the lone GP is the primary invadable OW blocker and '
            'no minor pivot remains, the canonical helper must hold '
            'the war open (return const []) so the planner keeps '
            'fighting the blocker. A regression that dropped the '
            '!hasUninvadedOldWorldMinor gate would silently surrender '
            'the war here.',
      );
    });

    test(
      'sole GP fall-through (non-blocker, non-plateau) returns the single-GP list',
      () {
        // gp_own=8, gp_a=8 (stalled-plateau peers). gp_a holds nothing
        // on the invadable list; the sole invadable OW is owned by
        // minor_m1 → frontier is NOT GP-only. Plateau check fires but
        // gpOnlyFrontier=false → mutual-plateau carve-out skipped. The
        // blocker is null because gp_a owns no invadable, so the
        // sole-GP-blocker hold guard does not trigger. Multi-GP arm
        // requires length >= 2; with length 1 the function falls
        // through to `return gpWars` (single-GP fall-through path).
        final game = buildDefaultStartNearQuotaExpandPeaceGame(
          owOwners: const {
            defaultStartPeaceGpOwn: 8,
            defaultStartPeaceGpA: 8,
            defaultStartPeaceMinorM1: 1,
          },
          atWarPartners: const [defaultStartPeaceGpA],
        );
        final snapshot = defaultStartPeaceSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
          atWarWith: const [defaultStartPeaceGpA],
          invadableProvinceIdsSorted: const ['oldWorld|minor_m1_1'],
        );
        expect(
          nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
          const [defaultStartPeaceGpA],
          reason:
              'The sole-GP fall-through path returns the single-GP list '
              'unchanged when neither the mutual-plateau carve-out nor '
              'the blocker hold-open guard fires.',
        );
      },
    );
  });
}
