// criticalMultiFrontGpPeaceTargets — determinism (Refs #4602 Slice B).

// Case bodies for criticalMultiFrontGpPeaceTargets pins in
// `expand_phase_planner_critical_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_peace_support.dart';

void
registerCriticalMultiFrontPeaceCriticalmultifrontgppeacetargetsDetermiCases() {
  group('criticalMultiFrontGpPeaceTargets — determinism', () {
    test(
      'two consecutive invocations return identical lists (Must-have #7)',
      () {
        const invadable = 'oldWorld|frontier_invadable';
        final game = buildCriticalExpandPeaceGame(
          ownProvinces: kStalledOldWorldProvinceThreshold,
          gpRivalProvincesById: {
            criticalPeaceGpStronger: [invadable],
            criticalPeaceGpThird: criticalPeaceRivalProvinces(
              criticalPeaceGpThird,
              5,
            ),
            criticalPeaceGpFourth: criticalPeaceRivalProvinces(
              criticalPeaceGpFourth,
              5,
            ),
          },
          atWarFactionIds: const [
            criticalPeaceGpStronger,
            criticalPeaceGpThird,
            criticalPeaceGpFourth,
          ],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [
            criticalPeaceGpFourth,
            criticalPeaceGpStronger,
            criticalPeaceGpThird,
          ],
          invadableProvinceIdsSorted: const [invadable],
        );
        final first = criticalMultiFrontGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = criticalMultiFrontGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, const [criticalPeaceGpFourth, criticalPeaceGpThird]);
      },
    );
  });
}
