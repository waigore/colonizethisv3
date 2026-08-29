// Topic-split cases from `expand_phase_planner_focus_minor_target_early_cases` (Refs #4669 Slice B).
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import '../support/expand_phase_planner_focus_minor_target_test_support.dart';

void registerExpandPhasePlannerFocusMinorTargetEarlyGuardsCases() {
  group('stalledFocusMinorTarget — canonical outer guards', () {
    test('returns null when no minor is at war', () {
      // Only a tribe and a rival GP are at war; the
      // Game.minorNations / RelationState.atWar filter rejects every
      // minor candidate before the invadable scan runs.
      final game = expandPhasePlannerFocusMinorTargetGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
        },
        peacefulMinors: const [kFocusMinorMinorAlpha],
        atWarTribes: const [kFocusMinorTribeOne],
        atWarRivalGps: const [kFocusMinorGpRival],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [kFocusMinorTribeOne, kFocusMinorGpRival],
        invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
      );
      expect(
        stalledFocusMinorTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No at-war minor → the at-war filter rejects every '
            'Game.minorNations candidate before the invadable scan; '
            'tribes do not participate even though tribe_one owns '
            'an invadable province in a sibling fixture.',
      );
    });

    test(
      'returns null when at-war minors exist but own no invadable OW provinces',
      () {
        // Both minors are at war but own only non-invadable OW
        // provinces; the bestInvadableCount stays at 0 so the helper
        // returns null without picking an arbitrary minor.
        final game = expandPhasePlannerFocusMinorTargetGame(
          ownProvinces: 7,
          minorOwnedInvadables: const {
            kFocusMinorMinorAlpha: ['oldWorld|alpha_home'],
            kFocusMinorMinorBeta: ['oldWorld|beta_home'],
          },
          atWarMinors: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
          // None of the at-war minors' provinces appear in the
          // invadable frontier.
          invadableProvinceIdsSorted: const [],
        );
        expect(
          stalledFocusMinorTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'Empty invadableProvinceIdsSorted → every minor scores '
              '0 → the strict-greater comparison never updates; '
              'returning null preserves the "no focused front" '
              'contract instead of arbitrarily picking one minor.',
        );
      },
    );
  });

}
