// Default soft-curve and determinism cases for Phase 3 declare-war NW wiring.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_diplomacy_declare_war_nw_suppression_support.dart';

void registerPhasePlannerDiplomacyDeclareWarNwSuppressionDefaultCurveCases() {
  group('Phase 3 diplomacy declare-war soft-weight default curve (Refs #2847)', () {
    test(
      'EXPAND default soft curve keeps NW tribe declare-war scorable '
      '(no boolean structural collapse)',
      () {
        const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
        final score = diplomacyNwSuppressionTribeDeclareWarScore(
          phasePlan: phasePlan,
        );
        expect(
          score,
          greaterThanOrEqualTo(kDeclareWarColonialAdjacentTribeBonus),
          reason:
              'EXPAND with default soft curve must NOT collapse NW tribe '
              'declare-war via the EXPAND-colonial suppression branch — '
              'the candidate must reach the colonial-adjacent tribe '
              'bonus path (weight = 0.05 > 0).',
        );
      },
    );

    test(
      'COLONIAL-lite default soft curve keeps NW tribe declare-war scorable',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonialLite,
        );
        final score = diplomacyNwSuppressionTribeDeclareWarScore(
          phasePlan: phasePlan,
        );
        expect(
          score,
          greaterThanOrEqualTo(kDeclareWarColonialAdjacentTribeBonus),
          reason:
              'COLONIAL-lite with default soft curve must NOT collapse NW '
              'tribe declare-war via the COLONIAL-lite suppression branch — '
              'the candidate must reach the colonial-adjacent tribe '
              'bonus path (weight = 0.05 > 0).',
        );
      },
    );

    test(
      'deterministic across repeated EXPAND default-curve calls '
      '(Must-have #7)',
      () {
        const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
        final a = diplomacyNwSuppressionTribeDeclareWarScore(phasePlan: phasePlan);
        final b = diplomacyNwSuppressionTribeDeclareWarScore(phasePlan: phasePlan);
        final c = diplomacyNwSuppressionTribeDeclareWarScore(phasePlan: phasePlan);
        expect(a, b, reason: 'two-call determinism');
        expect(b, c, reason: 'three-call determinism');
      },
    );
  });
}
