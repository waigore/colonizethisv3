// nearQuotaHoldPeaceTargets — determinism / delegation (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_default_start_near_quota_peace_support.dart';

void registerNearQuotaPeaceNearquotaholdpeacetargetsDeterminismDeCases() {
  group('nearQuotaHoldPeaceTargets — determinism / delegation', () {
    test('identical inputs return identical lists across two calls', () {
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {
          defaultStartPeaceGpOwn: 8,
          defaultStartPeaceGpA: 1,
          defaultStartPeaceGpB: 0,
        },
        atWarPartners: const [defaultStartPeaceGpA, defaultStartPeaceGpB],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [defaultStartPeaceGpA, defaultStartPeaceGpB],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      final first = nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot);
      final second = nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot);
      expect(
        second,
        first,
        reason:
            'Two consecutive canonical-helper invocations on identical '
            'inputs must return identical lists (Must-have #7).',
      );
    });
  });
}
