// Topic-split cases from `expand_phase_planner_focus_minor_target_early_cases` (Refs #4669 Slice B).
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import '../support/expand_phase_planner_focus_minor_target_test_support.dart';

void registerExpandPhasePlannerFocusMinorTargetEarlyBelowQuotaGuardCases() {
  group('belowQuotaActiveMinorWarTarget — canonical outer guard', () {
    test(
      'returns null at quota even when a focused minor would fire below',
      () {
        // ownOw == quota → isBelowObserverConquestQuota is false →
        // outer guard fires before the inner stalledFocusMinorTarget
        // delegation. Even with minor_alpha clearly leading the
        // invadable count, the helper returns null at quota.
        final game = expandPhasePlannerFocusMinorTargetGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          minorOwnedInvadables: const {
            kFocusMinorMinorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
          },
          atWarMinors: const [kFocusMinorMinorAlpha],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [kFocusMinorMinorAlpha],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
          ],
        );
        expect(
          belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'At quota the quota-met / consolidate deciders own '
              'minor-front decisions. A regression that flipped the '
              'guard from `<` to `<=` would silently engage the '
              'helper at quota and force-hold a minor war the '
              'consolidate arm intended to peace.',
        );
        // Sanity-pin the same input through the canonical inner
        // helper to confirm the outer guard is the only difference
        // (would have returned minor_alpha otherwise).
        expect(
          stalledFocusMinorTarget(game: game, snapshot: snapshot),
          kFocusMinorMinorAlpha,
          reason:
              'Without the below-quota guard the focused-minor scan '
              'would pick minor_alpha; the outer guard is the only '
              'reason belowQuotaActiveMinorWarTarget returns null.',
        );
      },
    );
  });
}
