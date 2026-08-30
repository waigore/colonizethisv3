// criticalWeakGpSurvivalPeaceTargets — determinism (Refs #4602 Slice B).

// Case bodies for criticalWeakGpSurvivalPeaceTargets pins in
// `expand_phase_planner_critical_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_peace_support.dart';

void registerExpandPhasePlannerCriticalWeakSurvivalPeaceDeterminismCases() {
  group('criticalWeakGpSurvivalPeaceTargets — determinism', () {
    test(
      'two consecutive invocations return identical lists (Must-have #7)',
      () {
        final game = buildCriticalExpandPeaceGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold,
          gpRivalProvincesById: {
            criticalPeaceGpStronger: criticalPeaceRivalProvinces(
              criticalPeaceGpStronger,
              7,
            ),
            criticalPeaceGpFourth: criticalPeaceRivalProvinces(
              criticalPeaceGpFourth,
              9,
            ),
          },
          atWarFactionIds: const [
            criticalPeaceGpStronger,
            criticalPeaceGpFourth,
          ],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
          atWarWith: const [criticalPeaceGpFourth, criticalPeaceGpStronger],
        );
        final first = criticalWeakGpSurvivalPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = criticalWeakGpSurvivalPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, const [criticalPeaceGpFourth, criticalPeaceGpStronger]);
      },
    );
  });
}
