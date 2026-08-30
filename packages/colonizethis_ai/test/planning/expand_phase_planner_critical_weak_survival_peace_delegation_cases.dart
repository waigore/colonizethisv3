// criticalWeakGpSurvivalPeaceTargets — stub delegation parity (Refs #4602 Slice B).

// Case bodies for criticalWeakGpSurvivalPeaceTargets pins in
// `expand_phase_planner_critical_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_peace_support.dart';

void registerExpandPhasePlannerCriticalWeakSurvivalPeaceDelegationCases() {
  group('criticalWeakGpSurvivalPeaceTargets — stub delegation parity', () {
    test('diplomacy_planner_peace_targets stub returns the canonical list', () {
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: criticalPeaceRivalProvinces(
            criticalPeaceGpStronger,
            7,
          ),
          criticalPeaceGpThird: criticalPeaceRivalProvinces(
            criticalPeaceGpThird,
            5,
          ),
        },
        atWarFactionIds: const [criticalPeaceGpStronger, criticalPeaceGpThird],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [criticalPeaceGpStronger, criticalPeaceGpThird],
      );
      final canonical = criticalWeakGpSurvivalPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot);
      expect(
        stub,
        equals(canonical),
        reason:
            'The legacy stub must remain byte-equivalent to the canonical '
            'helper so the legacy '
            'diplomacy_planner_mutual_exhausted_peace_test.dart and '
            'diplomacy_planner_stalled_peace_test.dart fixtures and the '
            'in-file _survivalGreatPowerPeaceTargets / '
            'stalledOwExpansionNeedsPeacePass consumer chains continue '
            'to resolve to the same behavior.',
      );
    });

    test(
      'stub returns const [] outer guard match (above defend threshold)',
      () {
        // Both stub and canonical must agree on the outer-guard skip.
        final game = buildCriticalExpandPeaceGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold + 1,
          gpRivalProvincesById: {
            criticalPeaceGpStronger: criticalPeaceRivalProvinces(
              criticalPeaceGpStronger,
              12,
            ),
          },
          atWarFactionIds: const [criticalPeaceGpStronger],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold + 1,
          atWarWith: const [criticalPeaceGpStronger],
        );
        final canonical = criticalWeakGpSurvivalPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final stub = diplomacy_planner_peace_targets
            .criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot);
        expect(canonical, isEmpty);
        expect(stub, isEmpty);
      },
    );
  });
}
