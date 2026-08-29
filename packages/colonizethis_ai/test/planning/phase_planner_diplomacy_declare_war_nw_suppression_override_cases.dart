// Override and legacy-path cases for Phase 3 declare-war NW wiring.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_diplomacy_declare_war_nw_suppression_support.dart';

void registerPhasePlannerDiplomacyDeclareWarNwSuppressionOverrideCases() {
  group('Phase 3 diplomacy declare-war override paths (Refs #2847)', () {
    test(
      'EXPAND with explicit nwAcquisition = 0.0 collapses NW tribe '
      'declare-war (legacy hard-suppress equivalent)',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: kDiplomacyNwSuppressionZeroAcquisition,
        );
        final score = diplomacyNwSuppressionTribeDeclareWarScore(
          phasePlan: phasePlan,
        );
        expect(
          score,
          kDeclareWarNonAdjacentSuppressedScore,
          reason:
              'EXPAND with nwAcquisition = 0.0 must collapse NW tribe '
              'declare-war via the EXPAND-colonial suppression branch '
              '(weight gate restored to the legacy hard-suppress).',
        );
      },
    );

    test(
      'COLONIAL-lite with explicit nwAcquisition = 0.0 collapses NW tribe '
      'declare-war (legacy hard-suppress equivalent)',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonialLite,
          priorityWeights: kDiplomacyNwSuppressionZeroAcquisition,
        );
        final score = diplomacyNwSuppressionTribeDeclareWarScore(
          phasePlan: phasePlan,
        );
        expect(
          score,
          kDeclareWarNonAdjacentSuppressedScore,
          reason:
              'COLONIAL-lite with nwAcquisition = 0.0 must collapse NW '
              'tribe declare-war via the COLONIAL-lite suppression branch.',
        );
      },
    );

    test(
      'DEVELOP suppression contract is preserved (DEVELOP collapses every '
      'declare-war candidate independent of NW weight)',
      () {
        const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
        final score = diplomacyNwSuppressionTribeDeclareWarScore(
          phasePlan: phasePlan,
        );
        expect(
          score,
          kDeclareWarNonAdjacentSuppressedScore,
          reason:
              'DEVELOP must still collapse every declare-war candidate '
              'via _declareWarSuppressedDevelopPhaseScore — the Phase 3 '
              'slice migrated EXPAND / COLONIAL-lite only.',
        );
      },
    );

    test(
      'null phase plan with at-quota colonial-acquisition snapshot keeps '
      'NW tribe declare-war scorable (legacy 1.0 weight branch)',
      () {
        final score = diplomacyNwSuppressionTribeDeclareWarScore(phasePlan: null);
        expect(
          score,
          greaterThanOrEqualTo(kDeclareWarColonialAdjacentTribeBonus),
          reason:
              'Null phase plan must use the legacy weight mapping; with '
              'visible colonial acquisition targets the weight maps to '
              '1.0 and the candidate survives via the `> 0.0` gate.',
        );
      },
    );
  });
}
