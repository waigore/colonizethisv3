// nearQuotaHoldPeaceTargets — multi-GP arm (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_default_start_near_quota_peace_support.dart';

void registerNearQuotaPeaceNearquotaholdpeacetargetsMultiGpArmCases() {
  group('nearQuotaHoldPeaceTargets — multi-GP arm', () {
    test('multi-GP at war excludes the blocker and returns ascending', () {
      // gp_own=8 (stalled-plateau, below quota). Three GPs at war
      // supplied out of order; gp_a owns the sole invadable OW
      // (blocker). Canonical helper returns [gp_b, gp_c] ascending.
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {
          defaultStartPeaceGpOwn: 8,
          defaultStartPeaceGpA: 1,
          defaultStartPeaceGpB: 0,
          defaultStartPeaceGpC: 0,
        },
        atWarPartners: const [
          defaultStartPeaceGpC,
          defaultStartPeaceGpA,
          defaultStartPeaceGpB,
        ],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [
          defaultStartPeaceGpC,
          defaultStartPeaceGpA,
          defaultStartPeaceGpB,
        ],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        const [defaultStartPeaceGpB, defaultStartPeaceGpC],
        reason:
            'The multi-GP arm excludes only the primary invadable OW '
            'blocker (gp_a) and returns the remaining GPs ascending '
            'across an out-of-order input list.',
      );
    });

    test(
      'multi-GP with null blocker (no invadable OW) returns every at-war GP sorted',
      () {
        // gp_own=8 (stalled-plateau). Two GPs at war but
        // invadableProvinceIdsSorted is empty → blocker == null →
        // every at-war GP is returned ascending.
        final game = buildDefaultStartNearQuotaExpandPeaceGame(
          owOwners: const {
            defaultStartPeaceGpOwn: 8,
            defaultStartPeaceGpA: 0,
            defaultStartPeaceGpB: 0,
          },
          atWarPartners: const [defaultStartPeaceGpA, defaultStartPeaceGpB],
        );
        final snapshot = defaultStartPeaceSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [defaultStartPeaceGpB, defaultStartPeaceGpA],
        );
        expect(
          nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
          const [defaultStartPeaceGpA, defaultStartPeaceGpB],
          reason:
              'When no invadable OW exists the blocker is null and the '
              'multi-GP arm peaces every at-war GP ascending.',
        );
      },
    );
  });
}
