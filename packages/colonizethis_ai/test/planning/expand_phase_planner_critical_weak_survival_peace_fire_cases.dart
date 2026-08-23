// criticalWeakGpSurvivalPeaceTargets — fire path filters and o (Refs #4602 Slice B).

// Case bodies for criticalWeakGpSurvivalPeaceTargets pins in
// `expand_phase_planner_critical_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_peace_support.dart';

void registerExpandPhasePlannerCriticalWeakSurvivalPeaceFireCases() {
  group('criticalWeakGpSurvivalPeaceTargets — fire path filters and order', () {
    test('filters non-GP atWarWith entries and sorts ascending', () {
      // gp_own at war with a minor, a tribe, and three GPs of mixed
      // strength. Only stronger GPs (lead >= 1 on the default-start
      // row at ownOw = 6) surface; minors and tribes are dropped.
      // Result must be lex-ascending by factionId.
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: criticalPeaceRivalProvinces(
            criticalPeaceGpStronger,
            7,
          ),
          criticalPeaceGpThird: criticalPeaceRivalProvinces(
            criticalPeaceGpThird,
            6,
          ),
          criticalPeaceGpFourth: criticalPeaceRivalProvinces(
            criticalPeaceGpFourth,
            9,
          ),
        },
        minorIds: const [criticalPeaceMinor1],
        tribeIds: const [criticalPeaceTribe1],
        atWarFactionIds: const [
          criticalPeaceGpStronger,
          criticalPeaceGpThird,
          criticalPeaceGpFourth,
          criticalPeaceMinor1,
          criticalPeaceTribe1,
        ],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [
          criticalPeaceGpFourth,
          criticalPeaceMinor1,
          criticalPeaceGpStronger,
          criticalPeaceTribe1,
          criticalPeaceGpThird,
        ],
      );
      final result = criticalWeakGpSurvivalPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        result,
        const [criticalPeaceGpFourth, criticalPeaceGpStronger],
        reason:
            'gp_fourth (lead 3) and gp_stronger (lead 1) both clear the '
            'minLead = 1 threshold; gp_third (lead 0) is equal-strength '
            'and dropped. Minor and tribe are filtered by Game.playerById. '
            'Sort order is ascending factionId regardless of input order.',
      );
    });
  });
}
