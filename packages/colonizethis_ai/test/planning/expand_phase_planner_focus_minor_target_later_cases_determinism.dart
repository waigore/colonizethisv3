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

void registerExpandPhasePlannerFocusMinorTargetLaterDeterminismCases() {
  group('Determinism (Must-have #7)', () {
    test('stalledFocusMinorTarget returns identical results on repeat', () {
      final game = expandPhasePlannerFocusMinorTargetGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
          kFocusMinorMinorBeta: ['oldWorld|beta_1', 'oldWorld|beta_2'],
        },
        atWarMinors: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_1',
          'oldWorld|beta_1',
          'oldWorld|beta_2',
        ],
      );
      final first = stalledFocusMinorTarget(game: game, snapshot: snapshot);
      final second = stalledFocusMinorTarget(game: game, snapshot: snapshot);
      expect(first, equals(second));
      expect(first, kFocusMinorMinorBeta);
    });

    test(
      'belowQuotaActiveMinorWarTarget returns identical results on repeat',
      () {
        final game = expandPhasePlannerFocusMinorTargetGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          minorOwnedInvadables: const {
            kFocusMinorMinorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
          },
          atWarMinors: const [kFocusMinorMinorAlpha],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [kFocusMinorMinorAlpha],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
          ],
        );
        final first = belowQuotaActiveMinorWarTarget(
          game: game,
          snapshot: snapshot,
        );
        final second = belowQuotaActiveMinorWarTarget(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, kFocusMinorMinorAlpha);
      },
    );
  });

}
