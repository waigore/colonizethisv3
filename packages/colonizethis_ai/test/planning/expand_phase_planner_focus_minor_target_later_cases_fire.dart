// Topic-split cases from `expand_phase_planner_focus_minor_target_later_cases` (Refs #4669 Slice B).
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import '../support/expand_phase_planner_focus_minor_target_test_support.dart';

void registerExpandPhasePlannerFocusMinorTargetLaterFireCases() {
  group('belowQuotaActiveMinorWarTarget — fire path', () {
    test(
      'returns the focused minor below quota (delegates to stalledFocusMinorTarget)',
      () {
        // ownOw < quota → outer guard passes → result mirrors
        // stalledFocusMinorTarget exactly.
        final game = expandPhasePlannerFocusMinorTargetGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          minorOwnedInvadables: const {
            kFocusMinorMinorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
            kFocusMinorMinorBeta: ['oldWorld|beta_1'],
          },
          atWarMinors: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
            'oldWorld|beta_1',
          ],
        );
        expect(
          belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
          kFocusMinorMinorAlpha,
          reason:
              'Below quota → outer guard passes → result mirrors '
              'stalledFocusMinorTarget which prefers minor_alpha (2 '
              'invadable provinces vs minor_beta\'s 1).',
        );
      },
    );

    test('returns null below quota when focused-minor scan finds nothing', () {
      // Below quota but no at-war minor owns an invadable province →
      // stalledFocusMinorTarget returns null → the wrapper passes
      // that null through unchanged.
      final game = expandPhasePlannerFocusMinorTargetGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
        minorOwnedInvadables: const {
          kFocusMinorMinorAlpha: ['oldWorld|alpha_home'],
        },
        atWarMinors: const [kFocusMinorMinorAlpha],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        atWarWith: const [kFocusMinorMinorAlpha],
        invadableProvinceIdsSorted: const [],
      );
      expect(
        belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Below quota but the inner focused-minor scan finds no '
            'candidate (empty invadable list) → the wrapper must '
            'return null instead of inventing a target.',
      );
    });
  });

}
